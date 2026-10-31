# Warfare Science Bunker Trade Inheritance v1.4

An addon for **Warfare ALife Overhaul (WALO)** on S.T.A.L.K.E.R. Anomaly/GAMMA that preserves the scientific trading role of the Yantar and Jupiter bunkers after faction ownership changes.

When WALO assigns a replacement trader to a captured bunker, this addon gives that trader the bunker's scientist trade profile. The NPC keeps their actual faction, while scientific supply progression uses goodwill with that faction.

## Main features

- Preserves Sakharov's trade profile at Yantar and Hermann's trade profile at Jupiter.
- Uses the trader's actual faction goodwill for scientific supply-tier checks instead of Ecologist goodwill.
- Repairs existing online traders after loading a save and checks newly spawned or returning online traders automatically.
- Restores the scientific profile if later trade initialization resets it to an ordinary faction profile.
- Updates both GAMMA's `trader_autoinject.supply_level()` helper and the inventory UI's separate `supply_level()` helper to use the same scientific tier, when those functions are available.

WALO remains responsible for bunker ownership, capture, service spawning and NPC replacement. The addon does not create traders or change their faction or diplomacy.

## Supported scientist bunkers

| Location | Smart terrain | Scientific trade profile |
|---|---|---|
| Yantar | `yan_smart_terrain_6_4` | `items\trade\trade_ecolog_sakharov.ltx` |
| Jupiter | `jup_b41` | `items\trade\trade_ecolog_hermann.ltx` |

The repair targets generated Warfare traders identified through their section or name, using the `sim_default_<faction>_trader` convention. Generated Ecologist traders at these bunkers also qualify. Named story scientists and traders at other locations are outside this filter.

## Behavior after faction capture

For example, if Mercenaries capture Yantar and WALO assigns a Mercenary trader there, the NPC remains a Mercenary but uses Sakharov's scientific trade profile. Scientific supply progression then uses Mercenary goodwill (`killer`) rather than Ecologist goodwill. At Jupiter, the same rule uses Hermann's profile.

The script reads the scientific profile's `buy_supplies` condition and substitutes the trader's faction for `ecolog` in `actor_goodwill_ge`, `actor_goodwill_gt`, `actor_goodwill_le` and `actor_goodwill_lt` checks. Other conditions, including `heavy_pockets_functor()`, are preserved. The profile files are not edited on disk; prices, discounts and other trade rules remain those of the selected scientific profile.

Available items and artifact recipes depend on the installed scientific profiles and GAMMA systems. The addon adds no recipe definitions or quest unlocks. It also does not make a hostile trader friendly or override WALO's bunker protection and capture settings.

Existing online traders are scanned on the actor's first update after loading. Generated traders are then checked through `npc_on_update` at most once every **3 seconds per NPC**, with an additional repair path through normal trade-manager updates. Offline traders must return online before these NPC checks can repair them.

## WALO dependency and compatibility

- Requires **WALO**, **Warfare enabled**, and the Anomaly/GAMMA trade resources and script APIs used by the addon.
- Requires the Sakharov and Hermann trade profiles supplied by the installation; they are not bundled here.
- **WALO 1.6.10** is the original documented target in the v1.4 script and historical README.
- **WALO 1.6.11** is the source-reviewed integration target recorded in the [WALO integration notes](INTEGRATION/WALO_AUTHOR_NOTES.md). That focused review found matching bunker identifiers, service-trader conventions and trade interfaces, with no release-blocking incompatibility identified in the reviewed scope.

The WALO 1.6.11 finding is source-level evidence, not a new in-game compatibility certification. Exact GAMMA/engine versions, the running MO2 virtual filesystem, resolved DLTX configuration and final Lua wrapper order remain unverified. Compatibility with other WALO versions or modpacks is not established by these notes.

SIN HQ and UNISG HQ are not dependencies. This addon supplies one separate script and does not replace WALO's controller or GAMMA/UI scripts.

## Installation with Mod Organizer 2

