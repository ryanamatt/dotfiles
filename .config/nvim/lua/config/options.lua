local opt = vim.opt

opt.number = true          -- Show line numbers
opt.relativenumber = true  -- Relative line numbers for easy jumping (e.g., 5k)
opt.tabstop = 4            -- 4 spaces per tab
opt.shiftwidth = 4
opt.expandtab = true       -- Convert tabs to spaces
opt.smartindent = true
opt.ignorecase = true      -- Ignore case on search...
opt.smartcase = true       -- ...unless capital letter is included
opt.termguicolors = true   -- True color support (essential for Hyprland/kitty/alacritty)
opt.signcolumn = "yes"     -- Prevents layout jump when LSP/git icons show up
opt.updatetime = 250       -- Faster UI updates
opt.clipboard = "unnamedplus"

