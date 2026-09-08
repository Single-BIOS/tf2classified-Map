# tf2c_mvm — Mann vs. Machine Game Mode Fix

原作者 Glaster。修復 TF2C MvM 回合流程問題：

- 波次失敗後沒有預備時間、無法重開當前波次（`music.mvm_lost_wave` → `tf_mvm_jump_to_wave`）
- 波次結束後的 setup time / round restart 相關 bug
- 任務開始啟動資金為 0（開局自動 `tf_mvm_jump_to_wave 1`，觸發引擎發放 `StartingCurrency`）

## 需求（版本不可錯）

| 元件 | 版本 | 說明 |
| ---- | ---- | ---- |
| Metamod:Source | `2.0.0-dev+1389` | TF2C 需要 dev build |
| SourceMod | `1.13.0.7301`（≤ git7354） | dev build；<SM git7354 才配 API 8 的 patched TF2 擴充 |
| Patched TF2 Tools 擴充 | API 8 | 來自 TF2C Discord 釘選訊息，無公開下載 |
| Team Fortress 2 Classified | — | — |

**穩定版 SM/MM 在 TF2C 上無法載入**，只能裝上面的 dev build。

## 安裝

1. 把 `tf2c_mvm.smx` 複製到 `tf2classified\addons\sourcemod\plugins\`
2. 重啟遊戲 / 伺服器
3. 驗證：console 打 `sm plugins list`，`[TF2C] Mann vs. Machine: Game Mode Fix` 應顯示 `running`。

## 編譯

```powershell
..\..\build.ps1   # 使用預設 spcomp64 路徑（見根目錄 build.ps1）
```

編譯器：SourceMod 1.13 的 `spcomp64.exe`。5 個「should return an explicit value」警告屬無害。

## 主要修改（相較上游）

- 波次失敗重開：監聽 `tf_mvm_lost_wave` 後於下一幀 `tf_mvm_jump_to_wave`，避免失敗後卡在無法繼續。
- 任務開局資金：`teamplay_round_start`（wave≤1）後 0.3s 自動 `tf_mvm_jump_to_wave 1` 一次（每張圖只觸發一次），讓引擎 `RestorePlayerCurrency` 發放 `StartingCurrency`。