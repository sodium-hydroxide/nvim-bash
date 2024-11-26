# Complete Bash Environment for Vim



## Installation Via Lazy

```lua
{
    "sodium-hydroxide/nvim-bash",
    dependencies = {
        -- LSP and Completion
        "neovim/nvim-lspconfig",
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-buffer",

        -- Formatting and Linting
        "nvim-lua/plenary.nvim",
        "jose-elias-alvarez/null-ls.nvim",

        -- Snippets
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",

        -- Treesitter for syntax highlighting
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("nvim-bash").setup({
            -- Optional: override default options
            shell_binary = vim.o.shell,  -- Use your default shell
            format_on_save = true,       -- Format shell scripts when saving
            lint_on_save = true,         -- Run shellcheck on save
            features = {
                lsp = true,              -- Enable bash-language-server
                formatter = true,        -- Enable shfmt
                linter = true,           -- Enable shellcheck
                treesitter = true,       -- Enable syntax highlighting
                completion = true        -- Enable completions
            }
        })
    end,
    -- These filetypes will trigger the loading of the plugin
    ft = { "sh", "bash", "zsh", "shell" },
}
```
