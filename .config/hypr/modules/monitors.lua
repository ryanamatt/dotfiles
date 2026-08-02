------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- hl.monitor({
--     output   = "",
--     mode     = "preferred",
--     position = "auto",
--     scale    = "auto",
-- })

-- Monitor 2
-- To Right of Monitor 1
hl.monitor({
    output   = "DP-2",
    mode     = "1920x1080@60",
    position = "1920x0",
    scale    = 1,
})

-- Monitor 1
-- Centered
hl.monitor({
    output   = "DP-3",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

hl.on("hyprland.start", function()
    -- Move cursor to the middle of DP-3 (adjust coordinates as needed)
    -- DP-3 is at 0x0, 1920x1080 resolution
    hl.dsp.cursor.move({ x = 1920 / 2, y = 1080 / 2})
end)

-- Assign workspaces 1-5 to DP-3
for i = 1, 5 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = "DP-3",
    })
end

-- Assign workspaces 6-10 to DP-2
for i = 6, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = "DP-2",
    })
end

hl.workspace_rule({
    workspace = "name:desktop",
    monitor = "DP-3"
})

hl.workspace_rule({
    workspace = "name:spotify"
})

hl.workspace_rule({
    workspace = "name:discord"
})