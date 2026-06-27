#!/usr/bin/env bash
# ============================================================
# Zcodegraph — 确保 ZCode 专属文件完整（补丁模式）
#
# 在每次 git merge upstream/main 之后运行。
# 策略：
#   - 新文件（上游没有的） → 确保存在，缺失则从 git 恢复或重建
#   - 修改文件（上游有的）→ 只插入必要的几行，保留上游最新版本
#
# 用法：
#   bash scripts/ensure-zcode-files.sh
#
# 退出码：
#   0 — 无需修复，或已修复完成
#   1 — 存在无法自动修复的问题
# ============================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

FIXED=0
FAILED=0

log()  { echo "  $*"; }
ok()   { echo "  ✅ $*"; }
warn() { echo "  ⚠️  $*"; FIXED=$((FIXED + 1)); }
err()  { echo "  ❌ $*"; FAILED=$((FAILED + 1)); }

echo "🔍 检查 ZCode 专属文件（补丁模式）..."
echo "   策略：上游有的 → 最小补丁 | 上游没有的 → 确保存在"
echo ""

# ───────────────────────────────────────────────
# 辅助：从 git HEAD 恢复文件
# ───────────────────────────────────────────────
restore_from_git() {
  local file="$1"
  if git show HEAD:"$file" > /dev/null 2>&1; then
    git checkout HEAD -- "$file" 2>/dev/null && return 0
  fi
  return 1
}

# ───────────────────────────────────────────────
# 1. .zcode-plugin/plugin.json（上游没有 → 确保存在）
# ───────────────────────────────────────────────
PLUGIN_JSON=".zcode-plugin/plugin.json"
if [ ! -f "$PLUGIN_JSON" ]; then
  warn "$PLUGIN_JSON 缺失，正在从 git 恢复..."
  mkdir -p "$(dirname "$PLUGIN_JSON")"
  if restore_from_git "$PLUGIN_JSON"; then
    ok "$PLUGIN_JSON 已从 git 恢复"
  else
    # 从模板重建
    cat > "$PLUGIN_JSON" << 'ZCODEPLUGIN'
{
    "name": "zcodegraph",
    "version": "0.0.0",
    "description": "CodeGraph MCP 集成 — 为 ZCode 提供语义化代码图谱能力。通过 tree-sitter 解析代码库，将符号、依赖关系、调用链存储在 SQLite 中，让 AI 代理用更少的 token 精准理解项目结构。",
    "author": {
        "name": "Venti"
    },
    "license": "MIT",
    "skills": "skills",
    "mcpServers": {
        "zcodegraph": {
            "command": "/Applications/ZCode.app/Contents/Frameworks/ZCode Helper.app/Contents/MacOS/ZCode Helper",
            "args": [
                "/Applications/ZCode.app/Contents/Resources/glm/zcode.cjs",
                "__zcode-plugin-host",
                "${ZCODE_PLUGIN_ROOT}/dist/mcp/server.js"
            ],
            "cwd": "${ZCODE_PROJECT_DIR}",
            "env": {
                "ELECTRON_RUN_AS_NODE": "1",
                "CODEGRAPH_PROJECT_DIR": "${ZCODE_PROJECT_DIR}"
            }
        }
    }
}
ZCODEPLUGIN
    ok "$PLUGIN_JSON 已从模板重建（版本号在后续步骤更新）"
  fi
else
  ok "$PLUGIN_JSON 存在"
fi

# ───────────────────────────────────────────────
# 2. .zcode-plugin-seed.json（上游没有 → 确保存在）
# ───────────────────────────────────────────────
SEED_JSON=".zcode-plugin-seed.json"
if [ ! -f "$SEED_JSON" ]; then
  warn "$SEED_JSON 缺失，正在从 git 恢复..."
  if restore_from_git "$SEED_JSON"; then
    ok "$SEED_JSON 已从 git 恢复"
  else
    cat > "$SEED_JSON" << 'ZCODESEED'
{
    "hash": "",
    "marketplace": "zcode-plugins-official",
    "plugin": "zcodegraph",
    "pluginVersion": "0.0.0",
    "source": "filesystem",
    "version": 1
}
ZCODESEED
    ok "$SEED_JSON 已重建（版本号在后续步骤更新）"
  fi
else
  ok "$SEED_JSON 存在"
fi

# ───────────────────────────────────────────────
# 3. skills/zcodegraph/SKILL.md（上游没有 → 确保存在）
# ───────────────────────────────────────────────
SKILL_MD="skills/zcodegraph/SKILL.md"
if [ ! -f "$SKILL_MD" ]; then
  warn "$SKILL_MD 缺失，正在从 git 恢复..."
  if restore_from_git "$SKILL_MD"; then
    ok "$SKILL_MD 已从 git 恢复"
  else
    err "$SKILL_MD 无法恢复，需要手动处理"
  fi
else
  ok "$SKILL_MD 存在"
fi

# ───────────────────────────────────────────────
# 4. src/installer/targets/zcode.ts（上游没有 → 确保存在）
# ───────────────────────────────────────────────
ZCODE_TS="src/installer/targets/zcode.ts"
if [ ! -f "$ZCODE_TS" ]; then
  warn "$ZCODE_TS 缺失，正在从 git 恢复..."
  if restore_from_git "$ZCODE_TS"; then
    ok "$ZCODE_TS 已从 git 恢复"
  else
    err "$ZCODE_TS 无法恢复，需要手动处理"
  fi
else
  ok "$ZCODE_TS 存在"
fi

