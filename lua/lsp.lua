--[[
 * @brief Manages LSP configuration for shell scripts
 * @module nvim-bash.lsp
 *
 * This module configures the bash-language-server and integrates shellcheck
 * diagnostics. It provides features like command completion, parameter hints,
 * and basic error detection.
--]]
local M = {}

--[[
 * @brief Default LSP configuration for bash-language-server
 * @local
--]]
local default_config = {
    settings = {
        bashIde = {
            -- Glob pattern for identifying shell scripts
            globPattern = "**/*@(.sh|.inc|.bash|.command)",
            -- Shell dialect to use for parsing
            shellcheckPath = "shellcheck",
            -- Enable explainshell integration if available
            enableExplainshell = true,
        }
    }
}

--[[
 * @brief Sets up LSP keybindings for shell script buffers
 * @param bufnr number Buffer number to attach keybindings to
 * @local
--]]
local function setup_keymaps(bufnr)
    local opts = { noremap=true, silent=true, buffer=bufnr }

    -- Navigation
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

    -- Code actions
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)

    -- Diagnostics
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, opts)
end

--[[
 * @brief Sets up shellcheck diagnostics integration
 * @param bufnr number Buffer number to configure
 * @local
--]]
local function setup_shellcheck(bufnr)
    local null_ls = require("null-ls")

    null_ls.setup({
        sources = {
            null_ls.builtins.diagnostics.shellcheck.with({
                diagnostics_format = '[shellcheck] #{m} [#{c}]',
                -- Enable all optional checks
                extra_args = {"--external-sources", "--enable=all"},
                -- Handle source env files
                filetypes = {"sh", "bash", "zsh"},
            })
        }
    })
end

--[[
 * @brief Sets up LSP for shell scripts
 * @param bufnr number Buffer number to configure
 * @param opts table Configuration options
--]]
M.setup = function(bufnr, opts)
    local lspconfig = require('lspconfig')

    -- Merge default config with any user overrides
    local config = vim.tbl_deep_extend("force", default_config, {
        on_attach = function(client, bufnr)
            setup_keymaps(bufnr)

            -- Configure document formatting if enabled
            client.server_capabilities.documentFormattingProvider = opts.format_on_save

            -- Set up shellcheck if linting is enabled
            if opts.features.linter then
                setup_shellcheck(bufnr)
            end
        end,

        -- Add shell-specific capabilities
        capabilities = vim.tbl_deep_extend(
            "force",
            require('cmp_nvim_lsp').default_capabilities(),
            {
                textDocument = {
                    completion = {
                        completionItem = {
                            -- Enable snippet completion
                            snippetSupport = true,
                            -- Support command documentation
                            documentationFormat = { "markdown", "plaintext" },
                            -- Parameter hints
                            parameterInformation = true,
                        }
                    }
                }
            }
        ),

        -- Configure shell dialect
        settings = {
            bashIde = {
                shellcheckPath = vim.fn.exepath("shellcheck"),
                -- Use the specified shell for parsing
                shellDialect = opts.shell_binary == "zsh" and "zsh" or "bash",
            }
        }
    })

    -- Initialize the language server
    lspconfig.bashls.setup(config)
end

return M
