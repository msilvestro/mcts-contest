-- Class for the Pokémon moves.

require "contest/movedb"

Move = {}

function Move:new(name)
  local move = {
    name = name, -- name of the move.
    condition = MoveDB[name].condition, -- condition of the move.
    appeal = TypeDB[MoveDB[name].mtype].appeal, -- how much appeal the moves has, i.e. how many heart will make the user gain.
    jam = TypeDB[MoveDB[name].mtype].jam, -- how much the move jams the others, i.e. how many heart will remove from others.
    jamall = TypeDB[MoveDB[name].mtype].jamall, -- if the jam affects all other participants (true) or just the previous one.
    trigger = TypeDB[MoveDB[name].mtype].trigger, -- when the effect must be executed.
    effect = TypeDB[MoveDB[name].mtype].effect -- additional effect.
  }
  -- Set prototype.
  setmetatable(move, self)
  self.__index = self
  self.__tostring = self.tostring
  return move
end

function Move:tostring()
  --[[
  Format as a string, as follows:
  Air Slash   [Beautiful]   Appeal: ♥   Jam: ♥♥♥♥
  ]]
  local appeal, jam = "", ""
  for i = 1, self.appeal do appeal = appeal .. "♥" end -- print as many heart as the appeal number.
  for i = 1, self.jam do jam = jam .. "♥" end -- same for jam.
  return self.name .. "\t[" .. self.condition .. "]\tAppeal: " .. appeal .. "\tJam: " .. jam
end