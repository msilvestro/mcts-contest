-- The main part: how a contest works!

require "contest/move"
require "contest/pokemon"

Contest = {}

--[[
In contests, there is a relation between conditions.
Excitement: +1 heart +1 star, when same contest-condition move-condition. (e.g. Cool -> Cool contest)
Indifference: Nothing changes. (e.g. Beautiful and Tough -> Cool contest)
Discontent: -1 heart -1 star. (e.g. Clever and Cute -> Cool contest)
In this table there are the move conditions that generates discontent when used in a specific condition contest.
Example:
A = {"B", "C"}
When using a B or C move in a A contest, generates discontent.
]]
discontent = {
  Cool = {"Clever", "Cute"},
  Beautiful = {"Clever", "Tough"},
  Cute = {"Cool", "Tough"},
  Cleverness = {"Beautiful", "Cool"},
  Tough = {"Beautiful", "Cute"}
}

-- In contests, there are some moves that makes a combo. If it happens, i.e. two moves of a combo are performed , there is a +3 bonus.
combo = {
  ["Rain Dance"] = "Weather Ball",
  ["Sunny Day"] = "Weather Ball",
  ["Hail"] = "Weather Ball",
  ["Agility"] = "Baton Pass",
  ["Agility"] = "Electro Ball"
}

