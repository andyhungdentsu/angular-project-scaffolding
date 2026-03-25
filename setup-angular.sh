#!/usr/bin/env bash
set -eou pipefail

# ============================================================
# Angular 專案初始化腳本
# 用法: bash setup-angular.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# ---------- 工具函式 ----------

info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$*"; }
error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; exit 1; }

prompt_input() {
  local msg="$1" var_name="$2"
  read -rp "$(printf "\033[1;36m[?]\033[0m %s: " "$msg")" "$var_name"
}

# ---------- 步驟 0：檢查 Git 設定 ----------

GIT_USER_NAME=$(git config user.name 2>/dev/null || true)
GIT_USER_EMAIL=$(git config user.email 2>/dev/null || true)

if [[ -z "$GIT_USER_NAME" ]]; then
  error "尚未設定 git user.name，請先執行：git config --global user.name \"Your Name\""
fi
if [[ -z "$GIT_USER_EMAIL" ]]; then
  error "尚未設定 git user.email，請先執行：git config --global user.email \"you@example.com\""
fi
info "Git 使用者: $GIT_USER_NAME <$GIT_USER_EMAIL>"

# ---------- 步驟 1：檢查 nvm / node ----------

HAS_NVM=false
NODE_VERSION="22.14.0"
ANGULAR_VERSION="20"

if command -v nvm &>/dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
  # 確保 nvm 已載入
  [ -s "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh"

  info "偵測到 nvm 已安裝"

  _INPUT_NODE=""
  prompt_input "請輸入要使用的 Node.js 版本（預設為 ${NODE_VERSION}）" _INPUT_NODE
  NODE_VERSION="${_INPUT_NODE:-$NODE_VERSION}"
  _INPUT_NG=""
  prompt_input "請輸入要使用的 Angular 版本（預設為 ${ANGULAR_VERSION}）" _INPUT_NG
  ANGULAR_VERSION="${_INPUT_NG:-$ANGULAR_VERSION}"

  # 切換 / 安裝 Node.js 版本
  if nvm ls "$NODE_VERSION" &>/dev/null; then
    nvm use "$NODE_VERSION"
  else
    info "安裝 Node.js v$NODE_VERSION ..."
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
  fi

elif command -v node &>/dev/null; then
  NODE_VERSION="$(node -v | sed 's/^v//')"
  ANGULAR_VERSION="19"
  info "未偵測到 nvm，但已安裝 Node.js v$NODE_VERSION"

  _INPUT_NG=""
  prompt_input "請輸入要使用的 Angular 版本（預設為 ${ANGULAR_VERSION}）" _INPUT_NG
  ANGULAR_VERSION="${_INPUT_NG:-$ANGULAR_VERSION}"

else
  error "未偵測到 nvm 或 Node.js，請先安裝其中之一後再執行此腳本。"
fi

NG_CMD="npx -y @angular/cli@${ANGULAR_VERSION}"
info "將使用 Angular CLI v${ANGULAR_VERSION}（透過 npx）"

# ---------- 步驟 2：詢問專案路徑與名稱 ----------

prompt_input "請輸入專案放置路徑（預設為當前目錄）" PROJECT_PATH
PROJECT_PATH="${PROJECT_PATH:-.}"

# 展開 ~ 與相對路徑
PROJECT_PATH="$(eval echo "$PROJECT_PATH")"
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || error "路徑不存在: $PROJECT_PATH"

[ -d "$PROJECT_PATH" ] || error "路徑不存在: $PROJECT_PATH"
[ -w "$PROJECT_PATH" ] || error "路徑無寫入權限: $PROJECT_PATH"

prompt_input "請輸入專案名稱" PROJECT_NAME
[ -z "$PROJECT_NAME" ] && error "專案名稱不可為空"

# ---------- 步驟 3：建立 Angular 專案 ----------

info "建立 Angular 專案: $PROJECT_PATH/$PROJECT_NAME ..."
cd "$PROJECT_PATH"
$NG_CMD new "$PROJECT_NAME"

cd "$PROJECT_NAME"
PROJECT_DIR="$(pwd)"
info "專案已建立於: $PROJECT_DIR"

# ---------- 步驟 4：安裝 ESLint + Prettier ----------

info "安裝 ESLint (angular-eslint) ..."
$NG_CMD add @angular-eslint/schematics --skip-confirmation

info "安裝 Prettier 及 ESLint 整合套件 ..."
npm install -D prettier eslint-config-prettier eslint-plugin-prettier prettier-plugin-organize-imports

# 寫入 .prettierrc
cat > .prettierrc <<'PRETTIEREOF'
{
  "printWidth": 100,
  "singleQuote": true,
  "trailingComma": "all",
  "plugins": ["prettier-plugin-organize-imports"],
  "overrides": [
    {
      "files": "*.html",
      "options": {
        "parser": "angular"
      }
    }
  ]
}
PRETTIEREOF
info "已建立 .prettierrc"

# 在 .vscode/extensions.json 加入 prettier 與 eslint 推薦
mkdir -p .vscode
EXTENSIONS_FILE=".vscode/extensions.json"
if [ -f "$EXTENSIONS_FILE" ]; then
  # JSONC (含註解) 需先去除註解再 parse
  node -e "
    const fs = require('fs');
    const raw = fs.readFileSync('$EXTENSIONS_FILE', 'utf8');
    const stripped = raw
      .replace(/\/\/.*$/gm, '')
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/,\s*([}\]])/g, '\$1');
    const ext = JSON.parse(stripped);
    const toAdd = ['esbenp.prettier-vscode','dbaeumer.vscode-eslint'];
    ext.recommendations = [...new Set([...(ext.recommendations||[]),...toAdd])];
    fs.writeFileSync('$EXTENSIONS_FILE', JSON.stringify(ext, null, 2) + '\n');
  "
