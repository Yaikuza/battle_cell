/* battle-cell.js — Battle Cell Evolution v3
   Depends on: shared.js (registerGame)
   Edit ONLY this file to change game mechanics, mutations, enemy types.
*/

import { registerGame } from './shared.js';

/* ==================== CONSTANTS — edit freely ==================== */

export const MUTATIONS = [
  { id:'tail',   icon:'🪱', name:'TAIL MUTANT',   desc:'ความเร็ว +22%',                    apply: P => { P.speed *= 1.22; P.tailLv++; } },
  { id:'eye',    icon:'👁️', name:'HYPER EYE',     desc:'กระสุน +1 ลูก ทุก level',          apply: P => { P.eyeLv++; } },
  { id:'spike',  icon:'🌵', name:'SPIKE SHELL',   desc:'หนาม +1 ดอก รอบตัว',              apply: P => { P.spikes += 1; } },
  { id:'wings',  icon:'🪽', name:'ENERGY WINGS',  desc:'คลื่นระเบิดรอบตัวทุก 4 วิ',       apply: P => { P.wings++; } },
  { id:'armor',  icon:'🛡️', name:'NANO SHIELD',   desc:'HP +30% ฟื้นทันที',               apply: P => { P.maxHp = Math.floor(P.maxHp * 1.3); P.hp = P.maxHp; } },
  { id:'atk',    icon:'💥', name:'COSMIC ATK',    desc:'ดาเมจ +35%',                       apply: P => { P.atkMult += 0.35; } },
  { id:'regen',  icon:'🧬', name:'REGEN NUCLEUS', desc:'ฟื้น HP ทุก 3 วิ',                 apply: P => { P.regenLv++; } },
  { id:'magnet', icon:'🧲', name:'GRAVITY PULL',  desc:'รัศมีดูด EXP +70%',               apply: P => { P.magnetR *= 1.7; } },
  { id:'crit',   icon:'⚡', name:'CRITICAL',      desc:'crit 25% → x2.5 ดาเมจ',           apply: P => { P.critChance += 0.25; } },
  { id:'vamp',   icon:'🩸', name:'VAMPIRIC',      desc:'ดูดเลือด 10% ต่อดาเมจ',           apply: P => { P.lifeSteal += 0.1; } },
  { id:'pierce', icon:'🔱', name:'PIERCE SHOT',   desc:'กระสุนทะลุศัตรู +1 ตัว',          apply: P => { P.piercing++; } },
  { id:'bomb',   icon:'💣', name:'CLUSTER BOMB',  desc:'ระเบิดลูกเล็ก 6 ลูก เมื่อ kill',  apply: P => { P.bomb++; } },
];

export const ENEMY_TYPES = [
  { type:'basic',    r:12, hpBase:2,   speed:0.70, color:'#ff6644', expVal:6,  score:20,  emoji:'●' },
  { type:'speeder',  r:9,  hpBase:1.5, speed:1.30, color:'#ff44aa', expVal:8,  score:25,  emoji:'◆' },
  { type:'tank',     r:22, hpBase:5,   speed:0.45, color:'#ff3333', expVal:18, score:55,  emoji:'■' },
  { type:'zigzag',   r:10, hpBase:1.8, speed:0.90, color:'#ffaa00', expVal:10, score:30,  emoji:'★' },
  { type:'splitter', r:16, hpBase:3.5, speed:0.55, color:'#aa44ff', expVal:14, score:45,  emoji:'✦' },
  // ────────────────── ADD NEW ENEMY TYPES HERE ──────────────────
  // boss is spawned separately by spawnBoss() — not in the random pool
];

/* ── BOSS CONFIG — แก้ได้อิสระ ── */
const BOSS_CFG = {
  r: 36, hpBase: 180, speed: 0.55, color: '#ff0055',
  expVal: 120, score: 500, emoji: '👾',
  spawnEvery: 180,   // วินาที (3 นาที)
};

