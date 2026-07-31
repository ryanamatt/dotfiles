------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

hl.workspace_rule({
    workspace = "name:desktop",
})

hl.workspace_rule({
    workspace = "name:spotify"
})

hl.workspace_rule({
    workspace = "name:discord"
})