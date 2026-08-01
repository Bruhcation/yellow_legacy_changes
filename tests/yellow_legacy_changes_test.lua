-- Standalone: luajit mods/yellow_legacy_changes/tests/yellow_legacy_changes_test.lua
-- Loads the mod through the real headless loader and asserts the merged
-- view carries the Yellow Legacy values (new numbers, deltas are context),
-- plus the two engine wraps: Focus Energy at exactly 2x crit rate and
-- Leech Seed draining a flat 1/8.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
Data:load()

-- seed vanilla base records for two ids the mod patches, so the deep
-- merge's preservation of unpatched fields is observable in the fixture
-- (every other id the mod touches is op-only here)
Data.moves.SKY_ATTACK = {
  id = "SKY_ATTACK", name = "SKY ATTACK", index = 88, type = "FLYING",
  power = 140, accuracy = 90, pp = 5, effect = "EFFECT_1E",
}
Data.pokemon.PIKACHU = {
  id = "PIKACHU", name = "PIKACHU", index = 25, dex = 25,
  baseStats = { hp = 35, attack = 55, defense = 30, speed = 90, special = 50 },
  catchRate = 190, baseExp = 82, growthRate = "MEDIUM_FAST",
  level1Moves = {}, tmhm = {}, learnset = {}, evolutions = {},
}
Data.pokemon.FIXMON_LEGACY = {
  id = "FIXMON_LEGACY", name = "FIXMON LEGACY", index = 99, dex = 99,
  baseStats = { hp = 40, attack = 50, defense = 40, speed = 45, special = 45 },
  catchRate = 190, baseExp = 64, growthRate = "MEDIUM_SLOW",
  level1Moves = {}, tmhm = {}, learnset = {}, evolutions = {},
}
-- seed a vanilla trainer base (Yellow: STARYU 18 / STARMIE 21) so the
-- deep merge's preservation of unpatched leaves is observable
Data.trainers.OPP_MISTY = {
  id = "OPP_MISTY", name = "MISTY", index = 35, baseMoney = 40,
  parties = {
    { { level = 18, species = "STARYU" }, { level = 21, species = "STARMIE" } },
  },
}
-- minimal species records for the trainer-team species the merged-view
-- assertions touch (the fixture itself only carries FIX_* species)
local function seedSpecies(id)
  Data.pokemon[id] = {
    id = id, name = id, index = 1, dex = 1,
    baseStats = { hp = 50, attack = 50, defense = 50, speed = 50, special = 50 },
    catchRate = 100, baseExp = 100, growthRate = "MEDIUM_FAST",
    level1Moves = {}, tmhm = {}, learnset = {}, evolutions = {},
  }
end
for _, id in ipairs({
  "PSYDUCK", "GOLDEEN", "STARMIE", "RAICHU", "TANGELA", "VICTREEBEL",
  "IVYSAUR", "VILEPLUME", "GOLBAT", "MUK", "TENTACRUEL", "VENOMOTH",
  "RAPIDASH", "CHARIZARD", "NINETALES", "ARCANINE", "MAGMAR", "ABRA",
  "HYPNO", "MR_MIME", "KADABRA", "ALAKAZAM", "DUGTRIO", "NIDOQUEEN",
  "PERSIAN", "NIDOKING", "RHYDON", "GYARADOS", "EXEGGUTOR", "JOLTEON",
  "DRAGONITE", "AERODACTYL", "ONIX", "KANGASKHAN", "MAROWAK", "KINGLER",
  "MACHOKE", "GOLEM", "MAGNETON", "DODRIO", "SANDSLASH", "CLOYSTER",
  "FLAREON", "MACHAMP", "PIDGEOT", "VAPOREON",
  "GRAVELER", "HAUNTER", "GENGAR", "POLIWHIRL", "POLIWRATH",
  "SEADRA", "GOLDUCK", "LAPRAS", "BLASTOISE",
}) do
  seedSpecies(id)
end

-- vanilla evolution rows, so the merged view shows the hack's changes
local function seedEvo(id, evos)
  local rec = Data.pokemon[id]
  rec.evolutions = evos
end
seedEvo("KADABRA", { { method = "TRADE", level = 1, species = "ALAKAZAM" } })
seedEvo("MACHOKE", { { method = "TRADE", level = 1, species = "MACHAMP" } })
seedEvo("GRAVELER", { { method = "TRADE", level = 1, species = "GOLEM" } })
seedEvo("HAUNTER", { { method = "TRADE", level = 1, species = "GENGAR" } })
seedEvo("POLIWHIRL", { { method = "LEVEL", level = 25, species = "POLIWRATH" } })

local run = T.sdk.loadMod("mods/yellow_legacy_changes", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mod and run.mod.state, "loaded", "reached the loaded state")

