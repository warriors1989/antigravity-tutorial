# Repository Guidelines

## 项目概述

本项目是 Google Antigrivity 产品生态（Antigrivity 2.0、CLI、SDK、IDE）的中文入门教程仓库。内容包含产品介绍、CLI 自定义脚本（如 statusline 优化）、使用指南与最佳实践。

## 目录结构

```
antigravity-tutorial/
├── AGENTS.md                     # 本文件 — 贡献者指南
├── README.md                     # 项目总览与 Antigrivity 产品介绍
└── antigrivity-cli/              # CLI 相关教程与自定义配置
    └── Customizations/
        ├── statusline/           # Statusline 自定义脚本
        │   ├── README.md
        │   ├── statusline.sh
        │   ├── statusline_with_quota.sh
        │   └── images/
        └── title/                # Title 自定义（待补充）
```

- `antigrivity-cli/Customizations/`：放置 CLI 自定义脚本，每个功能一个子目录，附带独立的 `README.md` 说明用法与效果截图。
- `images/`：每个自定义子目录下的 `images/` 存放运行效果截图，便于读者直观理解。

## 开发与本地预览

本项目以 Markdown 文档和 shell 脚本为主，无需构建流程。本地操作建议：

```bash
# 启动本地 Markdown 预览（使用 VS Code 或任何 Markdown 编辑器）
code .

# 本地 Git 历史查看
git log --oneline
```

## 编码风格

- **文档**：使用中文撰写，UTF-8 编码。Markdown 采用 ATX 标题（`##`），代码块标注语言标识。
- **脚本**：Shell 脚本遵循 POSIX sh 或 Bash 语法，使用 `set -e` 或 `set -o pipefail` 确保健壮性。变量命名采用 `snake_case`。
- **截图**：PNG 格式，清晰展示终端或 IDE 的实际运行效果，避免大尺寸文件。
- 无需 ESLint / Prettier 等格式化工具，保持内容整洁即可。

## 提交规范

参考项目 Git 历史，提交信息采用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>(<scope>): <简短描述>
```

- `type`：`feat`（新教程/脚本）、`docs`（文档更新）、`fix`（错误修正）、`chore`（项目初始化/杂项）。
- `scope`：可选，如 `Status Line`、`README`。
- 描述使用中文，时态用一般现在时。

示例：
```
docs(Status Line): 添加优化版 statusline 使用方法及下载命令
chore: 初始化 antigravity-tutorial 项目
```

## 贡献流程

1. Fork 本仓库并创建特性分支：`git checkout -b docs/add-xxx-tutorial`。
2. 在对应目录下添加或修改内容，附上必要的截图与说明。
3. 提交 Pull Request，标题遵循 Conventional Commits 格式，描述中说明改动内容与关联 Issue（如有）。
4. PR 审核通过后合并至 `main` 分支。

## 测试指南

本项目以文档与脚本为主，无自动化测试框架。提交前请确认：

- Shell 脚本可通过 `bash -n <script.sh>` 检查语法错误。
- 文档中的代码块示例可被实际执行验证。
- 截图路径正确，图片正常显示。

## 安全与配置提示

- 自定义脚本（如 `statusline.sh`）不涉及 API Key 或敏感凭据。若添加涉及认证的示例，务必使用环境变量传递密钥，切勿硬编码。
- 截图请避免暴露个人 token、quota 明细或工作区路径等敏感信息。

## Antigrivity 学习资源

| 产品 | 用途 |
|------|------|
| Antigrivity 2.0 | 桌面端指挥中心，支持多工作区与子智能体编排 |
| Antigrivity CLI | 轻量终端界面，适合 SSH 会话与快速交互 |
| Antigrivity SDK | Python 编程框架，提供声明式安全策略与智能体生成 |
| Antigrivity IDE | 全功能 AI 驱动开发环境 |

相关链接：[Google Antigrivity 官方文档](https://google-antigrivity.dev/)
