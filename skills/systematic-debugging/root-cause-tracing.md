# 根因回溯

## 概述

Bug 经常出现在调用栈深处：例如在错误目录执行 `git init`、文件被创建到错误位置、数据库用错路径。直觉会让你在报错点修复，但那通常只是症状。

**核心原则：** 沿调用链向后追踪，直到找到最初触发点，然后在源头修复。

## 何时使用

在这些情况下使用：

- 错误发生在很深的执行路径，而不是入口处
- 堆栈跟踪显示了较长调用链
- 不清楚无效数据从哪里来
- 需要找出哪个测试或代码路径触发了问题

## 回溯流程

### 1. 观察症状

```text
Error: git init failed in ~/project/packages/core
```

### 2. 找到直接原因

问：哪段代码直接导致了这个现象？

```ts
await execFileAsync('git', ['init'], { cwd: projectDir });
```

### 3. 继续追问：谁调用了这里？

```text
WorktreeManager.createSessionWorktree(projectDir, sessionId)
  -> Session.initializeWorkspace()
  -> Session.create()
  -> Project.create() 测试代码
```

### 4. 追踪传入的值

- `projectDir = ''`
- 空字符串作为 `cwd` 会退化为 `process.cwd()`
- 最终在源码目录里执行了危险操作

### 5. 找到最初触发点

```ts
const context = setupCoreTest(); // 初始返回 { tempDir: '' }
Project.create('name', context.tempDir); // beforeEach 之前访问了 tempDir
```

根因不是 `git init`，而是测试在初始化完成前读取了空目录。

## 添加诊断堆栈

无法手工追踪时，在危险操作前添加临时诊断：

```ts
async function gitInit(directory: string) {
  const stack = new Error().stack;
  console.error('DEBUG git init:', {
    directory,
    cwd: process.cwd(),
    nodeEnv: process.env.NODE_ENV,
    stack,
  });

  await execFileAsync('git', ['init'], { cwd: directory });
}
```

测试里优先用 `console.error()`，不要依赖可能被测试框架吞掉的 logger。

运行并筛选：

```bash
npm test 2>&1 | grep 'DEBUG git init'
```

分析重点：

- 哪个测试文件触发调用
- 哪一行传入坏值
- 是否多个测试共享同一种错误参数

## 查找污染测试

如果测试运行后出现了不该出现的文件或状态，但不知道哪个测试制造了污染，使用本目录的 `find-polluter.sh`：

```bash
./find-polluter.sh '.git' 'src/**/*.test.ts'
```

脚本会逐个运行测试文件，并在污染第一次出现时停止。

## 关键原则

不要只修复报错点。流程是：

1. 找到直接原因
2. 能继续向上一层追踪就继续追踪
3. 直到找到原始触发点
4. 在源头修复
5. 再沿数据路径增加必要校验

如果只能在症状处修复，说明证据还不够，先补诊断。
