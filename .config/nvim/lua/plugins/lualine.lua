return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        -- Re-run setup on every colorscheme change so the statusline picks
        -- up new matugen colors live.
        local function setup()
            require("lualine").setup({
                options = {
                    theme = require("matugen_theme").lualine_theme(),
                    component_separators = "|",
                    section_separators = "",
                },
            })
        end

        setup()
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("LualineMatugen", { clear = true }),
            callback = setup,
        })
    end,
}
