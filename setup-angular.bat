@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

REM ============================================================
REM Angular 專案初始化腳本 (Windows)
REM 用法: setup-angular.bat
REM ============================================================

set "SCRIPT_DIR=%~dp0"
set "TEMPLATES_DIR=%SCRIPT_DIR%templates"

set "NODE_VERSION=22.14.0"
set "ANGULAR_VERSION=20"

REM ---------- 步驟 0：檢查 Git 設定 ----------

for /f "usebackq tokens=*" %%a in (`git config user.name 2^>nul`) do set "GIT_USER_NAME=%%a"
for /f "usebackq tokens=*" %%a in (`git config user.email 2^>nul`) do set "GIT_USER_EMAIL=%%a"

if "%GIT_USER_NAME%"=="" (
    echo [ERROR] 尚未設定 git user.name，請先執行：
    echo         git config --global user.name "Your Name"
    exit /b 1
)
if "%GIT_USER_EMAIL%"=="" (
    echo [ERROR] 尚未設定 git user.email，請先執行：
    echo         git config --global user.email "you@example.com"
    exit /b 1
)
echo [INFO]  Git 使用者: %GIT_USER_NAME% ^<%GIT_USER_EMAIL%^>

REM ---------- 步驟 1：檢查 nvm / node ----------

where nvm >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO]  偵測到 nvm-windows 已安裝

    set /p "_INPUT_NODE=請輸入要使用的 Node.js 版本（預設為 %NODE_VERSION%）: "
    if not "!_INPUT_NODE!"=="" set "NODE_VERSION=!_INPUT_NODE!"

    set /p "_INPUT_NG=請輸入要使用的 Angular 版本（預設為 %ANGULAR_VERSION%）: "
    if not "!_INPUT_NG!"=="" set "ANGULAR_VERSION=!_INPUT_NG!"

    nvm use !NODE_VERSION! >nul 2>&1
    if !errorlevel! neq 0 (
        echo [INFO]  安裝 Node.js v!NODE_VERSION! ...
        nvm install !NODE_VERSION!
        nvm use !NODE_VERSION!
    )
) else (
    where node >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=*" %%v in ('node -v') do set "NODE_RAW=%%v"
        set "NODE_VERSION=!NODE_RAW:~1!"
        echo [INFO]  未偵測到 nvm，但已安裝 Node.js v!NODE_VERSION!

        set /p "_INPUT_NG=請輸入要使用的 Angular 版本（預設為 %ANGULAR_VERSION%）: "
        if not "!_INPUT_NG!"=="" set "ANGULAR_VERSION=!_INPUT_NG!"
    ) else (
        echo [ERROR] 未偵測到 nvm 或 Node.js，請先安裝其中之一後再執行此腳本。
        exit /b 1
    )
)

set "NG_CMD=npx -y @angular/cli@%ANGULAR_VERSION%"
echo [INFO]  將使用 Angular CLI v%ANGULAR_VERSION%（透過 npx）

REM ---------- 步驟 2：詢問專案路徑與名稱 ----------

set /p "PROJECT_PATH=請輸入專案放置路徑（預設為當前目錄）: "
if "%PROJECT_PATH%"=="" set "PROJECT_PATH=."

pushd "%PROJECT_PATH%" 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] 路徑不存在: %PROJECT_PATH%
    exit /b 1
)
set "PROJECT_PATH=%CD%"
popd

set /p "PROJECT_NAME=請輸入專案名稱: "
if "%PROJECT_NAME%"=="" (
    echo [ERROR] 專案名稱不可為空
    exit /b 1
)

REM ---------- 步驟 3：建立 Angular 專案 ----------

echo [INFO]  建立 Angular 專案: %PROJECT_PATH%\%PROJECT_NAME% ...
cd /d "%PROJECT_PATH%"
call %NG_CMD% new "%PROJECT_NAME%"

cd /d "%PROJECT_NAME%"
set "PROJECT_DIR=%CD%"
echo [INFO]  專案已建立於: %PROJECT_DIR%

REM ---------- 步驟 4：安裝 ESLint + Prettier ----------

echo [INFO]  安裝 ESLint (angular-eslint) ...
call %NG_CMD% add @angular-eslint/schematics --skip-confirmation

echo [INFO]  安裝 Prettier 及 ESLint 整合套件 ...
call npm install -D prettier eslint-config-prettier eslint-plugin-prettier prettier-plugin-organize-imports

