-- DayClockHUD: Shows game day, time-of-day cycle, daylight, next phase,
-- enemy evolution, and total playtime in a polished, collapsible HUD.

local DEFAULT_DAY_TICKS = 25000

-- ── helpers ──────────────────────────────────────────────────────────────────

local function format_duration(ticks)
  local s = math.floor(ticks / 60)
  local h = math.floor(s / 3600)
  local m = math.floor((s % 3600) / 60)
  s = s % 60
  if h > 0 then
    return string.format("%dh %02dm %02ds", h, m, s)
  elseif m > 0 then
    return string.format("%dm %02ds", m, s)
  else
    return string.format("%ds", s)
  end
end

-- Fraction of daylight at the given daytime (1 = full sun, 0 = full dark).
local function daylight_fraction(dt, dusk, evening, morning, dawn)
  if dt <= dusk or dt >= dawn then return 1.0 end
  if dt >= evening and dt <= morning then return 0.0 end
  if dt < evening then
    return 1.0 - (dt - dusk) / (evening - dusk)   -- sunset ramp: 1 → 0
  else
    return (dt - morning) / (dawn - morning)       -- sunrise ramp: 0 → 1
  end
end

-- Label + ticks until the next daylight boundary.
local function next_phase_info(dt, tpd, dusk, evening, morning, dawn)
  local events = {
    {at = dusk,    label = "Sunset"},
    {at = evening, label = "Nightfall"},
    {at = morning, label = "Sunrise"},
    {at = dawn,    label = "Full sun"},
  }
  local best_label, best_delta
  for _, ev in ipairs(events) do
    local delta = (ev.at - dt) % 1
    if delta <= 0 then delta = delta + 1 end   -- standing on a boundary → next cycle
    if not best_delta or delta < best_delta then
      best_delta = delta
      best_label = ev.label
    end
  end
  return best_label, math.floor(best_delta * tpd)
end

-- Gathers everything the HUD displays for one surface.
local function get_display_info(surface)
  -- surface.daytime: 0 = NOON (brightest), 0.5 = MIDNIGHT (darkest).
  local dt = surface.daytime
  local dusk, evening = surface.dusk, surface.evening
  local morning, dawn = surface.morning, surface.dawn
  local tpd = surface.ticks_per_day or DEFAULT_DAY_TICKS

  -- dt=0 is noon, so offset the clock by 12h.
  local raw_h = (dt * 24 + 12) % 24
  local clock = string.format("%02d:%02d", math.floor(raw_h), math.floor((raw_h % 1) * 60))

  local day = math.floor(game.tick / tpd) + 1

  local phase, lcol, bcol
  if dt <= dusk or dt >= dawn then
    phase = "Day"
    lcol  = {r = 1.0,  g = 0.92, b = 0.28}
    bcol  = {r = 1.0,  g = 0.85, b = 0.10}
  elseif dt >= evening and dt <= morning then
    phase = "Night"
    lcol  = {r = 0.55, g = 0.74, b = 1.0}
    bcol  = {r = 0.25, g = 0.45, b = 0.90}
  else
    phase = "Dusk / Dawn"
    lcol  = {r = 1.0,  g = 0.62, b = 0.22}
    bcol  = {r = 0.9,  g = 0.45, b = 0.05}
  end

  local light = daylight_fraction(dt, dusk, evening, morning, dawn)
  local next_label, next_ticks = next_phase_info(dt, tpd, dusk, evening, morning, dawn)

  -- Evolution is per-surface in 2.0; guard so it degrades gracefully on
  -- worlds / surfaces where it isn't available (e.g. no enemies, platforms).
  local evo
  local enemy = game.forces["enemy"]
  if enemy then
    local ok, v = pcall(enemy.get_evolution_factor, enemy, surface)
    if ok and type(v) == "number" then evo = v end
  end

  return {
    day = day, clock = clock, phase = phase, lcol = lcol, bcol = bcol,
    light = light, next_label = next_label, next_ticks = next_ticks, evo = evo,
  }
end

-- ── collapse state ─────────────────────────────────────────────────────────────

local function is_collapsed(player)
  return storage.collapsed and storage.collapsed[player.index] or false
end

local function apply_collapsed(player)
  local hud = player.gui.top["dayclock_hud"]
  if not hud then return end
  local collapsed = is_collapsed(player)
  hud.inner.body.visible = not collapsed
  hud.inner.hdr.dayclock_toggle.caption = collapsed and "▸" or "▾"
end

-- ── GUI build ─────────────────────────────────────────────────────────────────

