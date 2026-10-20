# QFX Keystone Routes

在 **Mythic Dungeon Tools (MDT)** 右侧显示 [keystone.guru](https://keystone.guru) 热门路线，支持**一键导入**到 MDT。

---

## 功能

| 能力 | 说明 |
|---|---|
| 副本联动 | MDT 切换副本 → 右侧挂件自动切换到该副本的路线列表 |
| 卡片信息 | 名次 / 名称 / 适合层数 / 浏览量 / 收藏量 / 作者 |
| 一键试用 | 点击卡片 → 导入 `QFX-` 路线并替换上一条自动管理的路线，跨副本也只保留一条 |
| 层数高亮 | 当前钥石等级落在路线层数区间内 → 绿色；否则灰色/橙色 |
| 数据来源 | keystone.guru 公开页面，**无需账号** |
| 内存友好 | 元数据首次打开 MDT 才展开；路线按副本合并压缩，仅将点击的路线转成 Lua 表，不缓存整组展开数据 |

---

## 目录结构

```
QFXKeystoneRoutes/
├─ QFXKeystoneRoutes.toc      插件清单
├─ Core.lua                   数据解码 / MDT 联动 / 导入接口
├─ QFXWidgets.lua             嵌入式界面工厂
├─ Panel.lua                  深色路线侧栏 / 排序 / 滚动列表
├─ data/
│  ├─ Data.lua                ★ 压缩数据包(自动生成, 当前约 115 KB)
│  ├─ meta.json               144 条元数据
│  ├─ routes/<slug>.json      每个副本的 mdt_string
│  └─ manifest.json           数据版本
├─ scripts/
│  ├─ collect.mjs             采集器
│  ├─ pack-data.mjs           共用打包器 / 离线重打包
│  ├─ verify-pack.mjs         采集后数据包校验
│  └─ make-test-fixture.mjs   测试夹具生成
├─ test/
│  ├─ run_test.lua            Lua 端集成测试 (32 项)
│  └─ mockdata.lua            测试夹具 (自动生成)
└─ .github/workflows/
   └─ collect.yml             每 48 小时自动采集 + 校验 + 提交
```

---

## 数据格式与内存

`data/Data.lua` 使用 `format = 2`，按副本合并各条 MDT 路线的原始 CBOR 字节，再一起 Deflate 压缩。`routeEnds[slug]` 保存每条路线的字节结束位置。共享压缩窗口可去掉不同路线之间的重复内容，保留全部路线的原始 CBOR，不修改路线信息。

点击时临时解压该副本的字节流，用字节索引取出选中的一条，仅调用一次 `C_EncodingUtil.DeserializeCBOR`。不创建整组 MDT 字符串数组，不缓存展开后的分片。临时字节流在读取返回后可由 Lua 正常回收；不强制全局垃圾回收，避免影响游戏帧率。导入后清空 MDT 导入框及其回调保留的编码文本。

当前 144 条路线的数据对比（同一数据版本，离线无损重打包）：

| 项目 | 原格式 | 新格式 |
|---|---|---|
| 数据文件 | 219,166 字节 | 118,153 字节（减少约 46%） |
| 路线压缩字符串合计 | 209,428 字节 | 110,780 字节（减少约 47%） |
| 元数据 JSON | 57,423 字节 | 35,079 字节（减少约 39%） |
| 解压后路线缓存 | 保留一个副本的 18 条 MDT 字符串 | 不保留；只解析点击的路线 |
| 元数据加载 | 登录时 | 首次打开 MDT 时 |

元数据只打包侧栏、排序和提示使用的字段，完整采集记录仍保存在 `data/meta.json`。首次解码后释放压缩元数据引用，副本索引直接复用解码后的字典。当前最大副本的临时 CBOR 字节流约 48 KB；这是解压期间的临时分配，不是常驻缓存。

以上文件/字节量不等于整个插件的游戏内总内存。总内存还包含 QFXWidgets 函数、界面框体、Lua 表开销及尚未回收的临时对象；导入后由 MDT 保存的路线也会占用 MDT 的内存。需要在游戏内用相同场景、相同垃圾回收状态比较。旧格式数据包仍可读取，但不会创建分片缓存。

已有数据无需重新联网采集，可执行：

```bash
node scripts/pack-data.mjs
```

离线重打包沿用已有数据的版本和采集时间；采集器也使用同一打包函数。插件版本只在正式发布时递增。

---

## 采集

```bash
node scripts/collect.mjs                          # 全量
node scripts/collect.mjs --limit 18               # 每副本条数(默认 18)
node scripts/collect.mjs --min-interval-hours 48  # 48h 闸门
node scripts/collect.mjs --force                  # 忽略闸门
node scripts/collect.mjs --deadline-minutes 20    # 单轮硬截止(默认 20 分钟)
```

**数据源（全部匿名公开）**

| 步骤 | 端点 | 取到 |
|---|---|---|
| 1 | `GET /routes/retail/{slug}` | 榜单顺序( popularity 降序 ) + 收藏量 |
| 2 | `GET /route/{slug}/{pk}/{titleSlug}` | 内联 JSON：层数/热度/浏览量/作者/词缀/mapping 版本 |
| 3 | `GET /ajax/{pk}/mdtExport?...` | `!~MDT2~…` MDT 原生路线串 |

第 3 步需要 `X-Requested-With: XMLHttpRequest` 与 `Referer`，否则 403。
签名 24 小时过期，**每次采集都要从详情页重新取**。

**已验证的数据契约**

- MDT 索引 ↔ keystone slug 全部匹配（去非字母数字后比较）
- `mdt_string` 内的 `currentDungeonIdx` 与 MDT 6.3.9 索引**完全一致** → 导入不会切错副本

---

## 自动更新

`.github/workflows/collect.yml`：

- 每天 `cron` 触发 → 脚本内 **48 小时闸门**（`data/manifest.json` 记录上次时间）
- 满 48h 才真正采集（~296 请求，约 3 分钟）
- 采集失败、页面结构变化、数据量异常下降或超过 20 分钟硬截止时**中止并保留旧数据**，不会提交空数据
- 采集后运行 `scripts/verify-pack.mjs`，校验版本、副本数、路线字节边界与可重现性
- 结果自动 commit 回 `data/`
- 也可在 Actions 页面手动 `Run workflow`，勾选 `force` 立即采集
- 每天有 run → 不会触发 GitHub「60 天无活动停用 schedule」

> 客户端无法自行热更新（WoW 12.x 没有通用 HTTP API，MDT 6.3.9 全库也不用）。
> 数据更新通过随包分发（CurseForge / Wago / 手动覆盖 addon 目录）生效。

---

## 测试

```bash
node scripts/make-test-fixture.mjs   # 生成测试夹具
luac -p Core.lua && luac -p Panel.lua && luac -p data/Data.lua
lua test/run_test.lua                # 核心功能
lua test/run_data_test.lua           # 144 条字节边界 / 单条解析 / 延迟加载 / 旧格式兼容
lua test/run_panel_test.lua zhCN     # 47 项，加载真实 QFXWidgets 工厂
lua test/run_panel_test.lua enUS     # 英文布局与交互
lua test/run_panel_test.lua zhTW     # 繁体中文布局与交互
lua test/run_import_test.lua /path/to/MythicDungeonTools/Modules/Presets.lua
```

覆盖：副本名归一化 / 数据解码 / 8 个 MDT 索引映射 / 副本切换联动 / 单条路线解析 / 导入调用 / 数值格式化。

导入替换测试直接加载指定 MDT 的 `ImportPreset` 和 `ValidateImportPreset`，验证连续点击、跨副本替换、导入失败保留旧路线、选择索引调整、手动路线与复制路线保护。

## 路线保存规则

- 本插件新导入的路线名称以 `QFX-` 开头，默认作为临时试用路线。全插件自动管理一条；新路线成功保存后，才删除上一条，不会先删后导入。
- 删除同时核对上次导入记录、MDT 唯一 ID、插件标记和名称前缀；手动路线、默认路线及 MDT 的新建占位项不会被删除。
- 想永久保留某条路线：在 MDT 中重命名，去掉开头的 `QFX-`，再点击其他卡片即可。MDT 中手动复制得到不同唯一 ID 的路线也会保留。
- 本次更新以前导入的未标记路线不会自动清理，需要时请在 MDT 中手动删除。
- `QFXKeystoneRoutesDB.managedRoute` 保存当前临时路线的副本索引、唯一 ID 和导入序号；`managedImportSerial` 用于识别实际保存成功的导入。不修改 MDT 的全局覆盖设置。

---

## 兼容性

- 目标：`## Interface: 120107, 120105`（WoW 12.1.x / 12.0.7）
- 依赖：`MythicDungeonTools, MythicDungeonTools_UI`（UI 子插件提供 AceGUI）
- MDT 6.3.9 分离版通过 `MythicDungeonToolsAPI` 获取副本信息，通过全局 `MDTFrame.sidePanel` 挂载；不依赖私有 UI namespace。
- 路线侧栏由 QFXWidgets 与原生框体绘制，不创建 AceGUI 控件；UI 子插件仍用于 MDT 自身的导入流程。
- 字体使用客户端的 `STANDARD_TEXT_FONT`，折叠图标由纹理绘制。标题使用客户端的单行溢出处理，不按 UTF-8 字节截断；完整标题和信息可在悬停提示中查看。
- 深色背景跟随 MDT，路线列表复用行框体，支持热门 / 浏览 / 层数排序；高度随 MDT 侧栏调整，折叠和重开保留滚动位置。
- 用到 12.x 新 API：`C_EncodingUtil`（MDT 自身也在用）

**已知约束**

- MDT 改版若移除 `MDTFrame.sidePanel`，挂件会自动隐藏；若改动原生导入框接口，需同步适配。
- 副本内禁 addon 间 `CHAT_MSG_ADDON`（12.0+），本插件不依赖该通道。
- 战斗中不能导入（`InCombatLockdown()`），已拦截并提示。

---

## 数据来源与合规

数据取自 keystone.guru 的公开页面，其 `robots.txt` 当前为空。采集器已做限速
（每个请求 160–280 ms 随机间隔）、失败重试与退避。如需长期运行，请自行确认
[keystone.guru 的服务条款](https://keystone.guru/terms) 并保持合理频率。
