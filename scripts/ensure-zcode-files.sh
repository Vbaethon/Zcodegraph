#!/usr/bin/env bash
# ============================================================
# Zcodegraph — 确保 ZCode 专属文件完整
#
# 在每次 git merge upstream/main 之后运行。
# 自动修复因合并导致缺失或不完整的 ZCode 定制文件。
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

echo "🔍 检查 ZCode 专属文件..."

# --------------------------------------------------
# 1. .zcode-plugin/plugin.json
# --------------------------------------------------
PLUGIN_JSON=".zcode-plugin/plugin.json"
if [ ! -f "$PLUGIN_JSON" ]; then
  warn "$PLUGIN_JSON 缺失，正在重建..."
  mkdir -p "$(dirname "$PLUGIN_JSON")"
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
  ok "$PLUGIN_JSON 已重建（版本号将在后续步骤更新）"
else
  ok "$PLUGIN_JSON 存在"
fi

# --------------------------------------------------
# 2. .zcode-plugin-seed.json
# --------------------------------------------------
SEED_JSON=".zcode-plugin-seed.json"
if [ ! -f "$SEED_JSON" ]; then
  warn "$SEED_JSON 缺失，正在重建..."
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
  ok "$SEED_JSON 已重建（版本号将在后续步骤更新）"
else
  ok "$SEED_JSON 存在"
fi

# --------------------------------------------------
# 3. skills/zcodegraph/SKILL.md
# --------------------------------------------------
SKILL_MD="skills/zcodegraph/SKILL.md"
if [ ! -f "$SKILL_MD" ]; then
  warn "$SKILL_MD 缺失！请从 git 历史恢复。"
  # 尝试从 git 恢复
  if git show HEAD:"$SKILL_MD" > /dev/null 2>&1; then
    git checkout HEAD -- "$SKILL_MD" 2>/dev/null || true
    ok "$SKILL_MD 已从 HEAD 恢复"
  else
    err "$SKILL_MD 无法自动恢复，需要手动处理"
  fi
else
  ok "$SKILL_MD 存在"
fi

# --------------------------------------------------
# 4. src/installer/targets/zcode.ts
# --------------------------------------------------
ZCODE_TS="src/installer/targets/zcode.ts"
if [ ! -f "$ZCODE_TS" ]; then
  warn "$ZCODE_TS 缺失！请从 git 历史恢复。"
  if git show HEAD:"$ZCODE_TS" > /dev/null 2>&1; then
    git checkout HEAD -- "$ZCODE_TS" 2>/dev/null || true
    ok "$ZCODE_TS 已从 HEAD 恢复"
  else
    err "$ZCODE_TS 无法自动恢复，需要手动处理"
  fi
else
  ok "$ZCODE_TS 存在"
fi

# --------------------------------------------------
# 5. registry.ts — 确保包含 zcodeTarget
# --------------------------------------------------
REGISTRY_TS="src/installer/targets/registry.ts"
if [ -f "$REGISTRY_TS" ]; then
  if grep -q "import { zcodeTarget } from './zcode';" "$REGISTRY_TS"; then
    ok "registry.ts 包含 zcodeTarget 导入"
  else
    warn "registry.ts 缺少 zcodeTarget 导入，正在修复..."
    # 在 kiroTarget 导入之后插入 zcodeTarget 导入
    if grep -q "import { kiroTarget } from './kiro';" "$REGISTRY_TS"; then
      sed -i '' "/import { kiroTarget } from '.\/kiro';/a\\
import { zcodeTarget } from '.\/zcode';
" "$REGISTRY_TS" 2>/dev/null || \
      sed -i "/import { kiroTarget } from '.\/kiro';/a import { zcodeTarget } from '.\/zcode';" "$REGISTRY_TS"
      ok "已添加 zcodeTarget 导入到 registry.ts"
    else
      err "无法定位 kiroTarget 导入行，请手动修复 registry.ts"
    fi
  fi

  # 确保 ALL_TARGETS 数组包含 zcodeTarget
  if grep -q 'zcodeTarget' "$REGISTRY_TS"; then
    if grep -q 'zcodeTarget,' "$REGISTRY_TS"; then
      ok "registry.ts ALL_TARGETS 包含 zcodeTarget"
    else
      warn "registry.ts ALL_TARGETS 缺少 zcodeTarget 条目，正在修复..."
      if grep -q 'kiroTarget,' "$REGISTRY_TS"; then
        sed -i '' "/kiroTarget,/a\\
  zcodeTarget,
