return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "bash", "hyprlang" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
    },
}