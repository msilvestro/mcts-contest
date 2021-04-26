-- Save the results.
function writeResults(filename, results)
  local content = ""
  local header = {"Speranza", "Tropica", "Plumy", "Macy", "Betta", "Trod"}
  local file = io.open(filename, "r")
  if not file then
    -- The file hasn't yet been created, add headers.
    for i = 1, #header do
      content = content .. header[i]
      if i ~= #header then content = content .. ";"
      else content = content .. "\n" end
    end
  end
  for i = 1, #header do
    if results[header[i]] then content = content .. results[header[i]] end
    if i ~= #header then content = content .. ";"
    else content = content .. "\n" end
  end
  --print(content)
  local file = io.open(filename, "a")
  file:write(content)
  file:close()
end