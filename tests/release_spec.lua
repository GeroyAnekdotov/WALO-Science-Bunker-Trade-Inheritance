-- Focused release checks against the unchanged script, with mocked engine APIs.
local SAKHAROV = "items\\trade\\trade_ecolog_sakharov.ltx"
local HERMANN = "items\\trade\\trade_ecolog_hermann.ltx"
local RAW = "{=actor_goodwill_ge(ecolog:2000)} supplies_5, " ..
    "{=heavy_pockets_functor()} supplies_5, {=actor_goodwill_gt(ecolog:1500)} supplies_4, " ..
    "{=actor_goodwill_le(ecolog:1000)} supplies_3, {=actor_goodwill_lt(ecolog:500)} supplies_2, supplies_1"

local function fresh(warfare, optional_helpers)
    local e = setmetatable({}, {__index = _G})
    e._G, e.WARFARE = e, warfare
    e.clock, e.profiles, e.callbacks = 0, {}, {}
    e.db = {actor = {}, storage = {}}
    e.time_global = function() return e.clock end
    e.character_community = function(npc) return npc.faction end
    e.IsStalker = function(npc) return npc.stalker == true end
    e.RegisterScriptCallback = function(name, fn) e.callbacks[name] = fn end
    e.xr_gulag = {get_npc_smart = function(npc) return {name = function() return npc.smart end} end}
    e.config = {r_string_ex = function(_, section, key)
        assert(section == "trader" and key == "buy_supplies")
        return RAW
    end}
    e.xr_logic = {
        parse_condlist = function(npc, section, key, raw)
            e.last_raw = raw
            return raw
        end,
        -- Fixed result tests propagation, not the engine's condlist evaluator.
        pick_section_from_condlist = function() return "supplies_4" end,
    }
    e.trade_manager = {
        trade_init = function(npc, cfg) e.profiles[npc:id()] = {cfg_ltx = cfg} end,
        update = function(npc, force)
            e.base_updates = (e.base_updates or 0) + 1
            e.profiles[npc:id()].current_buy_supplies = "supplies_1"
            return "base-result"
        end,
        get_trade_profile = function(id, key)
            local profile = e.profiles[id]
            if key then return profile and profile[key] end
            return profile
        end,
        get_trade_cfg = function() return e.config end,
    }
    local function helper(_, as_number) return as_number and -1 or "base-supplies" end
    if optional_helpers then
        e.trader_autoinject = {supply_level = helper}
        e.ui_inventory = {supply_level = helper}
    end
    e.make_npc = function(id, smart, faction, section)
        local npc = {smart = smart, faction = faction, stalker = true, purchases = 0}
        npc.id = function() return id end
        npc.section = function() return section or "sim_default_killer_trader" end
        npc.name = function() return npc:section() .. "_" .. id end
        npc.alive = function() return true end
        npc.buy_supplies = function(_, config, tier)
            assert(config == e.config and tier == "supplies_4")
            npc.purchases = npc.purchases + 1
        end
        e.db.storage[id] = {object = npc, gulag_name = smart}
        e.profiles[id] = {cfg_ltx = "generic.ltx"}
        return npc
    end
    local chunk = assert(loadstring(SCIENCE_SOURCE, "science-v1.4"))
    setfenv(chunk, e)()
    e.on_game_start()
    assert(e.callbacks.actor_on_first_update and e.callbacks.npc_on_update and e.callbacks.npc_on_death_callback)
    return e, helper
end

-- Both bunkers, existing-trader repair, NPC faction and all four substitutions.
local e = fresh(true, true)
local yantar = e.make_npc(1, "yan_smart_terrain_6_4", "killer")
local jupiter = e.make_npc(2, "jup_b41", "isg")
e.db.storage[2].gulag_name = nil -- Exercise xr_gulag smart fallback.
e.db.storage[99] = {object = {alive = function() error("Non-NPC alive() was called") end}}
e.actor_on_first_update()
assert(e.profiles[1].cfg_ltx == SAKHAROV and e.profiles[2].cfg_ltx == HERMANN)
assert(yantar.faction == "killer" and jupiter.faction == "isg")
assert(yantar.purchases == 1 and jupiter.purchases == 1)
assert(e.trade_manager.update(yantar, true) == "base-result")
for _, suffix in ipairs({"ge", "gt", "le", "lt"}) do
    assert(e.last_raw:find("actor_goodwill_" .. suffix .. "(killer:", 1, true))
