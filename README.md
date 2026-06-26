# Zcodegraph

> 🧠 让 AI 在 ZCode 里像人一样理解你的项目代码 —— 用图谱代替盲目翻文件

Zcodegraph 是 [CodeGraph](https://github.com/colbymchenry/codegraph) 的 ZCode 定制版。它把你的项目代码变成一张**知识图谱**，AI 代理只需要查图就能知道哪个函数调用了谁、这个类在哪些地方被用到——再也不用把几十个文件塞进上下文里了。

**省 Token · 更准确 · 完全本地运行**

---

## ✨ 它解决什么问题？

| 你的痛点 | Zcodegraph 怎么做 |
|---------|------------------|
| AI 每次都要读很多文件才能理解项目 | 一次性建图，AI 查图回答，**少读 90% 的文件** |
| 改一个函数不知道会影响哪些地方 | 图谱记录所有调用关系，**一秒找到所有影响点** |
| 项目越来越大，AI 越来越"笨" | 图谱大小固定，**无论项目多大，查询速度不变** |
| 担心代码上传到云端 | **100% 本地运行**，代码只在你电脑上处理 |

---

## 📦 安装（2 步搞定）

### 第 1 步：安装 CodeGraph 命令行工具

打开终端（Terminal），粘贴下面这一行：

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

> 💡 这一步只需要做一次。它会装一个叫 `codegraph` 的命令到你电脑上。

### 第 2 步：安装 Zcodegraph 插件到 ZCode

**方式一：一键安装（推荐）**

在终端中粘贴这一行：

```bash
curl -fsSL https://raw.githubusercontent.com/Vbaethon/Zcodegraph/main/install.sh | bash
```

脚本会自动完成：
1. 检查 `codegraph` 是否已安装（没有的话自动装）
2. 下载 Zcodegraph 插件文件
3. 把插件复制到 ZCode 的插件目录
4. 注册到 ZCode 插件市场

**方式二：手动安装**

```bash
# 克隆仓库
git clone https://github.com/Vbaethon/Zcodegraph.git
cd Zcodegraph

# 运行安装脚本
bash install.sh
```

> ⚠️ **安装完成后，必须完全退出并重启 ZCode**，插件才会生效。

---

## 🚀 在你的项目中使用

### 首次使用：给项目建图

用 ZCode 打开你的项目（或终端 `cd` 进去），然后：

```bash
cd 你的项目文件夹
codegraph init
```

> 📊 这一步会扫描你项目的所有代码，生成一张"图谱"。取决于项目大小，可能需要几秒到几分钟。

出现类似这样的输出就成功了：

```
✓ 项目图谱已创建
✓ 自动监听已开启（文件变动会自动更新图谱）
```

### 之后每次用 ZCode 时

**你什么都不用做。** Zcodegraph 会在后台自动工作：
- 你修改代码 → 图谱自动更新
- 你问 AI 问题 → AI 自动查图谱找答案
- 图谱永远是最新的

> 💡 **Zcodegraph 插件自带「技能」**，安装后 ZCode 会自动在以下场景优先使用图谱：
> - 查找函数/类/变量定义
> - 分析调用链和依赖关系
> - 重构前评估影响范围
> - 添加新功能前了解现有代码结构
>
> 你不需要手动告诉 AI "先用 codegraph"——技能会引导它自动这样做。

---

## 🎯 使用场景举例

### 场景 1："这个函数被哪些地方调用了？"

```
在 ZCode 里问 AI：
"showUserProfile 被哪些地方调用了？这些调用会受我改动的影响吗？"

→ AI 直接查图回答，不用读 50 个文件
```

### 场景 2："我想加一个新功能，改哪里最好？"

```
"这个项目里有没有和支付相关的代码？给我列出入口在哪"
"帮我把用户认证改成 Token 方式，先告诉我会影响哪些文件"

→ AI 看图就知道整个项目结构，精准定位
```

### 场景 3：重构大项目

```
"把所有的 API 请求从 Axios 换成 Fetch，列出所有需要改的文件"
"这个 interface 有哪些实现类？改了之后哪些测试需要更新？"

→ 图谱记录所有依赖关系，不会漏掉任何一个
```

---

## ❓ 常见问题

**Q：我的项目已经用 codegraph init 建过图了，还用再装 Zcodegraph 吗？**

A：需要装 Zcodegraph 插件，这样 ZCode 才能"看到"图谱数据。图已经有了，装插件就行。

**Q：图谱会占很多空间吗？**

A：一般项目几 MB 到几十 MB。一个 10 万行的项目大约 5-10 MB。

**Q：支持哪些语言？**

A：Python、JavaScript/TypeScript、Go、Rust、Java、C#、C/C++、Swift、Ruby、PHP、Kotlin、Scala、Lua、Vue、Svelte 等 20+ 种语言。

**Q：我的代码安全吗？**

A：完全安全。所有数据（图谱数据库）都放在你项目的 `.codegraph/` 文件夹里，**不上传任何东西**。

**Q：Zcodegraph 和原版 CodeGraph 有什么区别？**

A：Zcodegraph 是专门为 ZCode 适配的版本，增加了：
- ZCode 插件格式支持（一键安装到 ZCode）
- 自动版本同步（上游更新时自动跟进）
- 专门为 ZCode Agent 优化的上下文构建

**Q：我看不到插件，怎么办？**

A：确认两件事：
1. `codegraph` 命令能用吗？在终端输入 `codegraph --version` 试试
2. 插件安装后，**重启 ZCode** 才能生效

---

## 🔧 开发者相关

### 项目结构

```
Zcodegraph/
├── .zcode-plugin/          # ZCode 插件元数据
│   └── plugin.json         #   插件名、版本、MCP 配置
├── .zcode-plugin-seed.json # 插件注册种子
├── dist/
│   └── mcp/
│       └── server.js       # MCP 协议代理（连接 CodeGraph 和 ZCode）
├── src/installer/targets/
│   └── zcode.ts            # CodeGraph installer 的 ZCode 适配
└── .github/workflows/
    └── sync-upstream.yml   # 自动同步上游更新
```

### 更新到最新版

Zcodegraph 每天自动检查上游（CodeGraph 原版）是否有更新。如果有新版本：

- ✅ 自动合入新代码
- ✅ 自动编译
- ✅ 自动同步版本号

你只需在 ZCode 中重新安装插件即可获取更新。

---

## 📄 许可

MIT License — 继承自 [CodeGraph](https://github.com/colbymchenry/codegraph)
