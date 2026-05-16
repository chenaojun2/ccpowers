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

## 执行前检查

1. 模型配置存在：

```bash
echo "$MIDSCENE_MODEL_BASE_URL"
echo "$MIDSCENE_MODEL_API_KEY"
echo "$MIDSCENE_MODEL_NAME"
echo "$MIDSCENE_MODEL_FAMILY"
```

2. ADB 可用：

```bash
adb --version
echo "$ANDROID_HOME"
adb devices -l
```

3. 设备已开启开发者选项、USB 调试，必要时开启 USB 调试（安全设置）。
4. 项目依赖已安装，至少包含 `@midscene/android` 和 `dotenv`。

## 推荐执行流程

1. 先运行 `adb devices -l`，确认设备状态是 `device`。
2. 首次接入时运行 Playground 验证链路：

```bash
npx --yes @midscene/android-playground
```

3. 按项目脚本执行测试；没有 npm script 时可直接运行 TypeScript 脚本：

```bash
npx tsx path/to/ui-test.ts
```

4. 记录终端输出中的 Midscene 报告 HTML 路径。
5. 打开报告查看每一步交互、查询和断言结果。

## 常见失败处理

### 未发现设备

- 运行 `adb devices -l`
- 确认手机信任当前电脑
- 重新插拔 USB 或重启 adb server

### 无法注入点击事件

如果出现 `Injecting input events requires ... INJECT_EVENTS permission`，检查设备是否开启 USB 调试和 USB 调试（安全设置）。

### 输入后内容消失

优先把设备键盘隐藏策略改成 Android 返回键：

```ts
const device = new AndroidDevice('device-id', {
  keyboardDismissStrategy: 'back-first',
});
```

如果仍不稳定，可关闭自动隐藏键盘：

```ts
const device = new AndroidDevice('device-id', {
  autoDismissKeyboard: false,
});
```

### 模型配置错误

- 检查 `MIDSCENE_MODEL_BASE_URL`
- 检查 `MIDSCENE_MODEL_API_KEY`
- 检查 `MIDSCENE_MODEL_NAME`
- 检查 `MIDSCENE_MODEL_FAMILY`

### 断言不稳定

- 先用 `aiWaitFor` 等待页面状态稳定
- 减少固定 sleep，只保留必要的动画缓冲
- 在失败报告中检查 Midscene 实际看到的页面状态

## 执行准则

- 不在脚本或日志中暴露 API Key、账号密码等敏感信息。
- 执行前确认会操作的设备和环境，避免误操作真实生产账号。
- 失败时先保留报告路径和终端输出，再修改脚本。
- 环境问题和脚本问题分开处理：先确认 Playground 能控制设备，再诊断用例逻辑。

## 与其他技能的集成

- **ccpowers:ui-autotest-case-write** — 编写或维护 Midscene Android UI 自动化脚本
- **ccpowers:verification-before-completion** — 完成声明前验证测试结果
- **ccpowers:systematic-debugging** — 对持续失败或不稳定失败做根因分析
