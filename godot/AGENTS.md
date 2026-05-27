# Battle Cell: Evolution

2D Top-down Roguelike Bullet Heaven
ธีม **วิวัฒนาการของสิ่งมีชีวิต — 450 ล้านปีใน 30 นาที**

---

## ธีมและ Concept หลัก

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

### ระดับของสิ่งมีชีวิต / ยุคทางธรณี

```
ยุค Cambrian (0-3 นาที)
  └── ผู้เล่นเริ่มเป็น Single Cell
  └── ศัตรู: Trilobite, Anomalocaris, แพลงก์ตอน

ยุค Triassic (3-8 นาที)  
  └── ปลดล็อค: สัตว์น้ำ, สัตว์ครึ่งบกครึ่งน้ำ
  └── ศัตรู: Placoderm, Ammonite, Temnospondyl

ยุค Jurassic (8-15 นาที)
  └── ปลดล็อค: สัตว์เลื้อยคลาน, ไดโนเสาร์ยุคแรก
  └── ศัตรู: Dilophosaurus, Stegosaurus, Pterosaur

ยุค Cretaceous (15-25 นาที)
  └── ปลดล็อค: ไดโนเสาร์ขั้นสูง, นกยุคแรก
  └── ศัตรู: Tyrannosaurus, Velociraptor, Triceratops

ยุค Post-Cretaceous (25+ นาที) — What-If Zone
  └── ปลดล็อค: Crystal Entity, Void Walker, Celestial Being, WTF Forms
  └── ศัตรู: สิ่งมีชีวิตกลายพันธุ์/นอกโลก

ยุค Anthropocene (ถ้าสามารถอยู่ถึง & เลือกทาง Mammal)
  └── สาย Mammal → Primate → Human จะปลดล็อคยุคนี้
  └── ศัตรู: มนุษย์กลายพันธุ์, เครื่องจักร, Hybrid Species
  └── Lore: โลกที่มนุษย์ครอบงำ — หรือถูกครอบงำโดยสิ่งที่วิวัฒนาการเหนือกว่า
```

---

## Core Game Mechanics

### 1. ระบบ Genetic Points (GP)
- เดิมคือ **XP** — ศัตรูตายดรอป **Genetic Orbs** (สีเขียวเรืองแสง)
- เก็บ GP → สะสม → ถึง threshold **Evolve** ได้
- Threshold แต่ละครั้งสูงขึ้น (100 → 250 → 500 → ...)
- GP ยกมาเฉพาะ evolution นี้ (ไม่ reset)

### 2. ระบบ Evolution (แทน Level Up)
เมื่อ GP ถึง threshold จะเกิด **Evolution Screen**:
- โชว์ **Evolution Tree** ตามยุคปัจจุบัน
- เลือก **2-3 ทาง** (branching)
- แต่ละทางเปลี่ยน:
  - **รูปร่าง** — visual change
  - **อาวุธหลัก** — form-specific weapon
  - **Stats** — HP, speed, damage base
  - **Passive** — trait ติดตัวของสายพันธุ์

> **Lore:** คุณคือสิ่งมีชีวิตเซลล์เดียวใน "สวนวิวัฒนาการ" ที่ถูกสร้างขึ้นโดยนักวิทยาศาสตร์ปริศนา
> การที่คุณสามารถวิวัฒนาการถึงขั้นเป็น **มนุษย์** ได้นั้น ไม่ใช่เรื่องบังเอิญ
> มนุษย์ในโลกนี้ไม่ใช่ "จุดสิ้นสุด" หากแต่เป็นแค่ **ทางแยก** ของบางสิ่งที่ใหญ่กว่า
> What-If และ Failed Evolution คือ **"ร่องรอย"** ของการทดลองที่ผิดพลาด
> มีบางอย่างกำลังยุ่งเกี่ยวกับวิวัฒนาการจากนอกโลกใบนี้...

**ตัวอย่าง Evolution Tree แรก:**

```
                    ┌── Fish (น้ำ) — Water Jet + Swim Speed
Single Cell ────────┼── Amphibian (ครึ่งบก) — Tongue Lash + Regen
                    └── Bug (แมลง) — Sting Darts + Small Size
```

