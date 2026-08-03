-- Hard Mode rules for Yellow Legacy Changes: forced SET battle style,
-- no items in battle (Poké Balls excepted), and badge-gated level caps.
-- Pure helpers only -- the wiring lives in main.lua -- so the headless
-- test can drive them against fixture data without a running game.
--
-- Caps by gym badge (count, not which badges): 0 badges = 12, 1 = 21,
-- 2 = 24, 3 = 35, 4 = 43, 5 = 50, 6 = 53, 7 = 55.  Eight badges (and
-- any higher count) mean no cap at all.
local HardMode = {}

HardMode.LEVEL_CAPS = { 12, 21, 24, 35, 43, 50, 53, 55 }

-- Max level for a badge count (nil = uncapped).
function HardMode.capLevelFor(badgeCount)
  if type(badgeCount) ~= "number" then return nil end
  return HardMode.LEVEL_CAPS[badgeCount + 1]
end

-- The exp a mon may hold at its cap level (nil = uncapped).  Uses the
-- mon's own growth rate against the merged growth_rates, so a modded
-- curve caps on the same numbers the engine levels on.
function HardMode.capExpFor(data, mon, badgeCount)
  local cap = HardMode.capLevelFor(badgeCount)
  if not cap or not mon then return nil end
  local speciesDef = data and data.pokemon and data.pokemon[mon.species]
  if not speciesDef then return nil end
  local Growth = require("src.pokemon.Growth")
  return Growth.expForLevel(speciesDef.growthRate, cap, data.growth_rates)
end

-- Clamp a pending exp gain to the cap: 0 once the mon is already at the
-- cap (gain resumes when the next badge lifts it), otherwise the gain
-- trimmed so exp can never cross the cap level.
function HardMode.clampExpGain(data, mon, badgeCount, gained)
  local capExp = HardMode.capExpFor(data, mon, badgeCount)
  if not capExp then return gained end
  local exp = mon and mon.exp or 0
  if exp >= capExp then return 0 end
  return math.min(gained, capExp - exp)
end

-- Whether a RARE CANDY use would push the mon past its cap (the candy
-- sets exp by level directly, bypassing the exp path, so it needs its
-- own gate).
function HardMode.blocksRareCandy(data, mon, badgeCount)
  local cap = HardMode.capLevelFor(badgeCount)
  if not cap or not mon then return false end
  return (mon.level or 0) >= cap
end

return HardMode
