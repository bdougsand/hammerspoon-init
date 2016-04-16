function windowMove(wScale, hScale, xScale, yScale)
  local window = hs.window.focusedWindow()
  local f = window:frame()
  local screenFrame = window:screen():frame()

  f.x = screenFrame.w*xScale
  f.y = screenFrame.h*yScale
  f.w = screenFrame.w*wScale
  f.h = screenFrame.h*hScale
  window:setFrame(f)
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
