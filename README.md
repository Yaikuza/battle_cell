# Galaxy Arcade Hub — File Structure

```
galaxy-hub/
├── index.html          ← HTML shell only — แก้ layout/card/overlay structure
├── style.css           ← ทุก CSS — แก้ visual/theme/responsive
├── shared.js           ← starfield, banner animations, leaderboard, navigation
├── battle-cell.js      ← เกม 1: mechanics, mutations, enemy types
├── dino-memo.js        ← เกม 2: card matching logic, settings
├── whack-mole.js       ← เกม 3: whack stages, hole grid
└── virtual-joystick.js ← joystick wiring (แยกออกมาเพราะ touch-only)
```

---

## 🔧 อัพเดทยังไงไม่เปลืองโทเค่น

### เพิ่ม enemy type ใหม่ใน Battle Cell
paste เฉพาะ `ENEMY_TYPES` array ใน **battle-cell.js** แล้วบอกว่าจะเพิ่มตัวไหน

### เพิ่ม mutation ใหม่
paste เฉพาะ `MUTATIONS` array ใน **battle-cell.js**

### เพิ่มด่านใน Whack-a-Mole
paste เฉพาะ `STAGES` array ใน **whack-mole.js**

### เพิ่มไพ่ใน Dino Memory
แก้ `DINO_EMOJIS` array ใน **dino-memo.js**

### เปลี่ยนสี/font/layout
paste เฉพาะ **style.css**

### เพิ่มเกมใหม่
1. สร้าง `new-game.js` ตาม pattern เดิม (import registerGame, call registerGame('id', onOpen, onClose))
2. เพิ่ม card + overlay ใน **index.html**
3. import ใน `<script type="module">` ใน **index.html**

---

## ⚠️ Run locally
ต้องรันผ่าน local server เพราะใช้ ES modules:
```bash
# Python
python3 -m http.server 8080

# Node (npx)
npx serve .
```
แล้วเปิด http://localhost:8080