local moves = run.loader.content.moves
local pokemon = run.loader.content.pokemon

-- ---------- move patches (new values from the PDF) ----------

-- every move id the mod touches must resolve in the merged view (the deep
-- registry carries op-only partials), and the headline values must land
local MOVE_IDS = {
  "BARRAGE", "BIND", "COMET_PUNCH", "CONSTRICT", "DISABLE", "DIZZY_PUNCH",
  "DOUBLESLAP", "DOUBLE_EDGE", "EXPLOSION", "FOCUS_ENERGY", "FURY_ATTACK",
  "FURY_SWIPES", "GLARE", "MEGA_KICK", "PAY_DAY", "RAGE", "RAZOR_WIND",
  "SELFDESTRUCT", "SKULL_BASH", "SOFTBOILED", "SONICBOOM", "SUPERSONIC",
  "TACKLE", "TAKE_DOWN", "TRANSFORM", "TRI_ATTACK", "FIRE_PUNCH",
  "FIRE_SPIN", "BLIZZARD", "ICE_PUNCH", "THUNDER", "THUNDERPUNCH", "FLY",
  "GUST", "SKY_ATTACK", "WING_ATTACK", "CUT", "LEECH_LIFE", "PIN_MISSILE",
  "TWINEEDLE", "ABSORB", "EGG_BOMB", "LEECH_SEED", "MEGA_DRAIN",
  "PETAL_DANCE", "SOLARBEAM", "VINE_WHIP", "LICK", "NIGHT_SHADE",
  "ROCK_SLIDE", "ROCK_THROW", "BONE_CLUB", "BONEMERANG", "DIG", "BUBBLE",
  "CLAMP", "CRABHAMMER", "HYDRO_PUMP", "WATERFALL", "PSYWAVE",
  "HI_JUMP_KICK", "JUMP_KICK", "KARATE_CHOP", "LOW_KICK", "ROLLING_KICK",
  "SUBMISSION", "ACID", "POISON_GAS", "POISONPOWDER", "POISON_STING",
  "SLUDGE", "SMOG", "SLAM",
}
for _, id in ipairs(MOVE_IDS) do
  T.check(moves:get(id) ~= nil, id .. " resolves in the merged view")
end

