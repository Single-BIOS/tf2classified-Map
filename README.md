# TF2C MvM 修復套件（Team Fortress 2 Classified）

讓 TF2C 的 Mann vs. Machine 可以正常遊玩的修復與設定套件，隨附已補齊的地圖（可透過 `sv_downloadurl` CDN 自動下載）。

## 已修復的問題

| 症狀 | 修法 |
| ---- | ---- |
| MvM 選職業大頭照破圖（紫黑格） | 補上 `vgui/class_portraits/*_red_alpha.vmt`（玩家端） |
| 波次失敗後無法重新開始 | `tf2c_mvm.smx` 插件：監聽 `music.mvm_lost_wave` → `tf_mvm_jump_to_wave` |
| 任務開始資金為 0 | 插件開局自動 `tf_mvm_jump_to_wave 1`，觸發引擎 `RestorePlayerCurrency` 發放 `StartingCurrency` |
| 無法開 32 人房（maxplayers 卡死） | `mvmhost` alias + 正確的 `maxplayers` 執行時序 |

## 已知限制（不影響遊玩）

- **機器人投彈頻率較低**：地圖與原版完全一致（md5 相同）、無任何 throw 標記；投彈時機由 TF2C 引擎的 `server.dll` NextBot AI 決定，插件層無法控制，暫無公開修法，屬 TF2C 引擎行為。

## 目錄結構

```
tf2classified/
├── maps/                 MvM 地圖（sv_downloadurl CDN 用）
├── custom/               玩家端大頭照修復（複製進自己的遊戲）
│   └── mvmpatch/materials/vgui/class_portraits/*_red_alpha.vmt
├── cfg/                  伺服器端設定範例（mvmhost / autoexec / listenserver / mvm）
│   └── listenserver.cfg  含 sv_downloadurl、MvM 人數、網路參數
└── tf2c_mvm/             插件原始碼 + 編譯後 smx
```

## 安裝

### 玩家端（一定要裝，不然大頭照還是破的）

把 `tf2classified/custom/` 整個複製到你的：

```
Team Fortress 2 Classified\tf2classified\custom\
```

注意 TF2C 的 `custom/` 只接受「子資料夾」，請保留 `mvmpatch/` 這層，不要直接把 `materials` 丟進去。
裝好後**完整重啟遊戲**（custom 僅在啟動時掃描）。

### 伺服器端（開房者 / 主機）

1. **Metamod 2.0 + SourceMod 1.13（只能用 dev build）**
   - Metamod:Source `2.0.0-dev+1389`（build archive，選 Windows x64）
   - SourceMod `1.13.0.7301`（dev build，Windows x64）
   - TF2C 官方 wiki 明言**穩定版不會動**，必須用這兩個 dev build。
   - 安裝到 `tf2classified\addons\`，保留 `addons\metamod\metamod.vdf` 與 `metamod_x64.vdf`。

2. **Patched「TF2 Tools」擴充**（引擎偵測為 tf2，需 API 8）
   - 來源：TF2C Discord 釘選訊息（無公開下載）。
   - 安裝：
     - `addons\sourcemod\gamedata\custom\sm-tf2.games.txt`
     - `addons\sourcemod\extensions\x64\game.tf2.ext.2.tf2.dll`
     - `addons\sourcemod\extensions\game.tf2.autoload`（空檔）
   - 驗證：console 輸入 `sm exts list`，要有 `TF2 Tools`。

3. **插件與設定**
   - `tf2c_mvm\plugins\tf2c_mvm.smx` → `addons\sourcemod\plugins\`
   - `cfg\*.cfg` → `tf2classified\cfg\`（覆蓋/合併）
   - 驗證：`sm plugins list` → `[TF2C] Mann vs. Machine: Game Mode Fix` 顯示 `running`。

4. **開房**：主選單 console 輸入 `mvmhost`（=`exec mvmhost`：maxplayers 32 → `map mvm_coaltown`）
   - `maxplayers` 只能在「沒有伺服器在跑」時設定，所以一律用 `mvmhost` 開。

## 連線 / 防火牆

- `cfg\listenserver.cfg` 已設 `sv_lan 0`、公開伺服器列表、`sv_downloadurl` 指向本 repo 的 raw CDN。
- 若要讓朋友從外部連：路由器需開 port forwarding（TCP+UDP 27015 → 主機），並確認 Windows 防火牆放行 `tf2classified_win64.exe`。

## 自行編譯插件

```powershell
# 需安裝 SourceMod 1.13（含 spcomp64.exe）
.\build.ps1
# 或指定路徑
.\build.ps1 -Spcomp "D:\tf2c\addons\sourcemod\scripting\spcomp64.exe"
```

## 鳴謝

- `tf2c_mvm.smx` 原作者：Glaster
- 大頭照修復：參考 Purple Spy 的 GameBanana mod「Fixed MVM Class portraits UI」