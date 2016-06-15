spaces_imported, spaces = pcall(require, "hs._asm.undocumented.spaces") 
local lastRun = 0

-- TODO: Modal window arrangement

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
      window:setFrameInScreenBounds(f)
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

function windowTopLeft()
  windowMove(0.5, 0.5, 0, 0)
end

function windowTopRight()
  windowMove(0.5, 0.5, 0.5, 0)
end

function windowBottomRight()
  windowMove(0.5, 0.5, 0.5, 0.5)
end

function windowBottomLeft()
  windowMove(0.5, 0.5, 0, 0.5)
end

function fillSpace()
  local nextWindow = hs.window.orderedWindows()[2]
  local nextFrame = nextWindow:frame()
  local screenFrame = nextWindow:screen()
  local isLeft = nextFrame.x < screenFrame.w/2

  local window = hs.window.focusedWindow()
  local frame = window:frame()
  frame.w = isLeft and (screenFrame.w - nextFrame.x) or nextFrame.x
  frame.x = isLeft and nextFrame.x + nextFrame.w or 0
  window:setFrame(frame)
end

hs.hotkey.bind({"cmd", "alt"}, "Left", windowLeft)
hs.hotkey.bind({"cmd", "alt"}, "Right", windowRight)
hs.hotkey.bind({"cmd", "alt"}, "Up", windowTop)
hs.hotkey.bind({"cmd", "alt"}, "Down", windowBottom)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, ".", fillSpace)

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

if spaces_imported then
  function moveWindow(dir)
    local w = hs.window.frontmostWindow()
    local title = w:title()

    if #title > 23 then
      title = title:sub(0, 10) .. "..." .. title:sub(#title-9)
    end
    local fn = w["moveOneScreen" .. dir]
    fn(w)

    hs.alert("Moved '" .. title .. "' " .. dir, 2)
  end

  function moveWindowRight()
    moveWindow("East")
  end

  function moveWindowLeft()
    moveWindow("West")
  end

  hs.hotkey.bind({"cmd", "ctrl"}, "Right", moveWindowRight)
  hs.hotkey.bind({"cmd", "ctrl"}, "Left", moveWindowLeft)
end

-- Modal window management:
local windowManager = hs.hotkey.modal.new({"cmd", "alt", "ctrl"}, "Space", "Welcome to the Window Manager!")
function windowManager:exited()
  hs.alert("Goodbye!")
end
windowManager:bind("", "escape", function() windowManager:exit() end)
windowManager:bind("", "space", windowFull)
windowManager:bind("", "f", windowFull)
windowManager:bind("", "right", windowRight)
windowManager:bind("", "left", windowLeft)

-- TODO: When the audio device changes, display current volume briefly
-- TODO: Handle windows that can't be resized
-- TODO: Multiple monitors -- doesn't work
-- TODO: Fix bugs in moving windows

local menu = hs.menubar.new()
local endTime = 0
local standardTime = 1500
local timer = nil
local timerFormat = "%d - %d:%02d"
local counter = 0

function updateTimerMenu()
  local stopped = not timer
  menu:setMenu( {
      { title = "Start", fn = function() startTimer() end, disabled = not stopped },
      { title = "Reset", fn = function() resetTimer() end, disabled = stopped },
      { title = "Reset Counter", fn = function() resetCounter() end}
  })
end

function updateTimerIcon()
  local timeLeft
  if timer then
    timeLeft = endTime - hs.timer.secondsSinceEpoch()
  else
    timeLeft = standardTime
  end
  local min = math.floor(timeLeft/60)
  local sec = math.floor(timeLeft%60)

  menu:setTitle(timerFormat:format(counter, min, sec))
end

function updateTimer()
  local timeLeft = endTime - hs.timer.secondsSinceEpoch()
  if timeLeft <= 0 then
    finishTimer()
  end
  updateTimerIcon()
end

function resetTimer()
  if timer then
    timer:stop()
    timer = nil
  end
  updateTimerIcon()
  updateTimerMenu()
end

function resetCounter()
  counter = 0
  updateTimerIcon()
end

function finishTimer()
  hs.alert.show("Time!", 4)
  counter = counter + 1
  resetTimer()
end

function startTimer()
  endTime = hs.timer.secondsSinceEpoch() + standardTime
  timer = hs.timer.new(1, updateTimer)
  timer:start()
  updateTimerIcon()
  updateTimerMenu()
end

updateTimerIcon()
updateTimerMenu()
