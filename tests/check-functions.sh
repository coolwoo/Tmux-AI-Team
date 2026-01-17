#!/bin/bash
#===============================================================================
# 函数存在性检查
# 验证所有 PM 槽位管理函数是否已定义
#===============================================================================

cd "$(dirname "$0")/.."

# 加载函数库
source bashrc-ai-automation-v2.sh 2>/dev/null

FUNCTIONS=(
    "pm-init-slots"
    "pm-assign"
    "pm-status"
    "pm-check"
    "pm-mark"
    "pm-broadcast"
    "pm-history"
    "_pm_log"
    "get-role"
)

echo "=== 检查 Bash 函数 ==="

PASS=0
FAIL=0

for func in "${FUNCTIONS[@]}"; do
    if type "$func" &>/dev/null; then
        echo "✓ 已定义: $func"
        ((PASS++))
    else
        echo "✗ 未定义: $func"
        ((FAIL++))
    fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "结果: $PASS 通过, $FAIL 失败"
echo "═══════════════════════════════════════════"

[ $FAIL -eq 0 ] && exit 0 || exit 1
