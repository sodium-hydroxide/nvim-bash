--[[
 * @brief Manages shell script formatting using shfmt
 * @module nvim-bash.formatter
 *
 * This module configures shfmt for consistent shell script formatting.
 * shfmt supports POSIX shell, Bash, and mksh and can format scripts
 * according to various style guides including Google's style guide.
--]]
local M = {}

--[[
 * @brief Default configuration for shfmt
 * @local
 *
 * Style options:
 * - indent=4: Use 4 spaces for indentation
 * - binary-next-line: Binary operators like && and | go at the start of the line
 * - switch-case-indent: Switch cases are indented
 * - space-redirects: Put spaces after redirects
 * - keep-padding: Keep column alignment paddings
 * - func-next-line: Function opening braces go on next line
--]]
local default_formatter_config = {
    extra_args = {
        "-i", "4",        -- Use 4 spaces for indentation
        "-bn",           -- Binary ops like && and | go at the start of line
        "-ci",           -- Switch cases are indented
        "-sr",           -- Space after redirects
        "-kp",           -- Keep column alignment padding
        "-fn",           -- Function opening braces go on next line
    }
}

--[[
 * @brief Sets up format-on-save functionality
 * @param bufnr number Buffer to configure
 * @local
--]]
local function setup_format_on_save(bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
            vim.lsp.buf.format({
                timeout_ms = 2000,
                bufnr = bufnr,
            })
        end,
    })
end

--[[
 * @brief Configures shell script formatting
 * @param bufnr number Buffer to configure
 * @param opts table Configuration options from main setup
--]]
M.setup = function(bufnr, opts)
    local null_ls = require("null-ls")

    -- Extend default config with shell-specific options
    local config = vim.deepcopy(default_formatter_config)
    if opts.shell_binary == "bash" then
        table.insert(config.extra_args, "-ln", "bash")  -- Use bash syntax
    elseif opts.shell_binary == "zsh" then
        table.insert(config.extra_args, "-ln", "bash")  -- Fallback to bash syntax for zsh
    end

    -- Configure formatter through null-ls
    null_ls.setup({
        sources = {
            null_ls.builtins.formatting.shfmt.with({
                extra_args = config.extra_args,
                -- Add filetypes based on shell
                filetypes = {
                    "sh", "bash", "zsh",
                    -- Also format these files as shell scripts
                    "profile", "bashrc", "zshrc",
                    "bash_profile", "zprofile"
                }
            })
        },
        on_attach = function(client, bufnr)
            -- Setup format on save if enabled
            if opts.format_on_save then
                setup_format_on_save(bufnr)
            end

            -- Add command to manually format
            vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
                vim.lsp.buf.format({
                    timeout_ms = 2000,
                    bufnr = bufnr,
                })
            end, { desc = "Format current buffer with shfmt" })
        end
    })
end

return M
