require "contest/teams"
require "contest/conteststate"
require "contest/interface"
require "mcts/mcts"
require "treedisplay"

function love.load(arg)
  --[[ debug
  if arg[#arg] == "-debug" then require("mobdebug").start() end -- for debug reasons.
  -- /debug ]]
  love.graphics.setDefaultFilter("nearest")
  
  -- Variables to be changed.
  basetime = 1 -- time between actions.
  textfactor = 0.05 -- if there is a text to be displayed, textfactor is the time needed to read a letter of the text.
  steptime = 0.2 -- step time, time to wait for step animations: e.g. adding/removing hearts/stars.
  hint = true -- if there will be a hint or not for the human move.
  mainwidth = 800 -- width of the main part of the interface.
  linestodisplay = 33 -- maximum number of lines to display.
  
  humani = 1 -- index of the Pokémon human use in the contest.
  aistrength = {100, 100, 100, 100} -- the strength of the artificial intelligence.
  local team = buildBMTeam() -- the team to play with.
  -- The line above builds a team for a Master Beautiful constest just like in the DS game.
  -- Now, change humani and aistrength accordingly, making Speranza the human player and giving her more MCTS deep.
  for i = 1, 4 do
    if team[i].name == "Speranza" then
      humani = i
      aistrength[i] = 10000
    end
  end
  
  --[[ debug
  basetime = 0.01 -- time between actions.
  textfactor = 0.001 -- if there is a text to be displayed, textfactor is the time needed to read a letter of the text.
  steptime = 0.01
  aistrength = {1, 1, 1, 1}
  -- /debug ]]
  
  -- Variables not to be changed.
  
  math.randomseed(os.time())
  
  contest = ContestState:new("Beautiful", team, true) -- the contest to play with.
  
  turn = 1 -- number of the turn we are in.
  pokemoni = 0 -- index of the active Pokémon, 0 means we have to start the new turn (not yet an active Pokémon), range [1,4]
  pointer = 0 -- pointer that keeps track of where we are in the event table, 0 means we have yet to start (every turn is resetted).
  
  stars = 0 -- stars of the star meter.
  line = "" -- line to be displayed at the bottom of the screen, describes what is happening.
  ended = false -- the contest has ended or not?
  players = contest.playerNames -- table with the name of the participants.
  pokemons = {} -- table that associates participants names with hearts and status (see below).
  for i = 1, 4 do
    pokemons[players[i]] = {}
    pokemons[players[i]].hearts = 0
    pokemons[players[i]].status = 0 -- 0 = no status, 1 = protection (be it once in a turn or for all turn, graphically doens't make difference), 2 = nervous
    pokemons[players[i]].startled = false
  end
  
  timer = 0 -- timer to keep track of time passing, essential for animations.
  anitime = basetime -- animation time, how much to wait before performing next action.
  step = 0 -- how much step will be needed, e.g. 8 means we have to perform the stepaction 8 times (be it adding 8 hearts or removing them or whatsoever).
  stepaction = {} -- what action to perform after steptime passed, can be {"addhearts", dh = +1} -> add 1 heart.
  turnended = true -- true if the turn has already been displayed and you must now choose a move.
  
  human = {} -- contains info about human-controlled Pokémon (the one you will use).
  human.pokemon = contest.contest.pokemons[humani].name
  human.moves = objclone(contest.contest.pokemons[humani].moves)
  human.hint = {} -- will contain the hint moves and the decision game tree.
  moves = {} -- table of the moves to do in this turn, must be full to execute contest turn and then display the results.
  
  co = {} -- coroutines table.
  startThinking() -- load coroutines, so that the AI can start thinking.
  progress = {0, 0, 0, 0} -- how much iteration every player has done so far.
  total = 0 -- overall simulations to be done: sum all 4 player's ones if a hint must be given to human, else only sum all 3 AI player's ones.
  for i = 1, 4 do
    if hint or i ~= humani then
      total = total + aistrength[i]
    end
  end
  
  TreeDisplay:load(400, 15, 0, 0, {{183, 0, 44}, {94, 0, 183}, {0, 161, 183}, {30, 183, 0}}) -- load the tre display object.
  
  -- Graphical interface.
  font = love.graphics.newFont("font/pkmnrs.ttf", 26)
  font:setLineHeight(1.5)
  histfont = love.graphics.newFont("font/pkmnrs.ttf", 13)
  histfont:setLineHeight(1.5)
  height, width = love.window.getHeight(), love.window.getWidth()
  selectedmove = 1 -- what move is selected in the move selection screen.
  selection = false -- true if the user has already moved the arrow. If false, change the selected move to the hint one when decided.
  showtree = true -- must the tree be displayed?
  image = {
    background = love.graphics.newImage("img/bg.png"),
    stars = love.graphics.newImage("img/stars.png"),
    newstar = love.graphics.newImage("img/newstar.png"),
    pkmnbase = love.graphics.newImage("img/pokemon/pkmnbase.png"),
    pkmnchosen = love.graphics.newImage("img/pokemon/pkmnchosen.png"),
    pkmnheartred = love.graphics.newImage("img/pokemon/heartred.png"),
    pkmnheartblack = love.graphics.newImage("img/pokemon/heartblack.png"),
    pkmnprotect = love.graphics.newImage("img/pokemon/protect.png"),
    pkmnnervous = love.graphics.newImage("img/pokemon/nervous.png"),
    pkmnstartled = love.graphics.newImage("img/pokemon/startled.png"),
    sprite = {
      Betta = love.graphics.newImage("img/pokemon/sprite/Betta.png"),
      Speranza = love.graphics.newImage("img/pokemon/sprite/Speranza.png"),
      Tropica = love.graphics.newImage("img/pokemon/sprite/Tropica.png"),
      Trod = love.graphics.newImage("img/pokemon/sprite/Trod.png"),
      Macy = love.graphics.newImage("img/pokemon/sprite/Macy.png"),
      Plumy = love.graphics.newImage("img/pokemon/sprite/Plumy.png"),
    },
    movecondition = {
      Cool = love.graphics.newImage("img/move/chosencool.png"),
      Beautiful = love.graphics.newImage("img/move/chosenbeautiful.png"),
      Cute = love.graphics.newImage("img/move/chosencute.png"),
      Clever = love.graphics.newImage("img/move/chosenclever.png"),
      Tough = love.graphics.newImage("img/move/chosentough.png")
    },
    movehint = love.graphics.newImage("img/move/hint.png"),
    movearrow = love.graphics.newImage("img/move/arrow.png"),
    movedescription = love.graphics.newImage("img/description/bg.png"),
    selectedmovecondition = {
      Cool = love.graphics.newImage("img/description/cool.png"),
      Beautiful = love.graphics.newImage("img/description/beautiful.png"),
      Cute = love.graphics.newImage("img/description/cute.png"),
      Clever = love.graphics.newImage("img/description/clever.png"),
      Tough = love.graphics.newImage("img/description/tough.png")
    },
    selectedmoveheartred = love.graphics.newImage("img/description/heartred.png"),
    selectedmoveheartblack = love.graphics.newImage("img/description/heartblack.png"),
    descriptiontree = love.graphics.newImage("img/description/tree.png"),
    turndesk = love.graphics.newImage("img/turn/turndesk.png"),
    turndesk = love.graphics.newImage("img/turn/turndesk.png"),
    pkmnbaseplaying = love.graphics.newImage("img/turn/pkmnbaseplaying.png"),
    pkmnchosenplaying = love.graphics.newImage("img/turn/pkmnchosenplaying.png"),
    resultbase = love.graphics.newImage("img/result/base.png"),
    resultchosen = love.graphics.newImage("img/result/chosen.png"),
    onepercent = love.graphics.newImage("img/result/onepercent.png"),
    number = {
      love.graphics.newImage("img/result/1st.png"),
      love.graphics.newImage("img/result/2nd.png"),
      love.graphics.newImage("img/result/3rd.png"),
      love.graphics.newImage("img/result/4th.png")
    }
  }
  
  -- Result screen.
  resultstate = 0
end

function love.draw()
  love.graphics.setFont(font)
  love.graphics.draw(image.background, 0, 0)
  if not ended then -- if the contest is not yet ended...
    -- Calculate the percentage of the progress made by players.
    local percentage = 0
    for i = 1, 4 do
      if hint or i ~= humani then
        percentage = percentage + progress[i]
      end
    end
    percentage = math.floor(100*percentage/total)
    local percs = ""
    if not contest:isEnded() then percs =  " - Ragionando: sono al " .. percentage .. "%." end
    -- Print turn number.
    love.graphics.print("Esibizione n° " .. turn .. percs, 20, 20)
    -- Draw the star meter.
    love.graphics.draw(image.stars, 30, 57) -- background of the starmeter.
    local starpos = {{x = 37, y = 62}, {x = 58, y = 66}, {x = 78, y = 70}, {x = 98, y = 66}, {x = 119, y = 62}}
    for i = 1, stars do
      love.graphics.draw(image.newstar, starpos[i].x, starpos[i].y)
    end
    -- Print the Pokémon participants.
    for i = 1, 4 do
      -- Select the current Pokémon to display.
      local pokemon = pokemons[players[i]]
      -- Draw the background.
      local xi, yi = 82 + 164*(i-1), 114
      if players[i] == human.pokemon then
        if not turnended and i == pokemoni then love.graphics.draw(image.pkmnchosenplaying, xi-7, yi-7) end -- show selected Pokémon outlined, when playing the turn.
        love.graphics.draw(image.pkmnchosen, xi, yi)
      else
        if not turnended and i == pokemoni then love.graphics.draw(image.pkmnbaseplaying, xi-7, yi-7) end -- show selected Pokémon outlined, when playing the turn.
        love.graphics.draw(image.pkmnbase, xi, yi)
      end
      -- Draw the hearts.
      local heartpos = {
        {x = 35, y = 125}, {x = 98, y = 125},
        {x = 19, y = 123}, {x = 114, y = 123},
        {x = 28, y = 112}, {x = 105, y = 112},
        {x = 12, y = 110}, {x = 121, y = 110},
        {x = 37, y = 101}, {x = 96, y = 101},
        {x = 21, y = 99}, {x = 112, y = 99},
        {x = 30, y = 88}, {x = 103, y = 88},
        {x = 14, y = 86}, {x = 119, y = 86},
      }
      local hearts, heartimg = pokemon.hearts
      if hearts >= 0 then heartimg = image.pkmnheartred else heartimg = image.pkmnheartblack end
      for j = 1, math.abs(hearts) do
        love.graphics.draw(heartimg, xi + heartpos[j].x, yi + heartpos[j].y)
      end
      -- Draw the status.
      local xp, yp = xi + 54, yi + 93
      if pokemon.status == 1 then
        love.graphics.draw(image.pkmnprotect, xp, yp)
      elseif pokemon.status == 2 then
        love.graphics.draw(image.pkmnnervous, xp, yp)
      end
      -- Draw a scribble if the current Pokémon is being starled by another one.
      if pokemon.startled == true then love.graphics.draw(image.pkmnstartled, xp, yp) end
      -- Show Pokémon sprite.
      local sprite = image.sprite[players[i]]
      local xs, ys = xi + math.floor((144-sprite:getWidth())/2), yi + math.floor((118-sprite:getHeight())/2)
      love.graphics.draw(sprite, xs, ys)
    end
    
    -- If the turn display has endend show the move selection sceen.
    if turnended then
      for i = 1, 4 do
        local xm, ym = 51, 304 + 65*(i-1)
        -- Draw move background.
        love.graphics.draw(image.movecondition[human.moves[i].condition], xm, ym)
        -- Draw selected move border.
        if human.hint.move == i then
          love.graphics.draw(image.movehint, xm, ym)
        end
        -- Print move name.
        love.graphics.printf(moveName[human.moves[i].name], xm, ym + 23, 201, "center")
      end
      -- Draw the arrow that selects the move.
      love.graphics.draw(image.movearrow, 152, 285 + 65*(selectedmove-1))
      -- Draw the move description.
      local xd, yd = 296, 304
      love.graphics.draw(image.movedescription, xd, yd)
      if not showtree or not human.hint.tree then -- show move description, if no tree must be displayed or does not exist.
        love.graphics.draw(image.selectedmovecondition[human.moves[selectedmove].condition], xd + 31, yd + 27)
        love.graphics.draw(image.descriptiontree, xd + 380, yd + 19)
        local space = 35
        love.graphics.print("Fascino", xd + 31, yd + 86)
        for i = 1, human.moves[selectedmove].appeal do
          love.graphics.draw(image.selectedmoveheartred, xd + 130 + 25*(i-1), yd + 86)
        end
        love.graphics.print("Intralcio", xd + 31, yd + 86 + space)
        for i = 1, human.moves[selectedmove].jam do
          love.graphics.draw(image.selectedmoveheartblack, xd + 130 + 25*(i-1), yd + 86 + space)
        end
        love.graphics.printf(moveDescription[MoveDB[human.moves[selectedmove].name].mtype], xd + 31, yd + 87 + space*2, 444 - 31*2)
      else -- if the tree must be shown and there is a hint tree, display it
        TreeDisplay:draw(human.hint.tree, xd + 444/2, yd + 20)
      end
    else -- we are playing the turn.
      -- Print the line that shows what's happening.
      local xd, yd = 50, 304
      love.graphics.draw(image.turndesk, xd, yd)
      love.graphics.printf(line, xd+20, yd+20, image.turndesk:getWidth()-(xd+20), "center")
    end

else -- show results, since the contest is ended.
    local max = math.max(pokemons[players[1]].hearts, pokemons[players[2]].hearts, pokemons[players[3]].hearts, pokemons[players[4]].hearts) -- calculate maximum of hearts, to make a percentage (100% = better one's hearts)
    local xr, yr, space = 66, 88, 118
    for i = 1, 4 do
      -- Select current Pokémon.
      local pokemon = players[i]
      if i > 4-resultstate then
        -- Show the total hearts earned in the contest as percent over maximum.
        local percent = math.floor(pokemons[players[i]].hearts/max*100)
        -- Draw the bar.
        local barimg
        if pokemon == human.pokemon then barimg = image.resultchosen
        else barimg = image.resultbase end
        local xb, yb = xr, yr + space*(i-1)
        love.graphics.draw(barimg, xb, yb)
        -- Draw the one-per-cents of the bar.
        local xp, yp, pspace = xb + 78, yb + 7, 6
        for j = 1, percent do
          love.graphics.draw(image.onepercent, xp + pspace*(j-1), yp)
        end
        -- Draw the sprite of the Pokémon.
        local sprite = image.sprite[players[i]]
        love.graphics.draw(sprite, xb + math.floor((78-sprite:getWidth())/2), yb + math.floor((70-sprite:getHeight())/2))
        -- Draw the number.
        love.graphics.draw(image.number[i], xb-54/2, yb-56/2)
      end
    end
  end
  
  -- Display history.
  love.graphics.rectangle("fill", mainwidth, 0, width-mainwidth, 600)
  love.graphics.setColor{0, 0, 0}
  love.graphics.setFont(histfont)
  love.graphics.printf(getHistory(), mainwidth+10, 10, width-mainwidth-20)
  love.graphics.setColor{255, 255, 255}
end

function love.update(dt)
  -- Animate the screen.
  if not ended and not turnended then -- if the contest is not yet ended and the turn has not yet finished to be displayed...
    timer = timer + dt -- increment timer.
    if step == 0 and timer > anitime then -- step == 0 means no stepaction to be performed, timer > anitime means we must perform the next event.
      goNext() -- increment the pointer.
      timer = 0 -- reset the timer.
      local event = contest.contest.events[turn][pointer] -- select the current event, based on turn and pointer.
      local cat = event[1] -- category of the event.
      anitime = basetime -- default anitime is basetime, different if text is to be displayed.
      line = "" -- line to show on the bottom, default nothing and different if text.
      if cat == "turn" then
        -- A new Pokémon is about to appeal: increment current Pokémon index.
        pokemoni = pokemoni + 1
      elseif cat == "addstars" then
        -- Start the stepaction addstars to add the right amount of stars, one at a time.
        local ds = event.stars/math.abs(event.stars) -- get the sign of the number of stars to add, i.e. if positive get the increment +1, in negative -1.
        stars = stars + ds -- add +1/-1.
        step = math.abs(event.stars) - 1 -- the number of steps (in each step apply +1/-1) to animate.
        stepaction = {"addstars", ds = ds} -- set the stepaction.
      elseif cat == "resetstars" then
        -- Reset the stars, after reaching 5 stars and making Spectacular Talent.
        stars = 0
      elseif cat == "addhearts" then
        -- Start the stepaction addhearts to add the right amount of hearts, one at a time. Almost the same as addstars.
        local dh = event.hearts/math.abs(event.hearts) -- get +1 if we add hearts and -1 if we remove hearts.
        pokemons[players[pokemoni]].hearts = pokemons[players[pokemoni]].hearts + dh
        step = math.abs(event.hearts) - 1
        stepaction = {"addhearts", dh = dh}
      elseif cat == "removehearts" then
        -- Start the stepaction removehearts to remove the right amount of hearts on a specific Pokémon. Similar to addstars and addhearts, but every step is always -1.
        -- Note: in the original, the hearts are removed simultaneously to all Pokémons. Here it's left one at a time because I think shows more clearly what happens.
        pokemons[event.pokemon].hearts = pokemons[event.pokemon].hearts - 1
        pokemons[event.pokemon].startled = true
        step = event.hearts - 1
        stepaction = {"removehearts", dh = -1, pokemon = event.pokemon}
      elseif cat == "addprotect" then
        -- Add protection status.
        pokemons[players[pokemoni]].status = 1
      elseif cat == "removeprotect" then
        -- Remove protection status.
        pokemons[event.pokemon].status = 0
      elseif cat == "addnervous" then
        -- Add nervous status.
        -- Note: in the original, nervousness is applied simultaneously to all Pokémons. Same reason as above.
        pokemons[event.pokemon].status = 2
      elseif cat == "order" then
        -- Set the new order for the next turn, based on how well the Pokémons performed in the previous turn.
        players = event.pokemons
        -- Reset all.
        for i = 1, 4 do
          pokemons[players[i]].hearts = 0
          pokemons[players[i]].status = 0
        end
        pokemoni = 0
        pointer = 0
        turn = turn + 1
        turnended = true
        timer = 0
      elseif cat == "result" then
        -- Order Pokémons by result.
        players = event.pokemons
        for i = 1, 4 do
          pokemons[players[i]].hearts = event.hearts[i]
          pokemons[players[i]].status = 0 -- not necessary, just for cleaning up a bit.
        end
        ended = true                                          
      else
        -- Else, we must just display a line of text.
        line = eventToString(event)
        anitime = string.len(line)*textfactor
      end
    elseif step > 0 and timer > steptime then -- this means we must perform a stepaction.
      timer = 0
      -- Perform the correct stepaction.
      if stepaction[1] == "addhearts" then
        pokemons[players[pokemoni]].hearts = pokemons[players[pokemoni]].hearts + stepaction.dh
      elseif stepaction[1] == "removehearts" then
        pokemons[stepaction.pokemon].hearts = pokemons[stepaction.pokemon].hearts + stepaction.dh
        if step == 1 then pokemons[stepaction.pokemon].startled = false end
      elseif stepaction[1] == "addstars" then
        stars = stars + stepaction.ds
      end
      step = step - 1
    end
  end
  
  -- Choose the moves to do, until all the moves are chosen.
  if not contest:isEnded() then -- important! If the contest is ended, there is no reason to continue.
    for i = 1, 4 do
      if i ~= humani and not moves[i] then -- for each move not yet chosen that the AI must choose.
        local status, finished, res = coroutine.resume(co[i]) -- resume the coroutine that choose move.
        if finished then
          moves[i] = res
          progress[i] = aistrength[i] -- imporant! Else, if iteration is not a multiple of 100 progress will never reach 100%.
        else
          progress[i] = res
        end
      elseif hint and i == humani and not human.hint.move then -- add the hint for the human player and the tree to display.
        local status, finished, res, tree = coroutine.resume(co[i])
        if finished then
          human.hint.move, human.hint.tree = res, tree -- update the tree with new nodes.
          progress[i] = aistrength[i]
          if not selection then selectedmove = res end -- select the hint move, if the user has not yet changed move.
        else
          human.hint.tree = tree
          progress[i] = res
        end
      end
    end
  end
  -- Check if all moves have been chosen: if true, perform contest turn and start to display the results.
  if turnended then
    local completed = true
    for i = 1, 4 do if not moves[i] then completed = false end end -- check if all moves have been chosen.
    if completed then
      for i = 1, 4 do contest:doMove(moves[i]) end -- perform contest turn.
      moves = {} -- reset move table.
      human.hint = {} -- reset the hint for the human player.
      turnended = false -- start to display the results.
      selectedmove = 1 -- reset selected move and related stuff.
      selection = false
      showtree = true
      startThinking()
    end
  end
  
  -- Animate result screen, making participants appear one at a time.
  if ended and resultstate < 4 then
    timer = timer + dt
    if timer > 1 then
      timer = 0
      resultstate = resultstate + 1
    end
  end
end

function goNext()
  -- Update the pointer.
  pointer = pointer + 1
  local events = contest.contest.events[turn]
  if events[pointer][1] == "state" then -- skip state events.
    goNext()
  end
end

function love.keypressed(key)
  -- Get user input for move selection.
  if turnended then
    if key == "down" then
      selection = true
      if selectedmove < 4 then selectedmove = selectedmove + 1 end
    elseif key == "up" then
      selection = true
      if selectedmove > 1 then selectedmove = selectedmove - 1 end
    elseif key == "return" then
      moves[humani] = selectedmove
    elseif key == "tab" then
      showtree = not showtree
    end
  end
end

function love.mousepressed(x, y, button)
  --[[
  local xr, yr, w, h = 296+380, 304+19, 50, 30
  if isMouseIn(x, y, xr, yr, w, h) then
    showtree = not showtree
  end
  --]]
end

function startThinking()
  -- Starts the coroutines that makes the AI player choose a move.
  for i = 1, 4 do
    co[i] = coroutine.create(function () coroutine.yield(true, MCTS(contest, aistrength[i], i, false, true)) end)
  end
  progress = {0, 0, 0, 0}
end

function getHistory()
  -- Print all most recent history.
  local s = "-- Cronologia --\n"
  local starti, events -- starti means where to start from to read the history, events means what turn the events must be showed from.
  if turnended and turn > 1 then -- if we are in the move selection screen, show all previous turn events.
    events = contest.contest.events[turn-1]
    starti = #events
  else -- if we are displaying whats happening, show just what happened so far.
    events = contest.contest.events[turn]
    starti = pointer
  end
  for i = starti, 1, -1 do
    local event = events[i]
    local newline = ""
    if event[1] ~= "state" and event[1] ~= "order" and event[1] ~= "result" then -- skip state, order and result stuff.
      newline = eventToString(event) .. "\n"
    else
      newline = ""
    end
    local acwidth, lines = font:getWrap(s .. newline, 280) -- get how much lines the text would require, if exceed linestodisplay stop adding events.
    if lines < linestodisplay then
      s = s .. newline
    else return s end
  end
  return s
end