T.eq(moves:get("MEGA_DRAIN").power, 65, "MEGA_DRAIN power 65 (was 40)")
T.eq(moves:get("MEGA_DRAIN").pp, 20, "MEGA_DRAIN pp 20 (was 10)")
T.eq(moves:get("EXPLOSION").power, 250, "EXPLOSION power 250 (was 170)")
T.eq(moves:get("DOUBLE_EDGE").power, 120, "DOUBLE_EDGE power 120 (was 100)")
T.eq(moves:get("DOUBLE_EDGE").pp, 10, "DOUBLE_EDGE pp 10 (was 15)")
T.eq(moves:get("SOLARBEAM").power, 180, "SOLARBEAM power 180 (was 120)")
T.eq(moves:get("DIG").power, 70, "DIG power 70 (was 100)")
T.eq(moves:get("BUBBLE").power, 10, "BUBBLE power 10 (was 20)")
T.eq(moves:get("TAKE_DOWN").power, 95, "TAKE_DOWN power 95 (was 90)")
T.eq(moves:get("TAKE_DOWN").accuracy, 100, "TAKE_DOWN accuracy 100 (was 85)")
T.eq(moves:get("THUNDER").accuracy, 85, "THUNDER accuracy 85 (was 70)")
T.eq(moves:get("THUNDER").pp, 5, "THUNDER pp 5 (was 10)")
T.eq(moves:get("SKY_ATTACK").power, 120, "SKY_ATTACK power 120 (was 140)")
T.eq(moves:get("SKY_ATTACK").accuracy, 85, "SKY_ATTACK accuracy 85 (was 90)")
T.eq(moves:get("POISON_GAS").accuracy, 85, "POISON_GAS accuracy 85 (was 55)")
T.eq(moves:get("SOFTBOILED").pp, 5, "SOFTBOILED pp 5 (was 10)")
T.eq(moves:get("BONEMERANG").pp, 20, "BONEMERANG pp 20 (was 10)")
T.eq(moves:get("HI_JUMP_KICK").power, 120, "HI_JUMP_KICK power 120 (was 85)")
T.eq(moves:get("WING_ATTACK").power, 60, "WING_ATTACK power 60 (was 35)")
T.eq(moves:get("LEECH_LIFE").power, 50, "LEECH_LIFE power 50 (was 20)")
T.eq(moves:get("LEECH_LIFE").pp, 25, "LEECH_LIFE pp 25 (was 15)")
T.eq(moves:get("SLUDGE").power, 90, "SLUDGE power 90 (was 65)")
T.eq(moves:get("POISON_STING").power, 35, "POISON_STING power 35 (was 15)")
T.eq(moves:get("SMOG").accuracy, 80, "SMOG accuracy 80 (was 70)")
T.eq(moves:get("LICK").power, 40, "LICK power 40 (was 20)")
T.eq(moves:get("NIGHT_SHADE").power, 60, "NIGHT_SHADE power 60 (was 0)")
T.eq(moves:get("CRABHAMMER").power, 110, "CRABHAMMER power 110 (was 90)")
T.eq(moves:get("HYDRO_PUMP").accuracy, 85, "HYDRO_PUMP accuracy 85 (was 80)")
T.eq(moves:get("HYDRO_PUMP").pp, 10, "HYDRO_PUMP pp 10 (was 5)")
T.eq(moves:get("ROCK_THROW").accuracy, 95, "ROCK_THROW accuracy 95 (was 65)")
T.eq(moves:get("BONE_CLUB").accuracy, 100, "BONE_CLUB accuracy 100 (was 85)")
T.eq(moves:get("SUBMISSION").accuracy, 100, "SUBMISSION accuracy 100 (was 80)")
T.eq(moves:get("ROLLING_KICK").power, 70, "ROLLING_KICK power 70 (was 60)")
T.eq(moves:get("ROLLING_KICK").accuracy, 100, "ROLLING_KICK accuracy 100 (was 85)")
T.eq(moves:get("ACID").power, 65, "ACID power 65 (was 40)")
T.eq(moves:get("GLARE").accuracy, 90, "GLARE accuracy 90 (was 75)")
T.eq(moves:get("TACKLE").accuracy, 100, "TACKLE accuracy 100 (was 95)")
T.eq(moves:get("FURY_ATTACK").accuracy, 100, "FURY_ATTACK accuracy 100 (was 85)")
T.eq(moves:get("FURY_SWIPES").power, 20, "FURY_SWIPES power 20 (was 18)")
T.eq(moves:get("COMET_PUNCH").power, 25, "COMET_PUNCH power 25 (was 18)")
T.eq(moves:get("DOUBLESLAP").pp, 35, "DOUBLESLAP pp 35 (was 10)")
T.eq(moves:get("PIN_MISSILE").power, 20, "PIN_MISSILE power 20 (was 14)")
T.eq(moves:get("PIN_MISSILE").pp, 30, "PIN_MISSILE pp 30 (was 20)")
T.eq(moves:get("TWINEEDLE").power, 40, "TWINEEDLE power 40 per hit (was 25)")
T.eq(moves:get("ABSORB").power, 30, "ABSORB power 30 (was 20)")
T.eq(moves:get("ABSORB").pp, 25, "ABSORB pp 25 (was 20)")
T.eq(moves:get("PETAL_DANCE").power, 90, "PETAL_DANCE power 90 (was 70)")
T.eq(moves:get("VINE_WHIP").power, 40, "VINE_WHIP power 40 (was 35)")
T.eq(moves:get("VINE_WHIP").pp, 25, "VINE_WHIP pp 25 (was 10)")
T.eq(moves:get("CONSTRICT").power, 40, "CONSTRICT power 40 (was 10)")
T.eq(moves:get("BARRAGE").power, 20, "BARRAGE power 20 (was 15)")
T.eq(moves:get("BARRAGE").accuracy, 100, "BARRAGE accuracy 100 (was 85)")
T.eq(moves:get("BIND").accuracy, 95, "BIND accuracy 95 (was 85)")
T.eq(moves:get("DISABLE").accuracy, 75, "DISABLE accuracy 75 (was 55)")
T.eq(moves:get("SUPERSONIC").accuracy, 70, "SUPERSONIC accuracy 70 (was 55)")
T.eq(moves:get("MEGA_KICK").accuracy, 85, "MEGA_KICK accuracy 85 (was 75)")
T.eq(moves:get("MEGA_KICK").pp, 10, "MEGA_KICK pp 10 (was 5)")
T.eq(moves:get("PAY_DAY").power, 60, "PAY_DAY power 60 (was 40)")
T.eq(moves:get("RAGE").power, 60, "RAGE power 60 (was 20)")
T.eq(moves:get("SELFDESTRUCT").power, 200, "SELFDESTRUCT power 200 (was 130)")
T.eq(moves:get("FIRE_PUNCH").power, 70, "FIRE_PUNCH power 70 (was 75)")
T.eq(moves:get("ICE_PUNCH").power, 70, "ICE_PUNCH power 70 (was 75)")
T.eq(moves:get("THUNDERPUNCH").power, 70, "THUNDERPUNCH power 70 (was 75)")
T.eq(moves:get("FIRE_SPIN").accuracy, 85, "FIRE_SPIN accuracy 85 (was 70)")
T.eq(moves:get("BLIZZARD").accuracy, 85, "BLIZZARD accuracy 85 (was 90)")
T.eq(moves:get("FLY").accuracy, 100, "FLY accuracy 100 (was 95)")
T.eq(moves:get("CLAMP").accuracy, 85, "CLAMP accuracy 85 (was 75)")
T.eq(moves:get("WATERFALL").power, 70, "WATERFALL power 70 (was 80)")
T.eq(moves:get("JUMP_KICK").power, 90, "JUMP_KICK power 90 (was 70)")
T.eq(moves:get("KARATE_CHOP").accuracy, 95, "KARATE_CHOP accuracy 95 (was 100)")
T.eq(moves:get("LOW_KICK").accuracy, 100, "LOW_KICK accuracy 100 (was 90)")
T.eq(moves:get("PSYWAVE").accuracy, 95, "PSYWAVE accuracy 95 (was 80)")
T.eq(moves:get("POISONPOWDER").accuracy, 90, "POISONPOWDER accuracy 90 (was 75)")
T.eq(moves:get("SONICBOOM").accuracy, 100, "SONICBOOM accuracy 100 (was 90)")
T.eq(moves:get("EGG_BOMB").accuracy, 100, "EGG_BOMB accuracy 100 (was 75)")
T.eq(moves:get("ROCK_SLIDE").accuracy, 95, "ROCK_SLIDE accuracy 95 (was 90)")
T.eq(moves:get("ROCK_THROW").pp, 25, "ROCK_THROW pp 25 (was 15)")
T.eq(moves:get("RAZOR_WIND").power, 80, "RAZOR_WIND power 80")
T.eq(moves:get("RAZOR_WIND").accuracy, 100, "RAZOR_WIND accuracy 100 (was 75)")
T.eq(moves:get("SKULL_BASH").power, 100, "SKULL_BASH power 100")
T.eq(moves:get("SKULL_BASH").accuracy, 100, "SKULL_BASH accuracy 100")
T.eq(moves:get("DIZZY_PUNCH").pp, 20, "DIZZY_PUNCH pp 20 (was 10)")
T.eq(moves:get("TRI_ATTACK").power, 85, "TRI_ATTACK power 85 (was 80)")
T.eq(moves:get("TRI_ATTACK").pp, 15, "TRI_ATTACK pp 15 (was 10)")
T.eq(moves:get("FOCUS_ENERGY").pp, 30, "FOCUS_ENERGY pp 30")
T.eq(moves:get("TRANSFORM").pp, 10, "TRANSFORM pp 10")
T.eq(moves:get("LEECH_SEED").accuracy, 90, "LEECH_SEED accuracy 90")
T.eq(moves:get("SLAM").accuracy, 100, "SLAM accuracy 100 (was 75)")