เมื่อเลือกไปเรื่อยๆ กิ่งจะแตกย่อย:

```
                                    ┌── T-Rex (Crushing Bite + Intimidate)
Fish → Amphibian → Reptile ────────┼── Raptor (Slash Combo + Speed)
                     └── Mammal ───┼── Ankylosaur (Tail Sweep + Armor)
                                   └── Human (???)

                                 ┌── Pterosaur (Dive Bomb + Flight)
Bug → Insect → Winged Insect ────┼── Swarm Queen (Minion Spawn)
                                 └── Beetle (Shell Shield + Charge)

                                     ┌── Neanderthal (Club + Endurance)
Mammal → Primate → Early Human ────┼── Homo Sapiens (Tool Craft + Adapt)
                                     └── Homo Superior (Psychic + Tech)
```

#### Human Evolution Special
การเป็นมนุษย์ไม่ใช่จุดจบ — แต่เป็น **branch ที่แตกต่าง**:

| ร่าง | อาวุธ | Passive | จุดเด่น |
|---|---|---|---|
| Neanderthal | Wooden Club (ตีใกล้แรง) | Endurance + โอกาสต้านทาน | Tank สายถึก |
| Homo Sapiens | Tool Craft (สร้างอาวุธชั่วคราว) | Adapt — stats ปรับตามศัตรู | สายยืดหยุ่น |
| Homo Superior | Psychic Wave (คลื่นพลังจิต) | Tech Affinity — cooldown ลด | สายเวท/เทคโนโลยี |

**Lore Tie-in:** เมื่อไปถึง Human คุณจะเริ่มเห็น "message" จากนักวิทยาศาสตร์
— ข้อความที่บอกใบ้ถึง What-If, Failed Evolution,
และความจริงที่ว่า **การทดลองนี้มีจุดประสงค์ซ่อนเร้น**

### 3. ระบบ Hybrid Fusion
ที่จุด evolution บางจุด สามารถ **ผสม 2 กิ่ง** = ร่างลูกผสม:

- **Reptile + Bird = Dragon** (Fire Breath + Flight)
- **Fish + Insect = Crab-like** (Armor + Clamp Attack)
- **Mammal + Bird = Bat** (Sonar + Swarm)
- **Amphibian + Plant = Fungal Entity** (Spore + Regen)

### 4. ระบบ What-If Evolution (Secret)
ปลดล็อคด้วยเงื่อนไขพิเศษ เช่น:
- ฆ่า boss ด้วยอาวุธเฉพาะ
- ถึง threshold ขณะมี GP ติดตัว ≥ N
- ไม่ evolve เป็นเวลานาน (สะสม "mutation" แฝง)
- ผสมกิ่งที่ "เข้ากันไม่ได้" ทาง生物学?

**ตัวอย่าง What-If:**
| ชื่อ | แนวทาง | การเล่น |
|---|---|---|
| Crystal Entity | ร่างกายเป็นผลึก | Projectile สะท้อน,反射 damage |
| Void Walker | สิ่งมีชีวิตจากมิติเงา | Teleport, ชั่วคราวล่องหน |
| Celestial Being | พลังงานจักรวาล | Beam โจมตี, Gravity well |
| Omega Cell | กลับไปเป็นเซลล์อีกครั้ง แต่ทรงพลังกว่าเดิม | อาวุธทุกอย่าง +  stats มหาศาล (New Game+) |

เมื่อปลดล็อค What-If → โผล่ใน Evolution Tree ตลอดไป (account unlock)

#### สายหลุดโลก (WTF Evolution)
Evolution ที่ **ไม่มีทางเกิดขึ้นได้ในโลกจริง** — แนวคิดหลุดโลก, เมม, หรือ absurd:

