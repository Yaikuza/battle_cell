# Systems Design — EVOLVE (Godot, Solo Dev)

## หลักการหลัก: ทำ Foundation ก่อน Feature เสมอ

กฎของ solo dev — ถ้า system ล่างยังไม่นิ่ง system บนจะพังตามทุกครั้งที่แก้

---

## สถาปัตยกรรม 8 Layers

```
Layer 1: Core Loop
    ↓
Layer 2: Combat
    ↓
Layer 3: Data (Resource files)
    ↓
Layer 4: Mutation System
    ↓
Layer 5: Era System
    ↓                 ↘
Layer 6: Visual    Layer 7: Boss/Extinction
    ↘                 ↙
Layer 8: Meta & Save
```

ไม่มี layer ไหนขึ้นไปหา layer ล่าง — ทุก dependency ไหลลงข้างเดียว

### 🟥 Layer 1 — Core Loop (ทำก่อนทุกอย่าง)

**ระบบ:** PlayerController, EnemySpawner, WaveManager

ทำ loop ให้ครบก่อน แม้จะ placeholder ทั้งหมด:
Player เคลื่อนที่ → ศัตรู spawn → ศัตรูตาย → EP++ → wave ถัดไป

**Status:** ✅ COMPLETE
- Player movement (MovementComponent + Input Map)
- Enemy spawn + wave progression (WaveManager + PoolManager)
- GP system (GameManager._on_gp_collected)
- Evolution trigger (EventBus.evolution_ready)
- Game Over / Restart / Menu
- Boss ทุก 5 wave

### 🟥 Layer 2 — Combat System

**ระบบ:** HitboxSystem, DamageCalculator, AutoAttackController, DodgeController

สิ่งที่ต้อง lock ก่อนไปต่อ:
- Hitbox/Hurtbox เป็น Node แยก (ไม่ฝังใน player)
- DamageCalculator รับ base_damage, multiplier, armor — คำนวณกลางที่เดียว
- Dodge i-frame เป็น signal ไม่ใช่ boolean flag

**Status:** ✅ COMPLETE (v0.7.0)
- `HitboxComponent.gd` — Area2D แยก, ใช้ collision_layer 2, mask 4, emit `hit_detected`
- `HurtboxComponent.gd` — Area2D แยก, มี armor, damage_multiplier, invulnerable, signal `damage_taken`/`iframe_started`/`iframe_ended`
- `DamageCalculator.gd` — static calculate() รองรับ PHYSICAL (dmg-armor), MAGIC (dmg*(1-armor%)), TRUE (pass)
- `DodgeController.gd` — tween-based dash, cooldown timer, signal-based iframe ผ่าน Hurtbox

### 🟧 Layer 3 — Data Architecture

**ระบบ:** MutationResource, EraResource, EnemyResource (Godot Resource files)

ทำ .tres Resource สำหรับทุก data:
- MutationData.tres — id, tier, branch, effect_type, value, next_tier_id
- EraData.tres — era_id, enemy_pool, boss_scene, biome_theme, available_mutations

**Status:** ✅ COMPLETE (v0.7.0)
- `MutationData.gd` — Resource class with Branch enum (PREDATOR/ARMORED/SWIFT/HYBRID), EffectType, modifier binding
- `EraData.gd` — Resource class with era_id, enemy_ids, boss_id, zoom_level, available_mutation_ids
- `GameDatabase.gd` — Resource aggregator with forms/enemies/upgrades/hybrid_recipes/eras arrays + lookup methods
- `game_database.tres` — 800-line Resource file containing all game data

### 🟧 Layer 4 — Mutation System

**ระบบ:** MutationManager, MutationPool, MutationUI

MutationManager:
- current_mutations: Array[MutationData]
- apply_mutation(data: MutationData) ← emit signal ไปหา stat systems
- get_random_choices(pool, count=3)

PlayerStats ← รับ signal จาก MutationManager

กฎสำคัญ: MutationManager ไม่รู้จัก Player โดยตรง — ใช้ Signal เท่านั้น

**Status:** ⬜ NOT STARTED
- MutationData.gd exists (data schema)
- No MutationManager, MutationUI, or signal wiring yet
- EvolutionManager ปัจจุบันทำหน้าที่คล้าย mutation system แต่ใช้ inline data