function Contest:new(condition, pokemons, verbose)
  assert(condition == "Cool" or condition == "Beautiful" or condition == "Cute" or condition == "Clever" or condition == "Tough", condition .. " is not a valid condition.") -- check if it's provided a valid condition...
  assert(#pokemons == 4, "There must be 4 participants.") -- and 4 participants.
  local contest = {
    condition = condition, -- condition of the contest.
    pokemons = pokemons, -- the 4 Pokémon participants, in the correct order. Important: each one must have a different name.
    stars = 0, -- how much stars the star meter has, max is 5.
    turn = 1, -- turn number, max is 5.
    dampen = false, -- whether the enthusiasm is dampened or not. If dampened, stores the name of the Pokémon that made it.
    verbose = verbose, -- show or not info about the contest.
    fixedord = {}, -- all the Pokémon that have a fixed order. Index are Pokémon names, values means priority: the higher the first.
    randomoutcomes = {} -- contains all the choices made by random events (e.g. if a Pokémon is nervous or not or the order in case of tie), must be filled for the right move made by the right player if we want the random events to have a specific outcome. Essential for simulations.
  }
  -- Events is where all what happens goes, to be represented graphically (or textually).
  if contest.verbose then
    -- Only if we must show info about the contest, make the event table.
    contest.events = {} -- TODO change events so that it has event[turn][pokemon]
    require "contest/interface" -- and require all you need to display the info.
  end
  -- Set prototype.
  setmetatable(contest, self)
  self.__index = self
  self.__tostring = self.tostring
  return contest
end

function Contest:tostring()
  --[[
  Format as a string, as follows:
  ★★☆☆☆
  1. Machoke	  💔
  2. Masquerain	♥♥
  3. Vileplume	♥♥♥
  4. Gorebyss	  ♥♥♥♥
  ]]
  local s = ""
  -- Print the star meter.
  for i = 1, self.stars do s = s .. "★" end
  for i = self.stars+1, 5 do s = s .. "☆" end
  s = s .. "\n"
  -- Print all participants with hearts and statuses.
  for i, pokemon in pairs(self.pokemons) do
    local h, hearts, sym, status = "", math.abs(pokemon.hearts), "", ""
    if pokemon.protection == 1 then status = status .. "x" elseif pokemon.protection == 2 then status = status .. "X" end
    if pokemon.nervous == true then status = status .. "~" end
    if pokemon.hearts >= 0 then sym = "♥" else sym = "💔" end
    for i = 1, hearts do h = h .. sym end
    s = s .. i .. ". " .. pokemon.name .. " " .. status .. "\t" .. h .. "\n"
  end
  return s
end

function Contest:clone()
  -- Clone the contest.
  local pokemons = {}
  for i = 1, #self.pokemons do pokemons[i] = self.pokemons[i]:clone() end
  local clone = Contest:new(self.condition, pokemons, self.verbose)
  clone.stars = self.stars
  clone.turn = self.turn
  clone.dampen = self.dampen
  clone.fixedord = objclone(self.fixedord)
  clone.randomoutcomes = objclone(self.randomoutcomes)
  if self.verbose then clone.events = objclone(self.events) end
  return clone
end

function Contest:doMove(pi, mi)
  local pokemon, move = self.pokemons[pi], self.pokemons[pi].moves[mi] -- current Pokémon moving and current move used.
  local repeated = (move.name == pokemon.prevmove) -- has it executed the same move used the previous turn?
  if move.trigger == "repeat" then repeated = false end -- if the move trigger is repeat, it means that the repeat malus should not be applied.
  -- Execute the move appeal and appeal effect.
  self:addEvent{"appeal", pokemon = pokemon.name, move = move.name} -- "<Pokémon> si esibisce con <mossa>!"
  if move.trigger == "start" then move:effect(self, pi) end -- execute move effect to execute at the start.
  if move.trigger == "appeal" then
    pokemon.hearts = pokemon.hearts + move:effect(self, pi)
    -- In this case, the event history is handled by the move:effect function!
  else
    pokemon.hearts = pokemon.hearts + move.appeal
    self:addEvent{"addhearts", hearts = move.appeal}
  end
  -- Execute the jam, if the move has jam effect and the active Pokémon is not the first (since it will have no Pokémon to jam).
  if move.jam > 0 then
    self:addEvent{"startle"} -- "Cerca di spaventare gli avversari!"
    local success = false -- -- true if at least one of the previoys Pokémons get startled.
    for i = 1, pi-1 do
      -- If the jam must be executed only on the previous one, execute the loop just once (when the index reach the previous Pokémon). Else, execute the whole loop.
      -- This is to use the same code for jamall and jamonce.
      if (not move.jamall and i == pi-1) or move.jamall then
        local prev = self.pokemons[i]
        -- If there is no protection or user committed suicide (4 means it has committed suicide in a previous turn: in fact, if it has committed suicide in the current turn it can be startled), jam.
        if prev.protection == 0 and prev.cantmove ~= 4 then
          local jam
          if move.trigger == "jam" then jam = move:effect(self, i)
          else jam = move.jam end
          if prev.easystartle == true then
            prev.hearts = prev.hearts - jam*2
            self:addEvent{"removehearts", hearts = jam*2, pokemon = prev.name}
          else
            prev.hearts = prev.hearts - jam
            self:addEvent{"removehearts", hearts = jam, pokemon = prev.name}
          end
          success = true
        else -- if there is protection, no jam!
          -- If the Pokémon is just protected once, remove the protection now that it has protected.
          if prev.protection == 1 then
            prev.protection = 0
            self:addEvent{"removeprotect", pokemon = prev.name}
          end
        end
      end
    end
    if not success then self:addEvent{"miss"} end -- "Ma non ce la fa!"
  end
  if move.trigger == "end" then move:effect(self, pi) end -- execute move effect to execute at the end.
  -- Additional effects.
  -- Combo bonus: check if it is a combo move and if it has made a combo.
  if table.haskey(combo, move.name) then self:addEvent{"cancombo"} end -- "Il pubblico si aspetta molto dalla prossima combinazione!"
  if table.haskey(combo, pokemon.prevmove) and combo[pokemon.prevmove] == move.name then
    self:addEvent{"combo"} -- "Il pubblico ha apprezzato molto la combinazione con l'esibizione precedente!"
    pokemon.hearts = pokemon.hearts + 3 -- the combo increases hearts by 3.
    self:addEvent{"addhearts", hearts = 3}
  end
  -- Repeat malus: same move executed twice in a row gives -1 hearts and doesn't make the crowd excited.
  if repeated then
    self:addEvent{"repeated", pokemon = pokemon.name} -- "<Pokémon> delude il pubblico ripetendo la stessa esibizione!"
    pokemon.hearts = pokemon.hearts - 1
    self:addEvent{"addhearts", hearts = -1}
  end
  -- Same condition bonus: if the move and the contest has the same condition, add a heart and a star.
  -- Not applied if repeated move or Pokémon has earned no hearts or dampened crowd (but still applied if the Pokémon is the same that dampened the crowd, remember that self.dampen keeps the name of the Pokémon that dampened the crowd if any).
  if move.condition == self.condition and pokemon.hearts ~= 0 and not repeated and (not self.dampen or self.dampen == pokemon.name) then
    -- If the move has a special trigger related to the star meter and the condition is satisfied, double the stars.
    local stars
    if move.trigger == "stars" then
      stars = move:effect(self, pi)
    else
      stars = 1
      self:addEvent{"excited", condition = self.condition, pokemon = pokemon.name} -- "Il pubblico è entusiasta della <virtù> di <Pokémon>!"
    end
    local hearts = stars -- remember: if the effect adds two star but we can add only one, we add anyway two hearts.
    if self.stars + stars > 5 then stars = 5 - self.stars end
    self.stars = self.stars + stars
    self:addEvent{"addstars", stars = stars}
    pokemon.hearts = pokemon.hearts + hearts
    self:addEvent{"addhearts", hearts = hearts}
  elseif move.condition == self.condition and pokemon.hearts ~= 0 and not repeated and self.dampen then
    self:addEvent{"dampen1", dampener = self.dampen}
    self:addEvent{"dampen2", condition = self.condition, pokemon = pokemon.name}
  end
  -- Discontent malus: if the move generates discontent, remove a heart and a star.
  if move.condition == discontent[self.condition][1] or move.condition == discontent[self.condition][2] then
    self:addEvent{"discontent", condition = move.condition, pokemon = pokemon.name} -- Il pubblico non sembra colpito dalla <virtù> di <Pokémon>...
    if self.stars ~= 0 then
      self.stars = self.stars - 1
      self:addEvent{"addstars", stars = -1}
    end
    pokemon.hearts = pokemon.hearts - 1
    self:addEvent{"addhearts", hearts = -1}
    -- Remember: if 0 stars, the stars remains the same but the heart is removed anyway.
  end
  -- Excitement bonus: If the star meter reaches 5 stars, add 5 hearts and reset the meter.
  if self.stars == 5 then
    self:addEvent{"fascinated1", condition = self.condition, pokemon = pokemon.name} -- "Il pubblico è incantato dalla <virtù> di <Pokémon>!"
    self:addEvent{"fascinated2", condition = self.condition, pokemon = pokemon.name} -- "La Bellezza di <Pokémon> è quasi accecante!" (varia in base alla virtù)
    self:addEvent{"fascinated3"} -- "L'Esibizione Live ha lasciato il pubblico a bocca aperta!"
    pokemon.hearts = pokemon.hearts + 5
    self:addEvent{"addhearts", hearts = 5}
    self.stars = 0
    self:addEvent{"resetstars"}
  end
end

function Contest:doTurn(moves)
  -- Moves are given by the pair (Pokémon name, move number).
  -- Important: In this implementation, the Pokémon name is unique, so each Pokémon must have a different name.
  assert(self.turn < 6, "The contests end after 5 turns") -- error if turn is 6 or above.
  if self.verbose then self.events[self.turn] = {} end -- start the events for the turn.
  -- Execute the moves, one for each of the participants, in the correct order.
  for i = 1, 4 do
    local pokemon = self.pokemons[i]
    self:addEvent{"turn", pokemon = pokemon.name}
    if not pokemon.nervous and pokemon.cantmove == 0 then
      self:doMove(i, moves[pokemon.name])
      pokemon.prevmove = pokemon.moves[moves[pokemon.name]].name -- save the move used, so that if the next turn the move is repeated the malus applies.
    else
      if pokemon.nervous then
        self:addEvent{"nervous", pokemon = pokemon.name} -- "<Pokémon> non riesce a esibirsi per l'emozione!"
      end
      if pokemon.cantmove > 0 then
        self:addEvent{"cantmove", pokemon = pokemon.name} -- "<Pokémon> non può far altro che stare a guardare!"
      end
    end
    -- Save the current state.
    self:addEvent{"state", state = self:tostring()}
  end
  -- Choose the order for the next turn, if tie choose randomly.
  -- In the table fixedord there are the name of the Pokémons that must have a fixed order (first ones or last ones) associated to a priority value.
  -- The algorithm generates for every Pokémon a random number in (0,1) if no priority is given. Then there is comparison:
  -- - if both Pokémon have different hearts and no priority, first is the one with most hearts (since hearts are integer the random number is ininfluent);
  -- - if both Pokémon have the same hearts, the random number decides who goes first;
  -- - if a Pokémon has the priority, it's always first: priorities are multiple of 1000, in fact.
  -- See http://stackoverflow.com/questions/32069912/lua-sort-table-and-randomize-ties for further information.
  if self.randomoutcomes.fixedord then self.fixedord = self.randomoutcomes.fixedord end -- if the order has been fixed, set it.
  local rnd = self.fixedord
  table.sort(self.pokemons,
    function (a, b)
      rnd[a.name] = rnd[a.name] or math.random()
      rnd[b.name] = rnd[b.name] or math.random()
      return a.hearts + rnd[a.name] > b.hearts + rnd[b.name]
    end)
  -- Update the events to add the new order.
  local pokemons = {}
  for i = 1, 4 do pokemons[i] = self.pokemons[i].name end
  self:addEvent{"order", pokemons = pokemons}
  -- Reset all the participants.
  for i, pokemon in pairs(self.pokemons) do
    pokemon.tothearts = pokemon.tothearts + pokemon.hearts
    pokemon.hearts = 0
    pokemon.protection = 0
    pokemon.easystartle = false
    pokemon.nervous = false
    if pokemon.cantmove == 1 then pokemon.cantmove = 0 
    elseif pokemon.cantmove == 2 then pokemon.cantmove = 1
    elseif pokemon.cantmove == 3 then pokemon.cantmove = 4 end
  end
  -- The current turn has ended. Reset all contest stuff.
  self.turn = self.turn + 1
  self.dampen = false
  self.fixedord = {}
  self.randomoutcomes = {}
  -- If we finished all the 5 turns, sort the Pokémons by total hearts earned.
  if self.turn == 6 then
    local rnd = {}
    table.sort(self.pokemons,
      function (a, b)
        rnd[a.name] = rnd[a.name] or math.random()
        rnd[b.name] = rnd[b.name] or math.random()
        return a.tothearts + rnd[a.name] > b.tothearts + rnd[b.name]
      end)
    -- Update the events to add the final result. Overwrite the last order, that has no importance.
    local pokemons, hearts = {}, {}
    for i = 1, 4 do pokemons[i] = self.pokemons[i].name end
    for i = 1, 4 do hearts[i] = self.pokemons[i].tothearts end
    if self.verbose then self.events[5][#self.events[5]] = {"result", pokemons = pokemons, hearts = hearts} end
  end
end

function Contest:isEnded()
  -- Return true if the contest has endend, i.e. we passed through all the 5 turns.
  return self.turn == 6
end

function Contest:printResult()
  -- Print the final result of the contest.
  assert(self:isEnded(), "The contest is not yet ended, you can't have the result.")
  local s = "-- Results --\n"
  for i, pokemon in pairs(self.pokemons) do
    s = s .. i .. ". " .. pokemon.name .. "\t" .. pokemon.tothearts .. "♥\n"
  end
  print(s)
end

function Contest:getResult()
  -- Return the name of the winner.
  assert(self:isEnded(), "The contest is not yet ended, you can't have the result.")
  return self.pokemons[1].name
end

function Contest:shuffleOrder()
  -- Shuffle the starting order.
  for i = 1, 4 do
    local j = math.random(4)
    self.pokemons[i], self.pokemons[j] = self.pokemons[j], self.pokemons[i] 
  end
end

function Contest:getLastPokemonToAppeal(pi)
  -- Return the last Pokémon that has made an appeal.
  local i = pi-1
  -- Remember: if cantmove == 0 the Pokémon can move and has moves, and if cantmove == 3 the Pokémon has just made a suicide move but yet has moved, so you must not skip it.
  while i > 0 and (self.pokemons[i].nervous or self.pokemons[i].cantmove == 1 or self.pokemons[i].cantmove == 4) do
    i = i - 1
  end 
  return i
end

function Contest:addEvent(event)
  if self.verbose then
    table.insert(self.events[self.turn], event)
  end
end

function Contest:printEvents(turn)
  printEvents(self.events, turn)
end