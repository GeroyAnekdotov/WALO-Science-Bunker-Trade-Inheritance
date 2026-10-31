Warfare Science Bunker Trade Inheritance v1.4
================================================
For WALO 1.6.10 + Anomaly/GAMMA.

What this fixes
---------------
After a science bunker is captured, WALO spawns a normal trader belonging to the
new owning faction. Because of this, the former science base loses its Ecologist
trade inventory and artifact recipe progression.

v1.4:
- Yantar (yan_smart_terrain_6_4) uses Sakharov's trade profile.
- Jupiter (jup_b41) uses Hermann's trade profile.
- The trader NPC still belongs to the faction that captured the base.
- Science supply tiers are calculated using goodwill with the trader's ACTUAL
  owner faction instead of Ecologist goodwill.
- Existing traders are repaired after loading a save.
- Newly spawned/re-spawned traders are repaired automatically as well.
- If WALO/GAMMA later resets the trader back to a generic faction trade profile,
  v1.4 detects it and restores the science profile.

Installation
------------
1. Install v1.4 AFTER the WALO/GAMMA patches in MO2.
2. Load an existing save. A new game is not required.
3. Approach the trader at Yantar/Jupiter, or remain on the level for a few seconds.
4. If necessary, run "Refresh Trade Inventory" once from the Debug Launcher.

Expected behavior
-----------------
Captured Yantar:
  items\trade\trade_ecolog_sakharov.ltx

Captured Jupiter:
  items\trade\trade_ecolog_hermann.ltx

For example, if Mercenaries own the bunker, the trader remains a Mercenary NPC,
but uses the appropriate Ecologist science trade profile. Supply progression is
then based on Mercenary goodwill rather than Ecologist goodwill.

The patch also fixes supply-level checks used by GAMMA systems and UI components,
so the displayed trader level should match the inventory that is actually being
used.

What to look for in xray_server.log
-----------------------------------
[SCI-TRADE v1.4] installed
[SCI-TRADE v1.4] trader_autoinject.supply_level hook installed
[SCI-TRADE v1.4] ui_inventory.supply_level hook installed

For an existing trader you should see lines similar to:

[SCI-TRADE v1.4] profile repair npc=sim_default_killer_trader... smart=yan_smart_terrain_6_4 ... new=items\trade\trade_ecolog_sakharov.ltx
[SCI-TRADE v1.4] stock repair ... tier=supplies_1 -> supplies_5 ...

v1.4 changes
------------
- Keeps captured science bunkers tied to Sakharov/Hermann trade profiles.
- Uses the actual owner faction for science supply progression.
- Repairs existing and newly spawned WALO traders.
- Patches trader_autoinject.supply_level() for owner-faction-aware supply levels.
- Patches GAMMA/UI Rework ui_inventory.supply_level(), so the displayed supply
  level matches the real inventory tier instead of remaining at Level 1.
- Existing-trader scanning no longer calls alive() on anomalies or other non-NPC
  objects.

A new game is not required.
