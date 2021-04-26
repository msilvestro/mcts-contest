-- The interface, as of now, is only in Italian since I don't have access to a English versione of ORAS.

conditionName = {Cool = "Classe", Beautiful = "Bellezza", Cute = "Grazia", Clever = "Acume", Tough = "Grinta"}
conditionArticleName = {Cool = "la Classe", Beautiful = "la Bellezza", Cute = "la Grazia", Clever = "l'Acume", Tough = "la Grinta"}
function fascinatedQuote(condition, pokemon)
  if condition == "Cool" then
    return "La Classe di " .. pokemon .. " è incontenibile!"
  elseif condition == "Beautiful" then
    return "La Bellezza di " .. pokemon .. " è quasi accecante!"
  elseif condition == "Cute" then
    return "La Grazia di " .. pokemon .. " esplode sul palco!"
  elseif condition == "Clever" then
    return pokemon .. " fa sfoggio di un Acume esemplare!"
  elseif condition == "Tough" then
    return pokemon .. " scatena la sua Grinta impetuosa!"
  end
end
moveName = {
  ["Acupressure"] = "Acupressione",
  ["Agility"] = "Agilità",
  ["Air Slash"] = "Eterelama",
  ["Aqua Tail"] = "Idrondata",
  ["Attract"] = "Attrazione",
  ["Bide"] = "Pazienza",
  ["Body Slam"] = "Corposcontro",
  ["Bubble Beam"] = "Bollaraggio",
  ["Copycat"] = "Copione",
  ["Counter"] = "Contrattacco",
  ["Dazzling Gleam"] = "Magibrillio",
  ["Defense Curl"] = "Ricciolscudo",
  ["Destiny Bond"] = "Destinobbligato",
  ["Disarming Voice"] = "Incantavoce",
  ["Discharge"] = "Scarica",
  ["Dive"] = "Sub",
  ["Electro Ball"] = "Energisfera",
  ["Explosion"] = "Esplosione",
  ["Grassy Terrain"] = "Campo Erboso",
  ["Hail"] = "Grandine",
  ["Heal Bell"] = "Rintoccasana",
  ["Hydro Pump"] = "Idropompa",
  ["Hyper Voice"] = "Granvoce",
  ["Hyper Beam"] = "Iper Raggio",
  ["Leech Life"] = "Sanguisuga",
  ["Mimic"] = "Mimica",
  ["Mirror Coat"] = "Specchiovelo",
  ["Petal Blizzard"] = "Fiortempesta",
  ["Petal Dance"] = "Petalodanza",
  ["Protect"] = "Protezione",
  ["Rain Dance"] = "Pioggiadanza",
  ["Rest"] = "Riposo", 
  ["Return"] = "Ritorno",
  ["Round"] = "Coro",
  ["Safeguard"] = "Salvaguardia",
  ["Self Destruct"] = "Autodistruzione",
  ["Solar Beam"] = "Solarraggio",
  ["Sonic Boom"] = "Sonicboom",
  ["Sunny Day"] = "Giornodisole",
  ["Surf"] = "Surf",
  ["Swift"] = "Comete",
  ["Synthesis"] = "Sintesi",
  ["Tackle"] = "Azione",
  ["Teeter Dance"] = "Strampadanza",
  ["Weather Ball"] = "Palla Clima",
  ["Whirlpool"] = "Mulinello"
}
moveDescription = {
  ["40"] = "Ha un grande effetto sul pubblico.",
  ["10copy"] = "Ha un effetto sul pubblico identico a quello della mossa usata da chi precede.",
  ["10protectall"] = "Chi la usa non si spaventa per il resto dell'esibizione.",
  ["10random"] = "L'effetto sul pubblico dipende dal momento in cui viene eseguita.",
  ["10star"] = "Ha un effetto maggiore se il pubblico è in preda all'entusiasmo.",
  ["14"] = "Spaventa terribilmente il Pokémon che si è esibito prima di chi la usa.",
  ["20betterfirst"] = "Ha un enorme effetto se viene eseguita per prima nell'esibizione.",
  ["20betterlast"] = "Ha un enorme effetto se viene eseguita per ultima nell'esibizione.",
  ["20nervous"] = "Innervosisce tutti i Pokémon che si esibiscono dopo chi la usa.",
  ["20protectonce"] = "Chi la usa evita per una volta di spaventarsi durante l'esibizione.",
  ["20sametype"] = "Ha un effetto maggiore se è dello stesso tipo di quella precedente.",
  ["21half"] = "Spaventa terribilmente i Pokémon che si sono esibiti con successo.",
  ["22all"] = "Spaventa tutti i Pokémon che si sono già esibiti.",
  ["23"] = "Spaventa il Pokémon che si è esibito prima di chi la usa.",
  ["30dampen"] = "Smorza temporaneamente l'entusiasmo del pubblico.",
  ["30excitefirst"] = "Aumenta di molto l'entusiasmo del pubblico se viene eseguita per prima nell'esibizione.",
  ["30nextfirst"] = "Chi la usa agirà più presto nell'esibizione successiva.",
  ["30nextlast"] = "Chi la usa agirà più tardi nell'esibizione successiva.",
  ["30noboring"] = "Può essere usata più volte di seguito senza annoiare il pubblico.",
  ["30prev"] = "L'effetto sul pubblico è influenzato dall'esibizione precedente.",
  ["44cantmove"] = "Inibisce gli altri Pokémon, ma chi la usa non può agire nell'esibizione successiva.",
  ["60easystartle"] = "Ha un grande effetto sul pubblico, ma chi la usa tenderà a spaventarsi più facilmente.",
  ["80suicide"] = "Ha un enorme effetto, ma impedisce l'uso di altre mosse fino al termine della gara."
}

