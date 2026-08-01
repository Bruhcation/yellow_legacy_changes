-- Yellow Legacy by TSP -- move changes (pages 11-14) and stat changes
-- (pages 15-19) from the design PDF.  Values are the NEW numbers; the
-- patches touch only the fields the document changes.
--
-- Engine behavior changes that the data cannot express ride on wrapped
-- seams (installed on game.ready, the nuzlocke pattern):
--   * FOCUS ENERGY is functional: exactly 2x the usual crit rate, instead
--     of the Gen 1 bug (faithful ruleset) or the engine's 4x (modern).
--   * LEECH SEED drains a flat 1/8 of max HP per turn, without the Gen 1
--     toxic-counter glitch.
--
-- Learnset, TM/HM and encounter changes ship in learnsets.lua (generated
-- from 'Yellow Legacy Data.xlsx'): species and move display names are
-- resolved against the player's imported data at load, so the file works
-- on any build without shipping a name table.
local applyTables, resolveTables -- forward: applyLegacyTables reads the file then applies
local function applyLegacyTables(mod)
  local source = mod:read("learnsets.lua")
  if not source then
    mod.log:error("learnsets.lua missing from %s -- reinstall the mod", mod.path)
    return
  end
  local chunk, compileErr = load(source, "@" .. mod.path .. "/learnsets.lua")
  if not chunk then
    mod.log:error("learnsets.lua did not compile: %s", tostring(compileErr))
    return
  end
  local ok, data = pcall(chunk)
  if not ok then
    mod.log:error("learnsets.lua failed to load: %s", tostring(data))
    return
  end
  applyTables(mod, data)
end

