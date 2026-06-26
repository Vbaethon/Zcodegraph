#!/bin/bash
# ============================================================
# Zcodegraph 一键安装脚本
# 将 Zcodegraph 插件安装到 ZCode 中
#
# 使用方法：
#   curl -fsSL https://raw.githubusercontent.com/Vbaethon/Zcodegraph/main/install.sh | bash
#
# 或者克隆仓库后本地运行：
#   git clone https://github.com/Vbaethon/Zcodegraph.git
#   cd Zcodegraph && bash install.sh
# ============================================================
set -euo pipefail

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Zcodegraph 插件安装程序            ║"
echo "║   为 ZCode 装上代码图谱超能力 🧠         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ─── 第 1 步：检查 codegraph CLI ───────────────────────────
echo "[1/4] 检查 CodeGraph 命令行工具..."

if command -v codegraph &>/dev/null; then
    CG_VERSION=$(codegraph --version 2>/dev/null || echo "未知")
    echo "      ✓ 已安装: codegraph ${CG_VERSION}"
else
    echo "      ✗ 未找到 codegraph 命令"
    echo ""
    echo "      正在安装 CodeGraph（需要几秒钟）..."
    curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh

    # 刷新 PATH
    export PATH="$HOME/.local/bin:$PATH"
    if command -v codegraph &>/dev/null; then
        echo "      ✓ CodeGraph 安装成功"
    else
        echo "      ✗ 安装失败，请手动安装："
        echo "      curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh"
        exit 1
    fi
fi

# ─── 第 2 步：确定插件源目录 ───────────────────────────────
echo "[2/4] 定位 Zcodegraph 插件文件..."

PLUGIN_SRC=""
TMPDIR=""

# 优先使用当前目录（用户已克隆仓库）
if [ -f "./.zcode-plugin/plugin.json" ]; then
    PLUGIN_SRC="$(pwd)"
# 其次检查常见克隆位置
elif [ -f "$HOME/Documents/GitHub/Zcodegraph/.zcode-plugin/plugin.json" ]; then
    PLUGIN_SRC="$HOME/Documents/GitHub/Zcodegraph"
else
    # 从 GitHub 下载
    echo "      从 GitHub 下载 Zcodegraph..."
    TMPDIR=$(mktemp -d)
    git clone --depth 1 https://github.com/Vbaethon/Zcodegraph.git "$TMPDIR" 2>/dev/null || {
        echo "      ✗ 下载失败，请检查网络连接"
        exit 1
    }
    PLUGIN_SRC="$TMPDIR"
fi

echo "      ✓ 插件源: $PLUGIN_SRC"

# ─── 第 3 步：安装插件到 ZCode ─────────────────────────────
echo "[3/4] 安装插件到 ZCode..."

# 读取插件版本
VERSION=$(node -p "require('$PLUGIN_SRC/.zcode-plugin/plugin.json').version" 2>/dev/null || echo "1.1.1")

# ZCode 目录
ZCODE_PLUGIN_CACHE="$HOME/.zcode/cli/plugins/cache/zcode-plugins-official/zcodegraph/$VERSION"
ZCODE_PLUGIN_DATA="$HOME/.zcode/cli/plugins/data/zcodegraph@zcode-plugins-official"
ZCODE_MARKETPLACE="$HOME/.zcode/cli/plugins/marketplaces/zcode-plugins-official/marketplace.json"

# 创建目录
mkdir -p "$ZCODE_PLUGIN_CACHE/.zcode-plugin"
mkdir -p "$ZCODE_PLUGIN_CACHE/dist/mcp"
mkdir -p "$ZCODE_PLUGIN_DATA"

# 复制插件文件
cp "$PLUGIN_SRC/.zcode-plugin/plugin.json" "$ZCODE_PLUGIN_CACHE/.zcode-plugin/plugin.json"
cp "$PLUGIN_SRC/.zcode-plugin-seed.json" "$ZCODE_PLUGIN_CACHE/.zcode-plugin-seed.json"
cp "$PLUGIN_SRC/dist/mcp/server.js" "$ZCODE_PLUGIN_CACHE/dist/mcp/server.js"

echo "      ✓ 插件文件已复制到 ZCode 缓存目录"

# ─── 第 4 步：注册到 ZCode ─────────────────────────────────
echo "[4/4] 注册插件到 ZCode..."

# 确保 marketplace 目录存在
mkdir -p "$(dirname "$ZCODE_MARKETPLACE")"

if [ -f "$ZCODE_MARKETPLACE" ]; then
    node -e "
        var fs = require('fs');
        var m = JSON.parse(fs.readFileSync('$ZCODE_MARKETPLACE', 'utf-8'));

        // 检查是否已注册
        var exists = m.plugins.find(function(p) { return p.name === 'zcodegraph'; });
        if (exists) {
            exists.version = '$VERSION';
            exists.cachePath = '$ZCODE_PLUGIN_CACHE';
            console.log('      已更新 marketplace 中的 zcodegraph 条目');
        } else {
            m.plugins.push({
                cachePath: '$ZCODE_PLUGIN_CACHE',
                name: 'zcodegraph',
                source: 'filesystem',
                version: '$VERSION'
            });
            console.log('      已添加 zcodegraph 到 marketplace');
        }

        fs.writeFileSync('$ZCODE_MARKETPLACE', JSON.stringify(m, null, 2) + '\n');
    "
    echo "      ✓ 已注册到 ZCode 插件市场"
else
    echo "      ⚠ 未找到 marketplace.json，跳过注册（首次使用 ZCode 后会自动生成）"
fi

# ─── 完成 ──────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         ✅ 安装完成！                    ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  接下来你需要做："
echo ""
echo "  1. 重启 ZCode（完全退出再打开）"
echo ""
echo "  2. 打开你的项目，在终端中运行："
echo "     cd 你的项目文件夹"
echo "     codegraph init"
echo ""
echo "  3. 回到 ZCode，开始和 AI 对话"
echo "     AI 会自动使用图谱理解你的项目"
echo ""
echo "  提示：安装后可在 ZCode 设置 → 插件中看到 Zcodegraph"
echo ""

# 清理临时目录
if [ -n "${TMPDIR:-}" ] && [ "$TMPDIR" != "$PLUGIN_SRC" ]; then
    rm -rf "$TMPDIR" 2>/dev/null || true
fi
