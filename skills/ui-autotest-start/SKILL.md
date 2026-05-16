---
name: ui-autotest-start
description: 需要执行 Android UI 自动化测试脚本或诊断运行失败时使用 - 基于 MidsceneJS Android 检查环境、连接设备、运行脚本、查看报告
---

# UI 自动化测试执行

## 概述

执行和诊断基于 MidsceneJS Android 的 UI 自动化测试脚本。重点是先确认模型配置、ADB、设备授权和依赖完整，再运行脚本并根据报告定位失败原因。

默认方案：MidsceneJS Android（`@midscene/android`）。

参考文档：https://midscenejs.com/zh/android-getting-started

## 何时使用

- 需要运行 Android UI 自动化测试脚本
- 需要确认 Midscene Android 环境是否可用
- 需要连接真机或模拟器并验证 ADB 状态
- 需要用 Playground 快速验证设备操作链路
- 需要分析脚本失败、报告、截图、录屏或 trace

不用于编写新用例脚本；编写脚本时使用 `ccpowers:ui-autotest-case-write`。

## 项目结构约定

测试工作目录为 `tests/ui-autotest/`（相对于项目根目录）。该目录包含：
- `.env` — 模型配置和设备配置（由 `dotenv` 在脚本运行时加载，**不是** shell 环境变量）
- `package.json` — 依赖声明
- `node_modules/` — 已安装的依赖
- 各子目录下的 `.ts` 测试脚本

所有环境检查和脚本执行都必须以该目录为上下文。

## 执行前检查

**按以下顺序执行，可并行的步骤同时运行：**

### 步骤 1：定位测试目录（必须最先执行）

确认 `tests/ui-autotest/` 目录存在：

```bash
ls tests/ui-autotest/package.json
```

如果不存在，提示用户确认测试目录位置。后续所有操作基于此目录。

### 步骤 2：并行检查以下三项

**2a. 模型配置** — 读取 `.env` 文件内容（不是 shell 环境变量）：

使用 Read 工具读取 `tests/ui-autotest/.env`，确认以下字段已配置且非空：
- `MIDSCENE_MODEL_BASE_URL`
- `MIDSCENE_MODEL_API_KEY`
- `MIDSCENE_MODEL_NAME`
- `MIDSCENE_MODEL_FAMILY`

注意：这些配置由 `dotenv/config` 在脚本启动时加载，不会出现在 shell 环境变量中。**禁止使用 `echo "$MIDSCENE_MODEL_BASE_URL"` 等方式检测。**

**2b. Android SDK 环境变量、ADB 和设备状态**：

Midscene Android 底层依赖 `appium-adb`，即使 `adb` 已经在 `PATH` 中，也必须向当前 shell 导出 `ANDROID_HOME` 或 `ANDROID_SDK_ROOT`。先在项目根目录执行：

```bash
if [ -z "${ANDROID_HOME:-}" ] && [ -n "${ANDROID_SDK_ROOT:-}" ]; then
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
fi

if [ -z "${ANDROID_SDK_ROOT:-}" ] && [ -n "${ANDROID_HOME:-}" ]; then
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [ -z "${ANDROID_HOME:-}" ] && [ -d "$HOME/Library/Android/sdk" ]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [ -z "${ANDROID_HOME:-}" ] && [ -d "$HOME/Android/Sdk" ]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [ -z "${ANDROID_HOME:-}" ] || [ ! -d "$ANDROID_HOME/platform-tools" ]; then
  echo "未找到 Android SDK，请先设置 ANDROID_HOME 或 ANDROID_SDK_ROOT"
  exit 1
fi

export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

然后检查 ADB 和设备：

```bash
adb --version && adb devices -l
```

确认至少有一个设备状态为 `device`。

**2c. 依赖完整性** — 在测试目录下检查：

```bash
ls tests/ui-autotest/node_modules/@midscene/android/package.json
```

如果 `node_modules` 不存在或缺少关键依赖，在 `tests/ui-autotest/` 下执行 `npm install`。

### 步骤 3：发现可执行的测试脚本

扫描测试目录下的 `.ts` 脚本文件（排除 `node_modules`）：

```bash
find tests/ui-autotest -name '*.ts' -not -path '*/node_modules/*'
```

同时读取 `tests/ui-autotest/package.json` 的 `scripts` 字段，列出可用的 npm run 命令。

### 检查结果汇总

将所有检查结果整理为表格展示给用户：

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 测试目录 | ✅/❌ | tests/ui-autotest/ |
| .env 模型配置 | ✅/❌ | 从 .env 文件读取 |
| Android SDK 环境变量 | ✅/❌ | ANDROID_HOME 或 ANDROID_SDK_ROOT |
| ADB | ✅/❌ | 版本和设备列表 |
| 依赖 | ✅/❌ | @midscene/android 等 |
| 可用脚本 | — | 列出脚本路径和 npm scripts |

全部通过后，提示用户选择要运行的脚本。

## 推荐执行流程

1. 完成上述环境检查。
2. 首次接入设备时可运行 Playground 验证链路：

```bash
npx --yes @midscene/android-playground
```

3. 运行测试脚本（在 `tests/ui-autotest/` 目录下执行）：

```bash
# 通过 npm script
cd tests/ui-autotest
npm run test:settings

