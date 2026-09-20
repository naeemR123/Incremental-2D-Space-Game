# Incremental Space Game — Roadmap

> **Engine:** Godot 4.7 · **Language:** GDScript
> **Last updated:** 2026-09-11 — every item below was re-verified against the code on this date.

---

## Table of Contents

- [How to use this file](#how-to-use-this-file)
- [Completed](#completed)
  - [Architecture & Data](#architecture--data)
  - [Stat & Perk System](#stat--perk-system)
  - [Waves & Difficulty Scaling](#waves--difficulty-scaling)
  - [Asteroids & Spawning](#asteroids--spawning)
  - [Economy & Drops](#economy--drops)
  - [Defenses & Combat](#defenses--combat)
  - [UI & Shop](#ui--shop)
  - [Camera, Screen & Resize](#camera-screen--resize)
  - [Visual Effects & Shaders](#visual-effects--shaders)
- [Tier 2: Current Block](#tier-2-current-block)
  - [2A: Next Up](#2a-next-up)
  - [2B: Core Features](#2b-core-features)
  - [2C: Content](#2c-content)
  - [2D: Wiring Gaps & Debt](#2d-wiring-gaps--debt)
- [Tier 2.5: Audio & Art](#tier-25-audio--art)
- [Tier 3: Bigger Systems](#tier-3-bigger-systems)
- [Tier 4: Far Horizon](#tier-4-far-horizon)
- [Decisions Log](#decisions-log)
  - [Architecture](#architecture)
  - [Stats & Perks](#stats--perks)
  - [Economy](#economy)
  - [Spawning & Difficulty](#spawning--difficulty)
  - [Combat Geometry](#combat-geometry)
  - [Rendering & Presentation](#rendering--presentation)
- [Recurring Bug Patterns](#recurring-bug-patterns)
  - [State & Timing](#state--timing)
  - [Scene Tree & Lifecycle](#scene-tree--lifecycle)
  - [Math & Scaling](#math--scaling)
  - [Naming & Review Hygiene](#naming--review-hygiene)
  - [Resources, Data & Engine](#resources-data--engine)

---

## How to use this file

Tick boxes as things land. When a whole block completes, move it up to **Completed** with a
short note on what actually shipped. Keep the **Decisions Log** current — it exists so
future-you doesn't relitigate settled arguments. Check **Recurring Bug Patterns** first when
something behaves oddly.

Tiers are about *scope and ordering*, not importance:

| Tier | Meaning |
|---|---|
| **2** | The current block. Finish this and the game is a complete loop. |
| **2.5** | Audio, art, theming. Deliberately deferred until systems settle. |
| **3** | Bigger systems that change what the game *is*. |
| **4** | Far horizon. Fun to think about, not scheduled. |

Within Tier 2: **2A** is next up, **2B** is core features, **2C** is content, **2D** is wiring
gaps and debt. Items are grouped by subject; sub-checklists hold the specifics.

---

## Completed

### Architecture & Data

- [x] **Resource-based data system** — `DefenseData` → `SatelliteData` / `DroneData`, plus
      `UpgradeData`, `PerkData`, `AsteroidData`, `ResourceData`, `StatusEffectsData`.
- [x] **Constant ID classes** — `StatIDs`, `DefenseIDs`, `EffectIDs`, `CounterIDs`,
      `UnlockIDs`, `PurchaseBlock`. Raw strings removed from call sites.
- [x] **`PurchaseBlock.Reason`** — one enum drives button disabling, cost-label text, and tooltips.
- [x] **Autoloads + signals** — `Game_Manager`, `WaveManager`, `StatsManager`; signal-based
      decoupling throughout. `game_reset()` rebuilds registries rather than leaving holes in
      `active_stats`, and emits `reset_unlocks` so listeners (e.g. `ThreatArrowManager`) can
      re-lock themselves without a scene reload.
- [x] **`ResourceScanner` static class** — `register_folder(path, type, registrar, label)` +
      recursive `_scan_resource_folder()`. Shared by `Game_Manager` and `WaveManager`.
  - Walks subfolders via `DirAccess.get_files_at()` / `get_directories_at()`, so resource
    folders can be organised freely.
  - Handles `.remap` / `.res` export-build suffixes.
  - Collapsed three near-identical 30-line scan functions into one-liners using `Callable`
    and `is_instance_of()`.
- [x] **`@tool` debug settings in `main.gd`** — `_validate_property()` hides the value field
      until its toggle is on. Covers custom wave, boss wave, extra resources, shield, asteroid
      speed, and damage-number logging.
- [x] **Stat counters** — `StatsManager` with `run` / `lifetime` dictionaries, `increment()` /
      `record_max()` / `reset_run()`, `CounterIDs` constants.
  - No signal on increment (damage fires dozens of times a second); `debug_print()` covers
    display until the stats menu exists.
  - Damage is clamped to remaining health so overkill doesn't inflate the total.
  - `RESOURCES_SPENT` increments in all three purchase functions.
- [x] **`NumberFormat` static class** — `compact()` (K/M/B/T suffixes, truncation not
	  rounding) with trailing-zero stripping. Wired to every display call site.

### Stat & Perk System

- [x] **Layered stat system** — `perk_flat` / `perk_mult` hold perk contributions separately from
	  `active_stats`. `get_base_stat()` returns the pre-perk value (upgrade curve if one exists,
	  else the registered default); `recalculate_stat()` computes `(base + flat) * mult`.
	  **Single write path** — nothing outside `recalculate_stat()` writes `active_stats`.
- [x] **Perk system** — `purchase_perk()` structured as validate → charge → apply → notify, so
	  both perk kinds share cost/counter/signal bookkeeping and only the apply step branches.
  - `PerkEffect.STAT_MODIFIER` with `PerkType.FLAT` / `PERCENT`.
  - `PerkEffect.UNLOCK` perks carry an `unlock_id`, validated at registration so
	`purchase_perk()` never re-checks it. `Game_Manager.unlocked_features` +
	`is_feature_unlocked()` + `feature_unlocked(unlock_id)` signal.
  - Prerequisite tree via `PerkData.prerequisites`; `tier` groups perks into accordion rows.
  - **Partial-set targeting** — `target_categories: Array[String]` with `["all"]` as the
	wildcard; `_try_add_category()` dedupes. Note `"all"` skips every `NON_DEFENSE_DEFAULTS`
	category, so it does **not** include `"global"` — correct, but surprising given how close
	the two names read in `StatIDs`.
  - `register_perk_stats()` reports each bad target individually, then aborts only if the
	perk resolves to zero categories.
- [x] **`NON_DEFENSE_DEFAULTS` table** — replaced the `if category == PLANET` special cases in
	  `get_base_stat()`, `_resolve_perk_categories()` and `register_perk_stats()`. Adding a
	  non-defense category is one dictionary entry. Currently `planet`, `tractor_beam`, `global`.
- [x] **`global` → `planet` category rename** — `max_planet_shield` → `shield`.
	  `StatIDs.GLOBAL` was reserved for genuinely game-wide stats and now holds `drop_amount`.
- [x] **`_apply_shield_gain()`** — raising max shield tops up current shield by the difference,
	  so it works for both FLAT and PERCENT sources, from upgrades or perks.
- [x] **`shield_changed` / `planet_hit` signal split** — one signal was carrying both "value
	  changed, redraw" and "we got hit, shake". Screen shake now scales with damage.
- [x] **Planet shield as a computed property** proxying into `active_stats`.
- [x] `ScalingType.SUBTRACTIVE` for fire-rate style upgrades.
- [x] `purchase_upgrade()` cost/value ordering — cost read *before* `level_up()`, value *after*.

### Waves & Difficulty Scaling

- [x] **Wave system** — weighted spawn pool, `min_wave` gating, randomised boss waves every
	  15–20 waves (`is_boss_wave` flag reuses the normal spawn-tracking/completion logic).
- [x] **`WaveManager` as single source of truth for scaling.** One normalized
	  `wave_progress(wave)` (0.0 at wave 1 → 1.0 at `SCALING_END_WAVE = 100`, clamped) feeds
	  every wave-derived number. Two families sit on top of it:
  - **Bounded** — `lerpf(start, end, pow(progress, curve))` for anything with a real ceiling:
	`speed_multiplier()` (1.0 → `MAX_SPEED_SCALE = 2.2`), spawn interval
	(`max_spawn_interval = 7` → `MIN_SPAWN_INTERVAL = 0.5`), swarm group size, spawn weight.
  - **Unbounded** — `pow(2.0, (wave - 1) / X2_WAVE)` for stats the player's own power
    multiplies against: `health_multiplier()` (`HEALTH_X2_WAVE = 20`), `damage_multiplier()`
    (`DAMAGE_X2_WAVE = 25`). Expressed as a *doubling period* because "doubles every 20 waves"
	is reasonable to think about and `1.035` isn't.
  - `SCALING_END_WAVE` is typed `float` so the division promotes. The curve exponent only
	bends the middle (`pow(0, n) = 0`, `pow(1, n) = 1`) — endpoints are fixed by the lerp.
- [x] **Spawn count bookkeeping** — `register_spawns(count) -> int` clamps a group to the
	  remaining budget and returns how many the spawner may actually create. Wave-end check is
	  `>=` not `==`. `max_asteroids = clampi(3 + wave * 2, 1, 180)`.

### Asteroids & Spawning

- [x] **Radial world-space spawning** — spawns on a fixed-radius circle (2120px) around the
	  planet, so travel time is identical for every asteroid and every player. `asteroid.gd`'s
      despawn check is a scalar `despawn_dist` (spawn distance + margin) vs
      `distance_to(planet)`; it never reads viewport size. See [Decisions](#spawning--difficulty).
- [x] **Asteroid speed re-tune** — `speed_multiplier` starts at 1.0 (was `0.1 * wave`, which
      made wave 1 crawl). `max_speed` values re-derived from `radius / target_seconds`:
      Comet 177 ≈ 12s, Swarm 118 ≈ 18s, Common 96 ≈ 22s, Tank 71 ≈ 30s, Boss 47 ≈ 45s.
      `speed_variance` is a per-type *fraction* on `AsteroidData`. The `min_speed`/`max_speed`
      clamp was replaced with a `push_warning` — a silent clamp disguises bugs as mistuning.
- [x] **Group spawning** — `group_size_start` / `group_size_end` (`Vector2i` min/max) +
      `group_ramp_end_wave` + `group_curve` → `get_group_size(wave)`.
  - Progress is measured from `min_wave`, not wave 1, so a type unlocking at wave 10 starts
    at 0% of its own ramp.
  - `Vector2i(1, 1)` defaults → every existing `.tres` behaved identically, no migration.
  - `spawn_next()` rolls **one base angle per group**; `spawn_asteroid()` jitters ±7° and
    ±60px radially. The radial jitter staggers arrivals so the group reads as a swarm, not
    one hit. Speed variance is rolled once per group so members hold formation.
  - Swarms currently run 2–3 → 5–7 by wave 70.
- [x] **Spawn-weight ramping** — `spawn_weight_end` / `weight_ramp_end_wave` / `weight_curve`
      → `get_spawn_weight(wave)`, with `-1.0` as the "no ramp" sentinel. A static weight
      can only hold a share constant; with swarm groups inflating the population, a static tank
      weight made tanks *decline* from 18.9% to 11.8% between waves 10 and 70.
  - Ramps now set on all four regular types: Common 13 → 5, Swarm 1 → 5, Tank 1 → 15,
    Comet 1.5 → 3 (all ending at wave 80).
- [x] `pick_asteroid_type()` / `get_boss_asteroid()` rebuilt on parallel `eligible` / `weights`
      arrays built in one pass. Both previously computed each weight twice — a live desync
      hazard once the weight is wave-dependent.
- [x] **Status effect system** — `StatusEffectsData` with MODIFIER / PERIODIC families,
      source-keyed `status_effects` dict on the asteroid, per-asteroid `resistances`,
      strongest-wins `get_modifier()`. Tractor beam applies `slow` via `EffectIDs.TIME_SCALE`.
- [x] Randomized asteroid textures — `get_random_texture()` + `PlaceholderTexture2D` fallback.

### Economy & Drops

- [x] **Resource tiers** — `ResourceData` (`resource_type` enum, `value`, `textures`, `glow`,
      `base_weight`, `unlock_id`) auto-scanned from `Resources/ResourceTypes/`.
      Grey 1 / Blue 5 / Gold 10 / Red 20.
  - Four hand-drawn texture variants per tier via `get_random_texture()`.
  - `glow` / `glow_color` drive a `PointLight2D` on `resource.tscn`. Gold and Red glow.
  - `resource.gd` has no `_ready()` — setup lives in `initialize()` because `_ready()` ran
    during `add_child()`, *before* the deferred `initialize()` supplied data.
  - `collector_satellite` awards `resource.value` instead of a hardcoded 1.
- [x] **Per-asteroid drop weights** — `AsteroidData.drop_weights : Dictionary[ResourceType, float]`
	  overrides a type's `base_weight`; `drop_weight.get(type, base_weight)` gives per-entry
	  override with fallback. Every asteroid now lists all four tiers explicitly.
  - Current: Common `95/5/0.5/0`, Swarm `85/10/1/0`, Tank `70/26/4/0.5`, Comet `25/55/18/1.5`,
	Boss `0.5/70/25/5`. Drop counts: Common 1–3, Swarm 3–5, Tank 4–7, Comet 10–20, Boss 50–75.
- [x] **Perk-gated resource tiers** — `ResourceData.unlock_id` replaces `min_wave`; empty string
	  means always available (Grey). `_get_next_resource()` filters on `is_feature_unlocked()`,
	  skips zero-weight entries, and guards `is_empty()`.
- [x] **Drop scaling is perk-driven, not wave-driven** — `StatIDs.GLOBAL` category holds
	  `drop_amount`, default `1.0`. See [Decisions](#economy).
  - `asteroid._spawn_resources()` uses **stochastic rounding** — `floori(exact)` plus a
	`randf()` chance on the remainder — so small multipliers don't vanish to integer rounding.
- [x] **Economy perk branch (complete)** — ten FLAT `drop_amount` perks at `0.05`
      (Metal Refiner I–V, Dense Asteroids I–V; costs 20 → 800) landing on exactly +50%, plus
      three UNLOCK perks: Blue (after Refiner II), Gold (after Blue + Refiner V), Red (after
      Blue + Gold + Dense II). All tier 3.
- [x] `resource.gd` despawn is a world-distance check from the planet, not a screen-space box.

### Defenses & Combat

- [x] **Orbit ring system** — type-grouped rings under `OrbitManager`, even spacing,
      arc-motion tweening, `redistribute()` on purchase.
- [x] **Frame-based claim arbitration** for collector satellite gravity conflicts
      (`claimed_by` / `claim_frame` / `claim_distance` on the resource).
- [x] **Projectile speed upgrade** — `projectile_speed` flows `StatIDs.PROJ_SPEED` →
      `update_satellite_stats()` → `shoot()` → `projectile.start()`.
- [x] **Projectile despawn made travel-relative** — bounded by distance travelled from the
      firing point (`despawn_dist` = distance to target + margin, with a screen-derived floor),
      not a fixed 1920×1080 box at the origin that would have eaten vertical shots past
      ~580 range.
- [x] **Turret base stats re-tuned for wave 1** — damage 1.5 → 2.0, fire rate 2.4 → 2.0s,
	  projectile speed 300 → 600. Partial fix; see [2A](#2a-next-up) for what's still open.
- [x] **Range indicators on both satellite types** — `set_range_visible()` +
	  `set_preview_range_visible(can_see, radius)` with a looping alpha tween on the preview.

### UI & Shop

- [x] **Shop revamp, all three phases** — `TabContainer`, custom stretch `TabBar`,
	  `FoldableContainer` accordion rows (`ShopAccordionRow`), `PurchaseLine`.
  - Planet tab groups rows by category via `setup_upgrade_group()`, ordered by the
	`NON_DEFENSE_DEFAULTS` const rather than folder scan order.
  - Perks tab groups by `tier` via `setup_perk_tier()`. Perks whose prerequisites aren't
    met are **hidden** (`visible = false`) rather than shown greyed-out.
- [x] **Bulk purchase** — x10, Shift for max (`purchase_*_bulk()` with `-1` meaning max).
- [x] **Range upgrade hover preview** — hovering a `range` row shows one random satellite's
	  current ring and a blinking `Line2D` at the next-level radius. Both paths use
	  `has_method()` guards; the `false` path clears every satellite on the ring.
- [x] **Off-screen threat indicator** — `ThreatArrowManager` (`CanvasLayer`) draws edge arrows
	  for incoming asteroids outside the view, unlocked by `UnlockIDs.THREAT_INDICATOR`.
  - Ranks by *seconds until visible* (world-space distance to the visible rect ÷
	`asteroid.speed`), so a fast Swarm outranks a slow Tank at the same distance.
	Arrows scale with urgency and blink on appearance.
  - Fixed pool of 20 built in `_ready()`; nothing is instanced or freed during play.
  - **Stable assignment** — an `asteroid → arrow` Dictionary keeps each arrow with its
	asteroid for its whole lifetime (see [Bugs](#state--timing) on rank-indexed pools).
  - Per-frame pass: collect → rank → release → assign → update. Release must run before
	assign, or the pool looks empty and new threats get nothing.
  - A dot product against the direction to screen centre drops arrows for anything already
	receding — mainly comets after they pass.
  - Listens to `feature_unlocked` *and* checks in `_ready()`; `reset()` on `reset_unlocks`.
- [x] **Asteroid health bars** — `AsteroidHealthBars` (`Node2D`, z 100) does one `_draw()`
	  pass over the `Asteroids` group each frame: background, fill lerped
	  `bar_fill_empty → bar_fill_full`, outline. Skips dead, full-HP, and BOSS asteroids.
- [x] **Planet shield bar** (`ProgressBar` on the planet) + shield/resource/wave labels;
	  boss-wave warning label shows when the next boss is within 4 waves.
- [x] Custom mouse dot replaces the OS cursor inside the shop.

### Camera, Screen & Resize

- [x] **Aspect-ratio scaling** — `window/stretch/mode="canvas_items"` + `aspect="expand"`.
	  `canvas_items` renders UI at real resolution (the earlier `viewport` mode upscaled from
	  1920×1080 and blurred text); `expand` reveals extra world space rather than cropping.
	  `camera.gd._update_aspect_zoom()` counteracts it with a clamped `Camera2D.zoom`
	  (`min_zoom_factor 0.9` / `max_zoom_factor 1.15`), re-running on `size_changed`.
	  See [Decisions](#rendering--presentation).
- [x] **Resize-safe UI positioning** — `ui.gd` derives `shop_origin` / `shop_hidden_pos` from
	  the panel's anchors × `get_parent_area_size()`, then snaps to the correct target on
      resize. `camera.gd` stores `shop_open` so it can recompute `shop_offset` unprompted.
- [x] **Camera feel** — screen shake (scaled by damage, `move_toward` decay), mouse parallax,
      shop slide with camera counter-offset, player zoom (scroll / `+` / `-` / `0` reset).

### Visual Effects & Shaders

- [x] **Hit feedback** — hit flash (`Color(4,4,4)` tween), hit particles, death particles
      (four `GPUParticles2D` emitters with duplicated `ParticleProcessMaterial`s so direction
      is per-instance), floating damage numbers via `NumberFormat.compact()`.
- [x] **Projectile HDR glow** — `SatelliteData.projectile_color` → `turret_satellite.gd` →
	  `projectile.gd`'s `modulate`, with `WorldEnvironment` + Glow in `main.tscn`. New
	  projectile types set one export field. See [Decisions](#rendering--presentation) on HDR.
- [x] **Full-screen pixelation shader** — `PixelationLayer` (`CanvasLayer`, layer 2) with a
	  full-rect `ColorRect` reading `hint_screen_texture` at `filter_nearest`, snapping
	  `SCREEN_UV` to a `block_size = 3` grid and sampling each block's centre.
  - Layer ordering decides what gets quantized: world (0) and `ThreatArrowManager` (1) are
    pixelated; `UI` (3) stays crisp. `mouse_filter = Ignore` or the ColorRect eats every click.
  - Chosen full-screen over per-sprite — see [Decisions](#rendering--presentation).
- [x] **Parallax starfield** — four `Parallax2D` layers with procedurally generated
      `ImageTexture`s; twinkle shader with per-star phase baked into the blue channel.
  - **Twinkle alpha fix** — the shader multiplied RGB by `brightness_mult` but passed alpha
    through, so dimming stars went *dark and opaque*. Alpha now carries the dimming.
- [x] **Nebula background** — two `Parallax2D` layers (`scroll_scale` 0.05 / 0.1) holding
      `NoiseTexture2D` sprites (`FastNoiseLite` + alpha `Gradient` ramp). Mid layer blends
      additively; Far randomizes its seed per run via `nebula.gd`.
  - `repeat_size` must match the *scaled* sprite size (2560×1440 at 5× → 12800×7200) or the
    layers drift out of view, since `autoscroll` never wraps without it.
  - Seams fixed by raising `frequency` and scaling the sprite up rather than widening
    `seamless_blend_skirt`. Node `texture_filter` overridden to Linear (project default is
    Nearest, which produced 6px chunks at 5× — coarser than the 3px pixelation grid).
- [x] **Planet rotation shader** — `planet.gdshader` sphere-maps an equirectangular strip
      (`Planet_net_V1.png`) with a fisheye UV warp: axial tilt/roll, directional lighting with a
      soft terminator, ambient floor, limb darkening, edge softness. Rotation via `TIME`.
- [x] **Resource shimmer** — `resource_shimmer.gdshader` sweeps a diagonal glint band across
      whatever texture is assigned; `phase_offset` is randomised per instance in `initialize()`.
- [x] **Resource despawn blink** — a looping alpha + light-energy tween starts at
      `blink_threshold` seconds and speeds up (1× → 3× → 5×) as the timer runs out.

---

## Tier 2: Current Block

### 2A: Next Up

- [ ] **Wave 1 is not clearable** — confirmed in play. Three independent gates; fixing one
      alone is not enough. The first two are the blockers.
  - [x] **Shots can connect** — projectile speed raised 300 → 600, fire rate 2.4 → 2.0. At
        base 600 the effective range is ~188px against a 250 range (see
        [Combat Geometry](#combat-geometry) for the formula). The roadmap target was ~800;
        the projectile-speed upgrade `.tres` still says `base_value = 800` but the defense
        `default_stats` (600) wins because `register_upgrade_array()` syncs it.
  - [ ] **One-shot threshold** — a turret at orbit radius 160 / range 250 gets ~1.4s of
        expected firing time per asteroid. Base damage is now 2.0 vs a 3.0 HP common, still
        two shots at 2.0s apart. **Damage must reach 3.0** to one-shot a wave-1 common.
        Damage upgrade is MULTIPLICATIVE ×1.5 → level 2 = 3.0 exactly now (was 2.25 at 1.5
        base). So one free tutorial upgrade *does* cross it — or switch to ADDITIVE.
  - [ ] **The opening is a forced move** — turret 5 + collector 10 = 15, and without a
		collector there's no income. `starting_resources` in `main.tscn` is currently **27**
		(enough for collector + 2 turrets at 5 / 7). Two turrets is a bigger jump than it
		sounds: `redistribute()` keeps them 180° apart, so one is always within 90° of any
		incoming asteroid and worst-case engagement distance rises from d=90 to d=192.
		Test real wave 1 via debug injection at 15 / 22 / 33, find the loadout that works, then
		make the tutorial hand that over.
- [ ] **Wave length pacing** — wave duration is `events × spawn_interval`, and nothing tunes
	  the product. `max_asteroids` is now clamped to 180 (a bound, not a curve), so length
	  still humps mid-game and collapses late.
  - [ ] Decide: bound `max_asteroids` on a curve, *or* derive the interval from a target wave
		duration (`interval = target_seconds / expected_events`) so length is tuned directly.
  - [ ] Raising `MIN_SPAWN_INTERVAL` doesn't help (mid-game interval is nowhere near the
        floor) and stretching the ramp to wave 200 makes it monotonically worse.
  - [ ] 180 asteroids in one wave is the most likely framerate problem before object pooling.
- [ ] **Threat arrows are perk-gated during the waves that need them most** — radial spawning
      hides a wave-1 asteroid for ~16s and the mitigation is behind `UnlockIDs.THREAT_INDICATOR`
      (30 resources). Design call, not a bug. Options:
  - [ ] Ungate the base arrows; sell urgency scaling / glow / `max_arrows` as the perk.
  - [ ] Grant it free after wave N.
  - [ ] Accept it because early waves are forgiving.
- [ ] **Perk tree — non-economy branches** — economy is done (13 nodes). The combat/utility
      side is 4 stat perks + 1 unlock, and the tree shape is thin.
  - [ ] Aim for 3 roots / 4 middles / 1 capstone on the combat side so the prerequisite
        chain gets exercised beyond one link.
  - [ ] `damage_perk_1` ("High Caliber Bullets") has no `cost` set — it's free. Decide a price.
  - [ ] Decide whether hidden-until-unlocked perks (current behaviour) or greyed-out with the
		`Requires: X` tooltip (the code path that `_missing_prereq_names()` still supports but
		never reaches) is the intended UX. Hidden keeps the panel short; greyed-out shows the
		tree.

### 2B: Core Features

- [ ] **Save / load**
  - [ ] Serialize a plain Dictionary via `FileAccess` + `JSON`. Include a **version field**
		from day one.
  - [ ] Avoid `ResourceLoader` on user files — embedded scripts execute.
  - [ ] `StatsManager.lifetime` is the first customer ("survives reset, saves to disk").
- [ ] **Tutorial** — scripted opening before real wave 1.
  - [ ] Buy a collector and a turret (the forced move is what a tutorial wants), run a
		one-asteroid wave, teach the tractor beam on the drop.
  - [ ] Hand over a free upgrade and a free perk. Doubles as the delivery mechanism for
		whatever loadout real wave 1 actually needs (see 2A).
- [ ] **Shield recovery** — shield only ever decreases, so a rough early wave permanently
	  narrows the margin and the run spirals.
  - [ ] **Automatic regen** (~10–20% of max per wave) is the floor — the player who most needs
		a paid heal is the one who can't afford it. Also makes shield upgrades better, since it
        scales with max.
  - [ ] Shop heal item and a between-waves healing perk as acceleration.
  - [ ] Heal-dropping asteroid variant — the most interesting of the three: one enemy type
        becomes *wanted* rather than only feared.
- [ ] **Menus & game flow**
  - [ ] Start screen.
  - [ ] Pause menu — `PauseMenu` input action (Esc) is mapped to nothing.
  - [ ] **Game Stats menu** with wave-end summaries — depends on stat counters; coordinate
        with save/load. `StatsMenu` input action (S) is mapped to nothing.
- [ ] **Wave controls**
  - [ ] Game speed control — `0x` / `1x` / `2x` / `3x Speed` input actions already exist in the
        project (Space / 1 / 2 / 3) but nothing reads them. Interacts with `local_time_scale`
        slow effects.
  - [ ] Auto-start wave toggle.
  - [ ] Wave preview panel.
  - [ ] Wire the `RemainingAsteroids` label (exists in `ui.tscn`; the update line in
        `wave_tracker()` is commented out).
- [ ] **Shop features**
  - [ ] Sell / refund defenses.
- [ ] **Targeting modes** — `get_nearest_asteroid()` → `get_target()` with a mode enum
      (nearest / lowest HP / highest HP / closest to planet). `UnlockIDs.TARGET_MODES` is
      already reserved for the gating perk.

### 2C: Content

- [ ] **Turret variants & targeting**
  - [ ] **Predictive targeting perk** — turrets solve the intercept instead of firing at a
        position snapshot. This is the permanent fix for `effective_range` (see
        [Combat Geometry](#combat-geometry)); raising `projectile_speed` only buys time, because
        effective range shrinks as asteroid speed scales (×2.2 by wave 100). The perk becomes
        *more* valuable the deeper the run goes, with no balancing needed.
    - Use the iterative solve, not the quadratic — easier to read and it degrades gracefully
      if the target changes direction:
      ```gdscript
      var t : float = global_position.distance_to(target.global_position) / proj_speed
      for i in 3:
          var predicted : Vector2 = target.global_position + target.direction * target.speed * t
          t = global_position.distance_to(predicted) / proj_speed
      ```
    - Reads `target.direction` and `target.speed`, both already public on `asteroid.gd`.
	- **Known inaccuracy:** the tractor beam's slow is applied inside
	  `asteroid._physics_process()` via `get_modifier(TIME_SCALE)`, not to `speed` itself, so
	  slowed asteroids get over-led. Either expose an effective-speed getter or accept the drift.
  - [ ] **Hold-fire satellite** — a *distinct weapon identity*: filters targeting to within
		effective range and waits instead of spending cooldowns on misses. Pairs with a slow,
		heavy shot — explosive or burst-fire. Contrast with the base turret, which fires
		constantly and relies on projectile speed to connect.
  - [ ] Laser satellite, missile satellite (`DefenseIDs.LASER_SAT` / `MISSILE_SAT` reserved).
  - [ ] Cryo / incendiary satellite — first customers for on-hit status effects (see 2D).
- [ ] **Drones** — `DroneData` is still an empty marker class; the Drones tab is empty.
  - [ ] **Marker drone** — attaches to the asteroid it marks, applying `EffectIDs.DAMAGE_TAKEN`.
		The drone body *is* the visual indicator. Gives drones an identity distinct from
		satellites (they leave the ring and commit to a target), and caps concurrent marks at
		the number of drones owned.
	- Don't reparent to the asteroid — `queue_free()` takes children with it. Track the target
      and set `global_position` instead.
    - Decide source-key granularity: shared key = one mark per asteroid;
      `"marker_drone_%d" % get_instance_id()` = stacking.
    - Needs `is_instance_valid()` retarget handling — build after targeting modes.
  - [ ] Collector drone, turret drone (`DefenseIDs` reserved; `StatIDs` has `ACCELERATION`,
        `DRONE_SPEED`, `DRONE_COLLECTION_STRENGTH` waiting).
- [ ] **Asteroid variants**
  - [ ] **Splitter** — `@export var splits_into : AsteroidData` + `split_count`, branch in
        `die()`. Note the speed-unit decision: fragments spawning close still travel at their
        own `max_speed`, which is why speed stays in px/s.
  - [ ] Heal-dropping asteroid (from shield recovery, 2B).
- [ ] **Wave content**
  - [ ] **Wave modifiers** — a `WaveModifierData` resource, auto-scanned like everything else,
        applied in `start_wave()`.
  - [ ] **Boss health bar** — screen-top bar during boss waves; extends the existing
        `bwave_label` warning. `AsteroidHealthBars` already skips BOSS types for this reason.

### 2D: Wiring Gaps & Debt

- [ ] **Balance & tuning**
  - [ ] **Damage upgrade has no diminishing returns** — `val_per_level = 1.5` (MULTIPLICATIVE)
        and `cost_multiplier = 1.5` are the same number, so damage-per-resource is *constant
		forever*. There's never a reason to buy anything else. Either lower `val_per_level`
		below `cost_multiplier` or switch to ADDITIVE (which also settles the wave-1 threshold).
  - [ ] **Range upgrade is a trap purchase** — miss distance scales *with* flight distance, so
		buying range widens the band where a turret acquires targets it can't hit and burns
        cooldowns on them. `max_value = 1500` against an effective range of ~188 (at 600 proj
        speed) is net-negative past a point. Resolves once predictive targeting exists (2C);
        until then, cap `max_value` near effective range or accept the mistune.
  - [ ] **Verify turret damage reconciles** — a wave-35 log showed 13.5 damage, which matched
        ADDITIVE level 9 with *no* perk (`1.5 × 9`) but not MULTIPLICATIVE. Base is 2.0 now, so
        re-check: print `active_stats["turret_satellite"]["damage"]` after buying
        `damage_perk_1` (`target_categories = ["all"]`) and confirm the 10% lands.
  - [ ] **Income vs cost curve check** — income grows roughly linearly (asteroid count × a
        capped +50% × rarity-unlock step changes) but `UpgradeData.get_current_cost()` is
		geometric. Plot `income_per_wave / cost_of_next_upgrade` across waves 1–100; if it isn't
		roughly flat, purchases stop being decisions. `max_cost` is the flattening lever.
  - [ ] **Drop balance pass** — a Boss yields 50–75 drops weighted Blue/Gold/Red vs a Common's
        1–3 Grey. Verify in play before tuning further.
- [ ] **Status effects**
  - [ ] Generic on-hit effects — `SatelliteData.on_hit_effect` + magnitude/duration stats →
        `projectile.gd` + `turret_satellite.gd`. *Parked since the status-effect session;
        the marker drone / cryo satellite is the first real customer.*
  - [ ] **Acid** (PERIODIC family) — *parked until satellite/drone variety exists; 2C unblocks.*
        `EffectIDs.ACID` / `BURN` / `PROTECTION` are reserved.
  - [ ] `StatusEffectsData.stack_rule` is declared but never read — `apply_effect()` overwrites
        unconditionally, so STRONGEST vs REFRESH does nothing.
  - [ ] `StatusEffectsData.tint` unused — no visual for a slowed asteroid.
  - [ ] **Resolve the `get_modifier()` direction contract** — the comment says consumers apply
        `(1.0 - x)` as a reduction; a vulnerability debuff (`DAMAGE_TAKEN`) needs `(1.0 + x)`.
        Must be settled before the marker drone.
- [ ] **Perks & drops**
  - [ ] **Per-tier drop-chance perks** — `ResourceData.get_weight_stat_id()` now exists
		(`"blue_weight_mult"` etc., derived from `ResourceType.keys()` so there's no third
		encoding of the tier name). Still to wire: `_get_next_resource()` should do
		`resource_weight *= active_stats[GLOBAL].get(id, 1.0)`, and `NON_DEFENSE_DEFAULTS["global"]`
		needs the four keys at `1.0`. Note the tradeoff: renaming an enum member silently changes
		every derived key, including in save files.
  - [ ] Zero-weight entries aren't skipped in `pick_asteroid_type()` / `get_boss_asteroid()` —
        inert today, but a `roll` of exactly `0.0` picks the first entry regardless.
        `_get_next_resource()` already guards this.
- [ ] **Satellites & rings**
  - [ ] **Orbit radius upgrades don't work** — `satellite_ring.update_stats()` only reads
		`ORBIT_SPEED`; `my_orbit_radius` is set once in `initialize()` and never re-read.
		`StatIDs.ORBIT_RADIUS` exists but no upgrade `.tres` uses it yet.
  - [ ] Orbit ring visualization — per-ring `Line2D` circle owned by `satellite_ring.gd`.
  - [ ] `purchase_line._process()` polls Shift every frame on every row — move to one
		broadcaster (`ui.gd` or an input singleton) and let rows listen.
  - [ ] Comet sprite setup in `asteroid.start()` is hardcoded (`hframes = 8`, `scale 1.5`,
		`offset (-17, 0)`) — the comment says it needs rework. Move to `AsteroidData`.
- [ ] **Stats & counters**
  - [ ] `CounterIDs.RUNS_STARTED` increments in `Game_Manager._ready()` only, so `game_reset()`
		doesn't count a fresh run. Decide which moment the counter means and make it consistent.
  - [ ] `StatsManager._ready()` connects to `WaveManager.wave_complete` for `debug_print()` —
        undocumented autoload-order dependency; remove when the stats menu lands.
- [ ] **Code hygiene & cleanup**
  - [ ] Comet's `start()` comment says they fly *"without regard for the Planet"* — the intent
		is the opposite. Comets are aimed near the planet with a ±9° offset so a bad roll is a
		direct hit; that's why damage is 15 and they're rare and profitable. Fix the comment.
  - [ ] `asteroid_health_bars.gd` has a leftover `print(get_nodes_in_group(...).size())`
		inside the `_draw()` loop — fires once per damaged asteroid per frame.
  - [ ] `death_particles.gd`: `countdeb_material` duplicates `debris_node.process_material`,
		not `countdeb_node.process_material`. Works only while the two nodes share a material.
  - [ ] `projectile.gd` still reads `get_viewport_rect().size` for `despawn_dist_min`. Harmless
		as a floor, but it's the last viewport read in a gameplay script.
  - [ ] Debug flags are currently **on** in `main.tscn`: `custom_wave = true` (wave 12),
        `extra_resources = true` (10 000). Turn off before any real playtest.
  - [ ] Delete `Scenes/*.tmp` editor artifacts (4 files: `main` ×2, `resource`, `ui`);
        add `*.tmp` to `.gitignore`.
  - [ ] `Legacy (Unused)/` — `defenses_button` / `upgrade_button` scenes and scripts. Delete or
		confirm they're referenced nowhere.
  - [ ] Starfield twinkle gradient softening follow-up.

---

## Tier 2.5: Audio & Art

*Sound was deliberately moved here: a dedicated session once sprite work is further along.*

- [ ] **Audio**
  - [ ] `AudioManager` autoload — pool of `AudioStreamPlayer` nodes, signal-driven off
		`planet_hit`, asteroid death, purchases. Hook *events*, not state changes (see
		[Decisions](#architecture)).
- [ ] **Theming**
  - [ ] Universal `Theme` resource — replaces per-node `theme_override_*` before the UI grows.
- [ ] **Sprite work** — cartoon style in Krita, then Inkscape; pixelation shader overlay
	  (not native pixel art). *Shader is built.* Rules that follow from it:
  - Draw at display size (not small-then-upscaled); don't hand-place pixels.
  - Keep strokes and gaps ≥ 4px at scale 1.0; flat tones over gradients.
  - Greyscale anything that gets `modulate`-tinted.
  - [ ] Directional projectile art — currently a square, so the `rotation` already being set
        reads as nothing. An elongated bar shows travel direction for the same effort.
  - [ ] Planet surface texture pass — the shader is done; `Planet_net_V1.png` is the first
        strip. Strip should be ≈ π × on-screen diameter wide, half that tall (2:1), tiling
        left–right seamlessly.
  - [ ] Swarm and Boss asteroids have no textures (placeholder squares).
- [x] ~~Planet rotation shader~~ — done, see Completed.
- [x] ~~Resource glint shader~~ — done, see Completed.
- [x] ~~Resource despawn flash~~ — done as a blink tween, see Completed.

---

## Tier 3: Bigger Systems

- [ ] **Prestige / meta-progression** — the genre-defining feature. `game_reset()` already does
	  the hard part; add a currency it doesn't clear. Perks gain an `is_meta` flag and a second
	  tree rather than converting the run-scoped ones.
- [ ] **Visual perk tree** — `PerkData.tier` and `prerequisites` exist for exactly this.
- [ ] **Object pooling** — projectiles, resources, damage numbers, hit particles.
	  `ThreatArrowManager` is the in-house reference for a stable pool.
- [ ] **Achievements / milestones** — nearly free once stat counters persist.
- [ ] **`PurchasableData` base class** — *revisit here only if a fourth purchasable type
	  appears.* See [Decisions](#architecture).
- [ ] **Headless balance simulation tooling** — plot income vs cost, wave length, and kill
	  windows across waves 1–100 without playing.

---

## Tier 4: Far Horizon

- [ ] Multiple planets / solar system map
- [ ] Modular satellite building from parts
- [ ] Roguelite draft-pick run structure
- [ ] Web export + leaderboards
- [ ] Offline progress

---

## Decisions Log

Each entry: what was **chosen**, what was **rejected**, and **why**. Read before reopening any of these.

### Architecture

**`PurchasableData` base class — parked.**
- *Chose:* keep `DefenseData` / `UpgradeData` / `PerkData` separate; give `PerkData` the *same
  method names and shapes* (`get_current_cost()`, `get_block_reason() -> PurchaseBlock.Reason`)
  so `purchase_line.gd` can duck-type.
- *Rejected:* a shared base Resource.
- *Why:* all three would fully override both methods anyway, so the base hoists signatures and no
  implementation. Break-even is roughly four purchasable types; there are three.
- *Revisit if:* prestige upgrades, planet modules, or drone loadouts appear.

**Feature unlocks are an `Array[String]`, not a resource class.**
- *Chose:* `Game_Manager.unlocked_features : Array[String]` fronted by `is_feature_unlocked()`.
- *Rejected:* an `UnlockableData` Resource with `enable()` / `reset()` — it would need its own
  folder scan, registrar, and reset lifecycle to store a boolean.
- *Why:* the deciding question wasn't "how many unlocks" (an array scales to fifty) but "will an
  unlock ever carry data beyond on/off?" Today none do. Because callers go through
  `is_feature_unlocked()`, promoting to a Dictionary or resource later is a one-function change.

**Unlockable features need both a signal and a `_ready()` check.**
- *Chose:* `feature_unlocked(unlock_id)` signal *plus* a `_refresh_unlock_status()` call in
  `_ready()`, both routed through one function.
- *Why:* the signal only reaches nodes listening when it fires — it handles "unlocked mid-run"
  but not "already unlocked before I existed" (scene reload, node added later). One definition of
  "unlocked" keeps the two paths from drifting. The signal also lets a feature do one-time setup
  (flipping `set_process()`) instead of testing a flag every frame.
- *Consequence:* `game_reset()` emits `reset_unlocks` so listeners re-lock themselves; the
  `reload_current_scene()` that follows is no longer the only thing doing it.

**Signals are named after what happened, not what should happen next.**
- *Chose:* `shield_changed` (state changed) + `planet_hit(damage)` (event occurred).
- *Rejected:* one signal doing double duty — a perk purchase couldn't refresh the bar without
  faking a hit.
- *Consequence:* new feedback — sound, particles, vignette — hooks the **event**, not the state
  change.

**Perks are run-scoped for now.**
- *Chose:* flat one-time purchases on a prerequisite tree, bought with run currency; `game_reset()`
  calls `perk.reset()`.
- *Why:* that's a *build-choice* system — runs diverge based on which branches you could afford,
  which is interesting without prestige.
- *When prestige lands:* add a second set via `is_meta` rather than converting these.

**Placeholder art stays longer than feels comfortable.**
- *Why:* feel comes from motion, timing, sound, and feedback far more than sprites.

### Stats & Perks

**`active_stats` has a single-author rule — SOLVED, keep it that way.**
- *Problem:* `active_stats` stores one *final* value per stat, so any second contributor silently
  overwrote the first. Root cause of four separate bugs.
- *Chose:* layering. `perk_flat` / `perk_mult` hold perk contributions; `get_base_stat()` returns
  the pre-perk value; `recalculate_stat()` computes `(base + flat) * mult`.
- *Rule:* **`recalculate_stat()` is the only thing that may write `active_stats`.** Treat any new
  direct write as a bug.

**Wildcard perk targeting over explicit lists.**
- *Chose:* `target_categories = ["all"]` resolves against whatever categories exist at purchase
  time, so a new defense carrying the same stat is covered with no perk edits.
- *Rejected:* an `Array[DefenseData]` — manual maintenance that fails silently when forgotten,
  against the drop-a-file-in-a-folder philosophy of the codebase.
- *Note:* `"all"` deliberately excludes `NON_DEFENSE_DEFAULTS` categories (`planet`,
  `tractor_beam`, `global`). Name them explicitly when you mean them.

**FLAT perks for capped multipliers, PERCENT for open-ended ones.**
- *Why:* `perk_mult` accumulates as `mult * (1.0 + value)` — multiplicative. Ten 5% PERCENT perks
  give `1.05¹⁰ = 1.629`, not 1.5. Percentages stacking by multiplication never land on the round
  number you designed. FLAT against a base of `1.0` is additive and hits the cap exactly.
- *Applied to:* the ten `drop_amount` perks (`0.05` FLAT each → exactly 1.5).

### Economy

**Drop scaling is a player choice, not an automatic curve.**
- *Rejected:* a wave-based `drop_multiplier()` alongside rarity bias.
- *Why:* income already scaled on four multiplying axes — asteroid count, drops per asteroid,
  rarity weighting, resource value. Each looked mild alone; together ~100× income by wave 50
  against ~14× enemy health.
- *Chose:* move the multiplier into the perk tree. Two axes remain — asteroid count (automatic)
  and player purchases — making runaway income structurally hard rather than a tuning accident.
  It also converts invisible pacing into agency: `ResourceData.min_wave` used to unlock tiers
  silently; a perk makes it a decision with a cost.
- *Also rejected:* doing it with `UpgradeData` (levels and cost curves built in) — perks are where
  build-choice belongs; ten chained prerequisite nodes *are* the tree.

**Stochastic rounding for drop counts.**
- *Why:* `roundi(randi_range(1,3) * 1.05)` returns identical values to `* 1.0`, so the first
  three economy perks would have done literally nothing, and the tenth would have overdelivered
  at +67% instead of +50%.
- *Chose:* `floori(exact)` plus a `randf()` chance on the remainder. The average is exact at
  every scale.

### Spawning & Difficulty

**Radial spawning over screen-edge spawning.**
- *Rejected:* screen-derived spawn points. At 3440×1440 a side spawn was ~1495 units out and a top
  spawn ~626 — a 2.4× travel-time difference decided by a coin flip, shifting on every display.
  An ellipse spawner was also considered and rejected.
- *Chose:* a circle of fixed radius. Travel time is identical for everyone, and it matches the
  geometry that decides difficulty (turret range is a radius, satellites orbit in rings).
- *Accepted tradeoff:* on a non-square screen you can equalize travel time *or* visible lead-in,
  not both — top/bottom spawns stay off-screen longer. Visible lead-in is a presentation problem;
  the threat-arrow perk solves it.

**Asteroid speed stays in px/s, not "seconds to arrive."**
- *Rejected:* storing `approach_time` and deriving `speed = distance / time`. Clean while every
  trip is identical, but a splitter fragment spawning 400px out would compute `400 / 30 = 13 px/s`
  and crawl; a boss dropped in close for drama would slow down for it.
- *Why:* **speed is intrinsic to the asteroid; approach time is a property of one journey.** The
  reciprocal also fights the difficulty scale — `speed_multiplier` is a multiply, so in time-space
  it becomes a divide and equal multiplier steps produce shrinking time steps.
- *Real root cause was never the unit:* one bug (`0.1 * current_wave`) plus five numbers authored
  for a smaller radius. A doc comment on `max_speed` records the `radius / seconds` conversion.

**Sentinel defaults over renames, for zero-migration exports.**
- *Chose:* `spawn_weight_end = -1.0` meaning "no ramp"; `group_size_start = Vector2i(1, 1)`
  meaning "no group". Every existing `.tres` keeps working untouched.
- *Rejected:* renaming `spawn_weight` → `spawn_weight_start` for symmetry — Godot can't map the
  old property on load and silently zeroes all five values.
- *Why:* naming asymmetry is cheaper than a migration; a doc comment covers it.

**The shop closes during waves.**
- *Consequence:* spawn-time vs. death-time reads of player-purchased multipliers are equivalent,
  so `_spawn_resources()` can read `drop_amount` at death with no snapshotting.

**Boss waves reuse the normal machinery.**
- *Chose:* `is_boss_wave` flag + `max_asteroids = 1`; `get_boss_asteroid()` does weighted
  selection among BOSS-behavior asteroids filtered by `min_wave`, same as the regular picker.

### Combat Geometry

**Turret reach is `effective_range`, not `range` — and range is the wrong lever.**
- *Mechanism:* `shoot()` passes `target.global_position`, a snapshot; the projectile flies a fixed
  line while the asteroid keeps moving. A shot connects only when
  `asteroid_speed × (flight_distance / projectile_speed)` is smaller than the combined collision
  radius:
  ```
  effective_range = hit_radius × projectile_speed / asteroid_speed
  ```
- *Non-obvious consequence:* **miss distance scales with flight distance, so buying range extends
  acquisition without extending the kill zone.** Range upgrades currently *reduce*
  damage-on-target. Projectile speed is the lever now; predictive targeting is the real fix.
- *Orbit-phase geometry:* a turret at orbit radius 160 / range 250 engages from `d = 410` on the
  same side but only `d = 90` on the far side — a 4.5× swing the player doesn't control.
  Time-weighted, ~1.4s of expected firing per asteroid at wave 1.
- *Why two turrets ≫ one:* `redistribute()` keeps them 180° apart, so one is always within 90° of
  any incoming asteroid; worst-case engagement rises from `d = 90` to `d = 192`. The second turret
  is worth far more than the first.

**Marker variant is a drone, not a satellite.**
- *Chose:* a drone that physically attaches to the asteroid as the visual debuff indicator,
  applying `EffectIDs.DAMAGE_TAKEN` (MODIFIER family).
- *Open:* `get_modifier()`'s `(1.0 - x)` contract must be resolved before wiring — see 2D.

### Rendering & Presentation

**Aspect-ratio fairness — clamped zoom now, threat arrows as the real fix.**
- *Problem:* `expand` alone reveals extra space unevenly across axes, giving some aspect ratios
  free early warning.
- *Chose:* camera zoom compensation, deliberately clamped (`min_zoom_factor` / `max_zoom_factor`)
  — fully correcting for 21:9 would make 16:9 feel cramped.
- *Real fix:* the threat-arrow perk gives every player the same information regardless of what's
  physically visible. *(Shipped.)*

**Full-screen pixelation, not per-sprite.**
- *Why:* matching an art pixel to a shader block needs a fixed on-screen sprite size, and this
  project has none — `AsteroidData.scale_ratio` renders one texture at 0.5× / 1.0× / 1.5×, and
  aspect compensation adds a further 0.9–1.15× per monitor.
- *Chose:* a screen-space pass that quantizes *after* scaling, rotation and zoom, so every element
  shares one grid. It also fixes rotating sprites, which normally destroy a hand-drawn grid.
- *Consequence for art:* hand-placed pixel art only makes sense for fixed-size, non-rotating
  elements (UI icons). Everything else is painted and let the shader pixelate.

**HDR 2D was tried for glow and reverted.**
- *Problem:* `WorldEnvironment` glow needs RGB above 1.0, but the 2D renderer clamps to LDR unless
  `rendering/viewport/hdr_2d` is on — `projectile_color = Color(2.0, 2.0, 0.5)` was silently
  arriving as `(1, 1, 0.5)`.
- *Rejected:* enabling it — a project-wide colour-space change. Every existing overbright value
  starts blooming (the `Color(4,4,4)` hit flash especially) and shader samplers need
  `source_color` hints. Not worth rebalancing the whole project for two effects.
- *Chose:* baked glow — an additive radial gradient sprite behind the shape. Per-object, no global
  setting, quantizes predictably under the pixelation pass.
- *Note:* bloom never lights *surrounding* objects regardless; that needs `PointLight2D` (which is
  what Gold/Red resources use).

---

## Recurring Bug Patterns

Things that have bitten more than once. Format: **Name** — *cause → effect*. Rule. (Example.)

### State & Timing

- **State that outlives its validity window** — *a stored value is reused after something
  changed it → stale reads.* Three shapes: sampled once and reused after a tween moved it
  (shop panel `global_position`); cached at `_ready()` and invalidated by a later event (viewport
  size across a resize); a per-frame array appended to but never cleared (`tagged_asteroids` grew
  to 4000+ freed entries). Ask of any stored value: what could change underneath this, and does
  anything rebuild it?
- **`queue_free()` is deferred, not immediate** — *a freed node keeps receiving signals and
  physics callbacks for the rest of the frame → double-death, double loot, skipped wave counts.*
  Anything with a one-shot side effect needs a guard flag (`is_dead`), not just `queue_free()`.
- **Pooled objects assigned by sort rank are unstable** — *slot `i` means "the i-th most urgent
  thing right now", so the object behind a slot changes whenever the ranking shuffles → running
  tweens, fades, and lerps land on the wrong object.* Map owner → pooled object explicitly when
  continuity matters. (Threat arrows swapped screen edges whenever two asteroids traded places.)
- **Guard clauses before side effects** — *a mid-function early `return` after a mutation →
  silent partial state.* Validate everything at the top, *then* mutate. (A debug flag silently
  failed to set.)
- **Off-by-one around level-up** — *reading cost after `level_up()` → charging next level's
  price.* Cost reads *before* the increment, value reads *after*.

### Scene Tree & Lifecycle

- **`@onready` before `add_child()`** — *`@onready` vars are null until `_ready()` runs, which
  happens inside `add_child()` → crash or silent null.* Initialize *after* adding to the tree.
- **`add_child()` runs `_ready()` synchronously** — *a `_ready()` that reads data supplied by a
  later deferred `initialize()` sees null → nothing configured.* Either defer both in order, or
  don't put externally-supplied data in `_ready()` at all. (`resource.gd` has no `_ready()` for
  this reason.)
- **`duplicate()` + reassign** — *shared sub-resources (`CircleShape2D`,
  `ParticleProcessMaterial`) are edited on the original → every instance changes.* Duplicate
  *and* reassign back to the node; forgetting the reassignment is the common miss.
- **`Dictionary.duplicate()` is shallow** — *nested dictionaries stay shared references → one
  category's stats bleed into another.* Duplicate the inner block directly or pass
  `duplicate(true)`.

### Math & Scaling

- **Integer division in scaling math** — *`(wave - min_wave) / (end_wave - min_wave)` with
  all-`int` operands → `0` until the final wave, then `1`.* Looks like a step function instead of
  a ramp, no warning. Force one operand to `float`; `maxf()` on the denominator is tidiest since
  it doubles as the divide-by-zero guard.
- **`pow()` of a negative base with a fractional exponent is `NaN`** — *and `NaN` survives
  `clampf()` untouched, since every comparison against it is false → silently broken curve.*
  Clamp the *progress* before `pow()`, not the result after. Relevant anywhere a wave number can
  fall below a `min_wave` — wave preview will do this.
- **Multipliers initialize to `1.0`, additive bonuses to `0.0`** — *a bare `var health_mult :
  float` is `0.0`, and `data.max_health * 0.0` is a silent zero → asteroids die to any hit and
  deal no damage.* Use the identity value for the operation.
- **Correct only because a value is currently 0 or 1** — *`anchor_left * width` looked right while
  `anchor_left` was `0`; `get_viewport_rect().size / 2` matched the planet only while the canvas
  was exactly 1920×1080.* Test formulas against a value that *isn't* the identity.
- **Rounding a small integer destroys a small multiplier** — *`roundi(randi_range(1,3) * 1.05)`
  returns what `* 1.0` returns → first several levels do nothing; large multipliers overshoot
  (`roundi(1.5)` is +100% on that roll).* Use stochastic rounding: `floori()` plus a `randf()`
  chance on the remainder.
- **Two reasonable curves multiplying into an untuned third** — *income scaled on four axes each
  looking mild → ~100× total; wave length is `events × interval` and humps mid-game because
  neither curve is tuned against the product.* When two scaling systems feed one outcome, plot
  the outcome, not the inputs.
- **Exact-equality wave-end guards hang forever** — *`asteroids_spawned == max_asteroids` on a
  counter anything can touch → one overshoot and the wave never ends, no error.* Use `>=`.

### Naming & Review Hygiene

- **A local sharing a name with a `data.` field** — *the compiler is happy and the meaning quietly
  shifts.* Three in one session: `max_speed` (clamp ceiling) vs `data.max_speed` (stat) collapsed
  speed variance; `speed_variance` (rolled offset) vs `data.speed_variance` (fraction) reduced
  ±15% to ±0.15 px/s; `resource` as a `ResourceData` in one loop and an index in the next produced
  `weights[resource]`. Name the local for what it *is* (`speed_offset`, `i`).
- **A doc comment describing intent rather than behaviour** — *`spawn_weight_end = -1.0` was
  documented as "no ramp" and the function never checked for it → every unmodified asteroid's
  weight lerped toward `-1` and went negative around wave 68.* Stale comments do the same
  (`DROP_X2_WAVE` referenced after the constant was removed). Verify against the code, not the
  description. (The comet `start()` comment is a live example — see 2D.)
- **Loop variables never used in the body** — *either the loop is wrong or it shouldn't exist.*
  The perk resolver's `else` branch looped over `perk.target_categories` instead of using the outer
  `target`, duplicating perk tier rows.
- **`continue` followed by an indented block** — *that block is unreachable.* Watch the
  Debugger's unreachable-code warning.
- **Computing a value the engine already knows** — *re-deriving something Godot computed →
  subtly wrong coordinate space.* Four in one session: sampling `global_position` for a panel's
  resting spot when the anchors were clean; rebuilding a Control's parent width from
  `get_viewport().size` when `get_parent_area_size()` reports it in the right space; deriving
  world positions from screen dimensions in the spawner and the despawn check. Ask the engine.
- **Direct writes to `active_stats`** — *bypasses `recalculate_stat()` → the next recalculation
  overwrites your value, or yours overwrites a perk.* Four bugs so far. Only `recalculate_stat()`
  may assign.

### Resources, Data & Engine

- **`DirAccess` folder scanning in export builds** — *`.import` / `.remap` suffixes rename files
  → scan finds nothing, registration silently aborts.* `ResourceScanner` strips `.remap`; keep
  it that way for any new scan.
- **Texture sizing is an import-settings problem** — *fixing it via `scale_ratio` also scales the
  collision shape → hitboxes silently wrong.* Fix the import or the sprite, not the node scale.
- **`UpgradeData.base_value` in the Inspector may do nothing** — *`register_upgrade_array()`
  syncs it from the defense's `default_stats` → the `.tres` number is overwritten at startup.*
  Edit the defense's `default_stats` to change a base; the upgrade's `base_value` is derived.
  (Projectile speed upgrade says 800; the turret says 600; 600 wins.)
- **Shader alpha must carry dimming, not RGB** — *multiplying RGB while passing alpha through →
  "dim" pixels go dark and opaque, invisible on black, obvious over anything bright.* Dim via
  alpha for anything composited over a background.
