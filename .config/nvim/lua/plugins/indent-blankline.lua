
return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        ---@type ibl.config
        opts = {
            indent = {
                char = "│", -- Sets the character for indentation guides
            },
        scope = {
            enabled = true, -- Highlights the current scope
            show_start = false,
            show_end = false,
        },
        exclude = {
            filetypes = {
            "help",
            "dashboard",
            "neo-tree",
            "lazy",
            "mason",
            "toggleterm",
        },
      },
    },
  },
}