| ชื่อ | ที่มา | การเล่น |
|---|---|---|
| Rubber Chicken | ไก่ยางเด้งดึ๋ง | กระเด้งใส่ศัตรู, ดีด反弹เป็น chain |
| Meme Lord | พลังแห่งมeme | โจมตีด้วยข้อความสุ่ม, โมเมนตัมเพิ่มตาม toxicity |
| Infinite Cat | แมวไม่จำกัด | ปล่อยแมวออกมาเรื่อยๆ, แมวตาย = สร้างแมวใหม่ |
| Pizza Planet | มนุษย์พิซซ่า | ยิงชิ้นเปปเปอโรนี, พ่นชีสร้อน AoE, ครัสต์เป็นเกราะ |
| Keyboard Warrior | นักรบคีย์บอร์ด | พ่นคีย์บอร์ดใส่, หลบเก่ง, passive: toxic aura |
| T-Pose Tyrant | ไดโนเสาร์ T-Pose | T-pose ข่มขวัญศัตรู, ศัตรูใกล้ช้าลง + กลัว |
| Roomba Lord | หุ่นดูดฝุ่นครองโลก | ดูดศัตรูเข้ามา, กลืนกินอัตโนมัติ, movement random |
| Sentient Toaster | เครื่องปิ้งขนมปังมีชีวิต | ปิ้งศัตรู, pop-up อัตโนมัติ, ต่อสายฟ้าฟาด |
| Bee Movie Script | พลังแห่งบทหนัง | ยิงบทสนทนาจาก Bee Movie ทีละบรรทัด (ความยาว 90 นาที) |
| Among Us Imposter | สายสืบสวน | ลอบสังหารแบบไม่ให้ใครเห็น, vent หนี |

> **Note:** สาย WTF จะ unlock เมื่อสะสม GP ถึง threshold ในขณะมี "Playtime" ≥ 10 นาที หรือฆ่าศัตรูด้วยอาวุธที่ไม่ถนัด

#### Failed Evolution
วิวัฒนาการที่ **ผิดพลาด พิกล พิการ** — แต่ก็ยังมีข้อดีของมัน:

| ชื่อ | ความผิดปกติ | แต่ยัง... |
|---|---|---|
| Blind Cave Fish | ตาบอด (bullet ไม่มี homing) | Sensing สูงมาก, detect ศัตรูผ่านกำแพง |
| Vestigial Legs | ขาเล็กบ๊องส์ ไม่มีประโยชน์ | วิ่งเร็วที่สุดในเกม, roll dodge |
| Neotenic Axolotl | ตัวเด็กตลอดกาล ดักไม่โต | Regen มหาศาล, ศัตรูขนาดเล็กมองไม่เห็น |
| Missing Link | กึ่งๆ ทุกอย่าง ไม่ได้เรื่องสักอย่าง | Immune ต่อ status effect, resistant ทุกธาตุ |
| Failed Cloning | เงาประหลาด | Clone ตัวเองตายแทนได้, respawn ฟรี |
| Wrong Phylum | เกิดผิดประเภท | อาวุธไร้ประโยชน์ → จริงๆ OP แบบไม่ตั้งใจ |
| Stuck in Amber | ติดอยู่ในอำพัน | ขยับไม่ได้ แต่ป้องกันทะลุ ทุกอย่างเด้งกลับ |
| Left-handed | เกิดมาถนัดซ้ายในโลกที่ออกแบบมาสำหรับคนถนัดขวา | Attack animation กลับด้าน → ศัตรูสับสน |
| Suspicious Mutation | จากสายหนึ่ง กลายพันธุ์ไปอีกสาย | มี trait จากสายที่ไม่ได้เลือก (ผสมข้ามโดยไม่ตั้งใจ) |
| Extinction Event | สายที่สูญพันธุ์ไปแล้ว | ฟอสซิลกลับมา, มี "Ancient Power" |

> **Note:** Failed Evolution มักมาพร้อม **"แต่"** — จุดด้อยที่ตลก + จุดเด่นที่เซอร์ไพรส์
> เป็นที่นิยมในหมู่ speedrunner และ challenge run

### 5. ระบบศัตรูตามยุค
แต่ละยุคมี **Enemy Pool** ของตัวเอง:

