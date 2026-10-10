return {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        -- Colors pulled from the tokyonight-night palette
        local colors = {
            blue = "#7aa2f7",
            cyan = "#7dcfff",
            purple = "#bb9af7",
            green = "#9ece6a",
            orange = "#ff9e64",
            red = "#f7768e",
            comment = "#565f89",
            fg = "#c0caf5",
        }

        local function set_highlights()
            local hl = vim.api.nvim_set_hl
            hl(0, "DashboardHeader", { fg = colors.blue, bold = true })
            hl(0, "DashboardIcon", { fg = colors.cyan })
            hl(0, "DashboardDesc", { fg = colors.fg })
            hl(0, "DashboardKey", { fg = colors.orange, bold = true })
            hl(0, "DashboardShortCut", { fg = colors.orange, bold = true })
            hl(0, "DashboardProjectTitle", { fg = colors.purple, bold = true })
            hl(0, "DashboardProjectTitleIcon", { fg = colors.purple })
            hl(0, "DashboardProjectIcon", { fg = colors.cyan })
            hl(0, "DashboardMruTitle", { fg = colors.green, bold = true })
            hl(0, "DashboardMruIcon", { fg = colors.green })
            hl(0, "DashboardFiles", { fg = colors.fg })
            hl(0, "DashboardFooter", { fg = colors.comment, italic = true })
        end

        set_highlights()
        -- Re-apply if the colorscheme is reloaded
        vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

        local header = {
            "",
            "",
            "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
            "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
            "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
            "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
            "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
            "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
            "",
            "      ⚡  Edit fast. Think faster.  ⚡",
            "",
        }

        require("dashboard").setup({
            theme = "hyper",
            disable_move = true,
            shortcut_type = "letter",
            change_to_vcs_root = true,
            config = {
                header = header,
                week_header = { enable = false },
                shortcut = {
                    {
                        icon = "󰈞 ",
                        icon_hl = "DashboardIcon",
                        desc = "Find File",
                        group = "DashboardDesc",
                        key = "f",
                        key_hl = "DashboardKey",
                        action = "Telescope find_files",
                    },
                    {
                        icon = "󰱼 ",
                        icon_hl = "DashboardIcon",
                        desc = "Live Grep",
                        group = "DashboardDesc",
                        key = "g",
                        key_hl = "DashboardKey",
                        action = "Telescope live_grep",
                    },
                    {
                        icon = "󰋚 ",
                        icon_hl = "DashboardIcon",
                        desc = "Recent",
                        group = "DashboardDesc",
                        key = "r",
                        key_hl = "DashboardKey",
                        action = "Telescope oldfiles",
                    },
                    {
                        icon = "󰈔 ",
                        icon_hl = "DashboardIcon",
                        desc = "New File",
                        group = "DashboardDesc",
                        key = "n",
                        key_hl = "DashboardKey",
                        action = "enew",
                    },
                    {
                        icon = " ",
                        icon_hl = "DashboardIcon",
                        desc = "Config",
                        group = "DashboardDesc",
                        key = "c",
                        key_hl = "DashboardKey",
                        action = function()
                            require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
                        end,
                    },
                    {
                        icon = "󰒲 ",
                        icon_hl = "DashboardIcon",
                        desc = "Lazy",
                        group = "DashboardDesc",
                        key = "l",
                        key_hl = "DashboardKey",
                        action = "Lazy",
                    },
                    {
                        icon = "󰏖 ",
                        icon_hl = "DashboardIcon",
                        desc = "Mason",
                        group = "DashboardDesc",
                        key = "m",
                        key_hl = "DashboardKey",
                        action = "Mason",
                    },
                    {
                        icon = "󰗼 ",
                        icon_hl = "DashboardIcon",
                        desc = "Quit",
                        group = "DashboardDesc",
                        key = "q",
                        key_hl = "DashboardKey",
                        action = "qa",
                    },
                },
                packages = { enable = true },
                project = {
                    enable = true,
                    limit = 5,
                    icon = "󰉋 ",
                    label = " Recent Projects",
                    action = "Telescope find_files cwd=",
                },
                mru = {
                    enable = true,
                    limit = 8,
                    icon = "󰈙 ",
                    label = " Recent Files",
                    cwd_only = false,
                },
                footer = function()
                    local ok, lazy = pcall(require, "lazy")
                    local plugins = ok and lazy.stats().count or 0
                    return {
                        "",
                        "󱐋 " .. plugins .. " plugins loaded  |  " .. " v" .. vim.version().major .. "."
                            .. vim.version().minor .. "." .. vim.version().patch,
                    }
                end,
            },
            hide = {
                statusline = true,
                tabline = true,
                winbar = true,
            },
        })
    end,
}
