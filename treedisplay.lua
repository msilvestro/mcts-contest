-- This displays a tree in a defined area.

TreeDisplay = {}

function TreeDisplay:load(width, levelheight, marginleft, margintop, colors)
  -- The display area is limited only horizontally by width.
  self.levelheight = levelheight or 50 -- how much space there should be between tree levels.
  self.colors = colors or {{255, 255, 255}, {255, 255, 255}, {255, 255, 255}, {255, 255, 255}} -- colors of the four groups of the tree defined by first branches.
  local marginleft, margintop = marginleft or 0, margintop or 0 -- margin from left and top.
  self.x, self.y = marginleft + width/2, margintop -- coordinates of the point representing the root node.
  self.amp = width*3/4 -- amplitude of the branches of a node, i.e. how much space from far left child node to far right child node.
end

function TreeDisplay:draw(node, x, y, amp, color)
  -- Draw the tree from the node provided.
  -- Remember: x and y are the coordinates of the node.
  local x, y = x or self.x, y or self.y
  local amp = amp or self.amp
  local nc = #node.children -- number of children, supposed to be from 1 to 4.
  for i = 1, nc do
    local child = node.children[i] -- select the i-th child node.
    if not node.parent then
      i = child.move
      color = self.colors[i] -- if we are displaying a child of the root node, select the right color from the table.
    end
    love.graphics.setColor(color) -- set the right color.
    local nx, ny = x-amp/2+(i-1)*amp/(nc-1), y+self.levelheight -- coordinates of the point representing the child node.
    love.graphics.line{x, y, nx, ny} -- draw the branch that connects the two nodes.
    self:draw(child, nx, ny, amp/4, color) -- draw the rest of the tree, from the child node onwards.
  end
  if not node.parent then love.graphics.setColor(255, 255, 255) end -- set white color for the root node.
  love.graphics.point(x, y) -- draw the point representing the current node.
end