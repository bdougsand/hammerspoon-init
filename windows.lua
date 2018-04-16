local windows = {}

local spaces_imported, spaces = pcall(require, "hs._asm.undocumented.spaces")

function windows.allAppWindows(app)
  local windowFilter = hs.window.filter.new{
    [app:name()] = { visible = true, currentSpace = false }
  }
  return windowFilter:getWindows()
end

function windows.moveAppWindowsToSpace(limit)
  local currentApp = hs.application.frontmostApplication()
  local currentSpace = spaces.activeSpace()
  local appWindows = windows.allAppWindows(currentApp)

  for i, window in ipairs(appWindows) do
    spaces.moveWindowToSpace(window:id(), currentSpace)

    if limit and i == limit then
      break
    end
  end
end

function windows.moveForemostAppWindowToSpace()
  windows.moveAppWindowsToSpace(1)
end

return windows
