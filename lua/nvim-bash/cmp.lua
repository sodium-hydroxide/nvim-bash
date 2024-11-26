--[[
 * @brief Manages code completion for shell scripts using nvim-cmp
 * @module nvim-bash.cmp
 *
 * This module provides intelligent completion for:
 * - Shell commands and builtin functions
 * - Variables and parameters
 * - File paths
 * - Common shell script patterns through snippets
--]]
local M = {}

--[[
 * @brief Sets up shell-specific snippets
 * @local
 *
 * Provides snippets for common shell script patterns like:
 * - Script headers with proper shebang
 * - Function definitions with documentation
 * - Common control structures (if, case, loops)
 * - Error handling patterns
--]]
local function setup_snippets()
    local luasnip = require('luasnip')

    -- Load VSCode-style snippets for shell scripts
    require("luasnip.loaders.from_vscode").lazy_load({
        paths = { "./snippets/shell" },
        include = { "sh", "bash", "zsh" }
    })

    -- Add custom shell-specific snippets
    luasnip.add_snippets("sh", {
        -- Script header with shebang
        luasnip.snippet("header", {
            luasnip.text_node({"#!/usr/bin/env "}),
            luasnip.choice_node(1, {
                luasnip.text_node("bash"),
                luasnip.text_node("sh"),
                luasnip.text_node("zsh")
            }),
            luasnip.text_node({"", ""}),
            luasnip.text_node({"# Description: "}),
            luasnip.insert_node(2, "Script description"),
            luasnip.text_node({"", ""}),
            luasnip.text_node({
                "set -euo pipefail",
                "IFS=$'\\n\\t'",
                "",
                ""
            }),
            luasnip.insert_node(0)
        }),

        -- Function definition with documentation
        luasnip.snippet("func", {
            luasnip.text_node({"# "}),
            luasnip.insert_node(1, "Function description"),
            luasnip.text_node({"", "# Arguments:", "#   $1 - "}),
            luasnip.insert_node(2, "First argument"),
            luasnip.text_node({"", "# Returns:", "#   "}),
            luasnip.insert_node(3, "Return value description"),
            luasnip.text_node({"", "function "}),
            luasnip.insert_node(4, "function_name"),
            luasnip.text_node({" {", "    "}),
            luasnip.insert_node(0),
            luasnip.text_node({"", "}"}),
        }),

        -- Error handling pattern
        luasnip.snippet("error", {
            luasnip.text_node({
                "error() {",
                "    echo \"ERROR: $1\" >&2",
                "    exit 1",
                "}",
                "",
                ""
            }),
            luasnip.insert_node(0)
        }),

        -- Case statement
        luasnip.snippet("case", {
            luasnip.text_node("case "),
            luasnip.insert_node(1, "$variable"),
            luasnip.text_node({" in", "    "}),
            luasnip.insert_node(2, "pattern"),
            luasnip.text_node(")", luasnip.insert_node(3), " ;;"),
            luasnip.text_node({"", "    *) "}),
            luasnip.insert_node(4, "# Default case"),
            luasnip.text_node({" ;;", "esac"}),
        }),
    })
end

--[[
 * @brief Formats completion items for better display
 * @param entry The completion entry
 * @param item The vim completion item
 * @return The formatted completion item
 * @local
--]]
local function format_completion_item(entry, item)
    -- Add source indicators
    item.menu = ({
        nvim_lsp = "[LSP]",
        luasnip = "[Snippet]",
        buffer = "[Buffer]",
        path = "[Path]",
        cmdline = "[Shell]"
    })[entry.source.name]

    -- Add special formatting for shell commands and builtins
    if entry.source.name == "nvim_lsp" then
        if item.kind == "Function" then
            -- Add special formatting for shell functions
            item.kind = "🔧 " .. item.kind
        elseif item.kind == "Keyword" then
            -- Add special formatting for shell keywords
            item.kind = "🔑 " .. item.kind
        end
    end

    return item
end

--[[
 * @brief Default completion configuration
 * @local
--]]
local default_cmp_config = {
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },

    mapping = {
        ['<C-p>'] = function(fallback)
            local cmp = require('cmp')
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end,
        ['<C-n>'] = function(fallback)
            local cmp = require('cmp')
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ['<C-d>'] = require('cmp').mapping.scroll_docs(-4),
        ['<C-f>'] = require('cmp').mapping.scroll_docs(4),
        ['<C-Space>'] = require('cmp').mapping.complete(),
        ['<C-e>'] = require('cmp').mapping.close(),
        ['<CR>'] = require('cmp').mapping.confirm({
            behavior = require('cmp').ConfirmBehavior.Replace,
            select = true,
        }),
    },

    -- Configure completion sources and their priorities
    sources = {
        {
            name = 'nvim_lsp',
            priority = 1000,
            entry_filter = function(entry, ctx)
                -- Keep all LSP completions for shell scripts
                return true
            end
        },
        { name = 'luasnip',  priority = 750 },
        { name = 'path',     priority = 500 },
        { name = 'buffer',   priority = 250 },
    },

    -- Configure how completions are sorted
    sorting = {
        comparators = {
            require('cmp').config.compare.score,
            require('cmp').config.compare.recently_used,
            require('cmp').config.compare.locality,
        },
    },

    -- Format completion items
    formatting = {
        format = format_completion_item,
    },

    experimental = {
        ghost_text = true,
    },
}

--[[
 * @brief Sets up completion for shell scripts
 * @param bufnr number Buffer to configure
 * @param opts table Configuration options from main setup
--]]
M.setup = function(bufnr, opts)
    -- First, set up our custom snippets
    setup_snippets()

    -- Configure buffer-specific completion
    require('cmp').setup.buffer({
        sources = {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'path' },
            { name = 'buffer' },
            -- Add shell-specific sources
            {
                name = 'cmdline',
                option = {
                    ignore_cmds = { 'Man', '!' }
                }
            }
        }
    })
end

return M
