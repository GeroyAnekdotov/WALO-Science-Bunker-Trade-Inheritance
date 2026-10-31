# Changelog

The established two-part version numbering is retained. Dates for the earlier releases are not recorded in the supplied sources.

## v1.4 — first GitHub release preparation

- Retained the existing v1.4 gameplay script byte for byte; no gameplay version increase.
- Added English release documentation, WALO author integration notes, focused WALO 1.6.11 source-review findings and reproducible MO2 packaging with checksums.
- No new in-game test results are claimed for this preparation.

### Existing v1.4 gameplay changes

- Patched the separate GAMMA/UI inventory supply-level calculator to display the owner-aware scientific tier.
- Restricted the existing-trader scan to stalkers before calling `alive()`.

## v1.3

- Patched `trader_autoinject.supply_level()` to use owner-faction-aware scientific supply progression for the affected generated bunker traders.

## v1.2

- Added repair of existing traders, fallback smart-terrain resolution and verification of the live trade profile.
- Wrapped `trade_manager.update()` to restore scientific profiles after later reinitialization.
- Evaluated scientific `buy_supplies` conditions with the current trader faction's goodwill and added diagnostic logging.

Earlier behavior and version numbers are not reconstructed beyond the history recorded in the supplied v1.4 script and README.
