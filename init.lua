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
