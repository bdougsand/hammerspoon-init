
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

  f.x = xScale and (screenFrame.w*xScale + screenFrame.x) or f.x
  f.y = yScale and (screenFrame.h*yScale + screenFrame.y) or f.y
  f.w = wScale and (screenFrame.w*wScale) or f.w
  f.h = hScale and (screenFrame.h*hScale) or f.h

  window:setFrame(f)
end

windowMove = withCurrentWindow(doWindowMove)

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

function windowFillHeight()
  windowMove(nil, 1)
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

local windows = require("windows")

hs.hotkey.bind({"cmd", "alt"}, "Left", windowLeft)
hs.hotkey.bind({"cmd", "alt"}, "Right", windowRight)
hs.hotkey.bind({"cmd", "alt"}, "Up", windowTop)
hs.hotkey.bind({"cmd", "alt"}, "Down", windowBottom)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, ".", fillSpace)

hs.hotkey.bind({}, "F5", windows.moveAppWindowsToSpace)

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
local windowManager = hs.hotkey.modal.new({"cmd", "alt", "ctrl"}, "Space", "Window Manager!")
function windowManager:exited()
  hs.alert("Goodbye!")
end

windowManager
  :bind("", "escape", function() windowManager:exit() end)
  :bind("", "space", windowFull)
  :bind("", "f", windowFull)
  :bind("", "d", windowRight)
  :bind("", "]", windowRight)
  :bind("", "a", windowLeft)
  :bind("", "[", windowLeft)
  :bind("", "s", windowBottom)
  :bind("", "w", windowTop)
  :bind("", "q", windowTopLeft)
  :bind("", "e", windowTopRight)
  :bind("", "c", windowBottomRight)
  :bind("", "z", windowBottomLeft)
  :bind("shift", "\\", windowFillHeight)
    :bind("", "=", windows.moveAppWindowsToSpace)

-- Change screens:
windowManager
  :bind("", "up", moveWindowFn("North"))
  :bind("", "down", moveWindowFn("South"))
  :bind("", "left", moveWindowFn("West"))
  :bind("", "right", moveWindowFn("East"))

  :bind("", "j", selectWindowFn("South"))
  :bind("", "k", selectWindowFn("North"))
  :bind("", "h", selectWindowFn("West"))
  :bind("", "l", selectWindowFn("East"))



function doToggleMute()
  local device = hs.audiodevice.defaultOutputDevice()
  device:setOutputMuted(not device:outputMuted())
end

local lastSpotifyVolume = hs.spotify.getVolume()
function doToggleSpotifyMute()
  local volume = hs.spotify.getVolume()
  if volume <= 5 then
    hs.spotify.setVolume(lastSpotifyVolume)
  else
    hs.spotify.setVolume(1)
    lastSpotifyVolume = volume
  end
end

function doCopySpotifySongDetails()
  local title = hs.spotify.getCurrentTrack()
  local artist = hs.spotify.getCurrentArtist()
  local album = hs.spotify.getCurrentAlbum()

  hs.pasteboard.setContents(
    "\"" .. title .. "\" by " .. artist .. " (from " .. album .. ")")
end

hs.hotkey.bind({}, "F12", doToggleMute)
hs.hotkey.bind({"shift"}, "F12", doToggleSpotifyMute)
hs.hotkey.bind({}, "F2", hs.spotify.displayCurrentTrack)
hs.hotkey.bind({"shift"}, "F2", doCopySpotifySongDetails)


-- TODO: When the audio device changes, display current volume briefly
-- TODO: Handle windows that can't be resized
-- TODO: Multiple monitors -- doesn't work
-- TODO: Fix bugs in moving windows

local menu = hs.menubar.new()
--[[
local endTime = 0
local standardTime = 1500
local timer = nil
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
]]--


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



-- Network watching:
local trusted_path = os.getenv("HOME") .. "/trusted_networks.txt"

function writeTrusted(trusted)
  local f = io.open(trusted_path, "w")
  for k, _ in pairs(trusted) do
    f:write(k .. "\n")
  end
  f:close()
end

function readTrusted()
  local trusted = {}
  for line in io.lines(trusted_path) do
    if line:len() > 0 then
      trusted[line] = true
    else

    end
  end
  return trusted
end

