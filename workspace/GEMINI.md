# Antigravity Workspace Context

Welcome to the designated Antigravity agent workspace!

This workspace is managed by and connected to the **Antigravity Quickshell** configuration located in the parent directory (`../`).

## Important Resources

- Parent Quickshell Project: `../` (symlinked at `~/.config/quickshell/antigravity`)
- Skill Reference: See `.agents/skills/quickshell-manager/SKILL.md` (or activate `quickshell-manager`) for all Quickshell commands, IPC targets, QML rules, and architecture details.
- Active Shell Control:
  - Run `qs -c antigravity ipc call antigravity toggle` to test the HUD.
  - Run `qs -c antigravity ipc call search toggle` to test the App Launcher.
  - Run `quickshell log -c antigravity -t 30` to check real-time shell logs.
