-- Class to describe a participant Pokémon.

Pokemon = {}

function Pokemon:new(name, moves)
  assert(#moves == 4, "The Pokémon must have 4 moves.") -- in this implementation, every Pokémon must have 4 moves (reasonable).
  local pkmn = {
    name = name, -- name of the Pokémon.
    moves = moves, -- how many moves it has.
    hearts = 0, -- how much hearts it has.
    tothearts = 0, -- how much hearts it has won so far.
    prevmove = "", -- name of the previous move.
    protection = 0, -- 0 = no protection, 2->1 = protected once, 3->4 = protected for the whole turn. The first number means that the status has occured the current turn.
    easystartle = false, -- true if, when startled, loses double the hearts.
    nervous = false,
    cantmove = 0
  }
  -- Set prototype.
  setmetatable(pkmn, self)
  self.__index = self
  self.__tostring = self.tostring
  return pkmn
end

function Pokemon:tostring()
  --[[
  Format as string, as follows:
  Masquerain
  Moves:
  - Tackle	    [Though]	    Appeal: ♥♥♥♥	Jam: 
  - Air Slash	  [Beautiful]	  Appeal: ♥	    Jam: ♥♥♥♥
  - Rain Dance	[Beautiful]	  Appeal: ♥	    Jam: 
  - Bubble Beam	[Beutiful]	  Appeal: ♥♥	  Jam: ♥♥♥
  ]]
  local s
  s = self.name .. "\nMoves:\n"
  for _, v in pairs(self.moves) do
    s = s .. "- " .. tostring(v) .. "\n"
  end
  return s
end

function Pokemon:clone()
  -- Clone a Pokémon.
  local clone = Pokemon:new(self.name, self.moves)
  clone.hearts = self.hearts
  clone.tothearts = self.tothearts
  clone.prevmove = self.prevmove
  clone.protection = self.protection
  clone.easystartle = self.easystartle
  clone.nervous = self.nervous
  return clone
end