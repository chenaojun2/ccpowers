---
name: using-git-worktrees
description: 开始需要从当前工作区隔离的功能工作时或执行实施计划之前使用 - 确保通过原生工具或 git worktree 回退存在隔离工作区
---

# 使用 Git 工作树

## 概述

确保工作在隔离工作区中进行。优先使用平台的原生工作树工具。仅在没有原生工具时回退到手动 git worktree。

**核心原则：** 先检测现有隔离。然后用原生工具。然后回退到 git。不要与宿主环境对抗。

**开始时宣布：** "我正在使用 git 工作树技能来设置隔离工作区。"

## 步骤 0：检测现有隔离

**创建任何东西之前，检查你是否已在隔离工作区中。**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**子模块检测：**
```bash
# 如果返回路径，你在子模块中，不是工作树
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**如果 `GIT_DIR != GIT_COMMON`（且非子模块）：** 你已在链接工作树中。跳到步骤 3。

**如果 `GIT_DIR == GIT_COMMON`：** 你在普通仓库中。在创建工作树前询问用户同意。

> "要我设置一个隔离工作树吗？它能保护你当前分支不受变更影响。"

## 步骤 1：创建隔离工作区

### 1a. 原生工作树工具（首选）

你有原生工具（如 `EnterWorktree`）吗？如果有，使用它并跳到步骤 3。

### 1b. Git Worktree 回退

**仅在步骤 1a 不适用时使用。**

#### 目录选择优先级

1. 指令中声明的工作树目录偏好
2. 现有项目本地目录：`.worktrees` > `worktrees`
3. 都没有则默认 `.worktrees/`

#### 安全验证

**创建前必须验证目录已被忽略：**

```bash
git check-ignore -q .worktrees 2>/dev/null
```

**如果未被忽略：** 添加到 .gitignore 并提交，然后继续。

#### 创建工作树

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

## 步骤 3：项目设置

自动检测并运行适当的设置：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi
# Rust
if [ -f Cargo.toml ]; then cargo build; fi
# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
# Go
if [ -f go.mod ]; then go mod download; fi
```

## 步骤 4：验证干净基线

运行测试确保工作区起始干净。

**如果测试失败：** 报告失败，询问是否继续。
**如果测试通过：** 报告就绪。

## 快速参考

| 情况 | 动作 |
|------|------|
| 已在链接工作树中 | 跳过创建（步骤 0） |
| 在子模块中 | 当普通仓库处理 |
| 有原生工作树工具 | 使用它（步骤 1a） |
| 无原生工具 | Git worktree 回退（步骤 1b） |
| 目录未被忽略 | 添加到 .gitignore + 提交 |
| 创建权限错误 | 沙箱回退，就地工作 |

## 危险信号

**绝不要：**
- 步骤 0 检测到现有隔离时还创建工作树
- 有原生工作树工具时还用 `git worktree add`
- 跳过步骤 1a 直接到步骤 1b
- 不验证忽略就创建项目本地工作树
- 跳过基线测试验证
