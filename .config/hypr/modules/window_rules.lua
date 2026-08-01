--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
suppressMaximizeRule:set_enabled(true)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.layer_rule({
    name = "swaync-rules",
    match = { namespace = "swaync-control-center" },
    animation = "slide top",
    blur = true,
    ignore_alpha = 0.5
})

-- Float Rules

hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|nwg-look)$" },
    float = true
})

hl.window_rule({
    name = "float-dolphin-dialogs",
    match = { class = "dolphin", title = "^(Progress|Properties)|.*Copy.*|.*Move.*|.*Delete.*)$" },
    float = true
})

hl.window_rule({
    name = "no-chrome-blur",
    match = { class = "^google-chrome$" },
    no_blur = true,
    opacity = "1.0 override 1.0 override"
})

hl.window_rule({
    match = { class = "python3.14"},
    float = true
})

hl.window_rule({
    match = { class = "qimgv" },
    float = true,
    no_blur = true,
    decorate = false
})

hl.window_rule({
    workspace = "name:spotify",
    match = { class = "Spotify" }
})

hl.window_rule({
    workspace = "name:discord",
    match = { class = "discord" }
})
