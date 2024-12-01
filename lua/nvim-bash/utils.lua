--[[
 * @brief Utility functions for nvim-bash
 * @module nvim-bash.utils
 *
 * This module provides utility functions for detecting dependencies,
 * package managers, and displaying installation help.
--]]
local M = {}

--[[
 * @brief Checks if a command exists in the system PATH
 * @param cmd string The command to check
 * @return boolean True if command exists, false otherwise
--]]
function M.command_exists(cmd)
    local handle = io.popen('command -v ' .. cmd .. ' 2>/dev/null')
    if handle then
        local result = handle:read('*a')
        handle:close()
        return result ~= ''
    end
    return false
end

--[[
 * @brief Detects the system's package manager
 * @return string|nil Name of the detected package manager or nil
--]]
function M.detect_package_manager()
    -- Check for common package managers
    local package_managers = {
        { name = "brew", cmd = "brew" },
        { name = "apt", cmd = "apt-get" },
        { name = "dnf", cmd = "dnf" },
        { name = "npm", cmd = "npm" }
    }

    for _, pm in ipairs(package_managers) do
        if M.command_exists(pm.cmd) then
            return pm.name
        end
    end

    return nil
end

--[[
 * @brief Shows installation instructions for missing dependencies
 * @param instructions table List of installation instructions
--]]
function M.show_installation_help(instructions)
    if #instructions == 0 then return end

    local pm = M.detect_package_manager()

    -- Create notification message
    local msg = {"Some required tools are missing. Please install:"}

    for _, tool in ipairs(instructions) do
        local install_cmd = tool.commands[pm] or tool.commands.npm
        if install_cmd then
            table.insert(msg, string.format("\n%s:\n  %s", tool.tool, install_cmd))
        end
    end

    -- Show message in floating window
    vim.notify(
        table.concat(msg, "\n"),
        vim.log.levels.WARN,
        {
            title = "nvim-bash",
            timeout = 10000
        }
    )
end

return M