-- Pure resolution of one tables struct (the shape learnsets.lua returns)
-- against a content facade: display names -> ids.  Reads only (get/each),
-- so headless tests can drive it after the loader freezes registries.
-- Returns the resolved struct plus unknown-name counts.
resolveTables = function(content, data)
  local function norm(s) return (s:gsub("[^%w]", ""):upper()) end

  local moveId, speciesId = {}, {}
  for id, rec in content.moves:each() do
    if rec and rec.name then moveId[norm(rec.name)] = id end
  end
  for id, rec in content.pokemon:each() do
    if rec and rec.name then speciesId[norm(rec.name)] = id end
  end

  local counts = { moves = 0, species = 0, maps = 0 }
  local function moveByName(name)
    local id = moveId[norm(name)]
    if not id then counts.moves = counts.moves + 1 end
    return id
  end
  local function speciesByName(name)
    local id = speciesId[norm(name)]
    if not id then counts.species = counts.species + 1 end
    return id
  end

  local out = { learnsets = {}, tmhm = {}, encounters = {}, rods = {} }

  for name, entries in pairs(data.learnsets or {}) do
    local id = speciesByName(name)
    if id then
      local learnset, level1 = {}, {}
      for _, e in ipairs(entries) do
        local mid = moveByName(e[2])
        if mid then
          learnset[#learnset + 1] = { level = e[1], move = mid }
          if e[1] == 1 then level1[#level1 + 1] = mid end
        end
      end
      out.learnsets[id] = { learnset = learnset, level1 = level1 }
    end
  end

  for name, moves in pairs(data.tmhm or {}) do
    local id = speciesByName(name)
    if id then
      local list = {}
      for _, m in ipairs(moves) do
        local mid = moveByName(m)
        if mid then list[#list + 1] = mid end
      end
      out.tmhm[id] = list
    end
  end

  for mid, enc in pairs(data.encounters or {}) do
    local entry = {}
    if enc.grass and #enc.grass > 0 then
      local slots = {}
      for _, s in ipairs(enc.grass) do
        local sp = speciesByName(s[2])
        if sp then slots[#slots + 1] = { level = s[1], species = sp } end
      end
      if #slots > 0 then entry.grass = slots end
    end
    if enc.water and #enc.water > 0 then
      local slots = {}
      for _, s in ipairs(enc.water) do
        local sp = speciesByName(s[2])
        if sp then slots[#slots + 1] = { level = s[1], species = sp } end
      end
      if #slots > 0 then entry.water = slots end
    end
    for rod, slots in pairs(enc.rods or {}) do
      local list = {}
      for _, s in ipairs(slots) do
        local sp = speciesByName(s[2])
        if sp then list[#list + 1] = { species = sp, level = s[1] } end
      end
      if #list > 0 then
        out.rods[rod] = out.rods[rod] or {}
        out.rods[rod][mid] = list
      end
    end
    if next(entry) then
      if content.encounters:get(mid) then
        out.encounters[mid] = entry
      else
        counts.maps = counts.maps + 1
      end
    end
  end

  return out, counts
end

-- Pure application of one tables struct (the shape learnsets.lua returns),
-- so headless tests can drive the resolver + patch mechanics with fixture
-- names.  Species and move names are display names resolved against the
-- merged view; unknown names are counted and skipped.
applyTables = function(mod, data)
  local resolved, counts = resolveTables(mod.content, data)
  if resolved == nil then return end

  -- learnsets: replace wholesale (level 1 entries also seed level1Moves)
  for id, entry in pairs(resolved.learnsets) do
    local patch = { learnset = entry.learnset }
    if #entry.level1 > 0 then patch.level1Moves = entry.level1 end
    mod.content.pokemon:patch(id, patch)
  end

  -- tmhm: the workbook's per-species machine lists, in TM/HM order
  for id, list in pairs(resolved.tmhm) do
    mod.content.pokemon:patch(id, { tmhm = list })
  end

  -- encounters: grass + surf slot tables; rates stay vanilla
  for mid, entry in pairs(resolved.encounters) do
    local patch = {}
    if entry.grass then patch.grass = { slots = entry.grass } end
    if entry.water then patch.water = { slots = entry.water } end
    mod.content.encounters:patch(mid, patch)
  end

  -- fishing: per-map rod pools behind the three rod keys
  local poolKeys = { OLD_ROD = "legacyOldRod", GOOD_ROD = "legacyGoodRod",
                     SUPER_ROD = "legacySuperRod" }
  local fishing, pools = {}, {}
  for rod, perMap in pairs(resolved.rods) do
    if next(perMap) then
      fishing[rod] = { perMap = poolKeys[rod] }
      pools[poolKeys[rod]] = perMap
    end
  end
  if next(fishing) then
    mod.content.field:override("fishing", fishing)
    for key, perMap in pairs(pools) do
      mod.content.field:patch(key, perMap)
    end
  end

  if counts.moves > 0 then
    mod.log:warn("%d unknown move names skipped", counts.moves)
  end
  if counts.species > 0 then
    mod.log:warn("%d unknown species names skipped", counts.species)
  end
  if counts.maps > 0 then
    mod.log:warn("%d unknown maps skipped", counts.maps)
  end
end
return function(mod)
  local MOVES = {
    -- Normal / general
    BARRAGE = { power = 20, accuracy = 100 },
    BIND = { accuracy = 95 },
    COMET_PUNCH = { power = 25, accuracy = 100, pp = 25 },
    CONSTRICT = { power = 40 },
    DISABLE = { accuracy = 75 },
    DIZZY_PUNCH = { pp = 20, effect = "CONFUSION_SIDE_EFFECT" },
    DOUBLESLAP = { power = 20, accuracy = 100, pp = 35 },
    DOUBLE_EDGE = { power = 120, pp = 10 },
    EXPLOSION = { power = 250 },
    FOCUS_ENERGY = { pp = 30 },
    FURY_ATTACK = { accuracy = 100 },
    FURY_SWIPES = { power = 20, accuracy = 100 },
    GLARE = { accuracy = 90 },
    MEGA_KICK = { accuracy = 85, pp = 10 },
    PAY_DAY = { power = 60 },
    RAGE = { power = 60 },
    RAZOR_WIND = { power = 80, accuracy = 100, effect = "HYPER_BEAM_EFFECT" },
    SELFDESTRUCT = { power = 200 },
    SKULL_BASH = { power = 100, accuracy = 100, effect = "HYPER_BEAM_EFFECT" },
    SOFTBOILED = { pp = 5 },
    SONICBOOM = { accuracy = 100 },
    SUPERSONIC = { accuracy = 70 },
    TACKLE = { accuracy = 100 },
    TAKE_DOWN = { power = 95, accuracy = 100 },
    TRANSFORM = { pp = 10, priority = 1 },
    TRI_ATTACK = { power = 85, pp = 15, effect = "BURN_SIDE_EFFECT2" },
    -- Fire / Ice / Electric
    FIRE_PUNCH = { power = 70, effect = "BURN_SIDE_EFFECT2" },
    FIRE_SPIN = { accuracy = 85 },
    BLIZZARD = { accuracy = 85 },
    ICE_PUNCH = { power = 70 },
    THUNDER = { accuracy = 85, pp = 5 },
    THUNDERPUNCH = { power = 70 },
    -- Flying
    FLY = { accuracy = 100 },
    GUST = { type = "FLYING" },
    SKY_ATTACK = { power = 120, accuracy = 85, effect = "NO_ADDITIONAL_EFFECT" },
    WING_ATTACK = { power = 60 },
    -- Bug
    CUT = { power = 55, accuracy = 100, type = "BUG" },
    LEECH_LIFE = { power = 50, pp = 25 },
    PIN_MISSILE = { power = 20, accuracy = 100, pp = 30 },
    TWINEEDLE = { power = 40 },
    -- Grass
    ABSORB = { power = 30, pp = 25 },
    EGG_BOMB = { accuracy = 100, type = "GRASS" },
    LEECH_SEED = { accuracy = 90 },
    MEGA_DRAIN = { power = 65, pp = 20 },
    PETAL_DANCE = { power = 90 },
    SOLARBEAM = { power = 180 },
    VINE_WHIP = { power = 40, pp = 25 },
    -- Ghost / Rock / Ground
    LICK = { power = 40 },
    NIGHT_SHADE = { power = 60, effect = "NO_ADDITIONAL_EFFECT" },
    ROCK_SLIDE = { accuracy = 95, effect = "FLINCH_SIDE_EFFECT1" },
    ROCK_THROW = { accuracy = 95, pp = 25 },
    BONE_CLUB = { accuracy = 100 },
    BONEMERANG = { pp = 20 },
    DIG = { power = 70 },
    -- Water
    BUBBLE = { power = 10 },
    CLAMP = { accuracy = 85 },
    CRABHAMMER = { power = 110, accuracy = 100 },
    HYDRO_PUMP = { accuracy = 85, pp = 10 },
    WATERFALL = { power = 70, effect = "FLINCH_SIDE_EFFECT1" },
    PSYWAVE = { accuracy = 95 },
    -- Fighting
    HI_JUMP_KICK = { power = 120 },
    JUMP_KICK = { power = 90 },
    KARATE_CHOP = { accuracy = 95, type = "FIGHTING" },
    LOW_KICK = { accuracy = 100 },
    ROLLING_KICK = { power = 70, accuracy = 100 },
    SUBMISSION = { accuracy = 100 },
    -- Poison
    ACID = { power = 65 },
    POISON_GAS = { accuracy = 85, pp = 35 },
    POISONPOWDER = { accuracy = 90 },
    POISON_STING = { power = 35 },
    SLUDGE = { power = 90 },
    SMOG = { accuracy = 80 },
    -- Dragon / misc
    SLAM = { accuracy = 100, type = "DRAGON", effect = "FLINCH_SIDE_EFFECT1" },
  }

  local STATS = {
    CHARMANDER = { baseStats = { special = 55 } },
    CHARMELEON = { baseStats = { special = 70 } },
    CHARIZARD = { baseStats = { special = 95 } },
    ARBOK = { baseStats = { hp = 62, attack = 95, speed = 90 } },
    PIKACHU = { baseStats = { hp = 60, defense = 50, special = 70 } },
    CLEFABLE = { baseStats = { special = 95 } },
    VULPIX = { baseStats = { hp = 45, defense = 45, special = 70, speed = 75 } },
    WIGGLYTUFF = { baseStats = { defense = 55, special = 85 } },
    GOLBAT = { baseStats = { speed = 100 } },
    ODDISH = { baseStats = { hp = 50 } },
    GLOOM = { baseStats = { hp = 70 } },
    VILEPLUME = { baseStats = { hp = 90 } },
    VENOMOTH = { baseStats = { attack = 75, special = 95, speed = 100 } },
    DIGLETT = { baseStats = { attack = 70 } },
    DUGTRIO = { baseStats = { attack = 90 } },
    PONYTA = { baseStats = { speed = 100 } },
    RAPIDASH = { baseStats = { speed = 115 } },
    FARFETCHD = { baseStats = {
      hp = 62, attack = 75, defense = 65, special = 68, speed = 70,
    } },
    MUK = { baseStats = { special = 85 } },
    ONIX = { baseStats = { hp = 75, attack = 80, special = 65, speed = 85 } },
    MAROWAK = { baseStats = { special = 80 } },
    HITMONLEE = { baseStats = { hp = 65, defense = 70, special = 60, speed = 93 } },
    HITMONCHAN = { baseStats = { hp = 60, attack = 50, special = 105 } },
    LICKITUNG = { baseStats = { hp = 95, attack = 70, defense = 85, special = 75 } },
    MAGMAR = { baseStats = { special = 95 } },
    EEVEE = { baseStats = { hp = 70, attack = 65, defense = 65, special = 70 } },
    PORYGON = { baseStats = { hp = 75, attack = 70, special = 95 } },
  }

  -- Patch unconditionally: vanilla always carries every id, and a total
  -- conversion that tombstoned one simply wins over this op.  Deep
  -- registries accept patch on ids with no base record, which is also
  -- what keeps the headless fixture test able to verify the merged view.
  for id, patch in pairs(MOVES) do
    mod.content.moves:patch(id, patch)
  end
  for id, patch in pairs(STATS) do
    mod.content.pokemon:patch(id, patch)
  end

  -- Yellow Legacy type changes: GHOST attacks become special, and the
  -- Gen 1 chart bug that made Psychic immune to Ghost is fixed (Ghost is
  -- now super effective against Psychic).  Patch, not override: the type
  -- records and chart rows come from the engine's own registrations, and
  -- a total conversion that replaced them wins over this op.
  mod.content.type_chart:patch("GHOST", { category = "special" })
  mod.content.type_chart:patch("GHOST>PSYCHIC_TYPE", { multiplier = 20 })

  applyLegacyTables(mod)

  mod.events:on("game.ready", function()
    local Stats = require("src.pokemon.Stats")
    local Damage = require("src.battle.Damage")

    -- The engine's own high-crit list (src/battle/Damage.lua), copied so
    -- the wrap below stays an exact mirror of the vanilla roll.
    local HIGH_CRIT = {
      KARATE_CHOP = true, RAZOR_LEAF = true, CRABHAMMER = true, SLASH = true,
    }
    local function shl(x) return math.min(255, x * 2) end

    local vanillaCritRoll = Damage.critRoll
    Damage.critRoll = function(ruleset, attacker, moveId, rng, highCrit)
      if not attacker.focusEnergy then
        return vanillaCritRoll(ruleset, attacker, moveId, rng, highCrit)
      end
      -- focus energy: exactly 2x the usual crit rate (b doubles) in every
      -- ruleset, replacing both the Gen 1 bug and the engine's 4x
      local speed
      if ruleset.critUsesBaseSpeed == false then
        speed = Stats.applyStage(attacker.curStats.speed,
          attacker.stages and attacker.stages.speed or 0)
      else
        speed = attacker.def.baseStats.speed
      end
      local b = math.floor(speed / 2)
      b = shl(shl(b))
      if highCrit == nil then highCrit = HIGH_CRIT[moveId] end
      if highCrit then
        b = shl(shl(b))
      else
        b = math.floor(b / 2)
      end
      return rng(0, 255) < b
    end

    local Status = require("src.battle.Status")
    local Strings = require("src.core.Strings")
    local vanillaResidual = Status.residual
    Status.residual = function(battler, opponent, battle)
      local seeded = battler.leechSeeded and battler.mon.hp > 0
        and opponent.mon.hp > 0
      if not seeded then return vanillaResidual(battler, opponent, battle) end
      -- let vanilla handle every other residual; the seed itself is
      -- applied here as a flat 1/8 (no toxic-counter multiplication)
      battler.leechSeeded = nil
      local msgs = vanillaResidual(battler, opponent, battle) or {}
      battler.leechSeeded = true
      local mon = battler.mon
      local dmg = math.max(1, math.floor(mon.stats.hp / 8))
      dmg = math.min(dmg, mon.hp)
      mon.hp = mon.hp - dmg
      opponent.mon.hp = math.min(opponent.mon.stats.hp, opponent.mon.hp + dmg)
      msgs[#msgs + 1] = Strings("LEECH SEED saps\n%s!", battler.name)
      return msgs
    end
  end)

  -- "Dragon physical" toggle in the MODS menu: the per-mod options
  -- auto-UI renders DRAGON PHYS from the schema below, persists the value
  -- in options.lua under options.modOptions, and fires mod.options_changed
  -- when the player flips it.  The merged type records are live tables
  -- (TypeChart.category reads the record on every call), so the switch
  -- applies instantly to damage.  Default OFF = Gen 1 faithful.
  local function setDragonPhysical(data, on)
    local types = data and data.type_chart and data.type_chart.types
    local dragon = types and types.DRAGON
    if dragon then dragon.category = on and "physical" or "special" end
    return dragon ~= nil
  end

  mod.options:define({
    { key = "dragonPhysical", type = "toggle", label = "DRAGON PHYS",
      default = false },
  })

  local function applyDragonOption()
    local ok, Game = pcall(require, "src.core.Game")
    local data = ok and Game and Game.data
    if data then setDragonPhysical(data, mod.options:get("dragonPhysical")) end
  end

  mod.events:on("mod.options_changed", function(ev)
    if ev and ev.mod == mod.id and ev.key == "dragonPhysical" then
      local ok, Game = pcall(require, "src.core.Game")
      local data = ok and Game and Game.data
      if data then setDragonPhysical(data, ev.value == true) end
    end
  end)

  mod.events:on("game.ready", function()
    applyDragonOption()
  end)

  mod.exports = {
    applyTables = applyTables,
    resolveTables = resolveTables,
    setDragonPhysical = setDragonPhysical,
  }
end
