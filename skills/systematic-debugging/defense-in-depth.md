# 防御式校验

## 概述

当 bug 来自无效数据时，只在一个地方加校验看起来足够，但这个检查可能被其他调用路径、重构、mock 或平台差异绕过。

**核心原则：** 在数据经过的每一层都做合适校验，让同类 bug 在结构上变得不可能。

## 为什么需要多层防御

单点校验只能说明“这个入口修了”。多层防御要达到“这个坏值过不去”。

不同层负责不同风险：

- 入口校验挡住大多数坏输入
- 业务逻辑校验挡住上下文错误
- 环境防护阻止测试或 CI 中的危险操作
- 诊断日志为漏网问题保留取证信息

## 四层防御

### 第 1 层：入口校验

目的：在 API 边界拒绝明显无效输入。

```ts
function createProject(name: string, workingDirectory: string) {
  if (!workingDirectory || workingDirectory.trim() === '') {
    throw new Error('workingDirectory cannot be empty');
  }
  if (!existsSync(workingDirectory)) {
    throw new Error(`workingDirectory does not exist: ${workingDirectory}`);
  }
  if (!statSync(workingDirectory).isDirectory()) {
    throw new Error(`workingDirectory is not a directory: ${workingDirectory}`);
  }
}
```

### 第 2 层：业务逻辑校验

目的：确认数据对当前操作有意义。

```ts
function initializeWorkspace(projectDir: string, sessionId: string) {
  if (!projectDir) {
    throw new Error('projectDir required for workspace initialization');
  }
}
```

### 第 3 层：环境防护

目的：在特定环境中拒绝危险操作。

```ts
async function gitInit(directory: string) {
  if (process.env.NODE_ENV === 'test') {
    const normalized = normalize(resolve(directory));
    const tmpDir = normalize(resolve(tmpdir()));

    if (!normalized.startsWith(tmpDir)) {
      throw new Error(
        `Refusing git init outside temp dir during tests: ${directory}`
      );
    }
  }
}
```

### 第 4 层：诊断信息

目的：当其他层仍未覆盖某个路径时，保留可追踪上下文。

```ts
async function gitInit(directory: string) {
  logger.debug('About to git init', {
    directory,
    cwd: process.cwd(),
    stack: new Error().stack,
  });
}
```

## 应用步骤

发现根因后：

1. 画出坏数据流：坏值从哪里来，经过哪里，被哪里使用
2. 列出检查点：入口、业务操作、危险副作用、环境边界
3. 每层添加对应校验：不要把所有责任压到单个入口
4. 测试绕过路径：故意绕过第 1 层，确认第 2 层能挡住

## 示例

问题：空 `projectDir` 导致 `git init` 在源码目录运行。

数据流：

1. 测试初始化返回空字符串
2. `Project.create(name, '')`
3. `WorkspaceManager.createWorkspace('')`
4. `git init` 使用 `process.cwd()`

修复组合：

- `Project.create()` 校验目录非空、存在、可写
- `WorkspaceManager` 校验 `projectDir` 非空
- 测试环境中拒绝在临时目录外执行 `git init`
- 在执行 `git init` 前记录目录、cwd、堆栈

## 关键提醒

不要在第一个校验点停下。对会产生副作用、跨进程、跨环境或被测试 mock 绕过的路径，要把校验放到每个关键层。
