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
    name = "rofi-popup",
    match = { namespace = "rofi"},
    animation = "slide bottom",
    dim_around = true
})

hl.layer_rule({
    name = "notification-animations",
    match = { namespace = "swaync-control-center" },
    animation = "slide top"
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

hl.layer_rule({
    name  = "waybar-blur",
    match = { namespace = "waybar" },
    blur  = true,
    ignore_alpha = 0.5
})

hl.layer_rule({
    "swaync-blur",
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0.5
})

hl.window_rule({
    name = "no-chrome-blur",
    match = { class = "^google-chrome$" },
    no_blur = true,
    opacity = "1.0 override 1.0 override"
})