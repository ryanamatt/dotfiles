-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function () 
  hl.exec_cmd("wisp run")
  hl.exec_cmd("swaync")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("systemctl --user start hyprpolkitagent.service")

  -- Daemons
  hl.exec_cmd("openrazer-daemon -Fv")

  -- Special Apps on Workspaces
  hl.exec_cmd("spotify-launcher")
  hl.exec_cmd("discord")
end)
