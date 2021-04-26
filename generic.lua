-- Generic Lua functions.

function table.removeitem(tbl, item)
	-- Remove all occurencies of item in the table tbl and return the new table.
	local newtbl = {}
	for i, v in pairs(tbl) do
		if v ~= item then
			table.insert(newtbl, v)
		end
	end
	return newtbl
end

function table.isempty(tbl)
	-- Check if a table is empty (remember that in Lua {} == {} is false since they are different objects and points to different portions of memory)
	return (next(tbl) == nil)
end

function table.isin(tbl, item)
	-- Return true if item is inside the table.
	for _, v in pairs(tbl) do
		if v == item then return true end
	end
	return false
end

function table.haskey(tbl, key)
  -- Return true if the table has a certain key.
	for k, _ in pairs(tbl) do
		if k == key then return true end
	end
	return false
end

function table.issub(tbl, subtbl)
	-- Return true if the subtbl is a subtable of tbl (i.e. every item of subtbl in inside subtbl).
	for _, v in pairs(subtbl) do
		if not table.isin(tbl, v) then return false end
	end
	return true
end

function objclone(obj)
  -- Return a cloned object.
  if type(obj) ~= "table" then return obj end
  local clone = {}
  for i, v in pairs(obj) do
    clone[i] = objclone(v)
  end
  return clone
end

function isMouseIn(x, y, xr, yr, w, h)
  return x > xr and x < xr + w and y > yr and y < yr + h
end