/* ==================== STATE ==================== */
const bcCv  = document.getElementById('bc-canvas');
const bcCtx = bcCv.getContext('2d');
let bcW = 800, bcH = 500;
let bcRunning = false, bcRAF = null, bcTimerInt = null;
let bcScore = 0, bcTime = 0;

let P = {};   // player object — reset each game
let bullets = [], enemies = [], expOrbs = [], particles = [], shockwaves = [], dmgNumbers = [];
let spikeAngle = 0, wingsTimer = 0, spawnTimer = 0, shootTimer = 0;
let nextBossAt = 180;   // วินาทีแรกที่บอสจะโผล่ (= BOSS_CFG.spawnEvery)
let bossWarning = 0;    // countdown frames สำหรับ flash warning บนจอ

/* ==================== INPUT ==================== */
const keys = { ArrowUp:false, ArrowDown:false, ArrowLeft:false, ArrowRight:false, w:false, a:false, s:false, d:false };
let mouseTarget  = { x:0, y:0, active:false };
let vjInput      = { x:0, y:0, active:false };
let gamepadInput = { x:0, y:0, active:false };
let ctrlMode     = 'none';
let vjTouchId    = null;
let vjOrigin     = { x:0, y:0 };

/* keyboard */
document.addEventListener('keydown', e => { if (e.key in keys) { keys[e.key] = true; ctrlMode = 'keyboard'; } });
document.addEventListener('keyup',   e => { if (e.key in keys) keys[e.key] = false; });

/* mouse */
bcCv.addEventListener('mousemove', e => {
  if (!bcRunning) return;
  const r = bcCv.getBoundingClientRect(), sx = bcW / r.width, sy = bcH / r.height;
  mouseTarget = { x: (e.clientX - r.left) * sx, y: (e.clientY - r.top) * sy, active: true };
  ctrlMode = 'mouse';
});
bcCv.addEventListener('touchmove', e => {
  if (!bcRunning) return;
  e.preventDefault();
  const r = bcCv.getBoundingClientRect(), sx = bcW / r.width, sy = bcH / r.height;
  for (const t of e.changedTouches) {
    if (t.identifier === vjTouchId) continue; // นิ้วนี้เป็น joystick แล้ว
    mouseTarget = { x: (t.clientX - r.left) * sx, y: (t.clientY - r.top) * sy, active: true };
    ctrlMode = 'touch';
    break;
  }
}, { passive: false });

/* gamepad */
function pollGamepad() {
  const gps = navigator.getGamepads?.();
  if (!gps) return;
  for (const gp of gps) {
    if (!gp) continue;
    const lx = gp.axes[0] || 0, ly = gp.axes[1] || 0, dead = 0.12;
    gamepadInput = (Math.abs(lx) > dead || Math.abs(ly) > dead)
      ? { x: lx, y: ly, active: true }
      : { x: 0, y: 0, active: false };
    if (gamepadInput.active) ctrlMode = 'gamepad';
    break;
  }
}
window.addEventListener('gamepadconnected',    e => { document.getElementById('ctrl-indicator').textContent = '🎮 ' + e.gamepad.id.substring(0, 20); });
window.addEventListener('gamepaddisconnected', ()  => { document.getElementById('ctrl-indicator').textContent = ''; });

bcCv.addEventListener('touchstart', e => {
  if (!bcRunning) return;
  e.preventDefault();
  const r = bcCv.getBoundingClientRect(), sx = bcW / r.width, sy = bcH / r.height;
  for (const t of e.changedTouches) {
    if (vjTouchId !== null) break; // มีนิ้ว joystick แล้ว
    const cy = (t.clientY - r.top) * sy;
    if (cy >= bcH / 2) { // แตะครึ่งล่างเท่านั้น
      vjTouchId = t.identifier;
      vjOrigin  = { x: (t.clientX - r.left) * sx, y: cy };
      vjInput   = { x:0, y:0, active:true };
      ctrlMode  = 'joystick';
    }
  }
}, { passive: false });

