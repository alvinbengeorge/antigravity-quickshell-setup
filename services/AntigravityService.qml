pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int conversationCount: 0
    property string latestId: "None"
    property bool isActive: false
    property int stepCount: 0
    property string status: "IDLE"
    property string lastText: "Antigravity Ready"
    property int contextTokens: 0
    property int contextLimit: 1000000
    property real contextPercent: 0.0
    property string contextTokensStr: "0k"
    property int totalSessionTokens: 0
    property string totalSessionTokensStr: "0"
    property int gemini5hRemaining: 100
    property string gemini5hDesc: ""
    property int geminiWeeklyRemaining: 100
    property string geminiWeeklyDesc: ""
    property int claude5hRemaining: 100
    property string claude5hDesc: ""
    property int claudeWeeklyRemaining: 100
    property string claudeWeeklyDesc: ""
    property string defaultWorkspace: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/workspace"

    Process {
        id: statusProc
        running: false
        command: ["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_antigravity_status.py"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    const raw = collector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        root.conversationCount = data.conversation_count ?? 0;
                        root.latestId = data.latest_id ?? "None";
                        root.isActive = data.active ?? false;
                        root.stepCount = data.step_count ?? 0;
                        root.status = data.status ?? "IDLE";
                        root.lastText = data.last_text ?? "";
                        root.contextTokens = data.context_tokens ?? 0;
                        root.contextLimit = data.context_limit ?? 1000000;
                        root.contextPercent = data.context_percent ?? 0.0;
                        root.contextTokensStr = data.context_tokens_str ?? "0k";
                        root.totalSessionTokens = data.total_session_tokens ?? 0;
                        root.totalSessionTokensStr = data.total_session_tokens_str ?? "0";
                        root.gemini5hRemaining = data.gemini_5h_remaining ?? 100;
                        root.gemini5hDesc = data.gemini_5h_desc ?? "";
                        root.geminiWeeklyRemaining = data.gemini_weekly_remaining ?? 100;
                        root.geminiWeeklyDesc = data.gemini_weekly_desc ?? "";
                        root.claude5hRemaining = data.claude_5h_remaining ?? 100;
                        root.claude5hDesc = data.claude_5h_desc ?? "";
                        root.claudeWeeklyRemaining = data.claude_weekly_remaining ?? 100;
                        root.claudeWeeklyDesc = data.claude_weekly_desc ?? "";
                    }
                } catch(e) {
                    console.log("Error parsing Antigravity status: " + e);
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: ShellState.liteMode ? 10000 : 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running) {
                statusProc.running = true;
            }
        }
    }

    function refresh() {
        if (!statusProc.running) {
            statusProc.running = true;
        }
    }

    function launchCli() {
        Quickshell.execDetached([
            "kitty",
            "--directory", root.defaultWorkspace,
            "--title", "Antigravity CLI",
            "bash", "-c", `cd "${root.defaultWorkspace}" && /home/alvin/.local/bin/agy --dangerously-skip-permissions; exec bash`
        ]);
    }

    function continueCli() {
        Quickshell.execDetached([
            "kitty",
            "--directory", root.defaultWorkspace,
            "--title", "Antigravity CLI (Continue)",
            "bash", "-c", `cd "${root.defaultWorkspace}" && /home/alvin/.local/bin/agy -c --dangerously-skip-permissions; exec bash`
        ]);
    }

    function runPrompt(promptText) {
        if (!promptText || promptText.trim().length === 0) return;
        Quickshell.execDetached([
            "kitty",
            "--directory", root.defaultWorkspace,
            "--title", "Antigravity Task",
            "bash", "-c", `cd "${root.defaultWorkspace}" && /home/alvin/.local/bin/agy --dangerously-skip-permissions -i "${promptText.replace(/"/g, '\\"')}"; exec bash`
        ]);
    }

    function openBrainDir() {
        Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.gemini/antigravity-cli/brain"]);
    }

    function openWorkspaceDir() {
        Quickshell.execDetached(["xdg-open", root.defaultWorkspace]);
    }

    function openCurrentConversation() {
        if (root.latestId && root.latestId !== "None") {
            Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + `/.gemini/antigravity-cli/brain/${root.latestId}`]);
        }
    }
}