function eventToString(event)
  local s = "" -- string to output.
  local cat = event[1] -- category of the event.
  if cat == "appeal" then
    s = event.pokemon .. " si esibisce con " .. moveName[event.move] .. "!"
  elseif cat == "addhearts" then
    if event.hearts > 0 then s = "+" .. event.hearts .. "h"
    else s = event.hearts .. "h" end
  elseif cat == "addstars" then
    if event.stars > 0 then s = "+" .. event.stars .. "s"
    else s = event.stars .. "s" end
  elseif cat == "cancombo" then
    s = "Il pubblico si aspetta molto dalla prossima combinazione!"
  elseif cat == "combo" then
    s = "Il pubblico ha apprezzato molto la combinazione con l'esibizione precedente!"
  elseif cat == "startle" then
    s = "Cerca di spaventare gli avversari!"
  elseif cat == "removehearts" then -- not very explicative! better change name
    s = "-" .. event.hearts .. "h x " .. event.pokemon
  elseif cat == "addprotect" then
    s = "+protezione"
  elseif cat == "removeprotect" then
    s = "-protezione x " .. event.pokemon
  elseif cat == "addnervous" then
    s = "+nervoso x " .. event.pokemon
  elseif cat == "repeated" then
    s = event.pokemon .. " delude il pubblico ripetendo la stessa esibizione!"
  elseif cat == "excited" then
    s = "Il pubblico è entusiasta del" .. conditionArticleName[event.condition] .. " di " .. event.pokemon .. "!"
  elseif cat == "dampen1" then
    s = "Il pubblico continua a guardare " .. event.dampener .. "!"
  elseif cat == "dampen2" then
    s = "Nessuno presta attenzione al" .. conditionArticleName[event.condition] .. " di " .. event.pokemon .. "..."
  elseif cat == "discontent" then
    s = "Il pubblico non sembra colpito dal" .. conditionArticleName[event.condition] .. " di " .. event.pokemon .. "..."
  elseif cat == "fascinated1" then
    s = "Il pubblico è incantato dal" .. conditionArticleName[event.condition] .. " di " .. event.pokemon .. "!"
  elseif cat == "fascinated2" then
    s = fascinatedQuote(event.condition, event.pokemon)
  elseif cat == "fascinated3" then
    s = "L'Esibizione Live ha lasciato il pubblico a bocca aperta!"
  elseif cat == "resetstars" then
    s = "->0s"
  elseif cat == "nervous" then
    s = event.pokemon .. " non riesce a esibirsi per l'emozione!"
  elseif cat == "cantmove" then
    s = event.pokemon .. " non può far altro che stare a guardare!"
    
  elseif cat == "copy" then
    s = "Tiene testa all'esibizione dei Pokémon precedenti!"
  elseif cat == "protectall" then
    s = "Non si preoccupa più degli altri Pokémon!"
  elseif cat == "rating" then
    if event.rating == 1 then
      s = "L'esibizione di " .. event.pokemon .. " non è andata molto bene!"
    elseif event.rating == 2 then
      s = "L'esibizione di " .. event.pokemon .. " è andata benino!"
    elseif event.rating == 3 then
      s = "L'esibizione di " .. event.pokemon .. " è andata piuttosto bene!"
    elseif event.rating == 4 then
      s = "L'esibizione di " .. event.pokemon .. " è andata molto bene!"
    elseif event.rating == 5 then
      s = "L'esibizione di " .. event.pokemon .. " è andata benissimo!"
    end
  elseif cat == "first" then
    s = event.pokemon .. " si era già fatto notare e ora ha superato se stesso!"
  elseif cat == "last" then
    s = event.pokemon .. " non si stava distinguendo molto, ma ce l'ha messa tutta!"
  elseif cat == "unnerve" then
    s = "Prova a far innervosire i Pokémon che non si sono ancora esibiti!"
  elseif cat == "miss" then
    s = "Ma non ce la fa!"
  elseif cat == "protectonce" then
    s = "Ha riacquistato la calma."
  elseif cat == "sametype" then
    s = "Ha avuto successo perché è dello stesso tipo del Pokémon precedente!"
  elseif cat == "onlywatches" then
    s = "Cattura gli sguardi del pubblico in modo che non presti attenzione al" .. conditionArticleName[event.condition] .. " degli altri Pokémon!"
  elseif cat == "veryexcited" then
    s = event.pokemon .. " si mette in mostra e il pubblico l'acclama!"
  elseif cat == "nextfirst" then
    s = "Si fa avanti per esibirsi prima!"
  elseif cat == "nextlast" then
    s = "Ha ceduto il posto per ritardare la sua esibizione!"
  elseif cat == "howwell" then
    if event.rating == 0 then
      s = "Non ha fatto meglio del Pokémon precedente..."
    -- if rating == 1 (previous Pokémon had 3 hearts) don't print anything!
    elseif event.rating == 2 then
      s = "Si fa notare più del Pokémon precedente!"
    end
  elseif cat == "easystartle" then
    s = "Presterà più attenzione alle esibizioni dei Pokémon successivi!"
  elseif cat == "suicide" then
    s = event.pokemon .. " non può esibirsi dopo una tale esibizione!"
    
  elseif cat == "turn" then
    s = "-- " .. event.pokemon .. " --"
  elseif cat == "state" then
    s = event.state
  elseif cat == "order" then
    s = "Prossima esibizione: " .. event.pokemons[1]
    for i = 2, 4 do s = s .. ", " .. event.pokemons[i] end
  elseif cat == "result" then
    s = "Risultati:"
    for i = 1, 4 do s = s .. "\n" .. i .. ". " .. event.pokemons[i] .. "\t" .. event.hearts[i] end
  else -- if not a category, print its name, for debug reasons.
    s = event[1]
  end
  return s
end

function printTurnEvents(events, turn)
  print("-- Esibizione n° " .. turn .. "! --")
  for _, event in pairs(events[turn]) do
    print(eventToString(event))
  end
  print("")
end

function printEvents(events, turn)
  if turn then printTurnEvents(events, turn)
  else
    for i = 1, #events do
      printTurnEvents(events, i)
    end
  end
end