else
  cat > "$EXTENSIONS_FILE" <<'EXTEOF'
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint"
  ]
}
EXTEOF
fi
info "已更新 $EXTENSIONS_FILE"

# ---------- 步驟 5：安裝 Git Hooks ----------

info "安裝 husky 與 lint-staged ..."
npm install -D husky lint-staged
npx husky init

# ---------- 步驟 6：配置 lint-staged & test:ci ----------

info "配置 package.json (test:ci + lint-staged) ..."

# 讀取 lint-staged 設定模板
LINT_STAGED_JSON="$(cat "$TEMPLATES_DIR/lint-staged.json")"

node -e "
  const fs = require('fs');
  const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

  // 加入 test:ci script
  pkg.scripts['test:ci'] = 'ng test --no-watch --no-progress';

  // 加入 lint-staged 設定
  pkg['lint-staged'] = JSON.parse(\`$LINT_STAGED_JSON\`);

  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

# 設定 husky pre-commit hook
cat > .husky/pre-commit <<'HOOKEOF'
npx lint-staged
npm run test:ci
HOOKEOF
chmod +x .husky/pre-commit

info "已配置 lint-staged 與 pre-commit hook"

# ---------- 步驟 7：GitHub Actions ----------

info "建立 GitHub Actions 工作流程 ..."
mkdir -p .github/workflows

sed "s/__NODE_VERSION__/$NODE_VERSION/g" "$TEMPLATES_DIR/test.yml" > .github/workflows/test.yml

info "已建立 .github/workflows/test.yml"

# ---------- 步驟 8： Skills ----------

_INSTALL_SKILLS=""
prompt_input "是否要安裝 Angular 相關的 Claude Code Skills？(y/N)" _INSTALL_SKILLS

if [[ "$_INSTALL_SKILLS" =~ ^[Yy](es)?$ ]]; then
  info "安裝 Angular skills ..."
  info "請按照以下提示步驟完成安裝："
  info "  1. 執行安裝指令後，CLI 會顯示 skill 清單"
  info "  2. 依照提示確認要安裝的 skills"
  info "  3. 安裝完成後會自動繼續後續步驟"
  echo ""
  sleep 1.5
  npx skills add analogjs/angular-skills -a claude-code
  info "Angular skills 安裝完成！"
else
  info "跳過 Angular skills 安裝"
fi

# ---------- 步驟 9：Git Commit ----------

info "提交初始 commit ..."
git add .
git commit -m "feat: initialize Angular project with ESLint, Prettier, Git Hooks, and GitHub Actions"

info "專案初始化完成！"
info "路徑: $PROJECT_DIR"