-- type changes
T.eq(moves:get("GUST").type, "FLYING", "GUST is Flying now")
T.eq(moves:get("CUT").type, "BUG", "CUT is Bug now")
T.eq(moves:get("EGG_BOMB").type, "GRASS", "EGG_BOMB is Grass now")
T.eq(moves:get("KARATE_CHOP").type, "FIGHTING", "KARATE_CHOP is Fighting now")
T.eq(moves:get("SLAM").type, "DRAGON", "SLAM is Dragon now")

-- effect changes
T.eq(moves:get("DIZZY_PUNCH").effect, "CONFUSION_SIDE_EFFECT",
  "DIZZY_PUNCH confuses (10%)")
T.eq(moves:get("TRI_ATTACK").effect, "BURN_SIDE_EFFECT2",
  "TRI_ATTACK burns (30%)")
T.eq(moves:get("FIRE_PUNCH").effect, "BURN_SIDE_EFFECT2",
  "FIRE_PUNCH burn chance raised")
T.eq(moves:get("ROCK_SLIDE").effect, "FLINCH_SIDE_EFFECT1",
  "ROCK_SLIDE flinches (10%)")
T.eq(moves:get("WATERFALL").effect, "FLINCH_SIDE_EFFECT1",
  "WATERFALL flinches (10%)")
T.eq(moves:get("SLAM").effect, "FLINCH_SIDE_EFFECT1", "SLAM flinches (10%)")
T.eq(moves:get("RAZOR_WIND").effect, "HYPER_BEAM_EFFECT",
  "RAZOR_WIND recharges like Hyper Beam")
T.eq(moves:get("SKULL_BASH").effect, "HYPER_BEAM_EFFECT",
  "SKULL_BASH recharges like Hyper Beam")
T.eq(moves:get("SKY_ATTACK").effect, "NO_ADDITIONAL_EFFECT",
  "SKY_ATTACK no longer charges")
