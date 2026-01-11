# Tmux-AI 工具包

你正在 tmux 环境中工作。以下是可用的 Bash 工具函数。

## 窗口布局

| 窗口名称 | 用途 |
|----------|------|
| `Claude` | 你所在的窗口（Agent） |
| `Shell` | 命令行操作（按需创建） |
| `Server` | 开发服务器（按需创建） |

> 仅 Claude 窗口默认创建，其他窗口使用 `add-window` 按需创建。

## 核心函数

### 添加窗口
```bash
add-window <name>
```
按需创建新窗口。窗口已存在时自动切换。

示例:
```bash
add-window Shell   # 创建 Shell 窗口
add-window Server  # 创建 Server 窗口
```

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

## 更新工具包

如果函数不存在或行为异常，可能需要更新：

```bash
cd ~/Coding/Tmux-AI-Team && git pull
cp bashrc-ai-automation-v2.sh ~/.ai-automation.sh
source ~/.ai-automation.sh
```

## 更多功能

完整函数列表运行 `check-deps` 或查看项目文档。