bcCv.addEventListener('touchmove', e => {
  if (!bcRunning) return;
  e.preventDefault();
  const r = bcCv.getBoundingClientRect(), sx = bcW / r.width, sy = bcH / r.height;
  for (const t of e.changedTouches) {
    if (t.identifier === vjTouchId) {
      const dx = ((t.clientX - r.left) * sx) - vjOrigin.x;
      const dy = ((t.clientY - r.top)  * sy) - vjOrigin.y;
      const len = Math.hypot(dx, dy);
      const dead = 8;
      vjInput = len > dead
        ? { x: dx / len, y: dy / len, active: true }
        : { x: 0, y: 0, active: true };
      ctrlMode = 'joystick';
      return;
    }
  }
}, { passive: false });

bcCv.addEventListener('touchend', e => {
  e.preventDefault();
  for (const t of e.changedTouches) {
    if (t.identifier === vjTouchId) {
      vjTouchId = null;
      vjInput   = { x:0, y:0, active:false };
    }
  }
}, { passive: false });

bcCv.addEventListener('touchcancel', e => {
  for (const t of e.changedTouches) {
    if (t.identifier === vjTouchId) {
      vjTouchId = null;
      vjInput   = { x:0, y:0, active:false };
    }
  }
}, { passive: false });

/* ==================== HELPERS ==================== */
function resetPlayer() {
  P = { x:bcW/2, y:bcH/2, r:18, hp:100, maxHp:100, speed:2.4, exp:0, expNext:40, lv:1,
        atkMult:1, critChance:0, lifeSteal:0, regenLv:0, regenTimer:0,
        magnetR:90, spikes:0, wings:0, eyeLv:0, tailLv:0, piercing:0, bomb:0 };
}

function resizeBC() {
  const outer = document.getElementById('bc-outer');
  bcW = bcCv.width  = outer.clientWidth  || 800;
  bcH = bcCv.height = outer.clientHeight || 500;
}

function showScreen(id) {
  ['bc-start','evo-screen','dead-screen'].forEach(s => document.getElementById(s).classList.remove('show'));
  document.getElementById(id).classList.add('show');
}
function hideScreens() {
  ['bc-start','evo-screen','dead-screen'].forEach(s => document.getElementById(s).classList.remove('show'));
}

/* ==================== SPAWN ==================== */

/* ── scaling curve ──────────────────────────────────────────────
   hpMult  : เลือดศัตรู เพิ่มทุก 30 วิ  (+15% ต่อ tier)
   spdMult : ความเร็ว   เพิ่มทุก 20 วิ  (+8%  ต่อ tier)   cap ที่ x2.5
   countMod: โอกาสเกิด 2 ตัวพร้อมกัน เพิ่มตาม bcTime
──────────────────────────────────────────────────────────────── */
function scalingAt(t) {
  const hpMult  = 1 + Math.floor(t / 30) * 0.15;
  const spdMult = Math.min(2.5, 1 + Math.floor(t / 20) * 0.08);
  return { hpMult, spdMult };
}

function spawnEnemy() {
  const side = Math.floor(Math.random() * 4);
  let x, y;
  if (side === 0) { x = Math.random() * bcW; y = -25; }
  else if (side === 1) { x = bcW + 25; y = Math.random() * bcH; }
  else if (side === 2) { x = Math.random() * bcW; y = bcH + 25; }
  else { x = -25; y = Math.random() * bcH; }

  const { hpMult, spdMult } = scalingAt(bcTime);
  const r = Math.random();
  let tIdx = 0;
  if      (bcTime < 20) tIdx = 0;
  else if (r < 0.33)    tIdx = 0;
  else if (r < 0.52)    tIdx = 1;
  else if (r < 0.67)    tIdx = 2;
  else if (r < 0.83)    tIdx = 3;
  else                  tIdx = 4;
  tIdx = Math.min(tIdx, ENEMY_TYPES.length - 1);

  const T  = ENEMY_TYPES[tIdx];
  const hp = Math.ceil(T.hpBase * hpMult);
  enemies.push({ x, y, r: T.r, hp, maxHp: hp,
    speed: T.speed * spdMult,
    type: T.type, color: T.color, expVal: T.expVal, score: T.score, emoji: T.emoji,
    zigDir: 0, zigTimer: 0, angle: Math.atan2(P.y - y, P.x - x) });
}

