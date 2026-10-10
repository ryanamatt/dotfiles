return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
        local autopairs = require("nvim-autopairs")
        
        autopairs.setup({
        check_ts = true, -- Enable treesitter integration if desired
        ts_config = {
            lua = { "string" }, -- Don't add pairs in lua string treesitter nodes
            javascript = { "template_string" },
        },
        fast_wrap = {
            map = "<M-e>", -- Alt+e to fast wrap pairs
            chars = { "{", "[", "(", '"', "'" },
            pattern = string.gsub([[ [%$%(*+?%^%-%{%|%=] ]], "%s+", ""),
            offset = 0,
            end_key = "$",
            keys = "qwertyuiopzxcvbnmasdfghjkl",
            check_comma = true,
            highlight = "Search",
            highlight_grey = "Comment",
        },
        })

        -- Integrate with nvim-cmp (auto-insert parentheses after selecting a function/method)
        local cmp_status_ok, cmp = pcall(require, "cmp")
        if cmp_status_ok then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end
    end,
}