# 或直接运行脚本
npx tsx settings/settings-page-verify.ts
```

如果当前 shell 没有全局配置 Android SDK，必须先执行“Android SDK 环境变量、ADB 和设备状态”步骤中的导出命令，再运行 npm script；不要只依赖 `adb` 在 `PATH` 中。

4. 记录终端输出中的 Midscene 报告 HTML 路径。
5. 脚本执行结束后，**必须**进入测试结果分析阶段（见下方）。

## 测试结果分析（必须执行）

脚本运行结束后（无论成功还是失败），必须向用户报告以下内容：

### 成功时

汇总为表格：

| 步骤 | 结果 | 关键信息 |
|------|------|----------|
| 启动应用并进入目标页面 | ✅ | — |
| 验证区块 A | ✅ | 提取到的数据摘要 |
| 验证区块 B | ✅ | 提取到的数据摘要 |
| ... | ... | ... |

附上报告路径，告知用户所有断言通过。

### 失败时

**必须分析失败原因**，不能只贴错误信息。按以下步骤诊断：

1. **提取失败点**：从终端输出找到 `[FAIL]` 或 `Error` 行，确定是哪一步失败。
2. **区分失败类型**：
   - **环境问题**：`ANDROID_HOME` 缺失、设备断开、依赖缺失 → 参考"常见失败处理"修复后重试
   - **滚动问题**：日志中 `input swipe` 坐标超出屏幕、`scroll distance exceeds maximum` → 参考"滚动无效"章节
   - **断言失败**：`Assertion failed` + Midscene 给出的 Reason → 截图查看当前页面状态，判断是脚本预期不对还是 App 行为异常
   - **超时/卡死**：长时间无输出 → 检查设备是否弹出意外对话框、网络是否正常
3. **报告格式**：

```
❌ 测试失败

失败步骤：第 X 步 — <步骤描述>
失败类型：<环境问题 / 滚动问题 / 断言失败 / 超时>
错误信息：<精简的错误内容>
原因分析：<根据日志和截图判断的根因>
建议修复：<具体可操作的修复建议>
报告路径：<Midscene 报告 HTML 路径>
```

4. 如果是脚本逻辑问题（断言内容与实际 UI 不符、滚动策略不对），**主动建议修改脚本**并说明改哪里、怎么改。
5. 如果是环境问题，修复后**主动提议重新运行**，不要等用户再次触发。

## 常见失败处理

### 未发现设备

- 运行 `adb devices -l`
- 确认手机信任当前电脑
- 重新插拔 USB 或重启 adb server

### 未导出 Android SDK 环境变量

如果出现 `Neither ANDROID_HOME nor ANDROID_SDK_ROOT environment variable was exported`，说明当前 shell 没有把 SDK 根目录传给 Node 进程。优先执行：

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

然后在同一个 shell 中重新运行：

```bash
cd tests/ui-autotest
npm run test:settings
```

### 无法注入点击事件

如果出现 `Injecting input events requires ... INJECT_EVENTS permission`，检查设备是否开启 USB 调试和 USB 调试（安全设置）。

### 输入后内容消失

脚本执行 `aiType` 或类似输入操作后，输入的文字在键盘收起时被清空。

诊断方法：在报告中查看输入步骤的前后截图，确认文字是在键盘收起瞬间消失还是根本没输入成功。

**这是脚本编写问题。** 确认诊断后，按 `ui-autotest-case-write` skill 中的键盘隐藏策略修改脚本（`keyboardDismissStrategy`、`autoDismissKeyboard` 等选项）。

### 模型配置错误

- 检查 `MIDSCENE_MODEL_BASE_URL`
- 检查 `MIDSCENE_MODEL_API_KEY`
- 检查 `MIDSCENE_MODEL_NAME`
- 检查 `MIDSCENE_MODEL_FAMILY`

### 滚动无效或找不到页面元素

日志中有 `input swipe` 命令但 App 没有实际滑动，或反复滚动后仍找不到目标元素。

诊断方法：
1. 在终端日志中查找 `input swipe x y1 x y2`，对比 y1/y2 和屏幕物理高度（`adb shell wm size`）。如果坐标超出屏幕范围，说明是坐标越界。
2. 查找 `scroll distance exceeds maximum single swipe distance ... will be clamped`，说明单次滚动距离被截断，实际滑动幅度很小。

**这是脚本编写问题，不是环境问题。** 确认诊断后，按 `ui-autotest-case-write` skill 中的滚动规范修改脚本。

### 断言不稳定

同一脚本多次运行时断言时而通过时而失败。

诊断方法：在报告中对比通过和失败时的截图，确认是页面加载时机问题（截图时页面还在动画/加载中）还是 App 行为本身不一致。

**这是脚本编写问题。** 确认诊断后，按 `ui-autotest-case-write` skill 中的编写准则修改脚本（`aiWaitFor` 等待稳定、减少固定 sleep 等）。

## 执行准则

- 不在脚本或日志中暴露 API Key、账号密码等敏感信息。
- 执行前确认会操作的设备和环境，避免误操作真实生产账号。
- 失败时先保留报告路径和终端输出，再修改脚本。
- 环境问题和脚本问题分开处理：先确认 Playground 能控制设备，再诊断用例逻辑。

## 与其他技能的集成

- **ccpowers:ui-autotest-case-write** — 编写或维护 Midscene Android UI 自动化脚本
- **ccpowers:verification-before-completion** — 完成声明前验证测试结果
- **ccpowers:systematic-debugging** — 对持续失败或不稳定失败做根因分析