| ยุค | ศัตรู | ลักษณะ |
|---|---|---|
| Cambrian | Trilobite, Anomalocaris, Jellyfish | ช้า, pattern ง่าย, เหมาะกับ Cell |
| Triassic | Placoderm, Ammonite, Temnospondyl | ความเร็วปานกลาง, บางตัว ranged |
| Jurassic | Dilophosaurus, Stegosaurus, Pterosaur | HP สูง, movement หลากหลาย |
| Cretaceous | T-Rex, Velociraptor, Triceratops | ดุ, เร็ว, บางตัว boss-tier |
| Post-Cretaceous | Mutants, Aliens, Crystals | แปลก, มี ability พิเศษ |
| Anthropocene | Mutant Humans, Drones, Hybrid Species | ศัตรูฉลาด, ใช้อาวุธ, มีแทคติก |

- ทุก Wave = สุ่ม enemy pool ตามยุคปัจจุบัน
- **Boss** ทุก 5 Wave — สัตว์ใหญ่แห่งยุคนั้น

### 6. ระบบ Stats & Modifier
เหมือนเดิม — `StatsResource` พร้อม FLAT/PERCENT modifier
- แต่ละ form มี base stats ต่างกัน
- Evolution = เปลี่ยน base stats + change form
- หลังจาก evolve สามารถสะสม GP เพื่อ "Adapt" (อัปเกรด form ปัจจุบัน) หรือ "Evolve" (เปลี่ยนร่าง)

---

## Architecture

```
godot/
├── AGENTS.md                    # ไฟล์นี้
├── Main.gd                      # Root scene logic
├── project.godot
├── Scenes/
│   └── Main.tscn
├── core/
│   ├── EventBus.gd              # Global signal bus (autoload)
│   └── StatsResource.gd         # Stats with modifier system
├── data/                        # Data-Driven Resources
│   ├── EvolutionData.gd         # Evolution tree node schema
│   ├── FormData.gd              # Creature form stats + weapon
│   ├── WeaponData.gd
│   ├── EnemyData.gd
│   └── UpgradeData.gd
├── components/
│   ├── HealthComponent.gd
│   ├── MovementComponent.gd
│   └── WeaponComponent.gd
├── behaviors/
│   └── weapons/                 # Form-specific weapon behaviors
│       ├── AimedShot.gd
│       ├── WaterJet.gd
│       ├── TailSweep.gd
│       ├── CrushingBite.gd
│       └── ... (เพิ่มตาม form)
├── managers/
│   ├── GameManager.gd           # State, GP, evolution (autoload)
│   ├── WaveManager.gd           # Wave spawning, era progression
│   └── EvolutionManager.gd      # Evolution tree, form switching
├── entities/
│   ├── Player.gd                # Player cell/creature
│   ├── enemies/
│   │   └── Enemy.gd
│   ├── projectiles/
│   │   └── Bullet.gd
│   └── pickups/
│       └── GeneticOrb.gd        # เดิมคือ XPGem
└── ui/
    ├── HUD.gd                   # HP, GP bar, era, wave
    └── EvolutionScreen.gd       # Evolution choice UI (NEW)
```

### Autoloads
- `GameManager` — `res://managers/GameManager.gd` (renamed XP → GP, Level → Era)
- `EventBus` — `res://core/EventBus.gd`

---

## Roadmap (อัปเดตตามธีมใหม่)

### Phase 1 — Foundation & Core Loop ✅
- [x] Core architecture
- [x] Player movement (cell)
- [x] Enemy chase AI
- [x] Basic weapon (AimedShot = Pseudopod)
- [x] Wave spawning system
- [x] Genetic Point system (rename XP)
- [x] Energy Orb pickups (rename XPGem → GeneticOrb)
- [x] HUD แสดง GP, Era, Wave
- [x] Evolution Screen UI — หน้าจอเลือก evolution 2-3 ทาง
- [x] Form switching system — เปลี่ยนรูปร่างเมื่อ evolve (Player.apply_form)
- [x] Basic Evolution Tree — Cell → Fish / Amphibian / Bug
- [x] Era system — ยุคเปลี่ยนตาม wave
- [x] Game Over / Restart + Back to Menu

