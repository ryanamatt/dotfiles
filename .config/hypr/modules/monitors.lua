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
    workspace = "name:grave",
})

hl.workspace_rule({
    workspace = "name:spotify"
})

hl.workspace_rule({
    workspace = "name:discord"
})

hl.workspace_rule({
    workspace = "name:another"
})

hl.workspace_rule({
    workspace = "name:writing"
})
