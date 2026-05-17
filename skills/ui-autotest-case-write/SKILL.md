---
name: ui-autotest-case-write
description: 需要为 Android 应用新增或维护 MidsceneJS UI 自动化测试脚本、把手工步骤转成可执行用例、编写视觉断言或处理脚本稳定性时使用
---

# UI 自动化测试用例编写

## 概述

为 Android 应用编写 MidsceneJS UI 自动化测试脚本。重点是把用户流程拆成稳定、可读、可回放的脚本步骤，并使用 Midscene 的视觉驱动能力降低选择器维护成本。

默认方案：MidsceneJS Android（`@midscene/android`）。

参考文档：https://midscenejs.com/zh/android-getting-started

## 何时使用

- 需要新增 Android UI 自动化测试用例
- 需要把手工测试步骤转成可执行脚本
- 需要为登录、注册、搜索、下单、设置等界面流程编写断言
- 需要从界面提取结构化数据用于校验
- 需要维护已有 Midscene Android 脚本

不用于执行和诊断测试运行结果；执行脚本时使用 `ccpowers:ui-autotest-start`。

## 编写流程

1. 明确测试目标：应用入口、前置账号、设备状态、核心路径、预期结果。
2. 检查项目结构：优先复用 `tests/ui-autotest/`、现有脚本命名、包管理器和 npm script。
3. 读取 `tests/ui-autotest/.env` 的配置约定，不把模型配置、设备 ID、包名写死到脚本。
4. 确认依赖：需要 `@midscene/android`、`dotenv`，TypeScript 脚本通常还需要 `tsx`。
5. 确定保存路径：优先使用项目已有 UI 自动化测试目录；没有时创建 `tests/ui-autotest/<业务域>/<用例名>-<yymmdd>.ts`。
6. 编写脚本：使用 `AndroidDevice` 连接设备，使用 `AndroidAgent` 执行视觉驱动操作。
7. 加入稳定断言：关键页面使用 `aiWaitFor` 等待，再用 `aiAssert` 校验结果。
8. 输出可诊断信息：必要时用 `aiQuery` 提取界面数据并打印。

## 必须避免的错误

- 不要用 `echo "$MIDSCENE_MODEL_BASE_URL"` 之类方式判断模型配置是否存在；脚本应通过 `import 'dotenv/config'` 读取 `tests/ui-autotest/.env`。
- 不要在脚本里自己探测或设置 `ANDROID_HOME`。`getConnectedDevices()` 底层需要 `ANDROID_HOME`，但这是执行环境的职责（由 `ui-autotest-start` skill 或 shell profile 保证），不要在每个脚本里重复写 SDK 探测逻辑。
- 不要把滚动写成 `agent.aiAct('向下滚动页面...')`。Midscene 可能规划出屏幕外坐标，导致 App 实际没有滑动。滚动必须使用 `device.scrollDown()`、`device.scrollUntilTop()`、`device.scrollUntilBottom()` 等公开 API。
- 不要调用 `AndroidDevice` 的私有 API，例如 `performAction`、`swipePoint`、`performActionScroll`。
- 不要假设页面每次从顶部开始。应用可能保留上一次滚动位置；验证顶部区块前先执行 `device.scrollUntilTop()`。
- 不要一次大距离滚动后直接断言底部元素。使用多次小幅滚动，并在每次滚动后用 `aiBoolean` 判断目标是否可见。

## 保存路径

默认保存到：

```text
tests/ui-autotest/<业务域>/<用例名>-<yymmdd>.ts
```

路径规则：

- `<业务域>` 使用英文 kebab-case，例如 `login`、`checkout`、`settings`。
- `<用例名>` 使用英文 kebab-case，描述核心流程，并追加当前日期 `yymmdd` 后缀，例如 `login-with-password-260517.ts`。
- 如果项目已有 UI 自动化目录，优先沿用已有目录结构，例如 `e2e/`、`tests/e2e/`、`ui-tests/`。
- 如果同一业务域有多个用例，把共享帮助函数放到 `tests/ui-autotest/<业务域>/helpers.ts`。
- 不把临时调试脚本放进正式用例目录；临时脚本使用 `tmp/ui-autotest/`。

## 推荐脚本骨架