### Phase 1 Bug Fixes (post-review) ✅
- [x] Signal leaks — _exit_tree() disconnect บน EventBus consumers ทุกตัว
- [x] GP overflow discarded — gp=0 → gp-=gp_to_next
- [x] Player invulnerability — set_invulnerable(0.5) หลัง take_damage ป้องกัน multi-hit
- [x] Damage flash invert — Enemy brighten แล้ว restore (ไม่ติดสีแดงค้าง)
- [x] Boss uses PoolManager.get_orb() แทน GeneticOrbScript.new() (shared pool)

### Phase 2 — Evolution Deepening ✅
- [x] Evolution tree ขยาย (10 forms)
- [x] Adaptive upgrades (อัปเกรด form ปัจจุบัน)
- [x] Boss ทุกๆ 5 wave
- [x] Object Pooling (Bullet, Enemy, GeneticOrb) — PoolManager autoload + prewarm
- [x] Hybrid Fusion system (ผสม 2 กิ่ง → ร่างลูกผสม) — 3 recipes, path tracking, hybrid tag UI
- [x] ปรับ MovementComponent รองรับ Input actions (virtual joystick fallback)

### Phase 2.5 — Melee Weapon & Input Overhaul ✅
- [x] Hack & Slash weapon — SlashBehavior (3-step combo arc) + SlashEffect visual
- [x] Simple Predator form (อาวุธเริ่มต้นเป็น melee)
- [x] Input Map setup — move_left/right/up/down (keyboard + controller + touch)
- [x] VirtualJoystick — dynamic touch joystick (left 50% screen, auto-hide)

### Phase 3 — Content Expansion
- [ ] Sprite art แต่ละ form
- [ ] Particles / effects
- [ ] Sound
- [ ] Dinosaur era enemies
- [ ] Evolution animations
- [ ] UI anchor/layout refactor (รองรับหลาย aspect ratio)

### Phase 4 — What-If Secrets
- [ ] Secret evolution conditions
- [ ] What-If forms (Crystal, Void, Celestial)
- [ ] WTF forms (Rubber Chicken, Meme Lord, Pizza Planet...)
- [ ] Failed Evolution forms (Blind Cave Fish, Vestigial Legs, Missing Link...)
- [ ] Achievement system
- [ ] Account unlock (ระหว่างรัน)

### Phase 5 — Meta Progression
- [x] **Main menu** — Title, Play, Evolution Tree viewer, Options (volume + fullscreen)
- [ ] Evolution gallery (ดู form ที่ปลดล็อคแล้ว) — รวมเข้ากับ Evolution Tree viewer
- [ ] High score / stats tracking
- [ ] Save system (ConfigFile)
- [ ] Mobile export templates setup
- [ ] Android beta test (AAB)
- [ ] iOS build test (Xcode)
- [ ] Submit to App Store + Play Store

---

## Design Principles
1. **Evolution ต้องให้ความรู้สึก "ก้าวหน้า"** — แต่ละ form เปลี่ยนการเล่นจริง
2. **What-If ต้องมีเงื่อนไขที่น่าค้นหา** — ไม่บังคับทำ แต่ล่อใจให้ลอง
3. **Hybrid Fusion > Linear upgrade** — ผสมสายพันธุ์ = core fun
4. **อ้างอิงโลกจริง 50%, What-If 30%, WTF 10%, Failed 10%** — สมดุลระหว่างเป็นไปได้, เหนือจริง, และฮา
5. **Failed Evolution ≠ useless** — ทุก failed form มี "แต่" ที่ทำให้เลือกเล่นได้ (และมักมีมุกแทน)
6. **WTF forms คือ reward ของคนที่ลองของ** — unlock ยากกว่า แต่คุ้มค่าความฮา

---

## Mobile Strategy

### กลยุทธ์: Mobile-First Design, PC-First Development

ออกแบบระบบให้รองรับมือถือตั้งแต่第一天 แต่พัฒนา+debug บน PC ก่อน
เพราะ Bullet Heaven เป็นเกมที่適合กับมือถืออยู่แล้ว (Virtual stick เคลื่อนที่ + Auto-attack)

### Design Decisions ที่ต้องทำตั้งแต่ตอนนี้

