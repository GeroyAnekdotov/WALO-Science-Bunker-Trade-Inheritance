# WALO author integration notes — Science Bunker Trade Inheritance v1.4

## Integration target and payload

Target: **WALO 1.6.11 with Anomaly/GAMMA trade systems**. The original v1.4 header and historical README name WALO 1.6.10; they are preserved unchanged. The reviewed v1.4 script is the complete runtime payload:

`gamedata/scripts/zzzzzz_warfare_science_bunker_trade_fix.script`

[GAME_FILES_SHA256.txt](GAME_FILES_SHA256.txt) records its original SHA-256. No WALO, GAMMA or Anomaly source file is replaced or redistributed. This preparation changes documentation and release tooling only.

## Scope and control flow

`on_game_start()` installs wrappers and registers callbacks. Repair applies only when `IsWarfare()` returns true, or `_G.WARFARE` is true when that function is absent/fails. There is no separate Story Mode gate.

An NPC must match `sim_default_%a+_trader` through its section or name, resolve to one of the two mapped smart terrains, and have a valid actual community other than `none` or `trader`. The filter includes generated Ecologist traders and does not require a particular captor faction. It does not compare the NPC community with a separate smart-owner field.

| Smart terrain | Selected profile |
|---|---|
| `yan_smart_terrain_6_4` | `items\trade\trade_ecolog_sakharov.ltx` |
| `jup_b41` | `items\trade\trade_ecolog_hermann.ltx` |

Smart resolution tries `db.storage[id].gulag_name`, `xr_gulag.get_npc_smart(npc)`, then the ALife server object's `m_smart_terrain_id`. Faction resolution uses `character_community(npc)` with an NPC-method fallback.

On a profile mismatch, the captured original `trade_init()` installs the scientific profile and a normal base update initializes its trade rules. The addon reads `[trader] buy_supplies`, substitutes only `ecolog` arguments in the four `actor_goodwill_ge/gt/le/lt` condition calls, and evaluates the resulting condlist normally. `npc:buy_supplies(config, desired)` applies the selected supply section; `current_buy_supplies` is synchronized in the live trade profile. No profile file is written. Prices, discounts and other profile conditions are inherited as configured, not converted to owner-faction rules.

The first actor update scans online `db.storage` objects, calling `alive()` only after `IsStalker()`. NPC callbacks check generated traders at most every 3,000 ms per ID. Death clears the per-ID throttle and reentrancy guard. There is no offline spawn, capture change, custom save serializer, recipe definition or quest unlock.

## Hooks and dependencies

| Interface | Use |
|---|---|
| `trade_manager.trade_init(npc, cfg)` | Wrapper substitutes the profile only for matching bunker traders; otherwise delegates unchanged. |
| `trade_manager.update(npc, force_refresh)` | Wrapper repairs the profile, calls the captured base implementation, then applies the owner-aware scientific supply section. |
| `trade_manager.get_trade_profile(id[, key])` | Reads `cfg_ltx` and the live profile; updates `current_buy_supplies`. |
| `trade_manager.get_trade_cfg(path)` | Reads the cached scientific INI, with `ini_file(path)` fallback. |
| `trader_autoinject.supply_level(npc, as_number)` | Optional GAMMA helper wrapper returns the supply section or numeric tier; delegates outside scope. |
| `ui_inventory.supply_level(npc, as_number)` | Optional separate UI helper wrapper uses the same resolution; delegates outside scope. |
| `RegisterScriptCallback` | Registers `actor_on_first_update`, `npc_on_update`, `npc_on_death_callback`. |
| `xr_logic.parse_condlist`, `xr_logic.pick_section_from_condlist` | Evaluate the profile's supply expression against `db.actor` and the NPC. |
| `db.storage`, `db.actor`, `IsStalker`, `time_global` | Online scan, actor context and per-NPC timing. |
| NPC methods / ALife helpers | ID, name, section, alive/community, `buy_supplies`; optional smart-resolution fallbacks described above. |

The scientific INIs and all conditions referenced by them must exist in the target installation. The core repair needs the trade-manager and condlist APIs. The two display/helper hooks are optional and retried at actor/NPC updates if initially unavailable. Missing `IsStalker` prevents the initial scan; the NPC-update path remains separate. Initialization retries if the base `trade_init`/`update` functions are unavailable.

