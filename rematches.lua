-- Rematch teams from the Yellow Legacy disassembly
-- (cRz-Shadows/Pokemon_Yellow_Legacy, data/trainers/parties.asm: the
-- "; Rematch" row after each class).  Species are ROM constants resolved
-- against the player's imported data at load.  The mod appends each team
-- to the class's parties and marks the index as `rematchIndex`, which a
-- trainer-rematch mod reads to pick the rematch team.
return {
  rematches = {
  ["OPP_BROCK"] = {
    {level = 64, species = "OMASTAR"}, {level = 65, species = "ONIX"},
    {level = 64, species = "KABUTOPS"}, {level = 64, species = "GOLEM"},
    {level = 64, species = "NINETALES"}, {level = 65, species = "AERODACTYL"},
  },
  ["OPP_MISTY"] = {
    {level = 64, species = "SEADRA"}, {level = 65, species = "GOLDUCK"},
    {level = 64, species = "LAPRAS"}, {level = 64, species = "BLASTOISE"},
    {level = 64, species = "VAPOREON"}, {level = 65, species = "STARMIE"},
  },
  ["OPP_LT_SURGE"] = {
    {level = 64, species = "ELECTRODE"}, {level = 65, species = "MAGNETON"},
    {level = 64, species = "JOLTEON"}, {level = 64, species = "PORYGON"},
    {level = 64, species = "ELECTABUZZ"}, {level = 65, species = "RAICHU"},
  },
  ["OPP_ERIKA"] = {
    {level = 64, species = "TANGELA"}, {level = 64, species = "VENUSAUR"},
    {level = 64, species = "PARASECT"}, {level = 64, species = "EXEGGUTOR"},
    {level = 65, species = "VICTREEBEL"}, {level = 65, species = "VILEPLUME"},
  },
  ["OPP_KOGA"] = {
    {level = 64, species = "GOLBAT"}, {level = 64, species = "MUK"},
    {level = 64, species = "TENTACRUEL"}, {level = 65, species = "WEEZING"},
    {level = 64, species = "ARBOK"}, {level = 65, species = "VENOMOTH"},
  },
  ["OPP_BLAINE"] = {
    {level = 64, species = "RAPIDASH"}, {level = 64, species = "FLAREON"},
    {level = 64, species = "CHARIZARD"}, {level = 64, species = "NINETALES"},
    {level = 65, species = "ARCANINE"}, {level = 65, species = "MAGMAR"},
  },
  ["OPP_SABRINA"] = {
    {level = 65, species = "MR_MIME"}, {level = 64, species = "HYPNO"},
    {level = 64, species = "SLOWBRO"}, {level = 64, species = "JYNX"},
    {level = 64, species = "GENGAR"}, {level = 65, species = "ALAKAZAM"},
  },
  ["OPP_LORELEI"] = {
    {level = 70, species = "WIGGLYTUFF"}, {level = 71, species = "STARMIE"},
    {level = 71, species = "CLOYSTER"}, {level = 70, species = "OMASTAR"},
    {level = 70, species = "EXEGGUTOR"}, {level = 72, species = "LAPRAS"},
  },
  ["OPP_BRUNO"] = {
    {level = 71, species = "CLEFABLE"}, {level = 71, species = "MUK"},
    {level = 70, species = "SLOWBRO"}, {level = 72, species = "HITMONLEE"},
    {level = 72, species = "RHYDON"}, {level = 73, species = "MACHAMP"},
  },
  ["OPP_AGATHA"] = {
    {level = 71, species = "JYNX"}, {level = 71, species = "GYARADOS"},
    {level = 72, species = "ALAKAZAM"}, {level = 71, species = "VENUSAUR"},
    {level = 72, species = "ARBOK"}, {level = 73, species = "GENGAR"},
  },
  ["OPP_LANCE"] = {
    {level = 73, species = "ARCANINE"}, {level = 73, species = "ELECTABUZZ"},
    {level = 74, species = "SNORLAX"}, {level = 74, species = "CHARIZARD"},
    {level = 72, species = "KANGASKHAN"}, {level = 75, species = "DRAGONITE"},
  },
  ["OPP_RIVAL3"] = {
    {level = 77, species = "ALAKAZAM"}, {level = 76, species = "MACHAMP"},
    {level = 75, species = "GYARADOS"}, {level = 74, species = "PIDGEOT"},
    {level = 75, species = "EXEGGUTOR"}, {level = 77, species = "ARCANINE"},
  },
  },
}
