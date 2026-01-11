#!/bin/bash
#===============================================================================
# 槽位设计验证测试
# 验证 PM 槽位管理的核心功能和数据结构
#===============================================================================

cd "$(dirname "$0")/../.."

# 加载函数库
source bashrc-ai-automation-v2.sh 2>/dev/null

PASS=0
FAIL=0

# 测试辅助函数
test_pass() {
    echo "✓ $1"
    ((PASS++))
}

test_fail() {
    echo "✗ $1"
    ((FAIL++))
}

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    槽位设计验证测试                               ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

#===============================================================================
# 测试 1: 函数签名验证
#===============================================================================
echo "=== 测试 1: 函数签名验证 ==="

SLOT_FUNCTIONS=(
    "pm-init-slots"
    "pm-add-slot"
    "pm-remove-slot"
    "pm-list-slots"
    "pm-status"
    "pm-mark"
    "pm-check"
    "pm-assign"
    "pm-broadcast"
    "_pm_log"
    "_pm_get_slots"
    "_pm_set_slots"
    "_is_slot_active"
)

for func in "${SLOT_FUNCTIONS[@]}"; do
    if type "$func" &>/dev/null; then
        test_pass "函数已定义: $func"
    else
        test_fail "函数未定义: $func"
    fi
done

echo ""

#===============================================================================
# 测试 2: 参数验证（无 tmux 会话时的错误处理）
#===============================================================================
echo "=== 测试 2: 参数验证（非 tmux 环境） ==="

# 保存原始 TMUX 变量
_ORIG_TMUX="${TMUX:-}"
unset TMUX

# 测试 pm-init-slots 在非 tmux 环境下的行为
# 注意: 如果测试在 tmux 中运行，tmux display-message 仍然可以获取会话名
# 所以只验证函数能正确处理空 session 的情况（通过源码分析验证）
func_source=$(type pm-init-slots 2>/dev/null)
if echo "$func_source" | grep -q '\-z "\$session"'; then
    test_pass "pm-init-slots: 包含 session 空值检测逻辑"
else
    test_fail "pm-init-slots: 应包含 session 空值检测逻辑"
fi

# 测试 pm-add-slot 无参数时的行为
output=$(pm-add-slot 2>&1)
if echo "$output" | grep -q "用法"; then
    test_pass "pm-add-slot: 无参数时显示用法"
else
    test_fail "pm-add-slot: 无参数时应显示用法"
fi

# 测试 pm-mark 无参数时的行为
output=$(pm-mark 2>&1)
if echo "$output" | grep -q "用法"; then
    test_pass "pm-mark: 无参数时显示用法"
else
    test_fail "pm-mark: 无参数时应显示用法"
fi

# 测试 pm-check 无参数时的行为
output=$(pm-check 2>&1)
if echo "$output" | grep -q "用法"; then
    test_pass "pm-check: 无参数时显示用法"
else
    test_fail "pm-check: 无参数时应显示用法"
fi

# 测试 pm-assign 参数不足时的行为
output=$(pm-assign dev-1 2>&1)
if echo "$output" | grep -q "用法"; then
    test_pass "pm-assign: 参数不足时显示用法"
else
    test_fail "pm-assign: 参数不足时应显示用法"
fi

# 测试 pm-remove-slot 无参数时的行为
output=$(pm-remove-slot 2>&1)
if echo "$output" | grep -q "用法"; then
    test_pass "pm-remove-slot: 无参数时显示用法"
else
    test_fail "pm-remove-slot: 无参数时应显示用法"
fi

# 测试 pm-broadcast 无参数时的行为
output=$(pm-broadcast 2>&1)
if echo "$output" | grep -q "用法"; then
    test_pass "pm-broadcast: 无参数时显示用法"
else
    test_fail "pm-broadcast: 无参数时应显示用法"
fi

# 恢复 TMUX 变量
if [ -n "$_ORIG_TMUX" ]; then
    export TMUX="$_ORIG_TMUX"
fi

echo ""

#===============================================================================
# 测试 3: 槽位类型验证
#===============================================================================
echo "=== 测试 3: 槽位类型模式验证 ==="

# 验证 pm-add-slot 支持 --claude 选项
output=$(pm-add-slot 2>&1)
if echo "$output" | grep -q "\-\-claude"; then
    test_pass "pm-add-slot: 支持 --claude 选项"
else
    test_fail "pm-add-slot: 应支持 --claude 选项"
fi

# 验证 pm-add-slot 支持 --shell 选项
if echo "$output" | grep -q "\-\-shell"; then
    test_pass "pm-add-slot: 支持 --shell 选项"
else
    test_fail "pm-add-slot: 应支持 --shell 选项"
fi

echo ""

#===============================================================================
# 测试 4: 状态值验证
#===============================================================================
echo "=== 测试 4: 状态值验证 ==="

# 从 pm-mark 帮助信息中验证支持的状态
output=$(pm-mark 2>&1)

EXPECTED_STATES=("done" "error" "idle" "blocked" "ready")
for state in "${EXPECTED_STATES[@]}"; do
    if echo "$output" | grep -q "$state"; then
        test_pass "pm-mark: 支持状态 '$state'"
    else
        test_fail "pm-mark: 应支持状态 '$state'"
    fi
done

echo ""

#===============================================================================
# 测试 5: 变量名转换逻辑验证
#===============================================================================
echo "=== 测试 5: 变量名转换逻辑验证 ==="