/* จำนวนศัตรูที่ spawn ต่อรอบ — เพิ่มตามเวลา */
function spawnCount() {
  if (bcTime < 30)  return 1;
  if (bcTime < 90)  return Math.random() < 0.4 ? 2 : 1;
  if (bcTime < 180) return Math.random() < 0.6 ? 2 : 1;
  return Math.random() < 0.5 ? 3 : 2;
}

function spawnBoss() {
  const side = Math.floor(Math.random() * 4);
  let x, y;
  if (side === 0) { x = Math.random() * bcW; y = -50; }
  else if (side === 1) { x = bcW + 50; y = Math.random() * bcH; }
  else if (side === 2) { x = Math.random() * bcW; y = bcH + 50; }
  else { x = -50; y = Math.random() * bcH; }

  const wave = Math.floor(bcTime / BOSS_CFG.spawnEvery); // บอสรอบที่ n ยาก ขึ้น
  const hp   = Math.ceil(BOSS_CFG.hpBase * (1 + wave * 0.6));
  enemies.push({ x, y, r: BOSS_CFG.r, hp, maxHp: hp,
    speed: BOSS_CFG.speed * (1 + wave * 0.1),
    type: 'boss', color: BOSS_CFG.color,
    expVal: BOSS_CFG.expVal * (1 + wave), score: BOSS_CFG.score * (1 + wave),
    emoji: BOSS_CFG.emoji,
    zigDir: 0, zigTimer: 0, angle: Math.atan2(P.y - y, P.x - x) });
  bossWarning = 120; // 2 วิ flash
}

/* ==================== SHOOT ==================== */
function autoShoot() {
  if (!enemies.length) return;
  const count = 1 + P.eyeLv;
  const sorted = [...enemies].sort((a, b) => Math.hypot(a.x - P.x, a.y - P.y) - Math.hypot(b.x - P.x, b.y - P.y));
  for (let i = 0; i < Math.min(count, sorted.length); i++) {
    const e   = sorted[i];
    const ang = Math.atan2(e.y - P.y, e.x - P.x);
    const crit = Math.random() < P.critChance;
    const dmg  = Math.max(1, (crit ? 2.5 : 1) * Math.round(7 * P.atkMult));
    bullets.push({ x: P.x, y: P.y, vx: Math.cos(ang) * 7.5, vy: Math.sin(ang) * 7.5,
      r: 5 + i, dmg, crit, pierce: P.piercing, life: 90, hitEnemies: new Set() });
  }
}

/* ==================== EFFECTS ==================== */
function spawnParticles(x, y, color, n) {
  for (let i = 0; i < n; i++)
    particles.push({ x, y, vx: (Math.random() - .5) * 5, vy: (Math.random() - .5) * 5,
      r: Math.random() * 3 + 1, life: 30, maxLife: 30, color });
}
function addDmgNum(x, y, val, crit) {
  dmgNumbers.push({ x, y, val, crit, life: 45, maxLife: 45, vy: -1.5 });
}
function doShockwave() {
  shockwaves.push({ x: P.x, y: P.y, r: 0, maxR: 140, life: 22, dmg: Math.round(18 * P.atkMult) });
}
function spawnBombs(x, y) {
  for (let i = 0; i < 6; i++) {
    const a = i * (Math.PI / 3);
    bullets.push({ x, y, vx: Math.cos(a) * 5, vy: Math.sin(a) * 5, r: 4,
      dmg: Math.round(5 * P.atkMult), crit: false, pierce: 0, life: 40,
      hitEnemies: new Set(), isBomb: true });
  }
}

