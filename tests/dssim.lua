require "../contest/teams"
require "../contest/conteststate"
require "../contest/interface"
require "../mcts/mcts"
require "tests/writefile"

-- Record all the contest.
local conteststr = ""

-- Show all choices and made the user select four Pokémons from them.
--local choices = {Tropica = Tropica, Plumy = Plumy, Macy = Macy, Betta = Betta, Trod = Trod, Speranza = Speranza, Castform = Castform, Meganium = Meganium, Gyarados = Gyarados}
local choices = {Speranza = Speranza, Tropica = Tropica, Plumy = Plumy, Macy = Macy, Betta = Betta, Trod = Trod}
local s = "Scegli 4 Pokémon tra i disponibili (separando con uno spazio): "
for i, v in pairs(choices) do s = s .. i .. " " end
print(s)
local res = tostring(io.read())
local team = {}
local i = 0
for pokemon in string.gmatch(res, "%S+") do -- go from word to word.
  assert(choices[pokemon], "Il Pokémon " .. pokemon .. " non esiste!")
  i = i + 1
  team[i] = choices[pokemon]
end
assert(i == 4, "Ci sono possono essere solo 4 Pokémon, non " .. i .. "!")
assert(team[1].name ~= team[2].name and team[2].name ~= team[3].name and team[3].name ~= team[4].name, "Tutti i Pokémon devono essere diversi!")
conteststr = conteststr .. res
-- Ask for what Pokémon is the one controlled by the human.
print("Quale Pokémon controlli? [1-4]")
humani = tonumber(io.read())
assert(humani >= 1 and humani <= 4, humani .. " non è un numero dell'intervallo [1-4].")
conteststr = conteststr .. ";" .. humani
-- Ask for how much iteration the MCTS algorithm should do.
print("Quante iterazioni deve fare l'algoritmo? [>=1]")
iter = tonumber(io.read())
assert(iter >= 1, iter .. " non è un numero accettabile.")
conteststr = conteststr .. ";" .. iter

-- Load the contest.
contest = ContestState:new("Beautiful", team, true)

-- Create index (ordered as start position) to Pokémon name table.
local itopokemon = {}
for i = 1, 4 do itopokemon[i] = team[i].name end
-- Create a table with all move names (in Italian) for every Pokémon.
local moves = {}
for i = 1, 4 do
  moves[team[i].name] = {}
  for j = 1, 4 do moves[team[i].name][j] = moveName[team[i].moves[j].name] end
end

for t = 1, 5 do
  -- Choose the move the human should do with MCTS.
  print("\nRagionando...")
  local sm = MCTS(contest, iter, humani)
  print(itopokemon[humani] .. " dovrebbe scegliere " .. moves[itopokemon[humani]][sm] .. ".")
  
  local chosenmoves = {} -- will contain moves associated to the Pokémon's name.
  local randomoutcomes = {} -- will contain eventual random outcomes from moves.
  for i = 1, 4 do
    -- Print Pokémon name, moves and ask the human to choose.
    local pokemon = contest.contest.pokemons[i].name
    local s = "> " .. pokemon .. ":"
    for j = 1, 4 do
      s = s .. "\t[" .. j .. "] " .. moves[pokemon][j]
    end
    print(s)
    local hint = ""
    if contest.contest.pokemons[i].name == itopokemon[humani] then hint = " {" .. sm .. "}" end
    print("Quale mossa scegli? [1-4]" .. hint)
    local m = io.read()
    if m == "" then m = sm else
      m = tonumber(m)
      assert(m >= 1 and m <= 4, m .. " non è un numero dell'intervallo [1-4].")
    end
    chosenmoves[pokemon] = m
    conteststr = conteststr .. ";" .. m
    
    -- If the move makes Pokémons nervous or has a random number of hearts, ask to provide the random outcomes.
    local movetype = MoveDB[contest.contest.pokemons[i].moves[m].name].mtype
    if movetype == "20nervous" then
      print("Quali Pokémon diventeranno nervosi? [1=nervoso, 0=non nervoso]")
      local n = tostring(io.read())
      randomoutcomes[pokemon] = {}
      for j = 1, 4-i do
        randomoutcomes[pokemon][j] = (string.sub(n, j, j) == "1")
      end
      conteststr = conteststr .. ";" .. n
    elseif movetype == "10random" then
      print("Qual è il punteggio assegnato alla mossa? [1-5] {1, 2, 4, 6, 8}")
      local n = tonumber(io.read())
      assert(n >= 1 and n <= 5, m .. " non è un numero dell'intervallo [1-5].")
      randomoutcomes[pokemon] = n
      conteststr = conteststr .. ";" .. n
    end
  end
  
  -- Ask for the possibly different new order of the Pokémons.
  if t < 5 then
    local spokemons = "1=" .. itopokemon[1]
    for i = 2, 4 do spokemons = spokemons .. ", " .. i .. "=" .. itopokemon[i] end
    print("Qual è il nuovo ordine? [" .. spokemons .. "]")
    local o = tostring(io.read())
    if o ~= "" then
      local neworder = {}
      for i = 1, 4 do
        neworder[i] = itopokemon[tonumber(string.sub(o, i, i))]
        for j = 2, i-1 do assert(neworder[i] ~= neworder[j], "L'ordine non è nel formato corretto: c'è una posizione ripetuta.") end
      end
      contest:fixNextOrder(neworder)
    end
    conteststr = conteststr .. ";" .. o
  end

  -- Finally, execute the contest and print what happens that turn.
  print("")
  for i = 1, 4 do contest:doMove(chosenmoves[itopokemon[i]], randomoutcomes[itopokemon[i]]) end
  contest:printEvents(t)
end

-- Print the results.
print("")
contest:printResult()

local results = {}
for i = 1, 4 do results[contest.contest.pokemons[i].name] = contest.contest.pokemons[i].tothearts end
writeResults("tests/ds/hearts.csv", results)
local results = {}
for i = 1, 4 do results[contest.contest.pokemons[i].name] = (i == 1) and 1 or 0 end
writeResults("tests/ds/wins.csv", results)

-- Print in file the contest record.
local file = io.open("tests/ds/records.csv", "a")
file:write(conteststr .. "\n")
file:close()
print(conteststr)