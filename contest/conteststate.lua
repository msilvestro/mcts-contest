--[[
The problem is that contests are not completely sequential: in fact, the choice and actuation of moves is simultaneous.
This class is made to treat contest as completely sequential games: in fact, you can just say to ContestState (CS) to make a player perform a move, than CS deals with queueing all the moves and, when it has four of them, it executes a turn.
So thanks to this class we trasform a mixed sequential-simultaneous game into a full sequential game, that we can use to make a game tree.
]]

require "generic"
require "contest/contest"

ContestState = {}

function ContestState:new(condition, pokemons, verbose)
  local state = {
    contest = Contest:new(condition, pokemons, verbose), -- the contest this state refers to.
    player = 0, -- the player number that must choose the move to do.
    playerNames = {}, -- the name of all the players, that associate a player number (above) with its name in the game.
    queue = {} -- stores all the move already chosen by players. When it has 4 elements, the contest must perform a turn.
  }
  -- Add the name of the players. The number of the player is associated to the starting order of it in the contest.
  for i = 1, 4 do
    state.playerNames[i] = pokemons[i].name
  end
  -- Set prototype.
  setmetatable(state, self)
  self.__index = self
  self.__tostring = self.tostring
  return state
end

function ContestState:clone()
  -- Clone this state.
  local clone = ContestState:new(self.contest.condition, self.contest.pokemons)
  clone.contest = self.contest:clone()
  clone.player = 0
  clone.playerNames = objclone(self.playerNames)
  clone.queue = objclone(self.queue)
  return clone
end

function ContestState:tostring()
  return self.contest:tostring()
end

function ContestState:doMove(move, randomoutcomes)
  -- Make a move in the contest.
  self.player = self.player + 1 -- the player to move is the next one.
  if self.player == 5 then self.player = 1 end -- if the last player was 4, then reset to 1.
  self.queue[self.playerNames[self.player]] = move -- add to the move queue this move.
  if randomoutcomes then self.contest.randomoutcomes[self.playerNames[self.player]] = randomoutcomes end -- if there is a random chioce, add to the global table for that specific player.
  -- If player 4 has just chosen its move, all is ready to perform a turn.
  if self.player == 4 then
    self.contest:doTurn(self.queue)
    self.queue = {} -- reset the move queue.
  end
end

function ContestState:doRandomMove(moves)
  -- Make a random moves between the given ones (or all the possible ones, if not specified).
	local mv = moves or {1, 2, 3, 4}
	local rndmv = mv[math.random(#mv)]
	self:doMove(rndmv)
	return rndmv
end

function ContestState:doAlmostRandomMove()
  -- Make a random moves between the given ones (or all the possible ones, if not specified).
	local mv = {}
  if self.contest.turn < 5 then
    local pokemon
    for i = 1, 4 do
      local player = self.player+1
      if player == 5 then player = 1 end
      if self.playerNames[player] == self.contest.pokemons[i].name then pokemon = self.contest.pokemons[i] end
    end
    for i = 1, 4 do
      if MoveDB[pokemon.moves[i].name].mtype ~= "80suicide" then
        table.insert(mv, i)
      end
    end
  else
    mv = {1, 2, 3, 4}
  end
	local rndmv = mv[math.random(#mv)]
	self:doMove(rndmv)
	return rndmv
end

function ContestState:getResult(player)
  -- Get the result of the contest.
  assert(self:isEnded(), "The contest is not yet ended, you can't have the result.")
  -- If a player is specified, return 1 on win and 0 on defeat.
  if player then return (self.playerNames[player] == self.contest.pokemons[1].name) and 1 or 0
  -- Else the same as the contest class.
  else return self.contest:getResult() end
end

function ContestState:getTotHearts(player)
  -- Get the total hearts of a player.
  assert(self:isEnded(), "The contest is not yet ended, you can't have the result.")  local tothearts = {}
  for i = 1, 4 do
    tothearts[self.contest.pokemons[i].name] = self.contest.pokemons[i].tothearts
  end
  return tothearts[self.playerNames[player]]
end

function ContestState:isEnded()
  return self.contest:isEnded()
end

function ContestState:printResult()
  self.contest:printResult()
end

function ContestState:printEvents(turn)
  self.contest:printEvents(turn)
end

function ContestState:getMoves()
  -- Get the possible moves: all 4 if the contest is still going on, nothing if it's ended.
  -- Note: could be made more general if we accept that a Pokémon can have less than 4 moves (possible, very rare).
  if not self:isEnded() then
    return {1, 2, 3, 4}
  else return {} end
end

function ContestState:fixNextOrder(neworder)
  -- Fix the order of the next turn.
  self.contest.randomoutcomes.fixedord = {}
  for i = 1, 4 do
    self.contest.randomoutcomes.fixedord[neworder[i]] = 10^(4-i)
  end
end

function ContestState:getOrderString()
  local s, reverseName = "", {}
  for i = 1, 4 do reverseName[self.playerNames[i]] = i end
  for i = 1, 4 do s = s .. tostring(reverseName[self.contest.pokemons[i].name]) end
  return s
end