/* ==================== LEVEL UP ==================== */
function doLevelUp() {
  P.lv++; P.exp -= P.expNext; P.expNext = Math.floor(P.expNext * (P.lv <= 5 ? 1.6 : 1.2));
  bcRunning = false;
  const pool  = [...MUTATIONS];
  const picks = [];
  while (picks.length < 3 && pool.length) picks.push(pool.splice(Math.floor(Math.random() * pool.length), 1)[0]);
  const c = document.getElementById('evo-cards'); c.innerHTML = '';
  picks.forEach(m => {
    const d = document.createElement('div'); d.className = 'evo-card';
    d.innerHTML = `<div class="ec-icon">${m.icon}</div><h3>${m.name}</h3><p>${m.desc}</p>`;
    d.onclick = () => { m.apply(P); hideScreens(); bcRunning = true; bcLoop(); };
    c.appendChild(d);
  });
  showScreen('evo-screen');
}

/* ==================== HUD ==================== */
function updateHUD() {
  document.getElementById('hud-hp-txt').textContent = `${Math.max(0, Math.round(P.hp))}/${P.maxHp}`;
  const hpPct = Math.max(0, P.hp / P.maxHp * 100);
  const hpEl  = document.getElementById('hud-hp');
  hpEl.style.width = hpPct + '%';
  hpEl.style.background = P.hp < P.maxHp * .3
    ? 'linear-gradient(90deg,#ff4466,#ff2244)'
    : 'linear-gradient(90deg,#00ffb4,#00cc88)';
  document.getElementById('hud-lv').textContent    = `LV.${P.lv}`;
  document.getElementById('hud-exp').style.width   = (P.exp / P.expNext * 100) + '%';
  document.getElementById('hud-score').textContent = bcScore.toLocaleString();
  document.getElementById('hud-time').textContent  = bcTime + 's';
  const labels = { none:'', mouse:'🖱️', touch:'👆', keyboard:'⌨️', joystick:'🕹️', gamepad:'🎮' };
  document.getElementById('ctrl-indicator').textContent = labels[ctrlMode] || '';
}

