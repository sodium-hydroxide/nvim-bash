--[[
 * @brief Manages syntax highlighting and code navigation for shell scripts
 * @module nvim-bash.treesitter
 *
 * This module configures Treesitter for shell script syntax highlighting
 * and structural text objects.
--]]
local M = {}

--[[
 * @brief Default Treesitter configuration for shell scripts
 * @local
--]]
local default_ts_config = {
    ensure_installed = { "bash" },

    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,

        -- Custom captures for shell-specific syntax
        custom_captures = {
            ["function.builtin"] = "Special",
            ["variable"] = "Identifier",
            ["string.special"] = "SpecialChar",
            ["punctuation.special"] = "Special",
        },
    },

    indent = {
        enable = true,
    },

    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
        },
    },

    textobjects = {
        select = {
            enable = true,
            lookahead = true,

            keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@conditional.outer",
                ["ic"] = "@conditional.inner",
                ["al"] = "@loop.outer",
                ["il"] = "@loop.inner",
            },
        },

        move = {
            enable = true,
            set_jumps = true,

            goto_next_start = {
                ["]f"] = "@function.outer",
                ["]c"] = "@conditional.outer",
                ["]l"] = "@loop.outer",
            },
            goto_previous_start = {
                ["[f"] = "@function.outer",
                ["[c"] = "@conditional.outer",
                ["[l"] = "@loop.outer",
            },
        },

        swap = {
            enable = true,
            swap_next = {
                ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
                ["<leader>A"] = "@parameter.inner",
            },
        },
    },
}

--[[
 * @brief Additional queries for shell script syntax
 * @local
--]]
local additional_queries = {
    -- Highlight heredoc content differently
    highlights = [[
        (heredoc_start) @string.special
        (heredoc_body) @string
        (heredoc_end) @string.special

        (expansion
            "${" @punctuation.special
            "}" @punctuation.special) @none

        (arithmetic_expansion
            "$((" @punctuation.special
            "))" @punctuation.special) @none
    ]],

    -- Fixed textobjects query syntax
    textobjects = [[
        (function_definition) @function.outer
        (function_definition
            body: (_) @function.inner)

        (if_statement) @conditional.outer
        (if_statement
            (_) @conditional.inner)

        (case_statement) @conditional.outer
        (case_statement
            (_) @conditional.inner)

        (while_statement) @loop.outer
        (while_statement
            (_) @loop.inner)

        (for_statement) @loop.outer
        (for_statement
            (_) @loop.inner)
    ]]
}

--[[
 * @brief Sets up Treesitter for shell scripts
 * @param opts table Configuration options from main setup
--]]
M.setup = function(opts)
    -- Load the Treesitter configurations module
    require("nvim-treesitter.configs").setup(default_ts_config)

    -- Add our custom queries if supported
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    if parser_config.bash then
        vim.treesitter.query.set("bash", "highlights", additional_queries.highlights)
        vim.treesitter.query.set("bash", "textobjects", additional_queries.textobjects)
    end

    -- Set up folding based on syntax
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
    vim.opt_local.foldenable = false

    -- Set up additional highlights for shell constructs
    vim.cmd([[
        highlight link bashTSFunctionBuiltin Special
        highlight link bashTSVariableBuiltin Identifier
        highlight link bashTSKeywordOperator Operator
    ]])
end

return M
