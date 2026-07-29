.pragma library

// -----------------------------------------------------------------------
// Manual overrides for windows whose WM_CLASS doesn't line up with their
// desktop-entry id (so DesktopEntries.byId(wmClass) would fail to find
// them). Add to this table whenever you spot an app showing the wrong /
// generic icon.
//
// key   -> WM_CLASS, lowercased (check with `hyprctl -j clients | jq '.[].class'`)
// value -> desktop entry id, without the ".desktop" suffix
//          (check with `ls /usr/share/applications`)
// -----------------------------------------------------------------------
var classIconOverrides = {
    "spotify": "spotify-launcher",
}

// Parses `hyprctl -j workspaces` output into a sorted list of {id, name}.
// Returns [] on any parse failure instead of throwing, so a bad/empty
// hyprctl response just means an empty switcher instead of a crash.
function parseWorkspaces(jsonText) {
    let raw
    try {
        raw = JSON.parse(jsonText)
    } catch (e) {
        return []
    }

    if (!Array.isArray(raw)) return []

    return raw
        .map(ws => ({ id: ws.id, name: ws.name }))
        .sort((a, b) => a.id - b.id)
}

// Parses `hyprctl -j clients` output into a map of
// workspaceId -> [{ wmClass, title }, ...]
function groupClientsByWorkspace(jsonText) {
    let raw
    try {
        raw = JSON.parse(jsonText)
    } catch (e) {
        return {}
    }

    if (!Array.isArray(raw)) return {}

    const grouped = {}

    for (const client of raw) {
        if (!client.workspace || client.workspace.id === undefined) continue

        const wsId = client.workspace.id
        if (!grouped[wsId]) grouped[wsId] = []

        grouped[wsId].push({
            wmClass: client.class || client.initialClass || "",
            title: client.title || client.initialTitle || ""
        })
    }

    return grouped
}

// Combines the workspace list + grouped client data into the final
// model consumed by the PathView. Workspaces with no windows just get
// an empty apps array (the delegate can decide how to render that).
function buildWorkspaceModel(workspaces, groupedClients) {
    return workspaces.map(ws => ({
        id: ws.id,
        name: ws.name,
        apps: groupedClients[ws.id] || []
    }))
}

// Finds the index of a workspace id within an already-built model array.
// Used to point the PathView at whatever workspace was focused before
// the switcher opened.
function indexOfWorkspaceId(model, id) {
    for (let i = 0; i < model.length; i++) {
        if (model[i].id === id) return i
    }
    return -1
}