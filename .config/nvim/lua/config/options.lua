local opt = vim.opt

opt.title = true
opt.titlestring = "nvim: %{getcwd()}"

-- Appearance and basics
opt.number = true           -- Show line numbers
opt.relativenumber = true   -- Relative line numbers for easy jumping (e.g., 5k)
opt.tabstop = 4             -- 4 spaces per tab
opt.shiftwidth = 4
opt.expandtab = true        -- Convert tabs to spaces
opt.smartindent = true
opt.ignorecase = true       -- Ignore case on search...
opt.smartcase = true        -- ...unless capital letter is included
opt.termguicolors = true    -- True color support
opt.signcolumn = "yes"      -- Prevents layout jump when LSP/git icons show up
opt.updatetime = 250        -- Faster UI updates
opt.clipboard = "unnamedplus"

opt.scrolloff = 8           -- Keep context above and below cursor
opt.sidescrolloff = 8
opt.splitright = true       -- New vertical splits open to the right
opt.splitbelow = true       -- New horizontal splits open below
opt.confirm = true
opt.timeoutlen = 300        -- Snappier which-key
opt.inccommand = "split"    -- Live preview of :s 
opt.jumpoptions = "stack"   -- Tidier jumplist behavior

-- Show stray whitespace
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Folding via treesitter
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99

-- Spelling: keep a personal dictionary in the config
local spell_dir = vim.fn.stdpath("config") .. "/spell"
vim.fn.mkdir(spell_dir, "p")
opt.spellfile = spell_dir .. "/en.utf-8.add"
opt.spellsuggest = "best,9"   -- Short suggestion lists
opt.spelloptions = "camel"    -- Treat camelCase words as separate words

opt.suffixesadd:append(".md")

-- Prose settings for writing filetypes only, so code stays untouched
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true       -- Wrap at word boundaries
		vim.opt_local.breakindent = true     -- Indent wrapped lines
		vim.opt_local.showbreak = "↪ "
		vim.opt_local.textwidth = 0          -- No hard line breaks while typing
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })  -- No comment continuation
		vim.opt_local.display = "lastline"   -- Show as much of a long paragraph as fits
		vim.opt_local.smoothscroll = true
	end,
})

-- Hide markdown syntax like **bold** on lines that are not editing
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.conceallevel = 2
	end,
})
