## 開發守則

- 命名法則
  * 屬性以 lowerCamelCase 命名
  * private 屬性、方法前加上 \_ 命名
  * 屬性命名皆為名詞，並以單複數形式呈現
  * 常數的 const 以 UPPER_CASE 命名
  * class 以 UpperCamelCase 命名
  * Rxjs Observable Event 以 lowerCamelCase$ 命名
  * 檔案名稱以串燒命名（包含檔案名稱、資料夾名稱）
  * 禁止純字母命名 a, b, c … j, k
    - 除了一層迴圈可以用 i
    - 如果有兩層迴圈，就用如 profileIndex、accountIndex 的方式命名

- CSS 在任何情況下不超過五層套嵌，從 class 開始算第一層
- 如屬性的定義超過一行以上，與其他屬性之間必須要有空行分離
- 明確定義 private / protected / public，未提供外部使用即宣告為 protected 、 private
- public 屬性 / 方法必須加 public，方便辨識此行程式碼用於宣告
- 變數宣告僅能使用 let 並確保變數生命週期存在於合理範圍
- 函數命名必須由動詞開頭
- 使用 for loop 時必須遵守 for (初始化, 條件, 累進值) 規範，如果有任何缺少的資料，請使用 while loop
- if else 內的條件必須明確表達，如遇到複合子句請將其儲存於變數中
- 禁止使用陣列索引值來儲存或判斷不同的資料，請額外命名再進行後續動作

- Git 分支規則：採用簡化版 Git Flow
  * 主分支：main
  * 開發/測試中分支：develop
  * 開發中功能分支：develop-features/XXXXX
  * 合併方向： develop-features -> develop -> main
  * 衝突解決方式：採用 rebase 方式進行
  * 當需要 hotfix 時：從 develop 開分支 `develop-hotfix/XXXXX` 修正完成再合併回 develop 測試
  * 測試機上版：將 develop 分支打上標籤進行上版，標籤名稱 `TEST-20260319-01`
  * 正式機上版：將 main 分支打上標籤進行上版，標籤名稱 `RELEASE-20260319-01`