REM 寫入 .prettierrc
(
echo {
echo   "printWidth": 100,
echo   "singleQuote": true,
echo   "trailingComma": "all",
echo   "plugins": ["prettier-plugin-organize-imports"],
echo   "overrides": [
echo     {
echo       "files": "*.html",
echo       "options": {
echo         "parser": "angular"
echo       }
echo     }
echo   ]
echo }
) > .prettierrc
echo [INFO]  已建立 .prettierrc

REM 在 .vscode/extensions.json 加入 prettier 與 eslint 推薦
if not exist ".vscode" mkdir .vscode
set "EXTENSIONS_FILE=.vscode\extensions.json"
if exist "%EXTENSIONS_FILE%" (
    node -e "const fs=require('fs');const raw=fs.readFileSync('%EXTENSIONS_FILE:\=/%','utf8');const stripped=raw.replace(/\/\/.*$/gm,'').replace(/\/\*[\s\S]*?\*\//g,'').replace(/,\s*([}\]])/g,'$1');const ext=JSON.parse(stripped);const toAdd=['esbenp.prettier-vscode','dbaeumer.vscode-eslint'];ext.recommendations=[...new Set([...(ext.recommendations||[]),...toAdd])];fs.writeFileSync('%EXTENSIONS_FILE:\=/%',JSON.stringify(ext,null,2)+'\n');"
) else (
    (
    echo {
    echo   "recommendations": [
    echo     "esbenp.prettier-vscode",
    echo     "dbaeumer.vscode-eslint"
    echo   ]
    echo }
    ) > "%EXTENSIONS_FILE%"
)
echo [INFO]  已更新 %EXTENSIONS_FILE%

REM ---------- 步驟 5：安裝 Git Hooks ----------

echo [INFO]  安裝 husky 與 lint-staged ...
call npm install -D husky lint-staged
call npx husky init

REM ---------- 步驟 6：配置 lint-staged & test:ci ----------

echo [INFO]  配置 package.json (test:ci + lint-staged) ...

set "LINT_STAGED_FILE=%TEMPLATES_DIR%\lint-staged.json"
node -e "const fs=require('fs');const pkg=JSON.parse(fs.readFileSync('package.json','utf8'));pkg.scripts['test:ci']='ng test --no-watch --no-progress';pkg['lint-staged']=JSON.parse(fs.readFileSync('%LINT_STAGED_FILE:\=/%','utf8'));fs.writeFileSync('package.json',JSON.stringify(pkg,null,2)+'\n');"

REM 設定 husky pre-commit hook
(
echo npx lint-staged
echo npm run test:ci
) > .husky\pre-commit
echo [INFO]  已配置 lint-staged 與 pre-commit hook

REM ---------- 步驟 7：GitHub Actions ----------

echo [INFO]  建立 GitHub Actions 工作流程 ...
if not exist ".github\workflows" mkdir ".github\workflows"

node -e "const fs=require('fs');let t=fs.readFileSync('%TEMPLATES_DIR:\=/%/test.yml','utf8');t=t.replace(/__NODE_VERSION__/g,'%NODE_VERSION%');fs.writeFileSync('.github/workflows/test.yml',t);"

echo [INFO]  已建立 .github\workflows\test.yml

REM ---------- 步驟 8：Skills ----------

set /p "_INSTALL_SKILLS=是否要安裝 Angular 相關的 Claude Code Skills？(y/N): "
if /i "!_INSTALL_SKILLS!"=="y" (
    echo [INFO]  安裝 Angular skills ...
    echo [INFO]  請按照以下提示步驟完成安裝：
    echo [INFO]    1. 執行安裝指令後，CLI 會顯示 skill 清單
    echo [INFO]    2. 依照提示確認要安裝的 skills
    echo [INFO]    3. 安裝完成後會自動繼續後續步驟
    echo.
    call npx skills add analogjs/angular-skills -a claude-code
    echo [INFO]  Angular skills 安裝完成！
) else if /i "!_INSTALL_SKILLS!"=="yes" (
    echo [INFO]  安裝 Angular skills ...
    call npx skills add analogjs/angular-skills -a claude-code
    echo [INFO]  Angular skills 安裝完成！
) else (
    echo [INFO]  跳過 Angular skills 安裝
)

REM ---------- 步驟 9：Git Commit ----------

echo [INFO]  提交初始 commit ...
git add .
git commit -m "feat: initialize Angular project with ESLint, Prettier, Git Hooks, and GitHub Actions"

echo [INFO]  專案初始化完成！
echo [INFO]  路徑: %PROJECT_DIR%

endlocal
