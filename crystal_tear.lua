-- Crystal Tear post-game quest (wired in main.lua):
--   * Professor Oak gifts the CRYSTAL TEAR key item after the Hall of
--     Fame, once 150 species are owned (Mew excluded -- it cannot be
--     obtained by any in-game means).
--   * Using the tear on CERULEAN_CAVE_B1F after Mewtwo has been dealt
--     with (EVENT_BEAT_MEWTWO -- defeated, caught or fled, the same
--     gate as the static-battle flag) plays the "MEW!" reveal with
--     Mew's cry, then starts a level-75 Mew battle.  Whatever the
--     outcome (win, catch, flee or loss) the tear then shatters: a
--     text box announces it and the item leaves the bag -- one shot.
--
-- Pure logic lives here so the headless tests can drive every branch
-- without a live game: rows are plain script data, the condition is a
-- plain function.

local CrystalTear = {}

-- The gift condition counts every owned species except Mew: with Mew
-- unobtainable, "all 150" means the full dex minus the 151st slot.
-- Owning Mew through another means never fills a hole elsewhere.
function CrystalTear.ownedWithoutMew(save)
  local dex = save and save.pokedex
  local n = 0
  if dex and dex.owned then
    for id in pairs(dex.owned) do
      if id ~= "MEW" then n = n + 1 end
    end
  end
  return n
end

-- Hall of Fame beaten AND 150 owned: the Crystal Tear gift condition.
-- save.hallOfFame is the record list the champion battle appends to, so
-- "beat the Elite Four and the champion" is simply non-empty.
function CrystalTear.legacyComplete(save)
  if not save or not save.hallOfFame or #save.hallOfFame == 0 then
    return false
  end
  return CrystalTear.ownedWithoutMew(save) >= 150
end

-- Rows prepended to Oak's OAKS_LAB talk (TEXT_OAKSLAB_OAK1).  The gift
-- branch fires when the quest is ready and the tear has not been handed
-- over yet; anything else falls through to the regular dialogue via the
-- crystal_tear_regular label.  The base script's rows follow this list
-- verbatim (Yellow's OAK1 script branches on labels only, so prepending
-- is safe -- numeric jump targets would shift and are not used there).
-- A bag-full halt inside give_item aborts the script before the flag
-- row, so talking again retries cleanly, like the parcel gift.
function CrystalTear.giftRows()
  return {
    { "face_player" },
    { "check_flag", "EVENT_GOT_CRYSTAL_TEAR" },
    { "jump_if_true", "crystal_tear_regular" },
    { "check_crystal_tear_gift" },
    { "jump_if_false", "crystal_tear_regular" },
    { "give_item", "CRYSTAL_TEAR", 1, false },
    { "set_flag", "EVENT_GOT_CRYSTAL_TEAR" },
    { "show_text", "OAK: {PLAYER}!\nYou've caught all\n150 POKéMON!" },
    { "show_text", "You've truly\nbecome a POKéMON\nMASTER!" },
    { "show_text", "Take this -- it\nis the CRYSTAL\nTEAR." },
    { "play_sound", "Get_Key_Item" },
    { "show_text", "{PLAYER} got\nCRYSTAL TEAR!" },
    { "show_text", "OAK: Deep within\nCERULEAN CAVE\nMEW slumbers." },
    { "show_text", "Only a MASTER\ncan wake it.\fGo -- the CAVE\nawards it to you!" },
    { "jump", "end" },
    { "label", "crystal_tear_regular" },
  }
end

-- The tear's use sequence on CERULEAN_CAVE_B1F: the "MEW!" reveal with
-- Mew's cry, then the level-75 wild battle -- the same play_cry +
-- show_text + static_battle shape as the Mewtwo encounter
-- (data/scripts/flavor/cerulean_cave_b1f.lua).  static_battle only
-- stamps EVENT_BEAT_MEW on a non-blackout result, so a loss leaves it
-- unset; the rows after it run on every outcome (the runner resumes
-- once the battle closes, whatever the result), so the tear shatters
-- and leaves the bag even after a loss -- the encounter is one shot,
-- period.
function CrystalTear.mewRows()
  return {
    { "play_cry", "MEW" },
    { "show_text", "MEW!" },
    { "static_battle", "MEW", 75, "EVENT_BEAT_MEW" },
    { "set_flag", "EVENT_BEAT_MEW" },
    { "take_item", "CRYSTAL_TEAR", 1 },
    { "show_text", "The CRYSTAL TEAR\nshatters!" },
  }
end

-- Mew's learnset, patched wholesale so a level-75 Mew carries a strong
-- set: the most recent four moves at 75 are PSYCHIC, MEGA_PUNCH,
-- AMNESIA and SOFTBOILED (PSYCHIC is the engine's PSYCHIC_M move id --
-- the display name is PSYCHIC).  Mew cannot be obtained by any other
-- in-game route, so this never leaks into ordinary play.
function CrystalTear.mewLearnset()
  return {
    { level = 1, move = "POUND" },
    { level = 10, move = "TRANSFORM" },
    { level = 20, move = "METRONOME" },
    { level = 30, move = "BARRIER" },
    { level = 40, move = "PSYCHIC_M" },
    { level = 50, move = "MEGA_PUNCH" },
    { level = 60, move = "AMNESIA" },
    { level = 70, move = "SOFTBOILED" },
  }
end

return CrystalTear
