local config = require("persisted.config")
local finders = require("telescope.finders")

local M = {}

local no_icons = {
  selected = "",
  dir = "",
  branch = "",
}

---Shorten a path by replacing the longest matching configured prefix with its alias.
---Falls back to replacing the home directory with "~" when no alias matches.
---@param path string
---@param aliases table? list of { from = string, to = string } prefix substitutions
---@return string
local function default_shorten_path(path, aliases)
  local best_from, best_to
  for _, alias in ipairs(aliases or {}) do
    local from, to = alias.from or alias[1], alias.to or alias[2]
    if from and to and path:sub(1, #from) == from then
      if not best_from or #from > #best_from then
        best_from, best_to = from, to
      end
    end
  end

  if best_from then
    return best_to .. path:sub(#best_from + 1)
  end

  local home = vim.fn.expand("~")
  if path:sub(1, #home) == home then
    return "~" .. path:sub(#home + 1)
  end

  return path
end

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
        -- On Unix-like systems, prepend '/' to make it an absolute path if not already absolute
        if not dir_path:match("^/") then
            dir_path = "/" .. dir_path
        end
    end
    -- Shorten the path for display. Users can fully customize this by
    -- providing config.telescope.display(path) which receives the absolute
    -- directory path and returns the string to render. Otherwise, fall back
    -- to config.telescope.path_aliases (longest prefix match wins), and
    -- finally to replacing the home directory with "~".
    local display_path
    if type(config.telescope.display) == "function" then
      display_path = config.telescope.display(dir_path) or dir_path
    else
      display_path = default_shorten_path(dir_path, config.telescope.path_aliases)
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
