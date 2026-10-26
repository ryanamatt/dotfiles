-- Set leader key before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.vim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"http://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Load Config Modules
require("config.options")
require("config.keymaps")

-- Set up Spell Check on Text Files
local spell_types = { "text", "markdown", "gitcommit" }

vim.api.nvim_create_autocmd("FileType", {
	pattern = spell_types,
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
	end,
})

-- Cheat Sheet Command Open up
vim.api.nvim_create_user_command('Cheat', function()
    vim.cmd.vsplit(vim.fn.expand('~/dotfiles/docs/nvim.md'))
end, {})

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	install = { colorscheme = { "matugen" } },
})

-- Colorscheme generated from matugen
vim.cmd.colorscheme("matugen")
