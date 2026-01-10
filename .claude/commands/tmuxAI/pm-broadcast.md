---
description: 向所有工作中的 Agent 发送广播消息
allowedTools: ["Bash"]
---

# PM 广播消息

向所有工作中 (status=working) 的 Agent 发送消息。

## 参数

从 `$ARGUMENTS` 解析：
- `message`: 要广播的消息内容

## 执行步骤

使用 Bash 工具执行：

```bash
pm-broadcast "<message>"
```

## 示例

```bash
pm-broadcast "请准备提交代码"
pm-broadcast "暂停工作，等待需求确认"
pm-broadcast "15分钟后进行代码审查"
```

## 输出示例

```
→ dev-1: 已发送
→ dev-2: 已发送

✓ 广播完成: 2 个槽位
```

## 注意

- 只发送到 status=working 的槽位
- 空闲 (idle)、完成 (done)、出错 (error) 的槽位不会收到
- 消息前会加上 `[PM 广播]` 前缀