# ───────────────────────────────────────────────
# 5. install-plugin.sh（上游没有 → 确保存在）
# ───────────────────────────────────────────────
INSTALL_PLUGIN="install-plugin.sh"
if [ ! -f "$INSTALL_PLUGIN" ]; then
  warn "$INSTALL_PLUGIN 缺失，正在从 git 恢复..."
  if restore_from_git "$INSTALL_PLUGIN"; then
    ok "$INSTALL_PLUGIN 已从 git 恢复"
  else
    err "$INSTALL_PLUGIN 无法恢复，需要手动处理"
  fi
else
  ok "$INSTALL_PLUGIN 存在"
fi

# ───────────────────────────────────────────────
# 6. .github/workflows/sync-upstream.yml（上游没有 → 确保存在）
# ───────────────────────────────────────────────
SYNC_YML=".github/workflows/sync-upstream.yml"
if [ ! -f "$SYNC_YML" ]; then
  warn "$SYNC_YML 缺失，正在从 git 恢复..."
  if restore_from_git "$SYNC_YML"; then
    ok "$SYNC_YML 已从 git 恢复"
  else
    err "$SYNC_YML 无法恢复，需要手动处理"
  fi
else
  ok "$SYNC_YML 存在"
fi

# ───────────────────────────────────────────────
# 7. registry.ts → 最小补丁（上游文件 + 2 行插入）
# ───────────────────────────────────────────────
REGISTRY_TS="src/installer/targets/registry.ts"
if [ -f "$REGISTRY_TS" ]; then
  NEED_IMPORT=false
  NEED_ARRAY=false

  # 检查是否已有 zcode import
  if ! grep -qE "import\s*\{\s*zcodeTarget\s*\}\s*from\s*'\./zcode'" "$REGISTRY_TS"; then
    NEED_IMPORT=true
  fi

  # 检查 ALL_TARGETS 是否包含 zcodeTarget
  if ! grep -q 'zcodeTarget,' "$REGISTRY_TS"; then
    NEED_ARRAY=true
  fi

  if $NEED_IMPORT || $NEED_ARRAY; then
    warn "registry.ts 需要打补丁（上游更新后缺少 ZCode 条目）..."

    # 插入 import（在 kiro import 之后）
    if $NEED_IMPORT; then
      if grep -q "import { kiroTarget } from './kiro';" "$REGISTRY_TS"; then
        sed -i '' "/import { kiroTarget } from '.\/kiro';/a\\
import { zcodeTarget } from '.\/zcode';
" "$REGISTRY_TS" 2>/dev/null || \
        sed -i "/import { kiroTarget } from '.\/kiro';/a import { zcodeTarget } from '.\/zcode';" "$REGISTRY_TS"
        echo "  ↳ 已插入 zcodeTarget import"
      else
        err "无法定位 kiroTarget import 行，请手动修复 $REGISTRY_TS"
      fi
    fi

    # 插入 zcodeTarget 到 ALL_TARGETS 数组（在 kiroTarget 之后）
    if $NEED_ARRAY; then
      if grep -q 'kiroTarget,' "$REGISTRY_TS"; then
        sed -i '' "/kiroTarget,/a\\
  zcodeTarget,
" "$REGISTRY_TS" 2>/dev/null || \
        sed -i "/kiroTarget,/a\  zcodeTarget," "$REGISTRY_TS"
        echo "  ↳ 已插入 zcodeTarget 到 ALL_TARGETS 数组"
      else
        err "无法定位 kiroTarget 数组条目，请手动修复 $REGISTRY_TS"
      fi
    fi

    if [ "$FAILED" -eq 0 ] 2>/dev/null || [ "${FAILED:-0}" -eq 0 ]; then
      ok "registry.ts 补丁已应用"
    fi
  else
    ok "registry.ts 已包含 ZCode 条目"
  fi
else
  err "$REGISTRY_TS 不存在！"
fi

# ───────────────────────────────────────────────
# 8. types.ts → 最小补丁（上游文件 + 1 个类型追加）
# ───────────────────────────────────────────────
TYPES_TS="src/installer/targets/types.ts"
if [ -f "$TYPES_TS" ]; then
  if ! grep -q "'zcode'" "$TYPES_TS"; then
    warn "types.ts 需要打补丁（缺少 'zcode' 类型）..."

    # 在 'kiro' 之后追加 'zcode'
    if grep -q "| 'kiro'" "$TYPES_TS"; then
      sed -i '' "s/| 'kiro'/| 'kiro' | 'zcode'/" "$TYPES_TS" 2>/dev/null || \
      sed -i "s/| 'kiro'/| 'kiro' | 'zcode'/" "$TYPES_TS"
      echo "  ↳ 已追加 | 'zcode' 到 TargetId 类型"
      ok "types.ts 补丁已应用"
    else
      err "无法定位 'kiro' 类型定义，请手动修复 $TYPES_TS"
    fi
  else
    ok "types.ts 已包含 'zcode' 类型"
  fi
else
  err "$TYPES_TS 不存在！"
fi

# ───────────────────────────────────────────────
# 9. README.md → 始终是 ZCode 中文版，不应被上游覆盖
# ───────────────────────────────────────────────
README="README.md"
if [ -f "$README" ]; then
  if grep -q "Zcodegraph" "$README" 2>/dev/null; then
    ok "README.md 是 ZCode 中文版"
  else
    warn "README.md 被上游版本覆盖，正在恢复..."
    if restore_from_git "$README"; then
      ok "README.md 已恢复为 ZCode 中文版"
    else
      err "README.md 无法恢复，需要手动处理"
    fi
  fi
else
  err "README.md 不存在！"
fi

# ───────────────────────────────────────────────
# 结果汇总
# ───────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────"
echo "ZCode 补丁检查完成：修复 $FIXED 项，失败 $FAILED 项"
echo "──────────────────────────────────────"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

exit 0
