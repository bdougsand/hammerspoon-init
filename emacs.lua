local emacs = {}

local handlers = {}

-- Receive messages from emacs:
function emacs.addHandler(messageType, fn)
  handlers[messageType] = fn
end

function emacs.defaultHandler(object)
  local messageType = object["type"]
  if messageType then
    local handler = handlers[messageType]
    if handler then
      local response = handler(object)
      return response or {}
    else
      return {response="You sent me a " .. messageType .. " message."}
    end
  else
    return {response="Your message did not have a type."}
  end
end

local ipc = require("hs.ipc")
if ipc.cliInstall() then
  ipc.localPort("emacsInterop", function(port, mID, rawMessage)
                  if rawMessage:sub(1, 1) == "x" then
                    local succ, result = pcall(hs.json.decode, rawMessage:sub(2))
                    if succ then
                      return ">>" .. hs.json.encode(emacs.defaultHandler(result))
                    else
                      return ">>" .. hs.json.encode({error="parseError"})
                    end
                  end
  end)
  emacsRemotePort = hs.ipc.remotePort("emacsInterop")
end


-- Send messages to emacs:
local function shellCommand(command)
	local handle = io.popen(command)
	local output = handle:read("*all")
	local results = {handle:close()}

	return output, results[1]
end

local function parseResponse(response)
  if response == "nil" then
    return nil
  elseif response:match("^%d+$") then
    return 0+response
  end

  local spatt = response:match("^\".*\"")
  if spatt then
    return spatt:sub(2, -2):gsub("%\\(.)", "%1")
  end

  return response
end

function emacs.evalNoParse(command)
	local emacs_path = "/usr/local/bin/emacsclient"
	local full_command = string.format("%s -n -a false -e '%s'", 
                                     emacs_path, command:gsub("'", "\\'"))
	return shellCommand(full_command)
end

function emacs.eval(command)
  local response, succ = emacs.evalNoParse(command)
  if succ then
    return parseResponse(response), true
  else
    return nil, false
  end
end

function emacs.evalJSON(command)
  local response, succ = emacs.eval(command)
  if succ then
    local decoded, json = pcall(hs.json.decode, response)
    if decoded then
      return json
    else
      return nil
    end
  else
    return nil
  end
end


return emacs