1. Back up your save and retain your previous working package.
2. Install **`Warfare_Science_Bunker_Trade_Inheritance_1.4_FULL_MO2.zip`** through MO2. The archive has `gamedata/` directly at its root.
3. Disable duplicate or older Science Bunker Trade Inheritance packages. Keep WALO and its required GAMMA patches enabled, and place this addon after them in MO2's left pane.
4. Restart the game and load your Warfare save. **A new game is not required by this addon.**
5. Approach the trader at Yantar or Jupiter and allow a few seconds for the online NPC to update. If necessary, use **Refresh Trade Inventory** once from the Debug Launcher, if that option is available in your installation.

No manual changes to the original WALO or GAMMA installation are needed. MO2 file priority does not by itself guarantee the execution order of runtime Lua wrappers.

## Integration information for the WALO author

The complete gameplay payload is [zzzzzz_warfare_science_bunker_trade_fix.script](gamedata/scripts/zzzzzz_warfare_science_bunker_trade_fix.script). Its existing v1.4 implementation is retained.

The module wraps these functions while preserving the implementations present when it installs:

- `trade_manager.trade_init(npc, cfg)` — selects the scientific profile for matching bunker traders.
- `trade_manager.update(npc, force_refresh)` — repairs the profile and applies the owner-aware scientific supply section after the base update.
- `trader_autoinject.supply_level(npc, as_number)` — optional GAMMA helper hook.
- `ui_inventory.supply_level(npc, as_number)` — optional inventory UI helper hook.

It registers `actor_on_first_update`, `npc_on_update` and `npc_on_death_callback`. Core dependencies include `trade_manager.get_trade_profile()`, `trade_manager.get_trade_cfg()`, the `xr_logic` condlist functions, actor/NPC state and the installed scientific trade INIs. Smart-terrain lookup uses stored NPC data, with `xr_gulag` and ALife fallbacks.

The recommended initial integration approach is to evaluate the single script as a separate addon, loaded once, while keeping WALO authoritative for service lifecycle and ownership. An upstream incorporation must preserve existing wrapper chains and use one implementation path; the standalone module should be disabled in a package that incorporates the same feature natively.

See [INTEGRATION/WALO_AUTHOR_NOTES.md](INTEGRATION/WALO_AUTHOR_NOTES.md) for detailed dependencies, hooks, existing compatibility findings and recommended in-game acceptance checks.

## Known limitations

- Only the two mapped bunkers and matching generated Warfare traders are covered. The script does not force NPC spawning, offline updates or bunker capture.
- Outside Warfare, the trade wrappers delegate to the original behavior. There is no separate Story Mode gate; a complete Story Mode or quest playthrough is not claimed.
- Mods changing the two scientific profiles, bunker smart assignments or any hooked function require a compatibility check. The addon preserves other supply conditions and does not convert every profile rule to owner-faction goodwill.
- Optional GAMMA/UI helper hooks are retried if initially unavailable. Once installed, their flags do not detect or reinstall a hook replaced later by another script.
- Errors in dependent trade code can interrupt repair. The per-NPC reentrancy guard is cleared on the normal return path, rather than through protected exception cleanup; the integration notes record this as an unverified failure-path risk.
- No new in-game testing is claimed for the release preparation or this README correction. Source checks and mocked tests do not establish final inventory, delayed injections, capture/respawn behavior or UI rendering in a running game.

## Diagnostics and documentation

The script writes diagnostics to `xray_server.log` with the `[SCI-TRADE v1.4]` prefix. Installation messages include:

```text
[SCI-TRADE v1.4] installed
[SCI-TRADE v1.4] trader_autoinject.supply_level hook installed
[SCI-TRADE v1.4] ui_inventory.supply_level hook installed
```

The two helper messages appear only when those functions are available. `profile repair` and `stock repair` messages identify the affected NPC, smart terrain, faction, profile and selected tier. Hook installation alone does not prove the final stock is correct in game.

The original `README.txt` is retained in the source repository as historical v1.4 documentation. See [CHANGELOG.md](CHANGELOG.md) for the documented version history and [RELEASE_NOTES.md](RELEASE_NOTES.md) for the release description.