### 🟨 Layer 5 — Era System

**ระบบ:** EraManager, EraTransitionController, BiomeLoader

EraManager:
- current_era: int
- era_configs: Array[EraResource]
- transition_to_next_era()

Era เป็นแค่ "config loader" — ไม่มี logic เอง แค่บอกว่า wave นี้ใช้ pool อะไร

**Status:** 🟡 PARTIAL
- EraData.gd exists (data schema)
- GameManager มี era progression logic (wave-based era index)
- WaveManager ใช้ ERA_POOLS dictionary (hardcoded, not from GameDatabase)
- WaveManager ยังไม่ refactor ให้ใช้ GameDatabase / EraData
- EraManager autoload ยังไม่มี

### 🟨 Layer 6 — Visual Evolution System

**ระบบ:** EvolutionVisualController, MorphingSystem, PartLibrary

แนะนำ:
```
Player
└── EvolutionVisualController
    └── PartSlots (head, body, limbs, tail)
        └── แต่ละ slot โหลด Sprite2D ตาม build + era
```

ใช้ Tween สำหรับ morph transition

**Status:** 🟡 BASIC
- Player มี Sprite2D ตัวเดียว (_load_texture ตาม form_id)
- Evolution animation (_animate_evolution) มี tween 3-phase
- ยังไม่มี EvolutionVisualController, PartSlots
- ยังไม่มี morphing system

### 🟩 Layer 7 — Extinction Event / Boss System

**ระบบ:** BossController, ExtinctionEventManager, EnvironmentHazardSystem

ExtinctionEventManager:
- trigger_event(type: ExtinctionType)
- events: { SNOWBALL: ShrinkPlayfieldEvent, ASTEROID: DebrisRainEvent, ANOXIA: OxygenDrainEvent }

แยก event logic ออกจาก boss ตัวเอง

**Status:** 🟡 BASIC
- Boss.gd exists (simple chase + damage + hp bar + multi-orb drop)
- Boss ทุก 5 wave via WaveManager
- ยังไม่มี ExtinctionEventManager
- ยังไม่มี EnvironmentHazardSystem
- Boss ยังไม่ใช้ HitboxComponent/HurtboxComponent

### 🟩 Layer 8 — Meta & Save System

**ระบบ:** SaveManager, MetaProgressionManager, UnlockTracker

ทำสุดท้ายเพราะต้องรู้ก่อนว่า data อะไรบ้างที่ต้อง save

SaveData:
- unlocked_mutations: Array[String]
- era_mastery: Dictionary
- fossil_records: Array[int]
- run_history: Array[RunData]

**Status:** ✅ COMPLETE
- SaveManager.gd — ConfigFile-based, gallery/highscores/settings/run save
- MetaManager.gd — DNA progression, 5 tabs (Ancestral Traits, Start Perks, Legacy Forms, WTF Edge, Titles)
- Run save/restore for quit-and-resume

---

## สถานะปัจจุบัน (v0.7.0)

| Layer | สถานะ | รายละเอียด |
|-------|--------|------------|
| 1 Core Loop | ✅ | Player, Enemy, Wave, GP, Evolution, Game Over |
| 2 Combat | ✅ | HitboxComponent, HurtboxComponent, DodgeController, DamageCalculator |
| 3 Data | ✅ | MutationData, EraData, GameDatabase, game_database.tres |
| 4 Mutation | ⬜ | มีแค่ data schema ยังไม่มี system |
| 5 Era | 🟡 | EraData มี, แต่วิธีใช้ปัจจุบันยัง hardcode ใน WaveManager |
| 6 Visual | 🟡 | Sprite swap เบื้องต้น ยังไม่มี PartSlots |
| 7 Boss/Extinction | 🟡 | Boss พื้นฐาน ยังไม่มี ExtinctionEvent |
| 8 Meta/Save | ✅ | SaveManager + MetaManager |

---

## Node Structure (แนะนำ)