" "$REGISTRY_TS" 2>/dev/null || \
        sed -i "/kiroTarget,/a\  zcodeTarget," "$REGISTRY_TS"
        ok "已添加 zcodeTarget 到 ALL_TARGETS"
      else
        err "无法定位 kiroTarget 条目，请手动修复 registry.ts"
      fi
    fi
  fi
else
  err "$REGISTRY_TS 不存在！"
fi

# --------------------------------------------------
# 6. types.ts — 确保包含 'zcode' 类型
# --------------------------------------------------
TYPES_TS="src/installer/targets/types.ts"
if [ -f "$TYPES_TS" ]; then
  if grep -q "'zcode'" "$TYPES_TS"; then
    ok "types.ts TargetId 包含 'zcode'"
  else
    warn "types.ts TargetId 缺少 'zcode'，正在修复..."
    # 在 'kiro' 之后添加 'zcode'
    if grep -q "| 'kiro'" "$TYPES_TS"; then
      sed -i '' "s/| 'kiro'/| 'kiro' | 'zcode'/" "$TYPES_TS" 2>/dev/null || \
      sed -i "s/| 'kiro'/| 'kiro' | 'zcode'/" "$TYPES_TS"
      ok "已添加 'zcode' 到 TargetId 类型"
    else
      err "无法定位 'kiro' 类型，请手动修复 types.ts"
    fi
  fi
else
  err "$TYPES_TS 不存在！"
fi

# --------------------------------------------------
# 7. .github/workflows/sync-upstream.yml
# --------------------------------------------------
SYNC_YML=".github/workflows/sync-upstream.yml"
if [ ! -f "$SYNC_YML" ]; then
  warn "$SYNC_YML 缺失！请从 git 历史恢复。"
  if git show HEAD:"$SYNC_YML" > /dev/null 2>&1; then
    git checkout HEAD -- "$SYNC_YML" 2>/dev/null || true
    ok "$SYNC_YML 已从 HEAD 恢复"
  else
    err "$SYNC_YML 无法自动恢复，需要手动处理"
  fi
else
  ok "$SYNC_YML 存在"
fi

# --------------------------------------------------
# 8. install.sh — 确保是 ZCode 版本（非上游 CLI 安装器）
# --------------------------------------------------
INSTALL_SH="install.sh"
if [ -f "$INSTALL_SH" ]; then
  if grep -q "Zcodegraph" "$INSTALL_SH" 2>/dev/null; then
    ok "install.sh 是 ZCode 版本"
  else
    warn "install.sh 可能是上游版本（缺少 Zcodegraph 标识），正在恢复..."
    if git show HEAD:"$INSTALL_SH" > /dev/null 2>&1; then
      git checkout HEAD -- "$INSTALL_SH" 2>/dev/null || true
      ok "install.sh 已从 HEAD 恢复"
    else
      err "install.sh 无法自动恢复，需要手动处理"
    fi
  fi
else
  warn "install.sh 缺失，正在从 HEAD 恢复..."
  if git show HEAD:"$INSTALL_SH" > /dev/null 2>&1; then
    git checkout HEAD -- "$INSTALL_SH" 2>/dev/null || true
    ok "install.sh 已从 HEAD 恢复"
  else
    err "install.sh 无法自动恢复，需要手动处理"
  fi
fi

# --------------------------------------------------
# 结果汇总
# --------------------------------------------------
echo ""
echo "──────────────────────────────────────"
echo "ZCode 文件检查完成：修复 $FIXED 项，失败 $FAILED 项"
echo "──────────────────────────────────────"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

exit 0
