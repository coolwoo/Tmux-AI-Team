#!/bin/bash
#===============================================================================
# 语法检查脚本
# 检查 Bash 脚本语法是否正确
#===============================================================================

cd "$(dirname "$0")/.."

echo "=== Bash 语法检查 ==="

if bash -n bashrc-ai-automation-v2.sh 2>&1; then
    echo "✓ PASS: bashrc-ai-automation-v2.sh 语法正确"
    exit 0
else
    echo "✗ FAIL: bashrc-ai-automation-v2.sh 语法错误"
    exit 1
fi
