# ccpowers — 贡献者指南

## 项目概述

ccpowers 是一个面向 Claude Code 的中文核心技能库插件。它提供一套完整的软件开发方法论，包括头脑风暴、测试驱动开发、系统化调试、子代理驱动开发等核心技能。

所有提示词和注释均为简体中文。

## 技能列表

| 技能 | 说明 |
|------|------|
| 使用ccpowers | 入门引导，建立技能使用规则 |
| 头脑风暴 | 创造性工作前的设计探索 |
| 编写计划 | 将规格转化为详细实施计划 |
| 执行计划 | 按计划逐步执行 |
| 测试驱动开发 | 红-绿-重构循环 |
| 系统化调试 | 四阶段根因分析 |
| 并行代理调度 | 独立任务并行执行 |
| 子代理驱动开发 | 每任务子代理 + 两阶段审查 |
| 请求代码审查 | 分派审查子代理 |
| 接收代码审查 | 技术严谨地处理审查反馈 |
| 完成验证 | 证据先于声明 |
| 完成开发分支 | 合并/PR/清理工作流 |
| 使用git工作树 | 隔离工作区管理 |
| ui-autotest-case-write | 基于 MidsceneJS Android 编写 UI 自动化测试用例脚本 |
| ui-autotest-start | 执行 MidsceneJS Android UI 自动化测试脚本 |

## 目录结构

```
ccpowers/
  .claude-plugin/     # Claude Code 插件配置
  hooks/              # 会话启动钩子
  skills/             # 技能文件（每个技能一个目录）
  CLAUDE.md           # 此文件
  package.json        # 包信息
```

## 开发规范

- 所有技能文件使用中文编写
- 技能目录名使用英文 kebab-case，并与 SKILL.md 的 frontmatter `name` 一致
- SKILL.md 的 frontmatter 中 name 字段使用英文 kebab-case，只包含小写字母、数字和连字符
- description 字段以"……时使用"的模式描述触发条件
- 遵循 YAGNI 原则，不添加不必要的功能
