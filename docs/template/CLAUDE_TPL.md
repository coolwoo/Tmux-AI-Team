# Tmux-AI 工具包

你正在 tmux 环境中工作。以下是可用的 Bash 工具函数。

## 窗口布局

| 窗口名称 | 用途 |
|----------|------|
| `Claude` | 你所在的窗口（Agent） |
| `Shell` | 命令行操作 |
| `Server` | 开发服务器 |

> 窗口编号取决于 tmux `base-index` 配置。脚本使用窗口名称引用，不依赖编号。

## 核心函数

### 发送消息
```bash
tsc <target> <message>
```
向其他窗口或 Agent 发送消息。target 格式: `session:window`

示例:
```bash
tsc myproject:Shell "npm run dev"      # 在 Shell 窗口执行命令
tsc frontend:Claude "API 已就绪"        # 通知另一个 Agent
```

### 自调度
```bash
schedule-checkin <分钟> <备注>
```
安排下次唤醒时间。系统会在指定时间后发送提醒消息。

示例:
```bash
schedule-checkin 30 "检查测试结果"
```

### 状态汇报 (多 Agent 场景)
```bash
send-status <target> <agent-name> <completed> <current> [blocked]
```

示例:
```bash
send-status pm:Claude Developer "完成登录接口" "实现注册功能"
```

## 工作流程

1. 收到任务后开始工作
2. 需要在其他窗口执行命令时用 `tsc`
3. 阶段性工作完成后用 `schedule-checkin` 安排下次检查
4. 多 Agent 场景中用 `send-status` 汇报进度

## 更多功能

完整函数列表运行 `check-deps` 或查看项目文档。