```
Main
├── GameManager (Autoload)
├── EraManager (Autoload) ← ยังไม่มี
├── MutationManager (Autoload) ← ยังไม่มี
├── SaveManager (Autoload)
│
├── World
│   ├── BiomeEnvironment
│   ├── HazardLayer
│   └── SpawnPoints
│
├── Entities
│   ├── Player
│   │   ├── HitboxComponent
│   │   ├── HurtboxComponent
│   │   ├── StatsComponent
│   │   ├── DodgeController
│   │   ├── AutoAttackComponent
│   │   └── EvolutionVisualController ← ยังไม่มี
│   └── EnemyContainer
│
└── UI
    ├── HUD
    ├── MutationPickerUI ← ยังไม่มี
    └── EraTransitionUI ← ยังไม่มี
```

Autoload = Singleton ที่ทุก scene เข้าถึงได้ — ใช้แค่ 4-6 ตัว อย่าเพิ่มจนเกินไป

---

## Roadmap

### ✅ Phase 1 — Foundation & Core Loop (Layer 1)
- Core architecture
- Player movement (cell)
- Enemy chase AI
- Basic weapon (AimedShot = Pseudopod)
- Wave spawning system
- Genetic Point system
- Energy Orb pickups
- HUD
- Evolution Screen UI
- Form switching system
- Basic Evolution Tree
- Era system (basic)
- Game Over / Restart + Back to Menu

### ✅ Phase 1 Bug Fixes
- Signal leaks — _exit_tree() disconnect
- GP overflow discarded
- Player invulnerability
- Damage flash invert
- Boss uses PoolManager.get_orb()

### ✅ Phase 2 — Evolution Deepening
- Evolution tree ขยาย (10+ forms)
- Adaptive upgrades
- Boss ทุกๆ 5 wave
- Object Pooling (PoolManager)
- Hybrid Fusion system
- MovementComponent รองรับ Input actions

### ✅ Phase 2.5 — Melee Weapon & Input Overhaul
- Hack & Slash weapon (SlashBehavior)
- Input Map setup (keyboard + controller + touch)
- VirtualJoystick

### ✅ Phase 3 — Content Expansion
- Sprite art (procedural PNG generator)
- Particles / effects (EffectManager)
- Evolution animations
- Sound (AudioManager)
- Dinosaur era enemies (6 behaviors)

### ✅ Phase 4 — Combat & Data (Layer 2 + 3) v0.7.0
- HitboxComponent (Area2D, collision_layer 2, mask 4)
- HurtboxComponent (armor, invulnerability, signals)
- DodgeController (tween dash, cooldown)
- DamageCalculator (PHYSICAL/MAGIC/TRUE)
- MutationData (Branch, EffectType, modifier binding)
- EraData (era_id, enemy/boss/zoom config)
- GameDatabase (aggregate Resource + .tres)

### ⬜ Phase 5 — Mutation System (Layer 4)
- [ ] MutationManager (Autoload)
- [ ] MutationPool (random weighted selection)
- [ ] MutationUI (picker screen)
- [ ] Signal wiring: MutationManager → StatsResource
- [ ] Mutation tier progression (tier 1→2→3 chains)
- [ ] Refactor EvolutionManager ให้ใช้ GameDatabase แทน inline data

### ⬜ Phase 6 — Era Refactor (Layer 5)
- [ ] EraManager (Autoload)
- [ ] WaveManager refactor: ใช้ GameDatabase EraData แทน ERA_POOLS
- [ ] EraTransitionController (visual transition between eras)
- [ ] Biome loading per era

### ⬜ Phase 7 — Visual Evolution (Layer 6)
- [ ] EvolutionVisualController (child node of Player)
- [ ] PartSlots: head, body, limbs, tail
- [ ] Morph transition via Tween
- [ ] Part library (sprite parts per form + era)

### ⬜ Phase 8 — Extinction Events (Layer 7)
- [ ] ExtinctionEventManager
- [ ] BossController refactor (ใช้ Hitbox/Hurtbox)
- [ ] Events: ShrinkPlayfield, DebrisRain, OxygenDrain
- [ ] EnvironmentHazardSystem

### ⬜ Phase 9 — Secrets & What-If
- [ ] Secret evolution conditions
- [ ] What-If forms (Crystal, Void, Celestial)
- [ ] WTF forms
- [ ] Failed Evolution forms
- [ ] Achievement system
- [ ] Account unlock

