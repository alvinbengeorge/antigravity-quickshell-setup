pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var allApps: {
        const apps = DesktopEntries.applications.values || [];
        const result = [];
        const seen = new Set();
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i];
            if (!app || app.noDisplay) continue;
            if (!app.name || app.name.trim().length === 0) continue;
            // Filter duplicate names
            const key = app.name.trim().toLowerCase();
            if (seen.has(key)) continue;
            seen.add(key);
            result.push(app);
        }
        result.sort((a, b) => a.name.localeCompare(b.name));
        return result;
    }

    function search(query) {
        if (!query || query.trim().length === 0) {
            return allApps;
        }

        const raw = query.trim().toLowerCase();
        // Strip common action prefixes: "open ", "launch ", "run ", "start ", "goto ", "app "
        const stripped = raw.replace(/^(?:open|launch|run|start|goto|app)\s+/i, "").trim();

        // Targets to search against: both stripped verb query and raw query
        const targets = [stripped];
        if (raw !== stripped && raw.length > 0) {
            targets.push(raw);
        }

        const scored = [];

        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i];
            if (!app) continue;

            const name = (app.name || "").toLowerCase();
            const comment = (app.comment || "").toLowerCase();
            const generic = (app.genericName || "").toLowerCase();
            const exec = (app.execString || "").toLowerCase();
            const id = (app.id || "").toLowerCase();
            const startup = (app.startupClass || "").toLowerCase();

            let kwStr = "";
            if (Array.isArray(app.keywords)) {
                kwStr = app.keywords.join(" ").toLowerCase();
            } else if (typeof app.keywords === "string") {
                kwStr = app.keywords.toLowerCase();
            }

            let catStr = "";
            if (Array.isArray(app.categories)) {
                catStr = app.categories.join(" ").toLowerCase();
            } else if (typeof app.categories === "string") {
                catStr = app.categories.toLowerCase();
            }

            let bestScore = 0;

            for (let j = 0; j < targets.length; j++) {
                const t = targets[j];
                if (!t || t.length === 0) continue;

                let score = 0;

                // 1. Exact name match (Highest priority)
                if (name === t) {
                    score = Math.max(score, 100);
                }
                // 2. Name starts with query
                else if (name.startsWith(t)) {
                    score = Math.max(score, 85);
                }
                // 3. Any word in name starts with query
                else {
                    const words = name.split(/[\s\-_]+/);
                    for (let w = 0; w < words.length; w++) {
                        if (words[w].startsWith(t)) {
                            score = Math.max(score, 75);
                            break;
                        }
                    }
                    if (score === 0 && name.includes(t)) {
                        score = Math.max(score, 65);
                    }
                }

                // 4. Generic Name match (e.g. "Instant Messenger", "Web Browser")
                if (generic === t) {
                    score = Math.max(score, 65);
                } else if (generic.startsWith(t)) {
                    score = Math.max(score, 58);
                } else if (generic.includes(t)) {
                    score = Math.max(score, 45);
                }

                // 5. Comment / Description match (e.g. "WhatsApp Desktop for Linux")
                if (comment.length > 0) {
                    const commentWords = comment.split(/[\s\-_,.]+/);
                    for (let w = 0; w < commentWords.length; w++) {
                        if (commentWords[w].startsWith(t)) {
                            score = Math.max(score, 62);
                            break;
                        }
                    }
                    if (score < 50 && comment.includes(t)) {
                        score = Math.max(score, 50);
                    }
                }

                // 6. Keywords match (e.g. "WhatsApp;Chat;ZapZap;")
                if (kwStr.length > 0) {
                    const kwWords = kwStr.split(/[\s;,]+/);
                    for (let w = 0; w < kwWords.length; w++) {
                        if (kwWords[w].startsWith(t)) {
                            score = Math.max(score, 55);
                            break;
                        }
                    }
                    if (score < 45 && kwStr.includes(t)) {
                        score = Math.max(score, 45);
                    }
                }

                // 7. Startup Class / App ID match (e.g. "com.rtosta.zapzap" or "zapzap")
                if (startup === t || id === t) {
                    score = Math.max(score, 52);
                } else if (startup.includes(t) || id.includes(t)) {
                    score = Math.max(score, 40);
                }

                // 8. Exec string match
                if (exec.includes(t)) {
                    score = Math.max(score, 30);
                }

                // 9. Categories match
                if (catStr.includes(t)) {
                    score = Math.max(score, 20);
                }

                if (score > bestScore) {
                    bestScore = score;
                }
            }

            if (bestScore > 0) {
                scored.push({ app: app, score: bestScore });
            }
        }

        // Sort descending by score; tie-break alphabetically by name
        scored.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            return a.app.name.localeCompare(b.app.name);
        });

        return scored.map(item => item.app);
    }
}
