return {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gblame" },
    keys = {
        { "<leader>gs", "<cmd>Git<cr>", desc = "Git Status" },
        { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git Blame" },
        { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git Diff Split" },
        { "<leader>gp", "<cmd>Git push<cr>", desc = "Git Push" },
        { "<leader>gl", "<cmd>Git pull<cr>", desc = "Git Pull" },
    },
}