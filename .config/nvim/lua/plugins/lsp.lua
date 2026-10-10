return {
    {
        "williamboman/mason.nvim",
        config = function()
        require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
        require("mason-lspconfig").setup({
            ensure_installed = {
            "lua_ls",
            "clangd",
            "pyright",
            "ts_ls",
            "qmlls",
            "bashls",
            "awk_ls",
            },
        })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
        local capabilities = require('blink.cmp').get_lsp_capabilities()

        -- List of all language servers to configure and enable
        local servers = {
            "lua_ls",
            "clangd",
            "pyright",
            "ts_ls",
            "qmlls",
            "bashls",
            "awk_ls",
        }

        for _, server in ipairs(servers) do
            vim.lsp.config(server, {
            capabilities = capabilities,
            })
            vim.lsp.enable(server)
        end

        -- Global LSP Keybindings (triggered when an LSP attaches to a buffer)
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(ev)
            local opts = { buffer = ev.buf }
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts, { desc = "Go to declaration" })
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts, { desc = "Go to definition" })
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts, { desc = "Hover documentation" })
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts, { desc = "Code actions" })
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts, { desc = "Smart rename" })
            end,
        })
        end,
    },
}