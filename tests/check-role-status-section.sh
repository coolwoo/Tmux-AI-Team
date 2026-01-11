#!/bin/bash
#===============================================================================
# 角色命令状态汇报规范检查
# 验证角色命令是否包含状态标记规范
#===============================================================================

cd "$(dirname "$0")/.."

echo "=== 检查角色命令状态汇报规范 ==="

ROLES=(
    ".claude/commands/tmuxAI/role-developer.md"
    ".claude/commands/tmuxAI/role-qa.md"
    ".claude/commands/tmuxAI/role-reviewer.md"
    ".claude/commands/tmuxAI/role-devops.md"
)

PASS=0
FAIL=0

for role in "${ROLES[@]}"; do
    if [ ! -f "$role" ]; then
        echo "✗ 文件不存在: $role"
        ((FAIL++))
        continue
    fi

    # 检查必需的状态标记
    local has_done=$(grep -c "\[STATUS:DONE\]" "$role" 2>/dev/null)
    local has_error=$(grep -c "\[STATUS:ERROR\]" "$role" 2>/dev/null)
    local has_blocked=$(grep -c "\[STATUS:BLOCKED\]" "$role" 2>/dev/null)

    if [ "$has_done" -gt 0 ] && [ "$has_error" -gt 0 ] && [ "$has_blocked" -gt 0 ]; then
        echo "✓ 包含状态标记规范: $(basename "$role")"
        ((PASS++))
    else
        echo "✗ 缺少状态标记规范: $(basename "$role")"
        echo "    DONE: $has_done, ERROR: $has_error, BLOCKED: $has_blocked"
        ((FAIL++))
    fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "结果: $PASS 通过, $FAIL 失败"
echo "═══════════════════════════════════════════"

[ $FAIL -eq 0 ] && exit 0 || exit 1
