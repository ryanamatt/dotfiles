return {
  {
    "saghen/blink.cmp",
    -- Use a release tag to download pre-built binaries (avoids needing a Rust toolchain)
    version = "1.*",
    dependencies = {
        "rafamadriz/friendly-snippets",
    },
    opts = {
        keymap = { preset = "default" }, -- Options: "default", "super-star", "enter"
        appearance = {
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
    },
    opts_extend = { "sources.default" },
    },
}
