---
name: ui-autotest-case-write
description: 需要为 Android 应用编写或维护 UI 自动化测试用例脚本时使用 - 基于 MidsceneJS Android 方案生成可执行脚本、断言和数据提取流程
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
2. 检查项目结构：优先复用已有测试目录、脚本命名、包管理器和 npm script。
3. 确认依赖：需要 `@midscene/android`、`dotenv`，TypeScript 脚本通常还需要 `tsx`。
4. 确定保存路径：优先使用项目已有 UI 自动化测试目录；没有时创建 `tests/ui-autotest/<业务域>/<用例名>.ts`。
5. 编写脚本：使用 `AndroidDevice` 连接设备，使用 `AndroidAgent` 执行视觉驱动操作。
6. 加入稳定断言：关键页面使用 `aiWaitFor` 等待，再用 `aiAssert` 校验结果。
7. 输出可诊断信息：必要时用 `aiQuery` 提取界面数据并打印。

## 保存路径

默认保存到：

```text
tests/ui-autotest/<业务域>/<用例名>.ts
```

路径规则：

- `<业务域>` 使用英文 kebab-case，例如 `login`、`checkout`、`settings`。
- `<用例名>` 使用英文 kebab-case，描述核心流程，例如 `login-with-password.ts`。
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

async function main() {
  const devices = await getConnectedDevices();
  if (devices.length === 0) {
    throw new Error('未发现 Android 设备，请先确认 adb devices -l 有可用设备');
  }

  const device = new AndroidDevice(devices[0].udid);
  const agent = new AndroidAgent(device, {
    aiActionContext:
      '如果出现权限、定位、用户协议等弹窗，点击同意；如果出现登录页但本用例不需要登录，关闭登录页。',
  });

  await device.connect();

  await agent.aiAct('打开目标应用或页面');
  await sleep(1000);
  await agent.aiWaitFor('目标页面已经展示');
  await agent.aiAct('完成用户操作');
  await agent.aiAssert('界面展示了预期结果');
}

main().catch((error) => {
  console.error(error);
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

## 编写准则

- 用用户能理解的自然语言描述界面目标，不写脆弱坐标。
- 每个脚本聚焦一个业务流程，避免把多个无关路径塞进同一个用例。
- 在关键状态变化后先等待，再断言。
- 不把 API Key、账号密码、设备 ID 写死到脚本里；使用 `.env` 或测试配置。
- 对弹窗、权限、登录态等不稳定因素写入 `aiActionContext`。
- 输出报告路径、关键查询结果和失败上下文，方便执行技能继续诊断。

## 与其他技能的集成

- **ccpowers:ui-autotest-start** — 执行脚本、检查设备连接、查看报告和诊断失败
- **ccpowers:test-driven-development** — 为待测代码设计测试行为时使用
- **ccpowers:systematic-debugging** — 自动化失败需要根因分析时使用