| เรื่อง | แนวทาง | ทำไม |
|---|---|---|
| **Input** | MovementComponent โหมด PLAYER รองรับทั้ง keyboard และ virtual joystick โดยตรวจ `Input.get_axis()` + fallback | ไม่ต้อง rewrite inputs ทีหลัง |
| **UI Scaling** | ใช้ `CanvasLayer` + anchor-based layout (ไม่ใช้ absolute position เท่าที่possible) | ปรับไปหลาย resolution อัตโนมัติ |
| **Aspect Ratio** | รองรับตั้งแต่ 4:3 (iPad) ถึง 20:9 (modern phones) | ใช้ `Content Scale Mode = expand` |
| **Performance** | Object Pooling ตั้งแต่ Phase 2 (enemy/projectile reuse แทน instance/free) | บนมือถือ GC = frame drop |
| **Touch** | เพิ่ม virtual joystick overlay (ไม่แทน keyboard — รองรับทั้ง 2) | เชื่อมต่อ Bluetooth keyboard ก็ใช้ได้ |
| **Save** | Godot `ConfigFile` หรือ `ResourceSaver` — local save ไม่ต้อง backend | mobile ต้อง save แม้ offline |
| **Orientation** | Landscape เท่านั้น (Bullet Heaven เล่นแนวตั้งไม่ได้) | lock ใน export template |
| **Build Size** | หลีกเลี่ยง assets ใหญ่ ใช้ procedural graphics (draw_circle, particles) | ไฟล์เล็ก ≈ โหลดเร็ว |
| **Export** | Android: Godot export template + AAB, iOS: export template + Xcode | ต้องเตรียม build ตั้งแต่ก่อนส่ง |

### สิ่งที่เปลี่ยนถ้าทำ Mobile

#### Virtual Joystick (จะเพิ่มใน Phase 2-3)
- แทนที่ MovementComponent.PLAYER ให้ฟังทั้ง keyboard และ virtual stick
- Touch input: `Input.is_key_pressed()` → เปลี่ยนเป็น `Input.get_axis("move_left", "move_right")` จริงๆ
- สร้าง `VirtualJoystick.gd` — เป็น Control overlay ที่จำลอง Input actions

#### UI Anchor (ค่อยๆ ปรับ)
- HUD components ควรใช้ `anchors` แทน hardcoded position
- ยกตัวอย่าง: hp_label.top = 10, hp_label.left = 10
- EvolutionScreen ใช้ center anchor

#### Performance Checklist
- [x] ใช้ ObjectPool สำหรับ Bullet, Enemy, GeneticOrb (Phase 2) — PoolManager autoload 30/10/20 prewarm + cap 60/20/40
- [ ] จำกัด max particles (Phase 3)
- [ ] `RenderingServer` แทน `_draw()` สำหรับ entities จำนวนมาก (ถ้าจำเป็น)
- [ ] Profiler check ทุก Phase

### ข้อดีของ Godot สำหรับ Mobile
- Export to Android/iOS ได้ทันที (ต้องติดตั้ง export templates)
- Vulkan renderer → ปรับเป็น OpenGL ES 3.0 สำหรับ mobile
- Mono/C# → ระวัง: ขนาด build จะใหญ่กว่า GDScript
- ใช้ GDScript ล้วน (current) = build เล็ก, debug ง่าย, port ไว

### ขนาด Build ที่คาดการณ์
| Platform | GDScript (current) | Mono/C# |
|---|---|---|
| Windows | ~40-60 MB | ~80-120 MB |
| Android (APK/AAB) | ~30-50 MB | ~70-100 MB |
| iOS | ~40-60 MB | ~80-120 MB |

### Timeline
```
Phase 1-3: Dev on PC/Mac (ด้วย mobile-first design)
Phase 4:   เพิ่ม touch controls + ปรับ UI scaling
Phase 5:   Export test → Android (beta) → iOS
           Submit to App Store + Play Store
```

---

## Conventions
- 4 spaces indentation
- snake_case for variables/functions
- PascalCase for class_name
- autoload scripts ห้ามมี class_name
- ไฟล์ script: PascalCase.gd
- class_name ทุก script ที่ต้อง instanced โดยตรง
