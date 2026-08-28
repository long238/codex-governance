# 治理工具仓库开发约束

## 仓库定位

- 本仓库只维护可复用的项目级 Codex 治理资料、`bootstrap-project-governance` Skill 和安装脚本，不包含任何软件项目的业务源码或脚手架。
- `README.md` 是本仓库的使用入口；Skill 的工作流以 `skills/bootstrap-project-governance/SKILL.md` 为准；通用治理模型以其 `references/governance-model.md` 为准。
- `skills/bootstrap-project-governance/assets/project-governance/` 是候选治理包，不得把它描述为已适配任意目标项目的最终文件。目标项目事实必须在应用时从目标目录核对。

## 内容边界

- 模板只保留跨项目通用的研发治理原则。不得加入来源项目名称、领域术语、具体框架类型、产品路径、数据结构、测试目标或交付文件名。
- 无法从目标项目证明的构建、测试、架构、依赖和交付事实必须标记为“待确认”，不得用示例冒充当前事实。
- 修改模板文件时，同步检查 Skill 工作流、治理模型说明和根 `README.md` 是否仍一致。
- 保持 `policy.allow_implicit_invocation: false`。除非用户明确改变需求，不得让 Skill 隐式触发。
- 不声明 MCP、外部账号或网络服务依赖。

## 修改与验证

- 修改前检查本仓库 Git 状态，保留未知或无关的已有改动。
- 文件编辑限定在本任务需要的路径；禁止无关格式化、批量重写和破坏性 Git 恢复。
- 纯 Markdown、Skill 说明和元数据修改至少执行：Skill 快速验证、引用与占位符检查、敏感词残留检查、`git diff --check` 和最终 diff 审查。
- 安装脚本修改还必须在可用的 Windows PowerShell 5.1 与 PowerShell 7 中进行语法检查，并用隔离的临时目标验证首次安装、幂等、差异拒绝、`-WhatIf` 和 `-Force` 备份替换。
- 安装或测试前后比较全局 Codex 指令文件哈希；不得修改全局 `AGENTS.md`、`config.toml` 或目标项目文件。
- 测试产生的临时目录必须位于明确的临时测试根内；删除前核对绝对路径和目录名前缀。

## 提交边界

- 完成且验证通过后，默认只为本仓库创建一次本地提交。
- 不配置远程、不推送，也不替目标项目初始化 Git、提交或修改嵌套治理文件，除非用户另行明确授权。
- 最终报告必须区分已通过、失败和未执行的验证，并列出实际修改文件及本地提交。
