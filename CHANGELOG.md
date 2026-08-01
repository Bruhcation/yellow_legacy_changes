# Changelog

## [1.6.0] - 2026-08-01

### Added

- The hack's rematch teams (`data/trainers/parties.asm` "; Rematch" rows)
  for the seven gym leaders, the Elite Four and the Champion, appended to
  each class's parties with a `rematchIndex` marker.  A trainer-rematch
  mod (Trainer Rematch 0.2.0+) reads the marker and uses the team when it
  triggers a rematch; without one, nothing changes.

## [1.5.0] - 2026-08-01

### Added

- Evolution changes from the Yellow Legacy disassembly
  (`data/pokemon/evos_moves.asm`): the four trade evolutions become level
  evolutions — KADABRA at 42, MACHOKE at 38, GRAVELER at 38, HAUNTER at 42 —
  and POLIWHIRL evolves into POLIWRATH at 18 (was 25).

## [1.4.0] - 2026-08-01

### Added

- Trainer and gym-leader team updates from the Yellow Legacy disassembly
  (cRz-Shadows/Pokemon_Yellow_Legacy, data/trainers/parties.asm): 44
  classes rebalanced -- route trainers, Rocket grunts, the Rival, Gym
  Leaders, Elite Four and Champion. Levels and species follow the hack's
  teams exactly; party indexes are preserved so every battle maps to the
  same team as before.
- Only existing trainer classes are touched (no new trainers); appended
  rematch / Victory-Road battles from the hack are not ported.

## [1.0.0] - 2026-08-01

### Added

- Move changes from Yellow Legacy (TSP) PDF pages 11-14: 73 moves
  rebalanced (power/accuracy/pp), 5 type changes, 11 effect changes,
  FOCUS ENERGY functional at 2x crit, LEECH SEED flat 1/8 drain.
- Stat changes from pages 15-19: 27 species base stats rebalanced.

## [1.3.0] - 2026-08-01

### Changed

- The DRAGON PHYS toggle moved from the OPTIONS menu to the mod's own
  options in MODS > yellow_legacy_changes, using the per-mod options
  API (mod.options:define + mod.options_changed).

## [1.2.0] - 2026-08-01

### Added

- GHOST attacks now use the Special stat (Yellow Legacy type change).
- Ghost is now super effective against Psychic, fixing the Gen 1 chart
  bug that made Psychic immune.
- A **DRAGON PHYS** toggle in MODS > yellow_legacy_changes: switches
  DRAGON moves to the physical stat at runtime; persisted in options.lua,
  default OFF.

## [1.1.0] - 2026-08-01

### Added

- Learnsets for all 151 species from 'Yellow Legacy Data.xlsx' (sheet 1),
  replacing each species' level-up move list; level-1 entries seed the
  starting moves.
- TM/HM compatibility lists for 146 species (sheet 2), in TM01..HM05 order.
- Encounter changes for 57 maps (sheet 3): grass, surf and rod slot tables;
  encounter rates stay vanilla. Rod pools live behind per-map fishing
  groups for the Old, Good and Super Rods.
- Name resolution: species and move display names are resolved against the
  player's imported data at load, so the workbook's names never go stale.