```ts
import 'dotenv/config';
import {
  AndroidAgent,
  AndroidDevice,
  getConnectedDevices,
} from '@midscene/android';

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const APP_PACKAGE = process.env.APP_PACKAGE || 'com.example.app';

/**
 * 小幅多次向下滚动。
 * Midscene 会把逻辑距离 clamp 到屏幕安全范围内，单次不要超过 200。
 */
async function scrollPageDown(device: AndroidDevice, times = 3) {
  for (let i = 0; i < times; i++) {
    await device.scrollDown(200);
    await sleep(200);
  }
}

/**
 * 滚动直到目标文本出现在屏幕上。
 * 每轮滚动后用 aiBoolean 检测，避免盲目滚动。
 */
async function scrollUntilVisible(
  agent: AndroidAgent,
  device: AndroidDevice,
  target: string,
  maxRounds = 5
) {
  for (let i = 0; i < maxRounds; i++) {
    if (await agent.aiBoolean(`页面上是否能看到${target}？`)) return;
    await scrollPageDown(device);
  }
  throw new Error(`滚动 ${maxRounds} 轮后仍未看到目标：${target}`);
}

async function main() {
  // ANDROID_HOME 由执行环境保证（ui-autotest-start skill 或 shell profile）
  const devices = await getConnectedDevices();
  if (devices.length === 0) {
    throw new Error('未发现 Android 设备，请先确认 adb devices -l 有可用设备');
  }

  const udid = process.env.DEVICE_UDID || devices[0].udid;
  const device = new AndroidDevice(udid);
  const agent = new AndroidAgent(device, {
    aiActionContext:
      '如果出现权限、定位、用户协议等弹窗，点击同意；如果出现登录页但本用例不需要登录，关闭登录页。',
  });

  await device.connect();
  console.log(`已连接设备: ${udid}`);

  await agent.aiAct(`打开 ${APP_PACKAGE} 应用`);
  await sleep(1000);

  // 应用可能保留上次滚动位置，验证顶部内容前先回到顶部
  await device.scrollUntilTop();
  await sleep(500);

  await agent.aiWaitFor('目标页面已经展示');
  await agent.aiTap('明确可见的按钮或设置项');
  await scrollUntilVisible(agent, device, '"目标区块"标题');
  await agent.aiAssert('界面展示了预期结果');
}

main().catch((error) => {
  console.error('[FAIL] 测试失败:', error.message || error);
  process.exit(1);
});
```

## Midscene 方法选择

- `aiAct`：描述用户操作，让 Midscene 自动规划步骤。
- `aiTap`：需要直接点击明确目标时使用。
- `aiWaitFor`：等待页面状态稳定，不用固定 sleep 替代关键等待。
- `aiAssert`：验证界面是否满足预期。
- `aiQuery`：从界面提取结构化 JSON 数据。
- `aiBoolean` / `aiNumber` / `aiString`：提取简单类型结果。
- `device.scrollUntilTop()`：进入页面或返回页面后重置滚动位置。
- `device.scrollDown(200)`：查找下方区块时小幅滚动，配合 `aiBoolean` 判断目标是否出现。

`aiAct` 适合打开页面、关闭弹窗、返回等高层操作；不要用它承担滚动查找和精确点击。精确点击优先用 `aiTap`，滚动优先用 `AndroidDevice` 公开滚动 API。

## 编写准则

- 用用户能理解的自然语言描述界面目标，不写脆弱坐标。
- 每个脚本聚焦一个业务流程，避免把多个无关路径塞进同一个用例。
- 在关键状态变化后先等待，再断言。
- 不把 API Key、账号密码、设备 ID、应用包名写死到脚本里；使用 `.env` 或测试配置。
- 验证长页面时按“回到顶部 -> 验证顶部区块 -> 小幅滚动查找中部/底部区块 -> 再断言”的顺序写。
- 对底部或可能被截断的设置项，先滚动到可见，再执行 `aiAssert` 或 `aiTap`。
- 对弹窗、权限、登录态等不稳定因素写入 `aiActionContext`。
- 输出报告路径、关键查询结果和失败上下文，方便执行技能继续诊断。

## 长页面用例模板

```ts
await device.scrollUntilTop();
await agent.aiWaitFor('页面顶部区块已展示');
await agent.aiAssert('页面上存在"顶部区块"标题');

await scrollUntilVisible(agent, device, '"中部区块"标题');
await agent.aiAssert('页面上存在"中部区块"标题');

await scrollUntilVisible(agent, device, '"底部区块"标题');
await agent.aiAssert('页面上存在"底部区块"标题');
```

如果报告中出现类似 `input swipe 583 2902 583 2114`，且设备高度小于起点 Y 坐标，说明自动滚动坐标越界。把对应步骤改为 `device.scrollDown()` 小幅滚动，不要继续调 prompt。

## 与其他技能的集成

- **ccpowers:ui-autotest-start** — 执行脚本、检查设备连接、查看报告和诊断失败
- **ccpowers:test-driven-development** — 为待测代码设计测试行为时使用
- **ccpowers:systematic-debugging** — 自动化失败需要根因分析时使用
