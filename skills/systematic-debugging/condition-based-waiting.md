# 条件等待

## 概述

不稳定测试经常用固定延迟猜测时机，例如 `sleep(100)` 或 `setTimeout(50)`。这会制造竞态：快机器上通过，CI 或并行运行时失败。

**核心原则：** 等待真正关心的条件，而不是猜它需要多久。

## 何时使用

在这些情况下使用：

- 测试包含随意延迟：`setTimeout`、`sleep`、`time.sleep()`
- 测试偶发失败，在负载或 CI 下更明显
- 并行运行时超时
- 需要等待异步操作完成

不要用于验证真实时间行为，例如 debounce、throttle、固定轮询间隔。必须使用固定等待时，要先等待触发条件，并写清楚为什么需要这个时间。

## 核心模式

```ts
// 修复前：猜测 50ms 后结果应该出现
await new Promise((resolve) => setTimeout(resolve, 50));
const result = getResult();
expect(result).toBeDefined();

// 修复后：等待结果真实出现
await waitFor(() => getResult() !== undefined, 'result to be available');
const result = getResult();
expect(result).toBeDefined();
```

## 常见场景

| 场景 | 模式 |
|------|------|
| 等待事件 | `waitFor(() => events.find((e) => e.type === 'DONE'))` |
| 等待状态 | `waitFor(() => machine.state === 'ready')` |
| 等待数量 | `waitFor(() => items.length >= 5)` |
| 等待文件 | `waitFor(() => fs.existsSync(path))` |
| 等待复合条件 | `waitFor(() => obj.ready && obj.value > 10)` |

## 通用实现

```ts
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000
): Promise<T> {
  const startTime = Date.now();

  while (true) {
    const result = condition();
    if (result) return result;

    if (Date.now() - startTime > timeoutMs) {
      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
    }

    await new Promise((resolve) => setTimeout(resolve, 10));
  }
}
```

完整的事件等待示例见 `condition-based-waiting-example.ts`。

## 常见错误

| 错误 | 修复 |
|------|------|
| 1ms 轮询，浪费 CPU | 通常 10ms 轮询足够 |
| 没有超时，条件永不满足时挂死 | 必须带清楚的超时错误 |
| 在循环前缓存状态 | 在每次轮询中重新读取最新状态 |
| 固定等待后直接断言 | 先等待明确条件，再断言 |

## 固定等待何时可以接受

只有在测试真实时间行为时可以使用，并且要满足：

1. 先等待触发条件
2. 等待时间来自已知机制，不是猜测
3. 注释说明为什么需要这个时间

```ts
await waitForEvent(manager, 'TOOL_STARTED');
// 工具每 100ms 输出一次；等待两个 tick 来验证部分输出。
await new Promise((resolve) => setTimeout(resolve, 200));
```
