local keymap = vim.keymap

-- Quick save & quit
keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- Clear search highlights
keymap.set("n", "<leader>nh", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Window splitting
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split horizontally" })

-- Move between windows
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

local opts = { noremap = true, silent = true }
-- Normal Mode: Indent / Outdent a single line
keymap.set("n", "<Tab>", ">>", opts)
keymap.set("n", "<S-Tab>", "<<", opts)

-- Insert Mode
keymap.set("i", "<S-Tab>", "<C-d>", opts)

-- Visual Mode: Indent / Outdent a block and keep the selection highlighted
keymap.set("v", "<Tab>", ">gv", opts)
keymap.set("v", "<S-Tab>", "<gv", opts)
