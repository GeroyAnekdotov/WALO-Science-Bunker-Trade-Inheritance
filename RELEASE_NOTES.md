# Warfare Science Bunker Trade Inheritance v1.4

Yantar and Jupiter retain their scientific trading role after Warfare ownership changes. WALO's replacement trader keeps the capturing faction's identity while using Sakharov's or Hermann's trade profile. Scientific supply goodwill checks follow the trader's actual faction, and the GAMMA trader/UI tier helpers use the same calculation.

This first GitHub release preserves the existing **v1.4 gameplay script byte for byte**. Documentation and packaging have been prepared without resetting the version history or adding gameplay functionality.

## Install

Install **`Warfare_Science_Bunker_Trade_Inheritance_1.4_FULL_MO2.zip`** through MO2 after WALO and the required GAMMA patches. Disable duplicate versions, restart the game and load your Warfare save. Visit the bunker and allow its trader to update for a few seconds. Back up saves; this addon does not require a new game.

## Compatibility and validation

The original target was WALO 1.6.10 with Anomaly/GAMMA. A focused review against available **WALO 1.6.11** sources found matching bunker identifiers, service-trader conventions and trade initialization. The available Anomaly APIs and selected installed GAMMA trader/UI helpers match the required interfaces. No release-blocking incompatibility was found in the reviewed scope.

Release checks cover the unchanged gameplay hash, Lua 5.1 syntax and mocked repair/delegation scenarios, plus archive integrity and exact source equality. **No new in-game test was performed.** Running MO2 VFS, resolved DLTX data, final Lua wrapper order and exact GAMMA/engine versions remain unverified. Other trade-wrapper or bunker changes require a compatibility check; see the README and WALO author notes.

## Assets

- `Warfare_Science_Bunker_Trade_Inheritance_1.4_FULL_MO2.zip` — complete addon with root-level `gamedata/` and release documentation; WALO/GAMMA dependencies are installed separately.
- `Warfare_Science_Bunker_Trade_Inheritance_1.4_FULL_MO2.zip.sha256` — archive checksum.

WALO author integration notes are included under `INTEGRATION/`. No SIN HQ, UNISG HQ, local reference library or installed dependency files are bundled.
