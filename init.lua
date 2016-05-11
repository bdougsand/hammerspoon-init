spaces_imported, spaces = pcall(require, "hs._asm.undocumented.spaces") 
local lastRun = 0

function windowMove(wScale, hScale, xScale, yScale)
  local now = hs.timer.secondsSinceEpoch()
  local window = hs.window.focusedWindow()

  if window:isFullScreen() then
    return
  end

  local f = window:frame()
  local screenFrame = window:screen():frame()

  local newX = screenFrame.w*xScale
  local newY = screenFrame.h*yScale
  local newW = screenFrame.w*wScale
  local newH = screenFrame.h*hScale
  local dt = now - lastRun
  lastRun = now

  if dt >= 0.5 then
    f.x = newX
    f.y = newY
    f.w = newW
    f.h = newH
    window:setFrame(f)
  else
    local screenId = window:screen():id()
    local windows = hs.window.orderedWindows()
    -- local i = 2
    -- window = windows[i]
    -- while window and window:screen():id() ~= screenId do
    --   i = i + 1
    --   window = windows[i]
    -- end
    window = windows[2]

    if window then
      if wScale < 1 then
        newW = (1 - wScale)*screenFrame.w
        if xScale == 0 then
          newX = wScale*screenFrame.w
        else
          newX = 0
        end
      elseif yScale < 1 then
        newH = (1 - hScale)*screenFrame.h
        if yScale == 0 then
          newY = hScale*screenFrame.h
        else
          newY = 0
        end
      else
        return
      end

      f = window:frame()
      f.x = newX
      f.y = newY
      f.w = newW
      f.h = newH
      window:setFrame(f)
    end
  end
end

function windowLeft()
  windowMove(0.5, 1, 0, 0)
end

function windowRight()
  windowMove(0.5, 1, 0.5, 0)
end

function windowTop()
  windowMove(1, 0.5, 0, 0)
end

function windowBottom()
  windowMove(1, 0.5, 0, 0.5)
end

function windowFull()
  windowMove(1, 1, 0, 0)
end

hs.hotkey.bind({"cmd", "alt"}, "Left", windowLeft)
hs.hotkey.bind({"cmd", "alt"}, "Right", windowRight)
hs.hotkey.bind({"cmd", "alt"}, "Up", windowTop)
hs.hotkey.bind({"cmd", "alt"}, "Down", windowBottom)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "Space", windowFull)


function findIndex(items, fn)
  for i, v in ipairs(items) do
    if fn(v) then
      return true, i
    end
  end

  return false
end

function indexOf(items, item)
  return findIndex(items, function(x) return x == item end)
end

function hello_world(x) print(x) end
if spaces_imported then
  function moveWindowBy(relative)
    local uuid = spaces.mainScreenUUID()
    local ids = spaces.spacesByScreenUUID()[uuid]
    local spaceId = spaces.activeSpace()
    local found, index = indexOf(ids, spaceId)

    if found then
      local newSpaceId = ids[index + relative]
      if newSpaceId then
        local w = hs.window.frontmostWindow()
        local title = w:title()

        if #title > 23 then
          title = title:sub(0, 10) .. "..." .. title:sub(#title-9)
        end
        spaces.moveWindowToSpace(w:id(), newSpaceId)
        hs.alert("Moved '" .. title .. "' to Space #" .. newSpaceId, 2)
      else
        hs.alert("There's no space in that direction!", 2)
      end
    end
  end

  function moveWindowRight()
    moveWindowBy(-1)
  end

  function moveWindowLeft()
    moveWindowBy(1)
  end

  hs.hotkey.bind({"cmd", "ctrl"}, "Right", moveWindowRight)
  hs.hotkey.bind({"cmd", "ctrl"}, "Left", moveWindowLeft)
end
