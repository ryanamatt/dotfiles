return {
    "lewis6991/gitsigns.nvim",
    opts = {
        on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation between changes (hunks)
        map("n", "]c", function()
            if vim.wo.diff then return "]c" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
        end, { expr = true, desc = "Next git hunk" })

        map("n", "[c", function()
            if vim.wo.diff then return "[c" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
        end, { expr = true, desc = "Previous git hunk" })

        -- Keymaps
        map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview git hunk" })
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Git blame line" })
        end,
    },
}