T.eq(moves:get("NIGHT_SHADE").effect, "NO_ADDITIONAL_EFFECT",
  "NIGHT_SHADE is a normal damaging move now")
T.eq(moves:get("TRANSFORM").priority, 1, "TRANSFORM has increased priority")

-- ---------- stat patches ----------

-- every species the mod touches resolves in the merged view
local SPECIES = {
  CHARMANDER = { special = 55 },
  CHARMELEON = { special = 70 },
  CHARIZARD = { special = 95 },
  ARBOK = { hp = 62, attack = 95, speed = 90 },
  PIKACHU = { hp = 60, defense = 50, special = 70 },
  CLEFABLE = { special = 95 },
  VULPIX = { hp = 45, defense = 45, special = 70, speed = 75 },
  WIGGLYTUFF = { defense = 55, special = 85 },
  GOLBAT = { speed = 100 },
  ODDISH = { hp = 50 },
  GLOOM = { hp = 70 },
  VILEPLUME = { hp = 90 },
  VENOMOTH = { attack = 75, special = 95, speed = 100 },
  DIGLETT = { attack = 70 },
  DUGTRIO = { attack = 90 },
  PONYTA = { speed = 100 },
  RAPIDASH = { speed = 115 },
  FARFETCHD = { hp = 62, attack = 75, defense = 65, special = 68, speed = 70 },
  MUK = { special = 85 },
  ONIX = { hp = 75, attack = 80, special = 65, speed = 85 },
  MAROWAK = { special = 80 },
  HITMONLEE = { hp = 65, defense = 70, special = 60, speed = 93 },
  HITMONCHAN = { hp = 60, attack = 50, special = 105 },
  LICKITUNG = { hp = 95, attack = 70, defense = 85, special = 75 },
  MAGMAR = { special = 95 },
  EEVEE = { hp = 70, attack = 65, defense = 65, special = 70 },
  PORYGON = { hp = 75, attack = 70, special = 95 },
}
for id, changed in pairs(SPECIES) do
  local rec = pokemon:get(id)
  T.check(rec ~= nil, id .. " resolves in the merged view")
  if rec then
    for stat, value in pairs(changed) do
      T.eq(rec.baseStats[stat], value, id .. " " .. stat .. " " .. value)
    end
  end
end

-- seeded bases: patched leaves land, unpatched leaves are preserved
local sky = moves:get("SKY_ATTACK")
T.eq(sky.power, 120, "seeded base: SKY_ATTACK power patched")
T.eq(sky.accuracy, 85, "seeded base: SKY_ATTACK accuracy patched")
T.eq(sky.pp, 5, "seeded base: unpatched pp preserved")
local pika = pokemon:get("PIKACHU")
T.eq(pika.baseStats.hp, 60, "seeded base: PIKACHU hp patched")
T.eq(pika.baseStats.defense, 50, "seeded base: PIKACHU defense patched")
T.eq(pika.baseStats.special, 70, "seeded base: PIKACHU special patched")
T.eq(pika.baseStats.attack, 55, "seeded base: PIKACHU attack preserved")
T.eq(pika.baseStats.speed, 90, "seeded base: PIKACHU speed preserved")

-- ---------- trainer team patches ----------

local trainers = run.loader.content.trainers
T.check(trainers ~= nil, "trainers registry present")

-- headline teams land in the merged view
T.eq(trainers:get("OPP_MISTY").parties[1][1].level, 19,
  "Misty leads PSYDUCK 19 (was STARYU 18)")
T.eq(trainers:get("OPP_MISTY").parties[1][1].species, "PSYDUCK",
  "Misty leads PSYDUCK (was STARYU)")
T.eq(trainers:get("OPP_MISTY").parties[1][3].species, "STARMIE",
  "STARMIE stays Misty's ace")
T.eq(trainers:get("OPP_MISTY").parties[1][3].level, 21, "ace level 21")
T.eq(trainers:get("OPP_MISTY").baseMoney, 40, "unpatched baseMoney preserved")

