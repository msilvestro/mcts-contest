-- Database that contains every type of move and every move you can use in the game.

-- Type defines the effect of the move in the game.
TypeDB = {
  -- Quite an appealing move.
  ["40"] = {appeal = 4, jam = 0},
  -- Shows off the Pokémon's appeal about as well as the moved used just before it. 
  ["10copy"] = {appeal = 1, jam = 0, trigger = "appeal",
    effect = function(move, contest, pi)
      local i = contest:getLastPokemonToAppeal(pi) -- get last Pokémon that made an appeal.
      local hearts
      if i == 0 then -- there was not an appeal before the active Pokémon.
        hearts = 1
        contest:addEvent{"addhearts", hearts = hearts}
        -- TODO does it says something here?
      else -- same appeal as the previous Pokémon + 1.
        hearts = math.max(contest.pokemons[i].hearts + 1, 1) -- to avoid getting negative hearts.
        contest:addEvent{"addhearts", hearts = hearts}
        contest:addEvent{"copy"}
      end
      return hearts
    end
  },
  -- Prevents the user from being startled until the turn ends. 
  ["10protectall"] = {appeal = 1, jam = 0, trigger = "end",
    effect = function(move, contest, pi)
      local pokemon = contest.pokemons[pi]
      contest:addEvent{"protectall"} -- "Non si preoccupa più degli altri Pokémon!"
      pokemon.protection = 2
      contest:addEvent{"addprotect"}
    end
  },
  -- Effectiveness varies depending on when it is used. 
  ["10random"] = {appeal = 1, jam = 0, trigger = "appeal",
    effect = function(move, contest, pi)
      -- Randomly chooses the hearts to give between 1, 2, 4, 6, 8!
      local random, randstar = math.random(5), {1, 2, 4, 6, 8} -- TODO give different probabilities
      local pokemon = contest.pokemons[pi].name
      if contest.randomoutcomes[pokemon] then random = contest.randomoutcomes[pokemon] end
      contest:addEvent{"addhearts", hearts = randstar[random]}
      contest:addEvent{"rating", rating = random, pokemon = pokemon}
      return randstar[random]
    end
  },
  -- Works better the more the crowd is excited.
  ["10star"] = {appeal = 1, jam = 0, trigger = "appeal",
    effect = function(move, contest, pi)
      local hearts
      -- Add hearts depending on how much stars: 0s -> 1, 1s -> 2, 2s -> 3, 3s -> 5, 4s -> 6.
      if contest.stars < 3 then hearts = 1 + contest.stars
      else hearts = 2 + contest.stars end
      contest:addEvent{"addhearts", hearts = hearts}
      contest:addEvent{"rating", rating = contest.stars + 1, pokemon = contest.pokemons[pi].name}
      return hearts
    end
  },
  ["14"] = {appeal = 1, jam = 4},
  -- Works great if the user goes first this turn. 
  ["20betterfirst"] = {appeal = 2, jam = 0, trigger = "appeal",
    effect = function(move, contest, pi)
      local hearts
      if pi == 1 then
        hearts = 6
        contest:addEvent{"first", pokemon = contest.pokemons[pi].name} -- "<Pokémon> si era già fatto notare e ora ha superato se stesso!"
      else
        hearts = 2
      end
      contest:addEvent{"addhearts", hearts = hearts}
      return hearts
    end
  },
  -- Works great if the user goes last this turn.
  ["20betterlast"] = {appeal = 2, jam = 0, trigger = "appeal",
    effect = function(move, contest, pi)
      local hearts
      if pi == 4 then
        hearts = 6
        contest:addEvent{"last", pokemon = contest.pokemons[pi].name} -- "<Pokémon> non si stava distinguendo molto, ma ce l'ha messa tutta!"
      else
        hearts = 2
      end
      contest:addEvent{"addhearts", hearts = hearts}
      return hearts
    end
  },
  -- Makes the remaining Pokémon nervous. 
  ["20nervous"] = {appeal = 2, jam = 0, trigger = "end",
    effect = function(move, contest, pi)
      contest:addEvent{"unnerve"} -- "Prova a far innervosire i Pokémon che non si sono ancora esibiti!"
      local success = false -- true if at least one of the remaining Pokémons becomes nervous.
      for i = pi+1, 4 do
        local foll = contest.pokemons[i] -- the current following Pokémon analyzed.
        if foll.cantmove == 0 then -- if the Pokémon is unable to move, can't be made nervous.
          local makenervous
          if contest.randomoutcomes[contest.pokemons[pi].name] then
            makenervous = contest.randomoutcomes[contest.pokemons[pi].name][i-pi] -- if the random outcome has already been chosen, set it.
          else
            local rnd = math.random()
            makenervous = (rnd <= 0.25) -- 25% of probability that a Pokémon becomes nervous.
          end
          if makenervous then
            foll.nervous = true
            contest:addEvent{"addnervous", pokemon = foll.name}
            success = true -- at least one Pokémon became nervous!
          end
        end
      end
      if not success then contest:addEvent{"miss"} end -- "Ma non ce la fa!"
    end
  },
  -- Prevents the user from being startled one time this turn.
  ["20protectonce"] = {appeal = 2, jam = 0, trigger = "start",
    effect = function(move, contest, pi)
      local pokemon = contest.pokemons[pi]
      contest:addEvent{"protectonce"}
      pokemon.protection = 1
      contest:addEvent{"addprotect"}
    end
  },
  -- Works well if it is the same type as the move used by the last Pokémon. 
  ["20sametype"] = {appeal = 2, jam = 0, trigger = "appeal",
    effect = function(move, contest, pi)
      local hearts
      local i = contest:getLastPokemonToAppeal(pi) -- get last Pokémon that made an appeal.
      if i == 0 then -- if i is null, it means there are no previous Pokémon that has made an appeal, so return the base appeal.
        hearts = 2
      else -- if i > 0, compare that previous Pokémon move condition and active Pokémon move condition: if is the same, +6.
        local prevcond = MoveDB[contest.pokemons[i].prevmove].condition
        if prevcond == move.condition then hearts = 6
        else hearts = 2 end
      end
      contest:addEvent{"addhearts", hearts = hearts}
      if hearts == 6 then contest:addEvent{"sametype"} end
      return hearts
    end
  },
  -- Badly startles all Pokémon that successfully showed their appeal. 
  ["21half"] = {appeal = 2, jam = 1, jamall = true, trigger = "jam",
    effect = function(move, contest, pi)
      local target = contest.pokemons[pi]
      if target.hearts > 1 then
        return math.floor(target.hearts/2) -- remove half the hearts (floor rounded).
      else
        return 1
      end
    end
  },
  -- Startles all of the Pokémon to act before the user. 
  ["22all"] = {appeal = 2, jam = 2, jamall = true},
  -- Startles the last Pokémon to act before the user. 
  ["23"] = {appeal = 2, jam = 3},
  -- Temporarily stops the crowd from growing excited. 
  ["30dampen"] = {appeal = 3, jam = 0,  trigger = "end",
    effect = function(move, contest, pi)
      local pokemon = contest.pokemons[pi]
      contest.dampen = pokemon.name
      contest:addEvent{"onlywatches", condition = contest.condition} -- "Cattura gli sguardi del pubblico in modo che non presti attenzione alla <virtù> degli altri Pokémon!"
    end
  },
  -- Excites the audience a lot if used first. 
  ["30excitefirst"] = {appeal = 3, jam = 0, trigger = "stars",
    effect = function(move, contest, pi)
      local pokemon = contest.pokemons[pi]
      if pi == 1 then
        contest:addEvent{"veryexcited", pokemon = pokemon.name} -- "<Pokémon> si mette in mostra e il pubblico l'acclama!"
        return 2
      else
        contest:addEvent{"excited", condition = contest.condition, pokemon = pokemon.name} -- "Il pubblico è entusiasta della <virtù> di <Pokémon>!"
        return 1
      end
    end
  },
  -- Causes the user to move earlier on the next turn.
  ["30nextfirst"] = {appeal = 3, jam = 0, trigger = "end",
    effect = function(move, contest, pi)
      -- Add a priority to the Pokémon, multiple of 1000, higher if the Pokémon acted first.
      -- In fact, if all 4 Pokémons used a move likes this, the order one the next turn is the same.
      contest.fixedord[contest.pokemons[pi].name] = 1000*(5-pi)
      contest:addEvent{"nextfirst"} -- "Si fa avanti per esibirsi prima!"
    end
  },
  -- Causes the user to move later on the next turn.
  ["30nextlast"] = {appeal = 3, jam = 0, trigger = "end",
    effect = function(move, contest, pi)
      contest.fixedord[contest.pokemons[pi].name] = -1000*(5-pi)
      contest:addEvent{"nextlast"} -- "Ha ceduto il posto per ritardare la sua esibizione!"
    end
  },
  -- An appealing move that can be used repeatedly without boring the audience. 
  ["30noboring"] = {appeal = 3, jam = 0, trigger = "repeat"},
  -- Affected by how well the previous Pokémon's move went.
  ["30prev"] = {appeal = 3, jam = 0, trigger = "appeal",
    effect = function(move, contest, pi)
      local hearts
      local i = contest:getLastPokemonToAppeal(pi) -- get last Pokémon that made an appeal.
      if i == 0 then hearts = move.appeal
      else
        local prev = contest.pokemons[i]
        -- The hearts depends on how well went the previous Pokémon appeal: if better active doubles, if not active gets nothing.
        if prev.hearts < 3 then hearts = 2*move.appeal
        elseif prev.hearts == 3 then hearts = move.appeal
        else hearts = 0 end
      end
      if hearts ~= 0 then contest:addEvent{"addhearts", hearts = hearts} end
      contest:addEvent{"howwell", rating = hearts/move.appeal} -- Non ha fatto meglio del Pokémon precedente... / - / Si fa notare più del Pokémon precedente!
      return hearts
    end
  },
  -- Startles all other Pokémon. User cannot act in the next turn. 
  ["44cantmove"] = {appeal = 4, jam = 4, jamall = true, trigger = "end",
    effect = function(move, contest, pi)
      local pokemon = contest.pokemons[pi]
      pokemon.cantmove = 2
      -- It doesn't say anything!
    end
  },
  -- A very appealing move, but after using this move, the user is more easily startled. 
  ["60easystartle"] = {appeal = 6, jam = 0, trigger = "end",
    effect = function(move, contest, pi)
      contest.pokemons[pi].easystartle = true
      contest:addEvent{"easystartle"} -- "Presterà più attenzione alle esibizioni dei Pokémon successivi!"
    end
  },
  -- A move of huge appeal, but using it prevents the user from taking further contest moves. 
  ["80suicide"] = {appeal = 8, jam = 0, trigger = "end",
    effect = function(move, contest, pi)
      local pokemon = contest.pokemons[pi]
      pokemon.cantmove = 3
      contest:addEvent{"suicide", pokemon = pokemon.name} -- "<Pokémon> non può esibirsi dopo una tale esibizione!"
    end
  }
}
-- 16 types so far.

