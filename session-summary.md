# Session Summary — 29 May 2026

## Changes Made

### 1. Parallax Sky Background (`Main.gd`)
- Replaced procedural blue-noise underwater background with 3-layer parallax sky
  - **Sky**: Solid `ColorRect` + vertical gradient (top `#284870` → bottom `#8cb8e0`)
  - **Far clouds**: Large, wispy white clouds at `alpha=0.08`, parallax factor `0.005`
  - **Near clouds**: Denser white clouds at `alpha=0.15`, parallax factor `0.025`
- Updated clear color from dark blue `#152a6b` to sky blue `#598cbf`
- Both cloud layers use procedural noise with thresholding + `pow()` shaping for soft cloud edges
- 1024×1024 tileable textures

### 2. PoolManager — `remove_child` Race Condition Fix (`PoolManager.gd`)
- Root cause: `release_*` deferred `remove_child` via `call_deferred` but immediately added object to pool → `get_*` popped an object still having a parent → `add_child` crash or `remove_child` mismatch
- Fix: Unified all three release functions (`release_bullet`, `release_enemy`, `release_orb`) into a single deferred `_finalize_release()` that atomically does **`remove_child` + `pool.append`** in one deferred call
- Removed the per-frame `_enemy_pending` list + `_process` approach
- `get_*` functions retain a safety `remove_child` check for edge cases

### 3. PauseMenu — Ordering Fix (`PauseMenu.gd`)
- Moved `get_viewport().set_input_as_handled()` before action calls (same fix as Menu.gd)
- Prevents "Cannot call method on null value" when scene transition clears the viewport

### 4. Menu Background — Infinite Tween Warning (`Menu.gd`)
- Replaced `create_tween().set_loops()` (infinite) with single-shot tween + `tween_callback` that chains `_animate_bg_cell` recursively
- Eliminates Godot 4 "Infinite loop detected" console spam

### 5. Save & Continue System (Major Feature)

#### New SaveManager methods (`SaveManager.gd`):
- `save_run(data)` — saves run state to `[run]` section in `battle_cell.cfg`
- `load_run()` — loads saved run data
- `has_saved_run()` — checks if run save exists
- `delete_saved_run()` — removes `[run]` section

#### Data added to managers:
- `GameManager.get_save_data()` / `restore_from_save()` — GP, score, wave, era, kills, time
- `EvolutionManager.get_save_data()` / `restore_from_save()` — current form, evolution path, used upgrades, WTF progress
- `WaveManager.restore_from_save()` — starts spawn timer for current wave
- `HUD.refresh()` — reads GameManager state and updates all labels

#### UI:
- **PauseMenu**: Added "Save & Quit" button (middle, between Resume and Back to Main Menu)
- **Menu.gd**: 
  - Shows "Continue (Wave N)" button above PLAY when saved run exists
  - Clicking PLAY calls `delete_saved_run()` to start fresh
- **Main.gd**: 
  - `_ready()` checks `SaveManager.load_run()` → calls `_restore_run()` and skips `_check_start_form()`
  - `_restore_run()` restores GameManager, EvolutionManager (form + upgrades), Player (HP, position, second chance)
  - Evolution upgrade modifiers are re-applied from `_used_upgrades` data

## Files Modified
| File | Changes |
|---|---|
| `godot/Main.gd` | New background, restore_run logic |
| `godot/managers/PoolManager.gd` | `_finalize_release()` deferred approach |
| `godot/managers/GameManager.gd` | `get_save_data()`, `restore_from_save()` |
| `godot/managers/EvolutionManager.gd` | `get_save_data()`, `restore_from_save()`, `get_upgrade_data()` |
| `godot/managers/WaveManager.gd` | `restore_from_save()` |
| `godot/managers/SaveManager.gd` | `save_run()`, `load_run()`, `has_saved_run()`, `delete_saved_run()` |
| `godot/ui/Menu.gd` | Background tween fix, Continue button, Play deletes run |
| `godot/ui/PauseMenu.gd` | Save & Quit button, input ordering fix |
| `godot/ui/HUD.gd` | `refresh()` method |

## Known Issues
- None reported for current changes
