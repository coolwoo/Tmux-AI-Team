---
description: 手动标记槽位的任务状态
allowedTools: ["Bash"]
---

# PM 标记状态

手动标记槽位的任务状态。

## 参数

从 `$ARGUMENTS` 解析：
- `slot`: 槽位名称 (dev-1 | dev-2 | qa)
- `status`: 状态 (done | error | idle | blocked)

## 执行步骤

使用 Bash 工具执行：

```bash
pm-mark <slot> <status>
```

## 状态说明

| 状态 | 用途 |
|------|------|
| done | 任务已完成，清空任务描述，计算耗时 |
| error | 任务出错，保留任务描述供排查 |
| idle | 重置为空闲，清空任务描述，可重新分配 |
| blocked | 任务被阻塞，保留任务描述 |

## 示例

```bash
pm-mark dev-1 done    # 标记完成，显示耗时
pm-mark dev-2 error   # 标记出错
pm-mark qa idle       # 重置为空闲，可重新分配
pm-mark dev-1 blocked # 标记为阻塞状态
```

## 输出示例

```
✓ dev-1 状态已更新为: done (耗时: 45分钟)
```
