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
end