end
assert(not e.last_raw:find("ecolog:", 1, true))
assert(e.last_raw:find("heavy_pockets_functor()", 1, true))
assert(e.profiles[1].current_buy_supplies == "supplies_4")
for _, module in ipairs({e.trader_autoinject, e.ui_inventory}) do
    assert(module.supply_level(yantar, true) == 4)
    assert(module.supply_level(jupiter, false) == "supplies_4")
end

-- Reinitialization and later profile reset repair; callbacks retain installed wrappers.
e.trade_manager.trade_init(jupiter, "faction.ltx")
assert(e.profiles[2].cfg_ltx == HERMANN)
local wrapped_update = e.trade_manager.update
e.profiles[1].cfg_ltx = "reset.ltx"
e.npc_on_update(yantar)
assert(e.profiles[1].cfg_ltx == SAKHAROV)
e.profiles[1].cfg_ltx = "reset.ltx"
e.clock = 2999
e.npc_on_update(yantar)
assert(e.profiles[1].cfg_ltx == "reset.ltx")
e.clock = 3000
e.npc_on_update(yantar)
assert(e.profiles[1].cfg_ltx == SAKHAROV and e.trade_manager.update == wrapped_update)
e.profiles[1].cfg_ltx = "reset.ltx"
e.npc_on_death_callback(yantar)
e.npc_on_update(yantar)
assert(e.profiles[1].cfg_ltx == SAKHAROV)

-- Ordinary locations and named scientists delegate to the captured implementations.
local ordinary = e.make_npc(3, "esc_smart_terrain_2_12", "stalker")
local scientist = e.make_npc(4, "yan_smart_terrain_6_4", "ecolog", "yan_ecolog")
for _, npc in ipairs({ordinary, scientist}) do
    e.trade_manager.trade_init(npc, "ordinary.ltx")
    assert(e.profiles[npc:id()].cfg_ltx == "ordinary.ltx")
    assert(e.trade_manager.update(npc, false) == "base-result")
    assert(e.trader_autoinject.supply_level(npc, true) == -1)
    assert(e.ui_inventory.supply_level(npc, false) == "base-supplies")
    assert(npc.purchases == 0)
end

-- Warfare disabled bypasses the repair, including when IsWarfare overrides _G.WARFARE.
for _, use_function in ipairs({false, true}) do
    local off = fresh(false, true)
    if use_function then off.WARFARE = true; off.IsWarfare = function() return false end end
    local npc = off.make_npc(5, "jup_b41", "killer")
    off.trade_manager.trade_init(npc, "ordinary.ltx")
    off.actor_on_first_update()
    assert(off.profiles[5].cfg_ltx == "ordinary.ltx" and npc.purchases == 0)
    assert(off.ui_inventory.supply_level(npc, true) == -1)
end

-- Optional helpers can become available after core installation.
local late, original_helper = fresh(true, false)
local npc = late.make_npc(6, "yan_smart_terrain_6_4", "killer")
late.actor_on_first_update()
assert(late.profiles[6].cfg_ltx == SAKHAROV)
late.trader_autoinject = {supply_level = original_helper}
late.ui_inventory = {supply_level = original_helper}
late.npc_on_update(npc)
assert(late.trader_autoinject.supply_level(npc, true) == 4)
assert(late.ui_inventory.supply_level(npc, false) == "supplies_4")
print("PASS: focused Lua mocks (routing, supply hooks, scan, delegation, throttle, deferred helpers)")
