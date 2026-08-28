# Codex Project Governance

这是一个很小的“治理工具仓库”，用于在不同电脑之间携带一套项目级 Codex 协作约束。它不是软件项目模板，也不会生成业务代码、框架结构或运行时能力。

这里的几个名称分别表示：

- **治理工具仓库**：当前这个可被克隆或复制的 Git 仓库，保存 Skill、候选治理包和安装脚本。
- **项目治理包**：准备合并到某个目标项目根目录的 `AGENTS.md` 与 `docs/` 文档集合。它必须先根据目标项目事实进行审查和适配。
- **Skill**：`$bootstrap-project-governance`，负责检查目标项目并先给出提案；它不会在首次调用时直接写文件。
- **安装脚本**：把仓库内的 Skill 复制到当前用户的 Codex Skills 目录，不修改任何全局规则或配置。

项目级 `AGENTS.md` 会随项目目录生效；Skill 则是可显式调用的复用工作流。对应机制见 OpenAI 官方的 [AGENTS.md 文档](https://learn.chatgpt.com/docs/agent-configuration/agents-md) 与 [Skills 文档](https://learn.chatgpt.com/docs/build-skills)。

## 仓库结构

```text
codex-governance/
├─ AGENTS.md
├─ README.md
├─ .gitignore
├─ scripts/Install-Skill.ps1
└─ skills/bootstrap-project-governance/
   ├─ SKILL.md
   ├─ agents/openai.yaml
   ├─ references/governance-model.md
   └─ assets/project-governance/
      ├─ AGENTS.md
      └─ docs/
```

候选治理包包含文档路由、架构事实、测试验证、Plan、Decision 和 Playbook 的最小目录。`.codex/worklogs/` 不会被预先创建；只有目标项目的真实任务需要恢复现场时才创建，并应仅在目标仓库本地排除。

## 安装 Skill

在仓库根目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Skill.ps1
```

脚本默认把 Skill 安装到：

```text
%CODEX_HOME%\skills\bootstrap-project-governance
```

当 `CODEX_HOME` 未设置时，使用：

```text
%USERPROFILE%\.codex\skills\bootstrap-project-governance
```

常用参数：

```powershell
# 预览，不写入
.\scripts\Install-Skill.ps1 -WhatIf

# 把指定目录作为 Codex 根目录
.\scripts\Install-Skill.ps1 -DestinationRoot 'D:\CodexProfile'

# 目标内容不同时，先备份精确的 Skill 目录再替换
.\scripts\Install-Skill.ps1 -Force
```

源内容与已安装内容完全一致时，脚本会幂等退出；内容不同且未指定 `-Force` 时会拒绝覆盖。`-Force` 只移动精确的 `bootstrap-project-governance` 目标目录，备份保存在同级并带时间戳。

## 使用 Skill

在目标项目的新 Codex 会话中显式输入：

```text
$bootstrap-project-governance
```

默认目标是当前 Git 根目录；当前目录不属于 Git 仓库时，使用当前目录本身。也可以在提示中给出要处理的绝对目录。

工作流分为两个阶段：

1. Skill 只读检查目标目录，按“保留、建议新增、冲突、待确认”输出提案和候选文件清单。
2. 你审查提案并再次明确批准后，Skill 才能在该目标目录中创建或合并治理文件。

已有 `AGENTS.md` 时，Skill 只提出合并方案，保留无法判断的规则和项目专属约束；它不会自动覆盖、修改嵌套 `AGENTS.md`、初始化 Git、提交目标项目，或触碰全局 Codex 配置。

## 换电脑时

1. 把本仓库克隆或复制到新电脑。
2. 在本仓库根目录运行安装脚本。
3. 重启 Codex（如果新安装的 Skill 尚未出现在选择器中）。
4. 在具体软件仓库中显式调用 `$bootstrap-project-governance`。

软件项目仍保存在各自独立的仓库中。以后创建远程仓库时，只需同步本治理工具仓库，不需要把所有软件项目放进它。

## 维护边界

- 不在本仓库维护任何具体软件能力、领域逻辑或项目级事实。
- 候选模板中的“待确认”必须在应用到目标项目时通过代码、构建配置、测试入口和当前文档核对。
- 更新 Skill 后重新运行安装脚本；如本机安装内容不同，先审查差异，再决定是否使用 `-Force`。
- 本仓库不创建 MCP、Plugin、远程仓库，也不修改用户全局 `AGENTS.md` 或 `config.toml`。
