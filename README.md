# Galaxy Arcade Hub

Hub รวมเกมแนว Survivors/Toy ธีมหลากหลาย — ไทย ไซไฟ และแมทช์เกม

## โครงสร้างไฟล์

```
galaxy-hub/
├── index.html            ← Hub หลัก — การ์ดเกม, overlay, leaderboard
├── style.css             ← CSS ทั้งหมด
├── shared.js             ← starfield, banner animation, leaderboard, navigation
├── battle-cell.js        ← เกม Battle Cell (inline overlay ใน index)
├── dino-memo.js          ← เกม Dino Memory (inline overlay)
├── whack-mole.js         ← เกม Whack-a-Mole (inline overlay)
├── virtual-joystick.js   ← Joystick สำหรับ touch

├── bce.html              ← เกม Battle Cell Evolution (หน้าแยก)
├── ptbn.html             ← เกม พิทักษ์บ้านนา (หน้าแยก)
├── GDD.md                ← Game Design Document พิทักษ์บ้านนา
└── README.md
```

## เกมที่มี

| เกม | ไฟล์ | ประเภท | ธีม |
|-----|------|--------|-----|
| **Battle Cell Evolution** | `battle-cell.js` (inline) | Top-down Survivors | ไซไฟ มิวแทนท์ |
| **Battle Cell Neo** | `bce.html` | Top-down Survivors | ไซไฟ Cyber |
| **พิทักษ์บ้านนา** | `ptbn.html` | Top-down Survivors | ไทย ภูตผี |
| **Dino Memory** | `dino-memo.js` (inline) | จับคู่ไพ่ | ไดโนเสาร์ |
| **Whack-a-Mole** | `whack-mole.js` (inline) | ตีตุ่น | สัตว์ |

## 🌟 ระบบ Leaderboard (Supabase)

- ใช้ Supabase cloud database (`leaderboard` table)
- แยกเกมด้วย column `game` (`'bce'`, `'ptbn'`)
- รองรับ fallback เป็น localStorage เมื่อ offline
- แสดง Top 10 ในแต่ละเกม

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
1. สร้าง `new-game.js` ตาม pattern เดิม
2. เพิ่ม card + overlay ใน **index.html**
3. import ใน `<script type="module">` ใน **index.html**

## ⚠️ Run locally
ต้องรันผ่าน local server เพราะใช้ ES modules:
```bash
# Python
python3 -m http.server 8080

# Node (npx)
npx serve .
```
แล้วเปิด http://localhost:8080
