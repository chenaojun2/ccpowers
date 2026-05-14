---
name: ui-autotest
description: 需要运行、管理或分析 UI 自动化测试时使用 - 执行浏览器或应用界面测试、生成报告、分析失败原因、管理测试环境
---

# UI 自动化测试

## 概述

统一的 UI 自动化测试能力接口。提供浏览器或应用界面测试的运行、结果分析、报告生成和测试环境管理。

**核心原则：** 自动检测项目使用的 UI 测试框架，以统一的方式执行和报告界面测试结果。

**此技能为能力预留接口，等待接入具体的 UI 自动化测试服务或工具。**

## 何时使用

**使用场景：**
- 需要运行 Playwright、Cypress、Selenium、Appium 等 UI 自动化测试
- 需要验证页面或应用界面交互流程
- 需要生成 UI 测试报告、截图、录屏或 trace
- 需要分析 UI 测试失败原因
- 需要管理浏览器、模拟器、测试账号、mock 服务等测试环境
- CI/CD 流程中的 UI 回归测试阶段

**不使用场景：**
- 编写单个测试用例（使用 ccpowers:test-driven-development）
- 调试非 UI 自动化测试失败（使用 ccpowers:systematic-debugging）

## 能力接口

### 1. UI 测试发现

```
TODO：接入 UI 自动化测试发现服务
- 自动检测项目使用的 UI 测试框架
- 扫描项目中的 UI 测试文件
- 构建页面、场景、用例索引
- 支持按浏览器、设备、标签、模块、目录过滤
```

### 2. UI 测试执行

```
TODO：接入 UI 自动化测试执行引擎
- 支持浏览器、移动模拟器或真实设备执行
- 支持指定测试范围（全量、增量、指定文件、指定场景）
- 支持无头/有头模式、截图、录屏、trace
- 超时控制、重试策略与资源限制
- 实时进度报告
```

### 3. 结果分析

```
TODO：接入 UI 自动化测试结果分析服务
- 测试通过/失败/跳过统计
- 失败测试的根因分类（选择器失效、等待超时、网络异常、断言失败）
- 测试执行时间分析
- 不稳定测试（flaky test）检测
```

### 4. UI 测试报告

```
TODO：接入 UI 自动化测试报告工具
- HTML 报告、截图、录屏、trace 归档
- 失败步骤与 DOM 状态摘要
- 跨浏览器、跨设备结果对比
- 与变更差异关联的 UI 回归风险提示
```

### 5. 测试环境管理

```
TODO：接入 UI 自动化测试环境管理服务
- 浏览器、驱动、模拟器或设备管理
- 测试账号、测试数据、Mock 服务启动与管理
- 测试固件（fixture）管理
- 环境隔离与并行支持
```

## 当前回退行为

在具体 UI 自动化测试服务接入之前，此技能提供基础的框架检测和命令行执行：

```bash
# 自动检测并执行 UI 自动化测试
if [ -f package.json ]; then
    # 检测常见 UI 自动化测试框架
    if grep -q '"@playwright/test"' package.json; then
        npx playwright test
    elif grep -q '"cypress"' package.json; then
        npx cypress run
    elif grep -q '"selenium-webdriver"' package.json; then
        npm test
    else
        npm test
    fi
fi
```

## 扩展指南

要接入自定义 UI 自动化测试服务，需要实现以下接口：

1. **UI 测试发现器（UITestDiscoverer）：** 返回项目中所有 UI 测试用例的列表
2. **UI 测试执行器（UITestRunner）：** 接受 UI 测试用例列表并执行，返回结果
3. **结果报告器（ResultReporter）：** 将原始测试结果、截图、录屏和 trace 格式化为可读报告
4. **环境管理器（EnvironmentManager）：** 管理浏览器、模拟器、测试账号和依赖服务

每个接口独立实现，可按需组合。

## 与其他技能的集成

- **ccpowers:test-driven-development** — TDD 流程中调用此技能执行 UI 自动化测试
- **ccpowers:verification-before-completion** — 完成声明前调用此技能验证测试通过
- **ccpowers:systematic-debugging** — 调试阶段调用此技能复现问题
- **ccpowers:subagent-driven-development** — 子代理在实施后调用此技能验证