local function build_hud(player)
  if player.gui.top["dayclock_hud"] then return end

  local outer = player.gui.top.add{
    type = "frame", name = "dayclock_hud",
    direction = "vertical", style = "dayclock_frame",
  }

  local inner = outer.add{
    type = "frame", name = "inner",
    direction = "vertical", style = "dayclock_inner_frame",
  }

  -- ── Header (always visible): icon | DAY XX | time | spacer | phase | toggle ──
  local hdr = inner.add{type = "flow", name = "hdr", direction = "horizontal", style = "dayclock_header_flow"}

  hdr.add{type = "sprite", name = "clock_icon", sprite = "utility/clock", style = "dayclock_icon_style"}
  hdr.add{type = "label", name = "day_lbl", caption = "DAY 1", style = "dayclock_day_label"}
  hdr.add{type = "label", name = "time_lbl", caption = "12:00", style = "dayclock_hdr_time"}

  local spacer = hdr.add{type = "empty-widget", name = "spacer"}
  spacer.style.horizontally_stretchable = true

  hdr.add{type = "label", name = "phase_lbl", caption = "Day", style = "dayclock_phase_badge"}
  hdr.add{type = "button", name = "dayclock_toggle", caption = "▾", style = "dayclock_toggle_button"}

  -- ── Body (collapsible) ─────────────────────────────────────────────────────
  local body = inner.add{type = "flow", name = "body", direction = "vertical", style = "dayclock_body_flow"}

  body.add{type = "line", style = "dayclock_divider"}

  -- Light gauge
  local lr = body.add{type = "flow", name = "light_row", direction = "horizontal", style = "dayclock_row_flow"}
  lr.add{type = "label", name = "light_pfx", caption = "Light", style = "dayclock_dim_label"}
  lr.add{type = "progressbar", name = "day_bar", value = 1.0, style = "dayclock_progress"}

  -- Next phase countdown
  local nr = body.add{type = "flow", name = "next_row", direction = "horizontal", style = "dayclock_row_flow"}
  nr.add{type = "label", name = "next_pfx", caption = "Next", style = "dayclock_dim_label"}
  local nfill = nr.add{type = "empty-widget", name = "fill"}
  nfill.style.horizontally_stretchable = true
  nr.add{type = "label", name = "next_lbl", caption = "—", style = "dayclock_value_label"}

  -- Enemy evolution
  local er = body.add{type = "flow", name = "evo_row", direction = "horizontal", style = "dayclock_row_flow"}
  er.add{type = "label", name = "evo_pfx", caption = "Evo", style = "dayclock_dim_label"}
  local efill = er.add{type = "empty-widget", name = "fill"}
  efill.style.horizontally_stretchable = true
  er.add{type = "label", name = "evo_lbl", caption = "0%", style = "dayclock_value_label"}

  body.add{type = "line", style = "dayclock_divider"}

  -- Playtime
  local pr = body.add{type = "flow", name = "play_row", direction = "horizontal", style = "dayclock_row_flow"}
  pr.add{type = "sprite", name = "pt_icon", sprite = "utility/clock", style = "dayclock_icon_style"}
  pr.add{type = "label", name = "pt_pfx", caption = "Played", style = "dayclock_dim_label"}
  local pfill = pr.add{type = "empty-widget", name = "fill"}
  pfill.style.horizontally_stretchable = true
  pr.add{type = "label", name = "pt_lbl", caption = "0s", style = "dayclock_playtime_label"}

  apply_collapsed(player)
end

-- ── GUI update ────────────────────────────────────────────────────────────────

local function refresh_hud(player)
  local hud = player.gui.top["dayclock_hud"]
  if not hud then return end

  local info = get_display_info(player.surface)
  local inner = hud.inner

  -- Header
  inner.hdr.day_lbl.caption = "DAY " .. info.day
  inner.hdr.time_lbl.caption = info.clock
  inner.hdr.phase_lbl.caption = info.phase
  inner.hdr.phase_lbl.style.font_color = info.lcol

  -- Body
  local body = inner.body
  local bar = body.light_row.day_bar
  bar.value = info.light
  bar.style.color = info.bcol

  body.next_row.next_lbl.caption = info.next_label .. "  " .. format_duration(info.next_ticks)

  if info.evo then
    body.evo_row.visible = true
    body.evo_row.evo_lbl.caption = string.format("%.0f%%", info.evo * 100)
  else
    body.evo_row.visible = false
  end

  body.play_row.pt_lbl.caption = format_duration(game.tick)
end

local function rebuild_all()
  for _, p in pairs(game.players) do
    local hud = p.gui.top["dayclock_hud"]
    if hud then hud.destroy() end
    build_hud(p)
    refresh_hud(p)
  end
end

-- ── Events ────────────────────────────────────────────────────────────────────

-- Runs when the mod is first added to a save (new game OR an existing world).
script.on_init(function()
  storage.collapsed = {}
  for _, p in pairs(game.players) do
    build_hud(p)
    refresh_hud(p)
  end
end)

-- Runs on mod updates / version changes: rebuild so layout changes take effect.
script.on_configuration_changed(function()
  storage.collapsed = storage.collapsed or {}
  rebuild_all()
end)

script.on_event(defines.events.on_player_joined_game, function(e)
  local p = game.players[e.player_index]
  build_hud(p)
  refresh_hud(p)
end)

-- Collapse / expand toggle on the HUD itself.
script.on_event(defines.events.on_gui_click, function(e)
  local el = e.element
  if not (el and el.valid and el.name == "dayclock_toggle") then return end
  local p = game.players[e.player_index]
  storage.collapsed = storage.collapsed or {}
  storage.collapsed[e.player_index] = not is_collapsed(p)
  apply_collapsed(p)
end)

-- Rebuild after a resolution change (GUI reset).
script.on_event(defines.events.on_player_display_resolution_changed, function(e)
  local p = game.players[e.player_index]
  local hud = p.gui.top["dayclock_hud"]
  if hud then hud.destroy() end
  build_hud(p)
  refresh_hud(p)
end)

-- Update every second (60 ticks)
script.on_nth_tick(60, function()
  for _, p in pairs(game.players) do
    if p.connected then refresh_hud(p) end
  end
end)