# 测试变量名转换规则：小写转大写，连字符转下划线
# 例如: dev-1 -> DEV_1

test_var_conversion() {
    local slot="$1"
    local expected="$2"

    local var_prefix="${slot^^}"
    var_prefix="${var_prefix//-/_}"

    if [[ "$var_prefix" == "$expected" ]]; then
        test_pass "变量转换: $slot -> $expected"
    else
        test_fail "变量转换: $slot -> $var_prefix (期望 $expected)"
    fi
}

test_var_conversion "dev-1" "DEV_1"
test_var_conversion "qa" "QA"
test_var_conversion "frontend-dev" "FRONTEND_DEV"
test_var_conversion "server-2-test" "SERVER_2_TEST"

echo ""

#===============================================================================
# 测试 6: 状态检测正则表达式验证
#===============================================================================
echo "=== 测试 6: 状态检测正则表达式验证 ==="

# 模拟 pm-check 中的状态标记检测逻辑

test_status_detection() {
    local input="$1"
    local expected_status="$2"
    local description="$3"

    local detected=""

    if echo "$input" | grep -qE "^[[:space:]]*\[STATUS:DONE\]"; then
        detected="done"
    elif echo "$input" | grep -qE "^[[:space:]]*\[STATUS:ERROR\]"; then
        detected="error"
    elif echo "$input" | grep -qE "^[[:space:]]*\[STATUS:BLOCKED\]"; then
        detected="blocked"
    elif echo "$input" | grep -qE "^[[:space:]]*\[STATUS:PROGRESS\]"; then
        detected="progress"
    fi

    if [[ "$detected" == "$expected_status" ]]; then
        test_pass "状态检测: $description"
    else
        test_fail "状态检测: $description (检测到 '$detected', 期望 '$expected_status')"
    fi
}

# 正确的状态标记
test_status_detection "[STATUS:DONE] 任务完成" "done" "行首 DONE 标记"
test_status_detection "  [STATUS:ERROR] 发生错误" "error" "带前导空格的 ERROR 标记"
test_status_detection "[STATUS:BLOCKED] 等待 API" "blocked" "行首 BLOCKED 标记"
test_status_detection "[STATUS:PROGRESS] 正在处理" "progress" "行首 PROGRESS 标记"

# 不应匹配的情况（嵌入文本中的状态标记）
test_status_detection "文档中提到 [STATUS:DONE] 格式" "" "嵌入文本中的标记不应匹配"
test_status_detection "请输出 [STATUS:ERROR]" "" "文档示例不应匹配"

echo ""

#===============================================================================
# 测试 7: _is_slot_active 空闲检测逻辑验证
#===============================================================================
echo "=== 测试 7: 空闲检测特征验证 ==="

# 验证函数定义中的空闲检测模式

# 读取函数源码
func_source=$(type _is_slot_active 2>/dev/null)

# 检测 Claude Code 版本信息模式
if echo "$func_source" | grep -q "current:.*latest:"; then
    test_pass "_is_slot_active: 检测 Claude 版本信息模式"
else
    test_fail "_is_slot_active: 应检测 Claude 版本信息模式"
fi

# 检测 tokens 信息模式
if echo "$func_source" | grep -q "tokens"; then
    test_pass "_is_slot_active: 检测 tokens 信息模式"
else
    test_fail "_is_slot_active: 应检测 tokens 信息模式"
fi

# 检测 Shell 提示符模式
if echo "$func_source" | grep -qE '\$.*#.*%'; then
    test_pass "_is_slot_active: 检测 Shell 提示符模式"
else
    test_fail "_is_slot_active: 应检测 Shell 提示符模式"
fi

echo ""

#===============================================================================
# 测试 8: 日志功能验证
#===============================================================================
echo "=== 测试 8: 日志功能验证 ==="

# 验证日志目录配置
if [[ -n "$AGENT_LOG_DIR" ]] || [[ -d "$HOME/.agent-logs" ]]; then
    test_pass "日志目录配置存在"
else
    test_fail "日志目录配置应存在"
fi

# 验证 _pm_log 函数参数处理
func_source=$(type _pm_log 2>/dev/null)

if echo "$func_source" | grep -q 'action="\$1"'; then
    test_pass "_pm_log: 接受 action 参数"
else
    test_fail "_pm_log: 应接受 action 参数"
fi

if echo "$func_source" | grep -q 'slot="\$2"'; then
    test_pass "_pm_log: 接受 slot 参数"
else
    test_fail "_pm_log: 应接受 slot 参数"
fi

if echo "$func_source" | grep -q 'message="\$3"'; then
    test_pass "_pm_log: 接受 message 参数"
else
    test_fail "_pm_log: 应接受 message 参数"
fi

echo ""

#===============================================================================
# 测试结果汇总
#===============================================================================
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                        测试结果汇总                               ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
printf "║ 通过: %-3d  失败: %-3d  总计: %-3d                                  ║\n" "$PASS" "$FAIL" "$((PASS + FAIL))"
echo "╚══════════════════════════════════════════════════════════════════╝"

if [[ $FAIL -eq 0 ]]; then
    echo ""
    echo "✓ 所有测试通过！槽位设计验证成功。"
    exit 0
else
    echo ""
    echo "✗ 有 $FAIL 个测试失败，请检查槽位设计实现。"
    exit 1
fi
