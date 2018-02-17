local utils = {}

function utils.title(s)
  local words = {}
  for word in s:gmatch("[^%s-]+") do
    table.insert(words, word:sub(1, 1):upper() .. word:sub(2))
  end
  return table.concat(words, " ")
end

return utils