### ⬜ Phase 10 — Polish
- [ ] UI anchor/layout refactor
- [ ] Mobile export
- [ ] Performance optimization
- [ ] Submit to stores

---

## สิ่งที่ต้องทำต่อ (Priority)

### Critical — Layer 4: Mutation System
1. สร้าง `MutationManager.gd` (Autoload)
   - current_mutations: Array[MutationData]
   - apply_mutation(data: MutationData) → emit signal
   - get_random_choices(pool, count=3)
2. สร้าง `MutationUI.gd` (ใช้โครงสร้างเดียวกับ EvolutionScreen)
3. เชื่อม signal ไปยัง Player Stats
4. Mutation tier progression (tier 1 → tier 2 → tier 3 chains)

### High — Layer 5: Era Refactor
1. สร้าง `EraManager.gd` (Autoload)
2. Refactor WaveManager ให้ใช้ GameDatabase EraData
3. EraTransitionController

### Medium — Layer 6-7 Integration
1. Boss refactor (ใช้ Hitbox/Hurtbox)
2. EvolutionVisualController

---

## Conventions
- 4 spaces indentation
- snake_case for variables/functions
- PascalCase for class_name
- autoload scripts ห้ามมี class_name
- ไฟล์ script: PascalCase.gd
- class_name ทุก script ที่ต้อง instanced โดยตรง
- HitboxComponent: collision_layer=2, collision_mask=4
- HurtboxComponent: collision_layer=4, collision_mask=0
- ใช้ Signal เสมอในการสื่อสารระหว่าง Manager ↔ Entity
- ไม่ใช้ EventBus สำหรับ component-to-component (ใช้ signal โดยตรง)

---

## Game Lore & Concept

> คุณเริ่มต้นเป็น **เซลล์เดียว (Single Cell)** ในยุค Cambrian
> กลืนกิน วิวัฒนาการ ผสมสายพันธุ์
> เป้าหมาย: อยู่รอดและวิวัฒนาการข้ามผ่าน 450 ล้านปี
> จนกลายเป็นสิ่งมีชีวิตทรงพลัง — หรือค้นพบ **What-If Evolution**
> ที่ไม่เคยเกิดขึ้นบนโลกใบนี้

### แนวคิดหลัก
- สะสม **Genetic Points** (GP) จากการฆ่าและกลืนกินศัตรู
- ถึง threshold → เกิด **Evolution Event** — เลือกทางวิวัฒนาการ
- แต่ละ Evolution **เปลี่ยนรูปร่าง + อาวุธ + stats** ทั้งหมด
- ยิ่งอยู่นาน ยิ่งเจอสิ่งมีชีวิตจากยุคต่อๆ ไป
- **Secret What-If Evolution** — สิ่งมีชีวิตที่ไม่เคยเกิดขึ้นบนโลก ปลดล็อคด้วยการผสมข้ามกิ่ง หรือทำเงื่อนไขพิเศษ
- **Hybrid Fusion** — ผสม 2 กิ่ง → ร่างลูกผสม
- **Failed Evolution** — วิวัฒนาการที่ผิดพลาดแต่ก็มีข้อดี
- **WTF Evolution** — หลุดโลก เมม absurd

### ระดับของสิ่งมีชีวิต / ยุคทางธรณี
- Cambrian (0-3 นาที) — Trilobite, Anomalocaris, แพลงก์ตอน
- Triassic (3-8 นาที) — Placoderm, Ammonite, Temnospondyl
- Jurassic (8-15 นาที) — Dilophosaurus, Stegosaurus, Pterosaur
- Cretaceous (15-25 นาที) — Tyrannosaurus, Velociraptor, Triceratops
- Post-Cretaceous (25+ นาที) — What-If Zone: Crystal Entity, Void Walker
- Anthropocene (สาย Mammal) — Mutant Humans, Drones, Hybrid Species

---

## Environment

```
GODOT_EXECUTABLE=C:\Users\wasu\Desktop\GoDot\Godot_v4.6.1-stable_win64.exe
```

ใช้คำสั่ง validate:
```powershell
& "$env:GODOT_EXECUTABLE" --headless --import --path "D:\Documents\GitHub\battle_cell\godot"
```
