local config = require("persisted.config")
local finders = require("telescope.finders")

local M = {}

local no_icons = {
  selected = "",
  dir = "",
  branch = "",
}

---Create a finder for persisted sessions
---@param sessions table
function M.session_finder(sessions)
  local icons = vim.tbl_extend("force", no_icons, config.telescope.icons or {})

  local custom_displayer = function(session)
    local final_str = ""
    local hls = {}

    local function append(str, hl)
      local hl_start = #final_str
      final_str = final_str .. str
      if hl then
        table.insert(hls, { { hl_start, #final_str }, hl })
      end
    end

    -- is current session
    append(session.file_path == vim.v.this_session and (icons.selected .. " ") or "   ", "PersistedTelescopeSelected")

    -- session path
    -- Convert to proper path and format with ~
    local dir_path = session.dir_path:gsub("%%", "/")
    if jit and jit.os and jit.os:find("Windows") then
        dir_path = dir_path:gsub("^(%w)/", "%1:/")
    else
        -- On Unix-like systems, prepend '/' to make it an absolute path
        dir_path = "/" .. dir_path
    end
    -- Replace home directory with ~
    local home = vim.fn.expand("~")
    local display_path = dir_path
    if display_path:sub(1, #home) == home then
        display_path = "~" .. display_path:sub(#home + 1)
    end
    append(icons.dir, "PersistedTelescopeDir")
    append(display_path)

    -- branch
    if session.branch then
      append(" " .. icons.branch .. session.branch, "PersistedTelescopeBranch")
    end

    return final_str, hls
  end

  return finders.new_table({
    results = sessions,
    entry_maker = function(session)
      session.ordinal = session.name
      session.display = custom_displayer
      session.name = session.name
      session.branch = session.branch
      session.file_path = session.file_path

      return session
    end,
  })
end

return M