hs.wifi.watcher.new(function()
    local trusted = readTrusted()
    local network = hs.wifi.currentNetwork()

    if not trusted[network] then
      local choices = {
        { text = "Trust this Network",
          uuid = "trust" },
        { text = "Connect to VPN",
          uuid = "vpn" }
      }
      local chooser = hs.chooser.new(function(choice)
          if choice == "trust" then
            trusted[network] = true
            writeTrusted(Trusted)
          else
            -- Connect to VPN
          end
      end)
    end
end)


local emacs = require("emacs")
local utils = require("utils")


function printAgendaTime()
  local minutes = emacs.getAgendaTime()
  local hours = math.floor(minutes/60)
  local minutes = math.floor(minutes % 60)
  local message = string.format("%s:%02s", hours, minutes)

  hs.alert.show(message)
end


PomodoroTimer = {}
PomodoroTimer.__index = PomodoroTimer

function PomodoroTimer.new()
  local init = {endTime = 0,
                state = "waiting",
                count = 0,
                timer = nil,
                menu = hs.menubar.new(),
                timerFormat = "%d:%02d",
                -- Full path to the task
                task = nil,
                bufferName = nil,
                endHooksRan = 0}
  setmetatable(init, PomodoroTimer)
  return init
end

local eventStates = { pomodoroStarted = "running",
                      pomodoroFinished = "break",
                      pomodoroKilled = "waiting",
                      pomodoroBreakFinished = "waiting",
                      clockIn = "running" }

function PomodoroTimer:updateState(event)
  local msgType = event["type"]
  local stopped = msgType == "pomodoroKilled" or msgType == "pomodoroFinished"
  self.endTime = hs.timer.secondsSinceEpoch() + event["timeRemaining"]
  self.task = event["taskPath"] or {}
  self.bufferName = utils.title(event["bufferName"] or "")
  self.state = eventStates[msgType]

  self.count = event["count"]
  self:updateMenu()
end

function PomodoroTimer:updateMenu()
  if self.state == "running" then
    local taskName = self.task[#self.task]
    local menuItems = {
      { title = "Print Total Time", fn = printAgendaTime },
      { title = self.bufferName, disabled = true }}

    local l = #self.task
    for i, pathComponent in ipairs(self.task) do
      local title = pathComponent
      if i < l then
        title = title .. " -> "
      end
      table.insert(menuItems, { title = title, disabled = true })
    end

    self.menu:setMenu(menuItems):setTooltip(taskName)
  else
    self.menu:setMenu({{ title = "Print Total Time", fn = printAgendaTime }}):setTooltip("")
  end
end

function PomodoroTimer:emacsEvent(event)
  if event["type"] == "pomodoroFinished" then
    if not self._printTimeTimer then
      self._printTimeTimer = hs.timer.doAfter(1, printAgendaTime)
    end
  end
end

function PomodoroTimer:getState()
  local message = emacs.evalJSON("(json-encode (hammerspoon--get-pomodoro-state))")
  if message then
    self:updateState(message)
  end
end

function PomodoroTimer:timeRemaining()
	return self.endTime - hs.timer.secondsSinceEpoch()
end

function PomodoroTimer:tick()
  self:redrawMenuTitle()
end

function PomodoroTimer:start()
  if self.timer then
    if not self.timer:running() then
      self.timer:start()
    end
  else
    self.timer = hs.timer.doEvery(1, function() self:tick() end)
  end

  return self
end

function PomodoroTimer:redrawMenuTitle()
  local secs = self:timeRemaining()
  local remaining = self.timerFormat:format(math.floor(secs/60), math.floor(secs%60))
  local title

  if self.state == "running" then
	  title = string.format("⏱ [%d] %s", self.count, remaining)
  elseif self.state == "break" then
	  title = string.format("☕️ [%d] (%s)", self.count, remaining)
  else
	  title = string.format("⋯ [%d]", self.count)
  end

  self.menu:setTitle(title)
  return self
end


timerMenu = PomodoroTimer.new()
timerMenu:getState()
timerMenu:start()

for _, messageType in ipairs({"pomodoroStarted", "pomodoroFinished",
                              "pomodoroKilled", "pomodoroBreakFinished",
                              "clockIn"}) do
  emacs.addHandler(messageType,
                   function(message)
                     timerMenu:updateState(message)
                     timerMenu:emacsEvent(message)
                   end
  )
end



