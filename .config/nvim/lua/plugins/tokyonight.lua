return {
    "folke/tokyonight.nvim",
    lazy = false,    -- Load immediately at startup
    priority = 1000, -- High priority so colors load before other UI
    config = function()
        vim.cmd([[colorscheme tokyonight-night]])
    end,
}
