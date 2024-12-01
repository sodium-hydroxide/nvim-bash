-- treesitter.lua for nvim-bash
--[[
 * @brief Manages syntax highlighting and code navigation for shell scripts
 * @module nvim-bash.treesitter
 *
 * This module configures Treesitter for shell script syntax highlighting
 * and structural text objects. It provides intelligent navigation through
 * shell script constructs and enhanced syntax highlighting that understands
 * shell script structure.
--]]
local M = {}

--[[
 * @brief Default Treesitter configuration for shell scripts
 * @local
 *
 * This configuration enhances shell script editing with:
 * - Syntax highlighting that understands shell script structure
 * - Text objects for functions and blocks
 * - Navigation commands for moving between shell constructs
 * - Smart indentation based on shell script syntax
--]]
local default_ts_config = {
    ensure_installed = { "bash" },

    highlight = {
        enable = true,
        -- Disable vim regex highlighting in favor of treesitter
        additional_vim_regex_highlighting = false,

        -- Custom captures for shell-specific syntax
        custom_captures = {
            -- Highlight shell builtins specially
            ["function.builtin"] = "Special",
            -- Make variable expansions stand out
            ["variable"] = "Identifier",
            -- Highlight heredoc delimiters
            ["string.special"] = "SpecialChar",
            -- Special handling for command substitution
            ["punctuation.special"] = "Special",
        },
    },

    -- Smart indentation based on syntax tree
    indent = {
        enable = true,
    },

    -- Incremental selection based on syntax nodes
    incremental_selection = {
        enable = true,
        keymaps = {
            -- Start selecting the current node
            init_selection = "gnn",
            -- Increment to the bigger outer node
            node_incremental = "grn",
            -- Increment to the entire scope (e.g., entire function)
            scope_incremental = "grc",
            -- Decrement to the smaller node
            node_decremental = "grm",
        },
    },

    -- Text objects for smart selection
    textobjects = {
        -- Selection based on syntax nodes
        select = {
            enable = true,
            -- Look ahead for targets
            lookahead = true,

            keymaps = {
                -- Shell-specific text objects
                ["af"] = "@function.outer",        -- Select entire function
                ["if"] = "@function.inner",        -- Select function body
                ["ac"] = "@conditional.outer",     -- Select entire if/case statement
                ["ic"] = "@conditional.inner",     -- Select conditional body
                ["al"] = "@loop.outer",           -- Select entire loop
                ["il"] = "@loop.inner",           -- Select loop body
            },
        },

        -- Movement between syntax nodes
        move = {
            enable = true,
            -- Create jumplist entries for movements
            set_jumps = true,

            goto_next_start = {
                ["]f"] = "@function.outer",       -- Go to next function
                ["]c"] = "@conditional.outer",    -- Go to next conditional
                ["]l"] = "@loop.outer",          -- Go to next loop
            },
            goto_previous_start = {
                ["[f"] = "@function.outer",       -- Go to previous function
                ["[c"] = "@conditional.outer",    -- Go to previous conditional
                ["[l"] = "@loop.outer",          -- Go to previous loop
            },
        },

        -- Smart swapping of nodes
        swap = {
            enable = true,
            swap_next = {
                ["<leader>a"] = "@parameter.inner", -- Swap with next parameter
            },
            swap_previous = {
                ["<leader>A"] = "@parameter.inner", -- Swap with previous parameter
            },
        },
    },
}

--[[
 * @brief Additional queries for shell script syntax
 * @local
 *
 * These queries enhance Treesitter's understanding of shell script structure
 * by defining additional syntax patterns specific to shell scripting.
--]]
local additional_queries = {
    -- Highlight heredoc content differently
    highlights = [[
        (heredoc_start) @string.special
        (heredoc_body) @string
        (heredoc_end) @string.special

        ; Special highlighting for variable expansions
        (expansion
            "${" @punctuation.special
            "}" @punctuation.special) @none

        ; Highlight arithmetic expansions
        (arithmetic_expansion
            "$((" @punctuation.special
            "))" @punctuation.special) @none
    ]],

    -- Identify shell script text objects
    textobjects = [[
        ; Function definitions
        (function_definition) @function.outer
        (function_definition body: (_) @function.inner)

        ; Conditional statements
        (if_statement) @conditional.outer
        (if_statement
            (_) @conditional.inner)

        (case_statement) @conditional.outer
        (case_statement
            (_) @conditional.inner)

        ; Loops
        (while_statement) @loop.outer
        (while_statement body: (_) @loop.inner)
        (for_statement) @loop.outer
        (for_statement body: (_) @loop.inner)
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
        -- Add custom queries for better shell script support
        vim.treesitter.query.set("bash", "highlights", additional_queries.highlights)
        vim.treesitter.query.set("bash", "textobjects", additional_queries.textobjects)
    end

    -- Set up folding based on syntax
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"

    -- Start with all folds open
    vim.opt_local.foldenable = false

    -- Set up additional highlights for shell constructs
    vim.cmd([[
        highlight link bashTSFunctionBuiltin Special
        highlight link bashTSVariableBuiltin Identifier
        highlight link bashTSKeywordOperator Operator
    ]])
end

return M
