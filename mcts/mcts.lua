-- A Monte Carlo Tree Search player with Upper Confidence Bounds for Trees player.

math.randomseed(os.time())

require "mcts/node"
require "contest/conteststate"

function MCTS(rootstate, itermax, rootplayer, verbose, parallel)
  -- Set the rootplayer to be the first to play. (The order in which the moves are chosen is ininfluent on the game.)
  local rootstate = rootstate:clone()
  rootstate.playerNames[1], rootstate.playerNames[rootplayer] = rootstate.playerNames[rootplayer], rootstate.playerNames[1]
  rootstate.contest.verbose = false
  -- Apply the MCTS to find the best move starting from the root state specified, making itermax simulations. Returns the best move.
  local rootnode = Node:new(nil, nil, rootstate)
  
  for i = 1, itermax do
    local node = rootnode
    local state = rootstate:clone()
    -- Select.
    --[[
    While the node is fully expanded (we already tried all possible moves) and non terminal (it has at least one child), that node is not the right candidate, so continue to search the optimal node.
		So the right candidate is a node that has still some moves to try or that has no children.
    ]]
    while table.isempty(node.untriedmoves) and not table.isempty(node.children) do
			node = node:UCTSelectChild()
      --node = node:randomlySelectChild()
			state:doMove(node.move)
		end
    -- Expand.
    -- Expand the selected node adding a child, then select that child node.
    if not table.isempty(node.untriedmoves) then
			local m = state:doRandomMove(node.untriedmoves)
			node = node:addChild(m, state)
		end
    -- Rollout.
    -- Start a simulation from this node until the end of the game.
    while not state:isEnded() do
			local m = state:doRandomMove() -- could be a lot better if we make a better choose of the next move, adding domain knowledge.
		end
    -- Backpropagate.
    -- Go from the selected node back to the root node and update each one, adding the new obtained score and a new visit.
    while node ~= nil do -- while we have not yet reached to root node...
      --node:update(state:getResult(1))
      --node:update(state:getTotHearts(1)/80)
      node:update((state:getTotHearts(1)+state.contest.pokemons[4].tothearts)/80)
			node = node.parent -- go back to the parent node.
		end
    
    if parallel and i % 100 == 0 then coroutine.yield(false, i, rootnode) end -- for running 100 iteration at a time.
  end
  
  -- Output some information about the tree - can be omitted
  --if verbose then print(rootnode:treeToString())
  --else print(rootnode:childrenToString()) end
  
  table.sort(rootnode.children, function (a,b) return a.visits > b.visits end)
  return rootnode.children[1].move, rootnode -- return the tree (represented by the root node) as secondary output.
end