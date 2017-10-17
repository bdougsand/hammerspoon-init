spaces_imported, spaces = pcall(require, "hs._asm.undocumented.spaces") 
local lastRun = 0

function withRelativeWindow(n, fn)
  return function(...)
    local window = hs.window.focusedWindow()
    if n > 0 then
      window = window:otherWindowsSameScreen()[n]
    end
    fn(window, ...)
  end
end

function withCurrentWindow(fn)
  return withRelativeWindow(0, fn)
end

function doWindowMove(window, wScale, hScale, xScale, yScale)
  if window:isFullScreen() then
    return
  end

  local f = window:frame()
  local screenFrame = window:screen():frame()

  local newX = screenFrame.w*xScale + screenFrame.x
  local newY = screenFrame.h*yScale + screenFrame.y
  local newW = screenFrame.w*wScale
  local newH = screenFrame.h*hScale

  f.x = newX
  f.y = newY
  f.w = newW
  f.h = newH
  window:setFrame(f)
end

local windowMove = withCurrentWindow(doWindowMove)

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

function moveWindowFn(dir)
  local fn = hs.window["moveOneScreen" .. dir]
  return function()
    fn(hs.window.frontmostWindow())
  end
end

function selectWindowFn(dir)
  return function()
    local w = hs.window.frontmostWindow()
    hs.window["focusWindow" .. dir](w)
  end
end


-- Modal window management:
local windowManager = hs.hotkey.modal.new({"cmd", "alt", "ctrl"}, "Space", "Welcome to the Window Manager!")
function windowManager:exited()
  hs.alert("Goodbye!")
end

windowManager:bind("", "escape", function() windowManager:exit() end)
windowManager:bind("", "space", windowFull)
windowManager:bind("", "f", windowFull)
windowManager:bind("", "d", windowRight)
windowManager:bind("", "a", windowLeft)
windowManager:bind("", "s", windowBottom)
windowManager:bind("", "w", windowTop)
windowManager:bind("", "q", windowTopLeft)
windowManager:bind("", "e", windowTopRight)
windowManager:bind("", "c", windowBottomRight)
windowManager:bind("", "z", windowBottomLeft)
-- Change screens:
windowManager:bind("", "up", moveWindowFn("North"))
windowManager:bind("", "down", moveWindowFn("South"))
windowManager:bind("", "left", moveWindowFn("West"))
windowManager:bind("", "right", moveWindowFn("East"))

windowManager:bind("", "j", selectWindowFn("South"))
windowManager:bind("", "k", selectWindowFn("North"))
windowManager:bind("", "h", selectWindowFn("West"))
windowManager:bind("", "l", selectWindowFn("East"))

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


local usbWatcher = nil
function usbDeviceChange(data)
  local name = data["productName"]

  if data["eventType"] == "added" then
    if name == "E-MU XMidi1X1" then
      hs.application.launchOrFocus("GarageBand")
    end
  end
end

usbWatcher = hs.usb.watcher.new(usbDeviceChange)
usbWatcher:start()
function shellCommand(command)
	local handle = io.popen(command)
	local output = handle:read("*all")
	local results = {handle:close()}
	
	return {results[1], output}
end

function emacsEval(command)
	local emacs_path = "/usr/local/bin/emacsclient"
	local full_command = string.format("%s -a false -e '%s'", 
									  emacs_path, command:gsub("'", "\\'"))
	return shellCommand(full_command)
end
