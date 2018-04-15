local windows = {}

local spaces_imported, spaces = pcall(require, "hs._asm.undocumented.spaces")

function windows.allAppWindows(app)
  local windowFilter = hs.window.filter.new{
    [app:name()] = { visible = true, currentSpace = false }
  }
  return windowFilter:getWindows()
end

function windows.moveAppWindowsToSpace()
  local currentApp = hs.application.frontmostApplication()
  local currentSpace = spaces.activeSpace()
  local appWindows = windows.allAppWindows(currentApp)

  for _i, window in ipairs(appWindows) do
    spaces.moveWindowToSpace(window:id(), currentSpace)
  end
end

return windows
