return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "muniftanjim/nui.nvim",
    },
    config = function()
        require("neo-tree").setup({
            filesystem = {
                filtered_items = {
                    visible = false,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                }
            },
            window = {
                mappings = {
                ["<leader>ee"] = "close_window",
                },
            },
        })
        vim.keymap.set("n", "<leader>ee", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
    end,
}
