---
name: zcodegraph
description: >
  Zcodegraph — 语义化代码图谱。在修改代码、理解项目结构、查找符号定义/引用、分析调用链或依赖关系时使用。
  当项目根目录存在 .codegraph/ 时，优先使用 codegraph_explore MCP 工具（1 次调用替代多次文件读取）；
  当 MCP 不可用时，使用 shell 命令 `codegraph explore "<查询>"`。
  触发场景：查找函数、分析影响范围、理解代码架构、重构、追踪调用关系、添加新功能前了解现有代码。
---

# Zcodegraph — 代码图谱优先策略

## 核心原则

**理解代码 → 修改代码。在理解阶段，图谱优先于逐文件阅读。**

在项目根目录存在 `.codegraph/` 文件夹时（表示该项目已建立代码图谱），任何涉及"查找"、"理解"、"分析"、"影响评估"的操作，都要遵循以下顺序：

```
第一步：codegraph_explore 查图谱（1 次调用）
    ↓ 信息不够？
第二步：Read 关键文件补充（少量精准读取）
    ↓ 还不够？
第三步：Grep 搜索（最后手段）
```

### 具体规则

1. **修改代码前**：先 `codegraph_explore` 查询你要改的符号，了解它被哪些地方引用、它调用了谁、继承/实现关系。
2. **添加功能前**：先 `codegraph_explore` 了解相关模块的结构和入口点。
3. **重构前**：先 `codegraph_explore` 分析影响范围，列出所有受影响的调用方。
4. **修 Bug 前**：先 `codegraph_explore` 追踪出问题函数的调用链，定位根因。
5. **"这是什么"类问题**：直接 `codegraph_explore`，不要先用 Read 或 Grep。

### 何时不用

- 项目根目录没有 `.codegraph/` → 跳过，用户未建图
- 要读的是纯配置/数据文件（`.json`、`.yaml`、`.plist`、`README`）→ 直接 Read
- 你已经通过图谱拿到了完整信息 → 不需要重复查询

## 使用方式

### 方式 A：MCP 工具（ZCode 插件已安装时）

MCP 连接正常时，直接调用 `codegraph_explore` 工具即可。参数 `query` 填写要查的符号名或自然语言描述。

```
工具: codegraph_explore
参数: query = "UserAuth 类的所有调用方" 或 "showLogin 函数"
```

### 方式 B：Shell 命令（MCP 不可用时）

```bash
codegraph explore "要查的符号名或问题描述"
```

输出格式与 MCP 工具一致。

## 与 hermes-graph 的区别

- **hermes-graph**：项目级静态图谱（手动生成 MD 文件），适合整体架构理解
- **zcodegraph**：语义级动态图谱（CodeGraph 引擎），适合精准代码查询和影响分析

两者互不冲突。快速了解项目全貌用 hermes-graph；定位具体函数/类/调用关系用 zcodegraph。
