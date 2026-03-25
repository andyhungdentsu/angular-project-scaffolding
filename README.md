# Angular Project Scaffolding

一鍵初始化 Angular 專案的互動式 Shell 腳本，自動配置 ESLint、Prettier、Git Hooks、GitHub Actions 與 Angular 相關 Skills。

## 使用方式

```bash
bash setup-angular.sh
```

腳本會透過互動式問答引導你完成設定，包含以下可配置項目：

| 項目         | 預設值   |
| ------------ | -------- |
| Node.js 版本 | 22.14.0  |
| Angular 版本 | 19       |
| 專案放置路徑 | 當前目錄 |
| 專案名稱     | （必填） |

## 前置條件

- 已安裝 [nvm](https://github.com/nvm-sh/nvm) 或 [Node.js](https://nodejs.org/)

## 腳本執行步驟

1. **環境檢查** — 偵測 nvm / Node.js，切換或安裝指定版本，確認 Angular CLI
2. **建立專案** — 於指定路徑執行 `ng new`
3. **ESLint + Prettier** — 安裝 `@angular-eslint/schematics`、Prettier 及相關整合套件，寫入 `.prettierrc`
4. **VS Code 推薦擴充** — 在 `.vscode/extensions.json` 加入 Prettier 與 ESLint（相容 JSONC 格式）
5. **Git Hooks** — 安裝 husky + lint-staged，設定 pre-commit 執行 lint 與測試
6. **package.json 配置** — 加入 `test:ci` script 與 `lint-staged` 規則
7. **GitHub Actions** — 建立 `.github/workflows/test.yml`，於 PR 時自動執行 Lint 與 Test
8. **Skills** — 安裝 Angular skills
9. **Git Commit** — 提交初始 commit

## 檔案結構

```
├── setup-angular.sh            # 主腳本
├── templates/
│   ├── test.yml                # GitHub Actions 工作流程模板
│   └── lint-staged.json        # lint-staged 設定
└── README.md
```
