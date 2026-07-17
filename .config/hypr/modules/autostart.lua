-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function () 
  -- hl.exec_cmd("waybar")
  hl.exec_cmd("quickshell -p ~/dotfiles/quickshell/top-bar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

  -- Daemons
  hl.exec_cmd("openrazer-daemon -Fv")

end)
