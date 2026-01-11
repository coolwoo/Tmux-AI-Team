#!/bin/bash
#===============================================================================
# 文件存在性检查
# 验证所有开发产出物文件是否存在
#===============================================================================

cd "$(dirname "$0")/.."

echo "=== 检查开发产出物 ==="

PASS=0
FAIL=0

check_file() {
    if [ -f "$1" ]; then
        echo "✓ 存在: $1"
        ((PASS++))
    else
        echo "✗ 缺失: $1"
        ((FAIL++))
    fi
}

echo ""
echo "--- 斜杠命令 (PM 槽位管理) ---"
check_file ".claude/commands/tmuxAI/pm-init.md"
check_file ".claude/commands/tmuxAI/pm-assign.md"
check_file ".claude/commands/tmuxAI/pm-status.md"
check_file ".claude/commands/tmuxAI/pm-check.md"
check_file ".claude/commands/tmuxAI/pm-mark.md"
check_file ".claude/commands/tmuxAI/pm-broadcast.md"
check_file ".claude/commands/tmuxAI/pm-history.md"

echo ""
echo "--- 角色命令 ---"
check_file ".claude/commands/tmuxAI/role-developer.md"
check_file ".claude/commands/tmuxAI/role-qa.md"
check_file ".claude/commands/tmuxAI/role-reviewer.md"
check_file ".claude/commands/tmuxAI/role-devops.md"

echo ""
echo "--- 核心文件 ---"
check_file "bashrc-ai-automation-v2.sh"
check_file ".claude/TMUX_AI.md"

echo ""
echo "═══════════════════════════════════════════"
echo "结果: $PASS 通过, $FAIL 失败"
echo "═══════════════════════════════════════════"

[ $FAIL -eq 0 ] && exit 0 || exit 1
