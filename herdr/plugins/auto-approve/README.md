# Herdr Auto Approve

自动处理 Herdr pane 中 Codex 和 Claude Code 的明确权限确认，同时保留普通问题、目录信任、登录和无法可靠分类的 blocker。

## 交互

- `prefix+a`：切换当前 pane。
- `prefix+shift+a`：切换所有当前及未来的 Codex / Claude pane；每次切换会清空 pane override。
- `herdr plugin action invoke tychooo.auto-approve.disable-all`：紧急关闭全部自动审批。
- `herdr plugin action invoke tychooo.auto-approve.status`：显示当前状态。

开启状态只在当前 Herdr server 生命周期中有效；server startup hook 会清空运行态策略。

## 安全模型

插件只会在以下条件同时成立时发送一次 `Enter`：

1. Herdr 将 pane 识别为 `blocked`，agent 是 Codex 或 Claude Code。
2. 当前 pane 或全局策略已开启。
3. detection snapshot 能识别为 command/tool permission。
4. UI 当前明确选中了 `Yes`、`Allow`、`Approve` 或 `Proceed`。
5. 二次读取的 `pane_id`、`terminal_id`、agent、status 和 revision 均未变化。

Codex 的 `› 1. Yes, proceed` 已包含在匹配规则中；不会裸匹配任意
`1. Yes`，以免误批普通选择题。一次批准后，插件会短暂追踪 agent 状态，
继续处理随后出现的 permission；单次链式处理上限为 8。

插件不判断被批准命令本身是否安全。开启自动审批意味着符合上述 UI 规则的危险命令也会被批准。

## 测试

```bash
cd herdr/plugins/auto-approve
npm test
```
