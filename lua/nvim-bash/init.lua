--[[
 * @brief Main configuration module for Bash/Shell script development in Neovim
 * @module nvim-bash
 *
 * This module provides a complete environment for shell script development,
 * integrating LSP, formatting, linting, and syntax highlighting capabilities.
 * It's designed to work with bash, sh, and zsh files.
--]]
local M = {}

--[[
 * @brief Default configuration options
 * @field shell_binary Path to the shell binary (defaults to user's shell)
 * @field format_on_save Whether to format shell scripts on save
 * @field lint_on_save Whether to run shellcheck on save
 * @field features Table of feature flags for enabling/disabling components
--]]
M.options = {
    -- Default to user's shell or fall back to bash
    shell_binary = vim.o.shell or "bash",
    format_on_save = true,
    lint_on_save = true,
    -- Feature flags for different components
    features = {
        lsp = true,           -- bash-language-server
        formatter = true,     -- shfmt
        linter = true,        -- shellcheck
        treesitter = true,    -- syntax highlighting
        completion = true     -- cmp integration
    }
}

--[[
 * @brief Detects installed shell development tools
 * @return table Table of detected tools and their paths
 * @local
--]]
local function detect_dependencies()
    local utils = require("nvim-bash.utils")
    return {
        bash = utils.command_exists("bash"),
        shellcheck = utils.command_exists("shellcheck"),
        shfmt = utils.command_exists("shfmt"),
        bash_language_server = utils.command_exists("bash-language-server")
    }
end

--[[
 * @brief Provides installation instructions for missing dependencies
 * @param deps table The detected dependencies
 * @return table Installation instructions for missing tools
 * @local
--]]
local function get_install_instructions(deps)
    local utils = require("nvim-bash.utils")
    local pm = utils.detect_package_manager()
    local instructions = {}

    if not deps.shellcheck then
        table.insert(instructions, {
            tool = "shellcheck",
            commands = {
                brew = "brew install shellcheck",
                apt = "sudo apt install shellcheck",
                dnf = "sudo dnf install ShellCheck"
            }
        })
    end

    if not deps.shfmt then
        table.insert(instructions, {
            tool = "shfmt",
            commands = {
                brew = "brew install shfmt",
                apt = "GO111MODULE=on go install mvdan.cc/sh/v3/cmd/shfmt@latest",
                dnf = "GO111MODULE=on go install mvdan.cc/sh/v3/cmd/shfmt@latest"
            }
        })
    end

    if not deps.bash_language_server then
        table.insert(instructions, {
            tool = "bash-language-server",
            commands = {
                npm = "npm install -g bash-language-server"
            }
        })
    end

    return instructions
end

--[[
 * @brief Main setup function for the bash module
 * @param opts table Optional configuration overrides
--]]
M.setup = function(opts)
    -- Merge user options with defaults
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})

    -- Check dependencies
    local deps = detect_dependencies()
    if not (deps.shellcheck and deps.shfmt and deps.bash_language_server) then
        local instructions = get_install_instructions(deps)
        -- Show installation instructions
        require("nvim-bash.utils").show_installation_help(instructions)
    end

    -- Set up file type detection
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "*.sh", "*.bash", "*.zsh", ".bashrc", ".zshrc", ".profile" },
        callback = function(args)
            -- Set filetype
            vim.bo[args.buf].filetype = "sh"

            -- Set up features for this buffer
            if M.options.features.lsp then
                require("nvim-bash.lsp").setup(args.buf, M.options)
            end

            if M.options.features.formatter then
                require("nvim-bash.formatter").setup(args.buf, M.options)
            end

            if M.options.features.completion then
                require("nvim-bash.cmp").setup(args.buf, M.options)
            end
        end
    })

    -- Set up treesitter if enabled
    if M.options.features.treesitter then
        require("nvim-bash.treesitter").setup(M.options)
    end
end

return M