-- Moves are defined by the condition and the type (see above).
MoveDB = {
  ["Aqua Tail"] = {condition = "Beautiful", mtype = "40"},
  ["Dazzling Gleam"] = {condition = "Beautiful", mtype = "40"},
  ["Return"] = {condition = "Cute", mtype = "40"},
  ["Tackle"] = {condition = "Tough", mtype = "40"},
  
  ["Leech Life"] = {condition = "Clever", mtype = "10copy"},
  ["Copycat"] = {condition = "Cute", mtype = "10copy"},
  ["Mimic"] = {condition = "Cute", mtype = "10copy"},
  
  ["Heal Bell"] = {condition = "Beautiful", mtype = "10protectall"},
  ["Rest"] = {condition = "Cute", mtype = "10protectall"},
  
  ["Acupressure"] = {condition = "Tough", mtype = "10random"},
  ["Synthesis"] = {condition = "Clever", mtype = "10random"},
  
  ["Hydro Pump"] = {condition = "Beautiful", mtype = "10star"},
  ["Rain Dance"] = {condition = "Beautiful", mtype = "10star"},
  ["Sunny Day"] = {condition = "Beautiful", mtype = "10star"},
    
  ["Air Slash"] = {condition = "Beautiful", mtype = "14"},
  ["Body Slam"] = {condition = "Tough", mtype = "14"},
  
  ["Swift"] = {condition = "Cool", mtype = "20betterfirst"},
  ["Disarming Voice"] = {condition = "Cute", mtype = "20betterfirst"},
  
  ["Counter"] = {condition = "Tough", mtype = "20betterlast"},
  ["Mirror Coat"] = {condition = "Beautiful", mtype = "20betterlast"},
  
  ["Attract"] = {condition = "Cute", mtype = "20nervous"},
  
  ["Defense Curl"] = {condition = "Cute", mtype = "20protectonce"},
  ["Dive"] = {condition = "Beautiful", mtype = "20protectonce"},
  ["Protect"] = {condition = "Cute", mtype = "20protectonce"},
  ["Safeguard"] = {condition = "Beautiful", mtype = "20protectonce"},
  
  ["Round"] = {condition = "Beautiful", mtype = "20sametype"},
  
  ["Hail"] = {condition = "Beautiful", mtype = "21half"},
  
  ["Discharge"] = {condition = "Beautiful", mtype = "22all"},
  ["Hyper Voice"] = {condition = "Cool", mtype = "22all"},
  ["Petal Blizzard"] = {condition = "Beautiful", mtype = "22all"},
  ["Surf"] = {condition = "Beautiful", mtype = "22all"},
  
  ["Bubble Beam"] = {condition = "Beautiful", mtype = "23"},
  
  ["Whirlpool"] = {condition = "Beautiful", mtype = "30dampen"},
  
  ["Grassy Terrain"] = {condition = "Beautiful", mtype = "30excitefirst"},
  ["Electro Ball"] = {condition = "Cool", mtype = "30excitefirst"},
  
  ["Agility"] = {condition = "Cool", mtype = "30nextfirst"},
  
  ["Bide"] = {condition = "Cool", mtype = "30nextlast"},
  
  ["Sonic Boom"] = {condition = "Cool", mtype = "30noboring"},
  ["Weather Ball"] = {condition = "Beautiful", mtype = "30noboring"},
  
  ["Solar Beam"] = {condition = "Cool", mtype = "30prev"},
  
  ["Hyper Beam"] = {condition = "Cool", mtype = "44cantmove"},
  ["Teeter Dance"] = {condition = "Cute", mtype = "44cantmove"},
  
  ["Petal Dance"] = {condition = "Beautiful", mtype = "60easystartle"},
  
  ["Destiny Bond"] = {condition = "Clever", mtype = "80suicide"},
  ["Explosion"] = {condition = "Beautiful", mtype = "80suicide"},
  ["Self Destruct"] = {condition = "Beautiful", mtype = "80suicide"},
}