## Focused WALO 1.6.11 review

The preserved upstream package identifies itself as 1.6.11 in both `fomod/Info.xml` and `src/gamedata/scripts/warfare.script`. The relevant reference files were checked against the local library's recorded sizes and SHA-256 values; private library paths and manifests are not included in this release.

| Source checked | Finding |
|---|---|
| WALO `src/gamedata/configs/misc/warfare_smarts.ltx` | Both mapped bunker identifiers exist. They retain WALO's protection/resurrection settings; the addon does not make them capturable by overriding those settings. |
| WALO `warfare_utils.script`, `smart_terrain_warfare.script` | Native faction service squads and trader targeting remain WALO-controlled. |
| WALO `warfare_monkeypatches.script`, `xr_logic.configure_schemes` | Warfare-generated traders select faction trade profiles and call `trade_manager.trade_init(npc, trade_ini)`, providing the interception point used here. |
| WALO `warfare.script` | Uses the same generated-service name convention. |
| Available unpacked Anomaly `trade_manager.script` | Matching `trade_init`, `update`, `get_trade_profile`, `get_trade_cfg`, `cfg_ltx` and `current_buy_supplies` interfaces. Exact unpacked Anomaly version is not established. |
| Available Anomaly `xr_gulag.script`, `axr_main.script` | Matching smart lookup and callback names/signatures. |
| Selected installed GAMMA `trader_autoinject.script` and `ui_inventory.script` | Both expose `supply_level(npc, as_number)` and read the same trade-manager profile/INI APIs. The trade injector also wraps `trade_manager.update`, so preserving its chain matters. |
| Selected installed GAMMA Sakharov/Hermann INIs | Both use `actor_goodwill_ge(ecolog:...)`, `supplies_1` through `supplies_5`, and an additional `heavy_pockets_functor()` branch. The addon substitutes the faction argument while preserving the other branch. |

The selected loose providers were identified from the active MO2 profile order: `Anomalous_Stash` for the injector, `G.A.M.M.A. Accurate Defense Values` for the UI, and `G.A.M.M.A. Artefacts Reinvention` for both INIs. Their files matched the historical reference hashes. This identifies source files for review; it does not establish the running VFS, a resolved DLTX result or every runtime wrapper. No installed file was modified.

**Result:** no release-blocking defect or interface mismatch found in this focused review. Lua 5.1 syntax and mocked scenarios check profile routing, actual-faction supply substitution, helper results, scope delegation, existing-trader scanning, periodic repair and deferred optional hooks. They do not execute X-Ray inventory, asynchronous injections, capture/respawn logic or actual UI rendering. No new in-game test was performed.

## Recommended integration

1. For initial WALO evaluation, keep the single script as a separate addon with its existing filename. Load one copy, with the required GAMMA systems enabled. This retains the reviewed v1.4 behavior and avoids replacing a WALO controller.
2. Preserve the wrappers already present when this module installs. Check the final chain if another addon later assigns any of the four hooked functions. Installation flags prevent duplicate wrapping; they do **not** detect and reinstall a hook overwritten later by another script.
3. If adopting the feature into WALO, use a separate integration branch and retain one implementation path. Disable/remove the standalone module in that integrated package to avoid duplicate stock application. A native incorporation is future work, not part of this unchanged v1.4 release.
4. Keep WALO authoritative for service lifecycle and ownership. Do not move its trader spawn/capture logic into this module or convert all scientist profile conditions to owner-faction rules.

The existing per-NPC guard is cleared on the normal return path, not through protected exception cleanup. Errors in dependencies can therefore interrupt a repair and leave its guard set until death/reload; this is an unverified failure-path risk, not an observed release blocker. The addon is not a general recovery mechanism for incompatible trade implementations.

Before accepting an upstream integration, verify in game: Yantar and Jupiter under different non-Ecologist owners; differing owner/Ecologist goodwill; inherited recipe stock and preserved alternative conditions; inventory tier labels; an existing save; trader replacement/return online; profile reinitialization; ordinary traders and Warfare disabled. Check hostile traders without changing diplomacy. Compare after normal restock as well as an explicit refresh, including delayed GAMMA injections. These are recommended acceptance checks, not claimed gameplay results.
