import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * The rices known to the `rice` CLI, and an apply action.
 *
 * The CLI is the single source of truth for what a rice is and what applying
 * one does -- this only reads `rice list --json` and shells back out to
 * `rice apply`. Duplicating the apply logic in QML would mean two places to
 * fix every time a rice gains a new aspect.
 *
 * Entries are shaped like the wallpaper folder model (fileName / filePath /
 * fileIsDir) so the same carousel delegate renders both tracks unchanged.
 */
Singleton {
    id: root

    property list<var> rices: []
    property string currentRice: ""
    readonly property bool available: rices.length > 0
    readonly property bool busy: listProc.running || applyProc.running
    property string lastError: ""

    signal applied(string name)

    function reload(): void {
        listProc.running = false;
        listProc.running = true;
    }

    function apply(name: string): void {
        if (!name || name.length === 0)
            return;
        applyProc.riceName = name;
        applyProc.running = false;
        applyProc.running = true;
    }

    function indexOfCurrent(): int {
        for (let i = 0; i < rices.length; i++) {
            if (rices[i].riceName === root.currentRice)
                return i;
        }
        return 0;
    }

    Component.onCompleted: root.reload()

    Process {
        id: listProc
        // argv form, not a shell string: nothing here needs quoting.
        command: ["rice", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0)
                    return;
                try {
                    const parsed = JSON.parse(text);
                    root.currentRice = parsed.current ?? "";
                    root.rices = (parsed.rices ?? []).map(r => ({
                                // Mirror the folder model's field names.
                                // Label if the rice has one, folder name otherwise.
                                fileName: (r.label && r.label.length > 0) ? r.label : r.name,
                                filePath: r.wallpaper,
                                fileIsDir: false,
                                // Rice-specific extras.
                                riceName: r.name,
                                label: r.label ?? r.name,
                                isCurrent: r.current === true,
                                aspects: r.aspects ?? {},
                                cursor: r.cursor ?? "",
                                fontMain: (r.fonts ?? {}).main ?? ""
                            }));
                    root.lastError = "";
                } catch (e) {
                    root.lastError = `could not parse rice list: ${e}`;
                    console.log("[Rices]", root.lastError);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[Rices] list stderr:", text.trim());
            }
        }
    }

    Process {
        id: applyProc
        property string riceName: ""
        command: ["rice", "apply", applyProc.riceName]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[Rices]", text.trim());
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    root.lastError = text.trim();
                    console.log("[Rices] apply stderr:", root.lastError);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.applied(applyProc.riceName);
                // Applying rewrites the current-rice marker, so re-read.
                root.reload();
            }
        }
    }
}
