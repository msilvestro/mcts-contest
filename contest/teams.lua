-- This file contains some prebuild Pokémons to play with.

require "contest/move"
require "contest/pokemon"

-- Beautiful Master Pokémons.
Tropica = Pokemon:new("Tropica", {Move:new("Whirlpool"), Move:new("Aqua Tail"), Move:new("Surf"), Move:new("Agility")})
Plumy = Pokemon:new("Plumy", {Move:new("Petal Blizzard"), Move:new("Petal Dance"), Move:new("Grassy Terrain"), Move:new("Solar Beam")})
Macy = Pokemon:new("Macy", {Move:new("Attract"), Move:new("Return"), Move:new("Round"), Move:new("Sunny Day")})
Betta = Pokemon:new("Betta", {Move:new("Counter"), Move:new("Mirror Coat"), Move:new("Safeguard"), Move:new("Destiny Bond")})
Trod = Pokemon:new("Trod", {Move:new("Sonic Boom"), Move:new("Electro Ball"), Move:new("Discharge"), Move:new("Explosion")})

-- Other Pokémons.
Speranza = Pokemon:new("Speranza", {Move:new("Mimic"), Move:new("Round"), Move:new("Dazzling Gleam"), Move:new("Disarming Voice")})
Castform = Pokemon:new("Castform", {Move:new("Sunny Day"), Move:new("Rain Dance"), Move:new("Hail"), Move:new("Weather Ball")})
Meganium = Pokemon:new("Meganium", {Move:new("Solar Beam"), Move:new("Sunny Day"), Move:new("Synthesis"), Move:new("Body Slam")})
Gyarados = Pokemon:new("Gyarados", {Move:new("Surf"), Move:new("Dive"), Move:new("Hydro Pump"), Move:new("Tackle")})

-- Functions to build a team as in DS game, if playing with Speranza in a Master Beautiful contest.
local choices = {Speranza = Speranza, Tropica = Tropica, Plumy = Plumy, Macy = Macy, Betta = Betta, Trod = Trod} -- associate Pokémon name with Pokémon object.
local preliminary = {Betta = 1, Speranza = 2, Tropica = 3, Trod = 4, Macy = 5, Plumy = 6} -- every Pokémon has a Beautiful statistic: if higher you go first. In this table, the number are based on the order as seen on DS game, if the number is small the Pokémon goes firts.

function getPokemon(rnd, weights)
  -- Given a random number and a table of weights (random number between 1 and sum of weights) return the element of the table corresponding.
  -- E.g. rnd = 3, weights = {apple = 1, banana = 2, peach = 1} => returns banana.
  local cum = 0 -- cumulative count of weights.
  for n, v in pairs(weights) do -- iterate over the whole table.
    if rnd > cum and rnd <= cum + v then -- if the random number is inside the weight area return the element.
      return n
    end
    cum = cum + v -- update the cumulative count.
  end
end

function buildBMTeam()
  -- Return a team with Speranza and the usual Master Beautiful contest Pokémons, as in DS game.
  local team = {"Speranza"} -- Speranza must be always chosen.
  local weights = {Betta = 1, Tropica = 1, Trod = 1, Macy = 1, Plumy = 1} -- weights table, if a weight is higher there is more probability of being chosen. If all weights are equal we uniformly choose between them.
  local tot = 0
  for _, v in pairs(weights) do tot = tot + v end -- sum up all weights.
  for j = 1, 3 do -- choose three other Pokémon (other than Speranza).
    local pokemon = getPokemon(math.random(tot), weights) -- choose a Pokémon in the table.
    table.insert(team, pokemon) -- add it to the team table.
    -- Now, the chosen Pokémon can't be chosen again. So, put 0 as weight of that Pokémon - it won't be chosen again, this way.
    tot = tot - weights[pokemon]
    weights[pokemon] = 0
  end
  table.sort(team, function(a,b) return preliminary[a] < preliminary[b] end) -- sort team table by preliminary values.
  local Team = {}
  for j = 1, #team do Team[j] = choices[team[j]]:clone() end -- build team based on the Pokémon chosen before.
  return Team
end