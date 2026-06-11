-- DayClockHUD: Shows game day, time-of-day cycle, and playtime.

local DEFAULT_DAY_TICKS = 25000

-- ── helpers ──────────────────────────────────────────────────────────────────

local function format_playtime(ticks)
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

-- Returns: day_number, game_clock_str, phase_name, label_color, bar_color
local function get_display_info(surface)
  -- In Factorio, surface.daytime: 0 = NOON (brightest), 0.5 = MIDNIGHT (darkest).
  local dt = surface.daytime

  -- Map daytime → 24h clock. dt=0 is noon, so offset by 12h:
  -- dt 0 → 12:00, 0.25 (dusk) → 18:00, 0.5 → 00:00, 0.75 (dawn) → 06:00.
  local raw_h = (dt * 24 + 12) % 24
  local clock = string.format("%02d:%02d", math.floor(raw_h), math.floor((raw_h % 1) * 60))

  -- Day number from ticks (1-based). Use the surface's actual day length so it
  -- stays correct on worlds with non-default day-length settings.
  local tpd = surface.ticks_per_day or DEFAULT_DAY_TICKS
  local day = math.floor(game.tick / tpd) + 1

  -- Phase from the surface's own daylight segments (robust to custom/always-day
  -- settings). Daylight band wraps through 0: [dawn..1] ∪ [0..dusk] is full day,
  -- [evening..morning] is full night, the rest is the dusk/dawn transition.
  local dusk, evening   = surface.dusk, surface.evening
  local morning, dawn   = surface.morning, surface.dawn
  local phase, lcol, bcol
  if dt <= dusk or dt >= dawn then
    phase = "Day"
    lcol  = {r = 1.0, g = 0.92, b = 0.28}
    bcol  = {r = 1.0, g = 0.85, b = 0.10}
  elseif dt >= evening and dt <= morning then
    phase = "Night"
    lcol  = {r = 0.50, g = 0.70, b = 1.00}
    bcol  = {r = 0.25, g = 0.45, b = 0.90}
  else
    phase = "Dusk / Dawn"
    lcol  = {r = 1.0, g = 0.60, b = 0.20}
    bcol  = {r = 0.9, g = 0.45, b = 0.05}
  end

  return day, clock, phase, lcol, bcol
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

  -- ── Row 1: clock icon  |  DAY XX  |  <spacer>  |  phase badge ──────────
  local hdr = inner.add{type = "flow", name = "hdr", direction = "horizontal", style = "dayclock_header_flow"}

  hdr.add{type = "sprite", name = "clock_icon", sprite = "utility/clock", style = "dayclock_icon_style"}

  hdr.add{type = "label", name = "day_lbl", caption = "DAY 1", style = "dayclock_day_label"}

  local spacer = hdr.add{type = "empty-widget", name = "spacer"}
  spacer.style.horizontally_stretchable = true

  hdr.add{type = "label", name = "phase_lbl", caption = "Day", style = "dayclock_phase_badge"}

  -- ── Divider ──────────────────────────────────────────────────────────────
  inner.add{type = "line", style = "dayclock_divider"}

  -- ── Row 2: sun bar  |  time  ─────────────────────────────────────────────
  local tr = inner.add{type = "flow", name = "time_row", direction = "horizontal", style = "dayclock_row_flow"}

  tr.add{type = "label", name = "time_pfx", caption = "Time", style = "dayclock_dim_label"}

  tr.add{type = "progressbar", name = "day_bar", value = 0.5, style = "dayclock_progress"}

  tr.add{type = "label", name = "time_lbl", caption = "12:00", style = "dayclock_time_label"}

  -- ── Divider ──────────────────────────────────────────────────────────────
  inner.add{type = "line", style = "dayclock_divider"}

  -- ── Row 3: played label + value ──────────────────────────────────────────
  local pr = inner.add{type = "flow", name = "play_row", direction = "horizontal", style = "dayclock_row_flow"}

  pr.add{type = "sprite", name = "pt_icon", sprite = "utility/clock", style = "dayclock_icon_style"}

  pr.add{type = "label", name = "pt_pfx", caption = "Played", style = "dayclock_dim_label"}

  local fill = pr.add{type = "empty-widget", name = "fill"}
  fill.style.horizontally_stretchable = true

  pr.add{type = "label", name = "pt_lbl", caption = "0s", style = "dayclock_playtime_label"}
end

-- ── GUI update ────────────────────────────────────────────────────────────────

local function refresh_hud(player)
  local hud = player.gui.top["dayclock_hud"]
  if not hud then return end

  local day, clock, phase, lcol, bcol = get_display_info(player.surface)
  local inner = hud.inner

  -- Header
  inner.hdr.day_lbl.caption = "DAY " .. day
  inner.hdr.day_lbl.style.font_color = lcol
  inner.hdr.phase_lbl.caption = phase
  inner.hdr.phase_lbl.style.font_color = lcol

  -- Time row
  local bar = inner.time_row.day_bar
  bar.value = player.surface.daytime
  bar.style.color = bcol
  inner.time_row.time_lbl.caption = clock
  inner.time_row.time_lbl.style.font_color = lcol

  -- Playtime row
  inner.play_row.pt_lbl.caption = format_playtime(game.tick)
end

-- ── Events ────────────────────────────────────────────────────────────────────

local function rebuild_all()
  for _, p in pairs(game.players) do
    local hud = p.gui.top["dayclock_hud"]
    if hud then hud.destroy() end
    build_hud(p)
    refresh_hud(p)
  end
end

-- Runs when the mod is first added to a save (new game OR an existing world).
script.on_init(function()
  for _, p in pairs(game.players) do
    build_hud(p)
    refresh_hud(p)
  end
end)

-- Runs on mod updates / version changes: rebuild so layout changes take effect.
script.on_configuration_changed(rebuild_all)

script.on_event(defines.events.on_player_joined_game, function(e)
  local p = game.players[e.player_index]
  build_hud(p)
  refresh_hud(p)
end)

-- Rebuild after config changes (e.g. GUI reset)
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
