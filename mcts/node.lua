-- Describe a node of the game tree.

require "generic"

Node = {}

function Node:new(move, parent, state, player)
	-- Make a new node in the game tree.
	local node = {
		move = move, -- the move that got us into this state, nil for the root node.
		parent = parent, -- the parent node, nil for the root node.
		children = {}, -- the child nodes.
		wins = 0, -- number of wins of all the games played from this node.
		visits = 0, -- number of times the node was visited.
		untriedmoves = state:getMoves(), -- all the moves not yet tried, they will be the future nodes.
    player = state.player -- the player that just made the move.
	}
	-- Set prototype.
	setmetatable(node, self)
	self.__index = self
	self.__tostring = self.tostring
	return node
end

function Node:selectChild(move)
	-- Select the child corresponding to a certain move.
  for _, child in pairs(self.children) do
    if child.move == move then return child end
  end
end

function Node:randomlySelectChild()
  -- Select a uniformly random child.
  return self.children[math.random(#self.children)]
end

function Node:UCTSelectChild()
  --  Use the UCB1 formula to select a child node. Often a constant UCTK is applied so we have lambda c: c.wins/c.visits + UCTK * sqrt(2*log(self.visits)/c.visits to vary the amount of exploration versus exploitation.
  -- local UCT = function (c) return c.wins/c.visits + math.sqrt(2*math.log(self.visits)/c.visits) end
  local UCT = function (c) return c.wins/c.visits + math.sqrt(2*math.log(self.visits)/c.visits) end
  table.sort(self.children, function (a,b) return UCT(a) > UCT(b) end)
  return self.children[1]
end

function Node:addChild(m, s)
  -- Remove m from untriedMoves and add a new child node for this move. Return the added child node.
	local n = Node:new(m, self, s)
  self.untriedmoves = table.removeitem(self.untriedmoves, m)
	table.insert(self.children, n)
	return n
end

function Node:update(result)
  -- Update this node: one additional visit and add the result to the total.
  self.visits = self.visits + 1
  self.wins = self.wins + result
end

function Node:treeToString(indent)
  -- Print the tree from the actual node.
	local indent = indent or 0
	local s = self.indentString(indent) .. self:tostring()
	for _, c in pairs(self.children) do
		s = s .. c:treeToString(indent+1)
	end
	return s
end

function Node.indentString(indent)
  -- Indent the string with '|' symbols.
	local s = "\n"
	for i = 1, indent do
		s = s .. "| "
	end
	return s
end

function Node:childrenToString()
  -- Print all child nodes of a node.
	local s = ""
	for _, c in pairs(self.children) do
		s = s .. tostring(c) .. "\t"
	end
	return s
end


function Node:tostring()
  return "[P: " .. tostring(self.player) .. ", M: " .. tostring(self.move) .. ", W/V: " .. self.wins .. "/" .. self.visits .. "]"
end