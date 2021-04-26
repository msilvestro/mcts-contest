math.randomseed(os.time())

require "../contest/teams"
require "../mcts/mcts"
require "tests/writefile"

-- Make self simulations - contest between MCTS/random player inside the program itself.

local size = 370 -- size of the sample, i.e. how many simulations to do.
local random = false
local mctsequal = true
local baseiter = 10000
local betteriter = 10000
local betterplayer = "Speranza"
local simtype = "equal10000"

for i = 1, size do
  local contest = ContestState:new("Beautiful", buildBMTeam(), true)
  
  while not contest:isEnded() do
    for j = 1, 4 do
      if random then
        contest:doRandomMove()
      else
        local iter = baseiter
        if not mctsequal and contest.playerNames[j] == betterplayer then iter = betteriter end
        local m = MCTS(contest, iter, j)
        contest:doMove(m)
      end
    end
  end
  
  local results = {}
  for j = 1, 4 do results[contest.contest.pokemons[j].name] = contest.contest.pokemons[j].tothearts end
  writeResults("tests/self/" .. simtype .. "-hearts.csv", results)
  local results = {}
  for j = 1, 4 do results[contest.contest.pokemons[j].name] = (j == 1) and 1 or 0 end
  writeResults("tests/self/" .. simtype .. "-wins.csv", results)
  
  if i % 5 == 0 then print(math.floor(i/size*100) .. "%") end -- show progress.
end