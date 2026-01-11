---
description: 作为部署编排员根据项目规模部署合适的 Agent 团队
allowedTools: ["Bash", "Edit", "Glob", "Grep", "Read", "Task", "TodoRead", "TodoWrite", "Write"]
---

你好，我需要你帮助部署 Agent 团队：

$ARGUMENTS

## 解析参数

**参数格式**:
```
<项目名称> [small|medium|large] [SPEC: <规范文件路径>]
```

**示例**:
```bash
# 仅项目名（默认 medium 规模）
my-project

# 指定规模
my-project large

# 带规范文件
my-project SPEC: docs/requirements.md

# 完整参数
my-project medium SPEC: "docs/project spec.md"
```

**解析规则**:
1. **项目名称** - 第一个参数，必须
2. **团队规模** - small/medium/large，可选，默认 medium
3. **规范文件** - `SPEC:` 后的路径，可选，路径含空格时使用引号

## 团队配置建议

### 小型项目 (Small)
```
适用: 单一功能、Bug 修复、小型重构
周期: 1-3 天

团队结构:
┌─────────────┐
│     PM      │
└──────┬──────┘
       │
┌──────▼──────┐
│  Developer  │
└─────────────┘

槽位配置:
- dev-1: Developer (Claude Agent)
- Shell/Server: 按需创建
```

### 中型项目 (Medium)
```
适用: 新功能开发、模块重构
周期: 1-2 周

团队结构:
┌─────────────┐
│     PM      │
└──────┬──────┘
       │
┌──────┴──────┐
│             │
▼             ▼
┌───────┐  ┌──────┐
│ Dev 1 │  │  QA  │
└───────┘  └──────┘

槽位配置:
- dev-1: Developer
- qa: QA Engineer
- Shell/Server: 按需创建
```

### 大型项目 (Large)
```
适用: 系统重构、新产品开发
周期: 1 个月以上

团队结构:
         ┌─────────────┐
         │     PM      │
         └──────┬──────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌───────┐  ┌───────┐  ┌────────┐
│ Dev 1 │  │ Dev 2 │  │ DevOps │
└───────┘  └───────┘  └────────┘
    │           │
    └─────┬─────┘
          │
    ┌─────▼─────┐
    │    QA     │
    └───────────┘

槽位配置:
- dev-1: Lead Developer
- dev-2: Developer 2
- qa: QA Engineer
- devops: DevOps (按需)
- Shell/Server: 按需创建
```

## 部署流程

### 1. 分析项目

```bash
# 检查项目类型和规模
ls -la ~/Coding/<project>/
wc -l $(find ~/Coding/<project> -name "*.py" -o -name "*.js" -o -name "*.ts" 2>/dev/null) | tail -1

# 检查是否有规范文件
cat ~/Coding/<project>/project_spec.md 2>/dev/null
```

### 2. 初始化 PM 槽位

```bash
# 初始化槽位管理
pm-init-slots

# 根据团队规模添加槽位
pm-add-slot dev-2   # 中型/大型项目
pm-add-slot qa      # 中型/大型项目
pm-add-slot devops  # 大型项目

# 按需创建辅助窗口
add-window Shell
add-window Server
```

### 3. 分配任务到槽位

```bash
# 分配开发任务
pm-assign dev-1 role-developer "实现核心功能"
pm-assign dev-2 role-developer "实现辅助模块"  # 中型/大型

# 分配测试任务
pm-assign qa role-qa "测试功能完整性"  # 中型/大型
```

### 4. 建立通信

各角色启动后，建立通信渠道：
- Developer ↔ PM: 进度汇报、任务分配
- Developer ↔ QA: Bug 报告、验证请求
- PM ↔ Orchestrator: 状态汇总、问题升级

## 角色简报模板

> 注意: 使用 `pm-assign` 时会自动加载角色并发送任务，无需手动发送简报。

### Developer 角色 (role-developer)
```
职责: 实现功能、修复 Bug、编写测试
汇报: 使用 [STATUS:DONE/ERROR/BLOCKED] 标记汇报状态
协作: 通过 tsc 与其他槽位通信

Git 规则: 每 30 分钟提交一次。
```

### QA 角色 (role-qa)
```
职责: 测试功能、发现 Bug、验证修复
汇报: 使用 [STATUS:DONE/ERROR/BLOCKED] 标记汇报状态
协作: 通过 tsc 向开发槽位报告 Bug

使用标准 BUG 报告格式汇报问题。
```

### PM 监督
```
使用 /tmuxAI:pm-oversight 或 /tmuxAI:pm-status 监控团队。
- pm-status: 查看所有槽位状态
- pm-check <slot>: 检测槽位完成状态
- pm-broadcast: 向工作中的槽位广播消息
```

## 执行部署

根据分析结果，执行以下步骤：

1. 确定团队规模 (small/medium/large)
2. 初始化 PM 槽位 (`pm-init-slots`)
3. 根据规模添加额外槽位 (`pm-add-slot`)
4. 分配任务到槽位 (`pm-assign`)
5. 按需创建辅助窗口 (`add-window Shell/Server`)
6. 确认团队就绪 (`pm-status`)
7. 开始项目工作

---

现在请分析参数并执行部署。