-- ---------- rematch teams (the hack's "; Rematch" rows) ----------

local misty = trainers:get("OPP_MISTY")
T.eq(misty.rematchIndex, 2, "MISTY marks its rematch team at index 2")
T.eq(#misty.parties, 2, "MISTY keeps the vanilla team and gains the rematch")
local rm = misty.parties[2]
T.eq(#rm, 6, "the rematch team is a full six")
T.eq(rm[1].level, 64, "the rematch leads at 64")
T.eq(rm[1].species, "SEADRA", "SEADRA leads the rematch team")
T.eq(rm[6].level, 65, "the anchor sits at 65")
T.eq(rm[6].species, "STARMIE", "STARMIE anchors the rematch team")

local rival3 = trainers:get("OPP_RIVAL3")
T.eq(rival3.rematchIndex, 4, "RIVAL3's rematch team sits after its three teams")
T.eq(#rival3.parties, 4, "RIVAL3 gains a fourth team")
T.eq(rival3.parties[4][1].level, 77, "the champion rematch leads at 77")
T.eq(rival3.parties[4][1].species, "ALAKAZAM", "the champion rematch opens with ALAKAZAM")
T.eq(rival3.parties[4][6].level, 77, "the champion rematch closes at 77")

local other = trainers:get("OPP_YOUNGSTER")
T.eq(other and other.rematchIndex, nil, "classes without a rematch team carry no marker")

T.eq(trainers:get("OPP_LT_SURGE").parties[1][1].species, "RAICHU",
  "Lt. Surge: RAICHU 29")
T.eq(trainers:get("OPP_LT_SURGE").parties[1][1].level, 29, "Lt. Surge level")
T.eq(trainers:get("OPP_ERIKA").parties[1][1].species, "TANGELA",
  "Erika leads TANGELA 33 (was TANGELA 30)")
T.eq(trainers:get("OPP_KOGA").parties[1][1].species, "GOLBAT",
  "Koga leads GOLBAT 42")
T.eq(trainers:get("OPP_BLAINE").parties[1][5].species, "MAGMAR",
  "Blaine closes with MAGMAR 53 (was RAPIDASH solo)")
T.eq(trainers:get("OPP_SABRINA").parties[1][1].species, "ABRA",
  "Sabrina leads ABRA 50")
T.eq(#trainers:get("OPP_GIOVANNI").parties, 3, "Giovanni keeps three fights")
T.eq(trainers:get("OPP_GIOVANNI").parties[3][1].level, 53,
  "Viridian Giovanni: DUGTRIO 53 (was 50)")
T.eq(#trainers:get("OPP_RIVAL3").parties, 4,
  "champion rival keeps three teams plus the rematch team")
T.eq(trainers:get("OPP_RIVAL3").parties[1][1].species, "ALAKAZAM",
  "champion rival leads ALAKAZAM 63")
T.eq(trainers:get("OPP_LANCE").parties[1][1].species, "DRAGONITE",
  "Lance leads DRAGONITE 61 (was GYARADOS 58)")
T.eq(trainers:get("OPP_LANCE").parties[1][3].species, "CHARIZARD",
  "Lance fields CHARIZARD 60 (was DRAGONAIR)")

-- the mod never registers new classes (no Smith/Craig/Janine/Joy/Jenny)
for _, id in ipairs({ "OPP_SMITH", "OPP_CRAIG", "OPP_JANINE",
                      "OPP_JOY", "OPP_JENNY", "OPP_WEEBRA" }) do
  T.check(trainers:get(id) == nil, id .. " is not registered")
end

-- ---------- engine wraps ----------

local Runtime = require("src.mods.Runtime")
Runtime.emit("game.ready", { game = { data = Data } })

local Damage = require("src.battle.Damage")
local Stats = require("src.pokemon.Stats")

local attacker = {
  focusEnergy = true,
  def = { baseStats = { speed = 64 } },
  curStats = { speed = 64 },
}
-- rng stub: answer a fixed roll
local function rngAt(n)
  return function(lo, hi) assert(lo == 0 and hi == 255); return n end
end
-- base rate: plain b = 32 -> crit on <32.  focus 2x: b = 64 -> crit on <64.
local plain = { focusEnergy = nil, def = attacker.def, curStats = attacker.curStats }
T.check(not Damage.critRoll({}, plain, "X", rngAt(40), false),
  "plain misses at 40 (rate 32)")
T.check(Damage.critRoll({}, attacker, "X", rngAt(40), false),
  "focus energy crits at 40 (2x the normal rate)")
T.check(Damage.critRoll({}, plain, "X", rngAt(31), false),
  "plain crits below 32")
T.check(not Damage.critRoll({}, plain, "X", rngAt(32), false),
  "plain misses at 32")
T.check(not Damage.critRoll({}, attacker, "X", rngAt(64), false),
  "focus misses at 64 (rate 64)")
T.check(Damage.critRoll({}, attacker, "X", rngAt(63), false),
  "focus crits at 63")
T.check(Damage.critRoll({}, attacker, "X", rngAt(1), false),
  "focus crits on the low end")

local Status = require("src.battle.Status")
local battler = {
  name = "TEST",
  mon = { hp = 100, stats = { hp = 100 } },
  leechSeeded = true,
}
local opponent = { mon = { hp = 50, stats = { hp = 200 } } }
local msgs = Status.residual(battler, opponent, {})
T.eq(battler.mon.hp, 88, "leech seed drains 1/8 (100 -> 88)")
T.eq(opponent.mon.hp, 62, "the drain heals the opponent (50 -> 62)")
T.check(#msgs >= 1, "the seed reports the sap")

-- without a seed the wrap is a pass-through
local clean = { name = "TEST", mon = { hp = 100, stats = { hp = 100 } } }
local cleanOpp = { mon = { hp = 50, stats = { hp = 200 } } }
Status.residual(clean, cleanOpp, {})
T.eq(clean.mon.hp, 100, "an unseeded mon takes no residual")

-- ---------- learnset / tmhm / encounter resolution ----------

local resolveTables = run.loader.exports.yellow_legacy_changes.resolveTables
T.check(type(resolveTables) == "function", "resolveTables is published")

local mini = {
  learnsets = {
    ["Fixmon Legacy"] = {
      { 1, "Fix Tackle" }, { 7, "Fix Ember" }, { 12, "Fix Cut" },
    },
    ["No Such Mon"] = { { 1, "Fix Tackle" } },
  },
  tmhm = {
    ["Fixmon Legacy"] = { "Fix Cut", "Fix Ember" },
  },
  encounters = {
    FIX_ROUTE = {
      grass = { { 3, "Fixmon B" }, { 4, "Fixmon C" }, { 5, "Fixmon A" } },
      water = { { 10, "Fixmon B" } },
      rods = { OLD_ROD = { { 5, "Fixmon B" } } },
    },
    NO_SUCH_MAP = { grass = { { 2, "Fixmon A" } } },
  },
}

local resolved, counts = resolveTables(run.loader.content, mini)
T.eq(resolved.learnsets["FIXMON_LEGACY"].learnset[1].move, "FIX_TACKLE",
  "learnset level-1 move id resolves")
T.eq(resolved.learnsets["FIXMON_LEGACY"].learnset[2].move, "FIX_EMBERISH",
  "display names resolve to ids")
T.eq(resolved.learnsets["FIXMON_LEGACY"].learnset[2].level, 7, "level")
T.eq(resolved.learnsets["FIXMON_LEGACY"].learnset[3].move, "FIX_CUT",
  "machine moves resolve in learnsets")
T.eq(#resolved.learnsets["FIXMON_LEGACY"].level1, 1, "level-1 entries listed")
T.eq(resolved.learnsets["FIXMON_LEGACY"].level1[1], "FIX_TACKLE",
  "level-1 move id")
T.check(resolved.learnsets["NO_SUCH_MON"] == nil,
  "an unknown species resolves to nothing")
T.eq(#resolved.tmhm["FIXMON_LEGACY"], 2, "tmhm ids resolved in order")
T.eq(resolved.tmhm["FIXMON_LEGACY"][1], "FIX_CUT", "tmhm first entry")
T.eq(#resolved.encounters["FIX_ROUTE"].grass, 3, "grass slots resolved")
T.eq(resolved.encounters["FIX_ROUTE"].grass[1].species, "FIXMON_B",
  "grass species id")
T.eq(#resolved.encounters["FIX_ROUTE"].water, 1, "surf slots resolved")
T.eq(resolved.rods.OLD_ROD["FIX_ROUTE"][1].species, "FIXMON_B",
  "rod pool resolves species")
T.eq(resolved.rods.OLD_ROD["FIX_ROUTE"][1].level, 5, "rod pool level")
T.check(resolved.encounters["NO_SUCH_MAP"] == nil,
  "an unknown map resolves to nothing")
T.eq(counts.species, 1, "one unknown species counted")
T.eq(counts.maps, 1, "one unknown map counted")

-- trainer parties resolve ROM constants against registry ids
local mini2 = {
  trainers = {
    ["OPP_FIX_TRAINER"] = {
      parties = {
        { { level = 5, species = "Fixmon B" }, { level = 7, species = "Fixmon A" } },
      },
    },
    ["OPP_FIX_GHOST"] = {
      parties = { { { level = 9, species = "No Such Mon" } } },
    },
  },
}
local resolved2, counts2 = resolveTables(run.loader.content, mini2)
T.eq(resolved2.trainers["OPP_FIX_TRAINER"].parties[1][1].species, "FIXMON_B",
  "trainer species constant resolves to the registry id")
T.eq(resolved2.trainers["OPP_FIX_TRAINER"].parties[1][1].level, 5,
  "trainer party level")
T.eq(#resolved2.trainers["OPP_FIX_TRAINER"].parties[1], 2,
  "trainer party keeps both slots")
T.check(resolved2.trainers["OPP_FIX_GHOST"] == nil,
  "a class with an unknown species is dropped whole")
T.eq(counts2.species, 1, "one unknown trainer species counted")
T.eq(counts2.trainers, 1, "one trainer class skipped")

-- ---------- type chart changes ----------

local typeChart = run.loader.content.type_chart
T.eq(typeChart:get("GHOST").category, "special",
  "GHOST moves use the special stat (Yellow Legacy)")
T.eq(typeChart:get("GHOST>PSYCHIC_TYPE").multiplier, 20,
  "GHOST is super effective against PSYCHIC")

local mergedTypes = run.data.type_chart and run.data.type_chart.types
T.check(mergedTypes ~= nil and mergedTypes.GHOST ~= nil,
  "the merged view carries the type records")
T.eq(mergedTypes.GHOST.category, "special",
  "the merged GHOST record is special")

-- ---------- dragon physical toggle (MODS menu per-mod options) ----------

local exports = run.loader.exports.yellow_legacy_changes
T.check(exports ~= nil and exports.setDragonPhysical ~= nil,
  "setDragonPhysical is exported for testing")
T.check(exports.setDragonPhysical(run.data, true),
  "the toggle applies when the record exists")
T.eq(mergedTypes.DRAGON.category, "physical", "DRAGON is physical when ON")
exports.setDragonPhysical(run.data, false)
T.eq(mergedTypes.DRAGON.category, "special", "DRAGON returns to special when OFF")

-- the mod declares a toggle row in the MODS menu options schema
local schema = run.loader.optionSchemas.yellow_legacy_changes
T.check(type(schema) == "table" and #schema == 1,
  "the mod defines one options row")
T.eq(schema[1].key, "dragonPhysical", "the row is the dragon toggle")
T.eq(schema[1].type, "toggle", "the row is a toggle")
T.eq(schema[1].label, "DRAGON PHYS", "the row label is clear")
T.eq(schema[1].default, false, "defaults to OFF (Gen 1 faithful)")

-- flipping it in the manager applies the switch through the event
_G.package.loaded["src.core.Game"] = { data = run.data }
run.loader.events:emit("mod.options_changed",
  { mod = "yellow_legacy_changes", key = "dragonPhysical", value = true })
T.eq(mergedTypes.DRAGON.category, "physical",
  "mod.options_changed applies DRAGON physical")
run.loader.events:emit("mod.options_changed",
  { mod = "yellow_legacy_changes", key = "dragonPhysical", value = false })
T.eq(mergedTypes.DRAGON.category, "special",
  "mod.options_changed restores DRAGON special")

-- a stored option wins over the schema default on boot
run.loader.modOptions.yellow_legacy_changes = { dragonPhysical = true }
_G.package.loaded["src.core.Game"] = { data = run.data }
Runtime.emit("game.ready", { game = { save = { options = {} } } })
T.eq(mergedTypes.DRAGON.category, "physical",
  "a persisted ON applies at game.ready")
_G.package.loaded["src.core.Game"] = nil

-- ---------- evolutions (yellow legacy evos_moves.asm) ----------
-- vanilla trade rows become level rows at the hack's levels
local pokemonView = run.loader.content.pokemon
local function evoOf(id)
  local evos = pokemonView:get(id) and pokemonView:get(id).evolutions or {}
  return evos[1]
end
T.eq(evoOf("KADABRA").method, "LEVEL", "KADABRA -> ALAKAZAM by level")
T.eq(evoOf("KADABRA").level, 42, "KADABRA evolves at 42")
T.eq(evoOf("KADABRA").species, "ALAKAZAM", "KADABRA evolves into ALAKAZAM")
T.eq(evoOf("MACHOKE").method, "LEVEL", "MACHOKE -> MACHAMP by level")
T.eq(evoOf("MACHOKE").level, 38, "MACHOKE evolves at 38")
T.eq(evoOf("MACHOKE").species, "MACHAMP", "MACHOKE evolves into MACHAMP")
T.eq(evoOf("GRAVELER").method, "LEVEL", "GRAVELER -> GOLEM by level")
T.eq(evoOf("GRAVELER").level, 38, "GRAVELER evolves at 38")
T.eq(evoOf("GRAVELER").species, "GOLEM", "GRAVELER evolves into GOLEM")
T.eq(evoOf("HAUNTER").method, "LEVEL", "HAUNTER -> GENGAR by level")
T.eq(evoOf("HAUNTER").level, 42, "HAUNTER evolves at 42")
T.eq(evoOf("HAUNTER").species, "GENGAR", "HAUNTER evolves into GENGAR")
T.eq(evoOf("POLIWHIRL").method, "LEVEL", "POLIWHIRL stays a level evolution")
T.eq(evoOf("POLIWHIRL").level, 18, "POLIWHIRL evolves at 18 (was 25)")
T.eq(evoOf("POLIWHIRL").species, "POLIWRATH", "POLIWHIRL evolves into POLIWRATH")

run.release()
T.finish("yellow_legacy_changes")