/* ==================== MAIN LOOP ==================== */
function bcLoop() {
  if (!bcRunning) return;
  bcRAF = requestAnimationFrame(bcLoop);
  pollGamepad();

  const ctx = bcCtx;
  ctx.fillStyle = '#0d101a'; ctx.fillRect(0, 0, bcW, bcH);

  /* grid */
  ctx.strokeStyle = 'rgba(0,180,255,0.04)'; ctx.lineWidth = 1;
  for (let x = 0; x < bcW; x += 50) { ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,bcH); ctx.stroke(); }
  for (let y = 0; y < bcH; y += 50) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(bcW,y); ctx.stroke(); }

  /* move player */
  let dx = 0, dy = 0;
  if      (vjInput.active)     { dx = vjInput.x;     dy = vjInput.y; }
  else if (gamepadInput.active) { dx = gamepadInput.x; dy = gamepadInput.y; }
  else {
    if (keys.w || keys.ArrowUp)    dy -= 1;
    if (keys.s || keys.ArrowDown)  dy += 1;
    if (keys.a || keys.ArrowLeft)  dx -= 1;
    if (keys.d || keys.ArrowRight) dx += 1;
  }
  const dlen = Math.hypot(dx, dy);
  if (dlen > 0) { P.x += dx / dlen * P.speed; P.y += dy / dlen * P.speed; }
  else if (mouseTarget.active && ctrlMode === 'mouse') {
    const mdx = mouseTarget.x - P.x, mdy = mouseTarget.y - P.y, md = Math.hypot(mdx, mdy);
    if (md > 4) { P.x += mdx / md * P.speed; P.y += mdy / md * P.speed; }
  }
  P.x = Math.max(P.r, Math.min(bcW - P.r, P.x));
  P.y = Math.max(P.r, Math.min(bcH - P.r, P.y));

  /* spawn normal enemies */
  spawnTimer++;
  if (spawnTimer >= Math.max(15, 70 - Math.floor(bcTime / 5))) {
    spawnTimer = 0;
    const n = spawnCount();
    for (let i = 0; i < n; i++) spawnEnemy();
  }

  /* boss — every BOSS_CFG.spawnEvery seconds */
  if (bcTime >= nextBossAt) {
    nextBossAt += BOSS_CFG.spawnEvery;
    spawnBoss();
  }
  /* boss warning: flash 10 วิ ก่อนบอสมา */
  const warnStart = nextBossAt - 10;
  if (bcTime >= warnStart && bcTime < nextBossAt && Math.floor(Date.now() / 300) % 2 === 0) {
    ctx.fillStyle = 'rgba(255,0,85,0.07)'; ctx.fillRect(0, 0, bcW, bcH);
    ctx.fillStyle = 'rgba(255,0,85,0.8)';
    ctx.font = 'bold 18px Orbitron'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText('⚠ BOSS INCOMING ⚠', bcW / 2, 36);
  }

  /* shoot */
  shootTimer++;
  if (shootTimer >= Math.max(10, 60 - P.eyeLv * 2)) { shootTimer = 0; autoShoot(); }

  /* spikes */
  if (P.spikes > 0) {
    spikeAngle += 0.05;
    for (let i = 0; i < P.spikes; i++) {
      const a = spikeAngle + i * (Math.PI * 2 / P.spikes);
      const sx = P.x + Math.cos(a) * (P.r + 14), sy = P.y + Math.sin(a) * (P.r + 14);
      for (const e of enemies) {
        if (Math.hypot(e.x - sx, e.y - sy) < 13) { e.hp -= 0.6; spawnParticles(e.x, e.y, '#00ffb4', 1); }
      }
    }
  }

  /* wings */
  if (P.wings > 0) { wingsTimer++; if (wingsTimer >= 240) { wingsTimer = 0; doShockwave(); } }

  /* regen */
  if (P.regenLv > 0) { P.regenTimer++; if (P.regenTimer >= 180) { P.regenTimer = 0; P.hp = Math.min(P.maxHp, P.hp + P.regenLv); } }

  /* shockwaves */
  for (let i = shockwaves.length - 1; i >= 0; i--) {
    const sw = shockwaves[i]; sw.r += sw.maxR / sw.life; sw.life--;
    ctx.beginPath(); ctx.arc(sw.x, sw.y, sw.r, 0, Math.PI * 2);
    ctx.strokeStyle = `rgba(119,102,255,${sw.life / 22})`; ctx.lineWidth = 4; ctx.stroke();
    for (const e of enemies) if (Math.hypot(e.x - sw.x, e.y - sw.y) < sw.r + e.r) e.hp -= sw.dmg * .1;
    if (sw.life <= 0) shockwaves.splice(i, 1);
  }

  /* bullets */
  for (let i = bullets.length - 1; i >= 0; i--) {
    const b = bullets[i]; b.x += b.vx; b.y += b.vy; b.life--;
    let killed = false;
    for (let j = enemies.length - 1; j >= 0; j--) {
      const e = enemies[j];
      if (b.hitEnemies.has(j)) continue;
      if (Math.hypot(b.x - e.x, b.y - e.y) < b.r + e.r) {
        b.hitEnemies.add(j); e.hp -= b.dmg;
        if (P.lifeSteal > 0) P.hp = Math.min(P.maxHp, P.hp + b.dmg * P.lifeSteal);
        spawnParticles(e.x, e.y, b.crit ? '#ffd700' : '#ff6644', b.crit ? 10 : 4);
        addDmgNum(e.x, e.y - e.r, b.dmg, b.crit);
        bcScore += b.dmg;
        if (e.hp <= 0) {
          expOrbs.push({ x: e.x, y: e.y, r: 5, val: e.expVal });
          bcScore += e.score;
          if (P.bomb > 0) spawnBombs(e.x, e.y);
          enemies.splice(j, 1);
        }
        if (b.pierce <= 0 || b.hitEnemies.size > b.pierce) { killed = true; break; }
      }
    }
    if (killed || b.life <= 0 || b.x < -20 || b.x > bcW + 20 || b.y < -20 || b.y > bcH + 20)
      bullets.splice(i, 1);
  }

  /* exp orbs */
  for (let i = expOrbs.length - 1; i >= 0; i--) {
    const o = expOrbs[i]; const d = Math.hypot(P.x - o.x, P.y - o.y);
    if (d < P.magnetR) { const sp = 5 * (P.magnetR / 90); o.x += (P.x - o.x) / d * sp; o.y += (P.y - o.y) / d * sp; }
    if (d < P.r + o.r) {
      P.exp += o.val; expOrbs.splice(i, 1);
      if (P.exp >= P.expNext) { doLevelUp(); return; }
    }
  }

  /* enemies move & damage player */
  for (const e of enemies) {
    if (e.type === 'zigzag') {
      e.zigTimer++;
      if (e.zigTimer > 20) { e.zigTimer = 0; e.zigDir = (e.zigDir + 1) % 2; }
      e.angle = Math.atan2(P.y - e.y, P.x - e.x) + (e.zigDir ? 0.6 : -0.6);
    } else { e.angle = Math.atan2(P.y - e.y, P.x - e.x); }
    e.x += Math.cos(e.angle) * e.speed; e.y += Math.sin(e.angle) * e.speed;
    if (Math.hypot(e.x - P.x, e.y - P.y) < e.r + P.r) {
      P.hp -= e.type === 'boss' ? 3 : e.type === 'tank' ? 1.5 : e.type === 'speeder' ? 0.9 : 1;
      if (P.hp <= 0) { gameOver(); return; }
    }
  }

  /* particles */
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i]; p.x += p.vx; p.y += p.vy; p.vx *= .88; p.vy *= .88; p.life--;
    ctx.beginPath(); ctx.arc(p.x, p.y, p.r * (p.life / p.maxLife), 0, Math.PI * 2);
    ctx.fillStyle = p.color + Math.round(p.life / p.maxLife * 200).toString(16).padStart(2,'0'); ctx.fill();
    if (p.life <= 0) particles.splice(i, 1);
  }

  /* draw exp orbs */
  for (const o of expOrbs) {
    ctx.beginPath(); ctx.arc(o.x, o.y, o.r, 0, Math.PI * 2); ctx.fillStyle = '#7766ff'; ctx.fill();
  }

  /* draw enemies */
  for (const e of enemies) {
    if (e.type === 'boss') {
      // pulsing outer glow
      const pulse = 0.4 + 0.3 * Math.sin(Date.now() * 0.006);
      ctx.beginPath(); ctx.arc(e.x, e.y, e.r + 10, 0, Math.PI * 2);
      ctx.strokeStyle = `rgba(255,0,85,${pulse})`; ctx.lineWidth = 4; ctx.stroke();
    }
    ctx.beginPath(); ctx.arc(e.x, e.y, e.r, 0, Math.PI * 2); ctx.fillStyle = e.color + '22'; ctx.fill();
    ctx.beginPath(); ctx.arc(e.x, e.y, e.r, 0, Math.PI * 2);
    ctx.strokeStyle = e.color; ctx.lineWidth = e.type === 'boss' ? 4 : e.type === 'tank' ? 3 : 2; ctx.stroke();
    const hp = e.hp / e.maxHp;
    const barW = e.type === 'boss' ? e.r * 3 : e.r * 2;
    ctx.fillStyle = '#0d1525'; ctx.fillRect(e.x - barW / 2, e.y - e.r - 10, barW, e.type === 'boss' ? 6 : 4);
    ctx.fillStyle = hp > 0.5 ? '#00ffb4' : hp > 0.25 ? '#ffaa00' : '#ff4466';
    ctx.fillRect(e.x - barW / 2, e.y - e.r - 10, barW * hp, e.type === 'boss' ? 6 : 4);
    ctx.fillStyle = '#fff'; ctx.font = `${e.r}px sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(e.emoji, e.x, e.y);
  }

  /* draw spikes */
  if (P.spikes > 0) {
    for (let i = 0; i < P.spikes; i++) {
      const a = spikeAngle + i * (Math.PI * 2 / P.spikes);
      ctx.beginPath(); ctx.arc(P.x + Math.cos(a) * (P.r + 14), P.y + Math.sin(a) * (P.r + 14), 6, 0, Math.PI * 2);
      ctx.fillStyle = '#ff2222'; ctx.fill();
    }
  }

  /* magnet ring */
  ctx.beginPath(); ctx.arc(P.x, P.y, P.magnetR, 0, Math.PI * 2);
  ctx.strokeStyle = 'rgba(119,102,255,0.07)'; ctx.lineWidth = 1; ctx.stroke();

  /* player */
  ctx.beginPath(); ctx.arc(P.x, P.y, P.r + 5, 0, Math.PI * 2); ctx.fillStyle = 'rgba(0,255,180,0.06)'; ctx.fill();
  ctx.beginPath(); ctx.arc(P.x, P.y, P.r, 0, Math.PI * 2); ctx.fillStyle = '#0d2030'; ctx.fill();
  ctx.strokeStyle = '#00ffb4'; ctx.lineWidth = 2.5; ctx.stroke();
  ctx.beginPath(); ctx.arc(P.x, P.y, P.r * .45, 0, Math.PI * 2); ctx.fillStyle = 'rgba(0,255,180,0.65)'; ctx.fill();

  /* bullets */
  for (const b of bullets) {
    ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
    ctx.fillStyle = b.isBomb ? '#ffaa00' : b.crit ? '#ffd700' : '#00ffb4'; ctx.fill();
  }

  /* damage numbers */
  for (let i = dmgNumbers.length - 1; i >= 0; i--) {
    const dn = dmgNumbers[i]; dn.y += dn.vy; dn.life--;
    const a = dn.life / dn.maxLife;
    ctx.fillStyle = dn.crit ? `rgba(255,215,0,${a})` : `rgba(255,200,100,${a})`;
    ctx.font = dn.crit ? `bold 14px Orbitron` : `12px Orbitron`;
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(dn.crit ? `★${dn.val}` : dn.val, dn.x, dn.y);
    if (dn.life <= 0) dmgNumbers.splice(i, 1);
  }

  updateHUD();
}

/* ==================== LIFECYCLE ==================== */
function gameOver() {
  bcRunning = false; clearInterval(bcTimerInt);
  document.getElementById('dead-score').textContent = bcScore.toLocaleString();
  document.getElementById('dead-info').textContent  = `LV.${P.lv} · ${bcTime}s`;
  showScreen('dead-screen');
}

function onOpen() {
  resizeBC(); resetPlayer();
  bullets = []; enemies = []; expOrbs = []; particles = []; shockwaves = []; dmgNumbers = [];
  bcScore = 0; bcTime = 0; spikeAngle = 0; wingsTimer = 0; spawnTimer = 0; shootTimer = 0;
  nextBossAt = BOSS_CFG.spawnEvery; bossWarning = 0;
  showScreen('bc-start'); updateHUD();
}

function onClose() {
  bcRunning = false; clearInterval(bcTimerInt); if (bcRAF) cancelAnimationFrame(bcRAF);
}

export function startBC() {
  resizeBC(); resetPlayer();
  bullets = []; enemies = []; expOrbs = []; particles = []; shockwaves = []; dmgNumbers = [];
  bcScore = 0; bcTime = 0; spikeAngle = 0; wingsTimer = 0; spawnTimer = 0; shootTimer = 0;
  nextBossAt = BOSS_CFG.spawnEvery; bossWarning = 0;
  hideScreens(); bcRunning = true;
  clearInterval(bcTimerInt);
  bcTimerInt = setInterval(() => { if (bcRunning) bcTime++; }, 1000);
  if (bcRAF) cancelAnimationFrame(bcRAF);
  bcLoop();
}

window.startBC = startBC;
window.addEventListener('resize', () => { if (bcRunning) resizeBC(); });

registerGame('bc', onOpen, onClose);