/* battle-cell.js — Battle Cell Evolution v5 (Delta-Time Rewrite)
   Depends on: shared.js (registerGame)

   DELTA TIME DESIGN:
   - ทุก timer/cooldown วัดเป็น seconds (float)
   - game loop รับ timestamp จาก rAF → dt = (now - prev) / 1000
   - dt capped ที่ 0.1s เพื่อป้องกัน spike เวลา tab ซ่อน
   - speed ทุกตัว = units/second (ไม่ใช่ units/frame อีกต่อไป)
   - fireInterval, abilityTimer ทุกตัวเป็น seconds
*/

import { registerGame } from './shared.js';

/* ==================== CONSTANTS (TIME IN SECONDS) ==================== */
const FIRE_BASE_INTERVAL = 1.0;   // วิ ระหว่างยิง (base, ลดได้ด้วย rapid)
const WINGS_INTERVAL     = 4.0;
const REGEN_INTERVAL     = 3.0;
const FREEZE_INTERVAL    = 8.0;
const NOVA_INTERVAL      = 6.0;
const REPULSE_INTERVAL   = 5.0;
const CORONA_INTERVAL    = 3.0;
const BARRIER_DURATION   = 2.0;
const BARRIER_COOLDOWN   = 6.0;  // วิ cooldown หลัง barrier หมด
const FREEZE_DURATION    = 3.0;   // ศัตรู frozen กี่วิ
const GROWTH_INTERVAL    = 30.0;  // growth tick ทุก 30 วิ
const SPAWN_BASE         = 1.2;   // วิ ระหว่าง spawn (ลดได้ตามเวลา)
const BOSS_SPAWN_EVERY   = 180.0; // วิ

/* ==================== MUTATIONS ==================== */
export const MUTATIONS = [
  { id:'eye',      tag:'weapon', icon:'👁️', name:'HYPER EYE',      desc:'กระสุน +1 ลูก ทุกครั้งที่เลือก',     apply: P => { P.eyeLv++; } },
  { id:'pierce',   tag:'weapon', icon:'🔱', name:'PIERCE SHOT',     desc:'กระสุนทะลุศัตรู +1 ตัว',             apply: P => { P.piercing++; } },
  { id:'bomb',     tag:'weapon', icon:'💣', name:'CLUSTER BOMB',    desc:'ระเบิดลูกเล็ก 6 ลูก เมื่อ kill',     apply: P => { P.bomb++; } },
  { id:'snipe',    tag:'weapon', icon:'🎯', name:'SNIPER CELL',     desc:'ยิงไกล +40% กระสุนเร็ว +20%',         apply: P => { P.bulletRange *= 1.4; P.bulletSpd *= 1.2; } },
  { id:'spread',   tag:'weapon', icon:'🌀', name:'SPREAD SHOT',     desc:'ยิงกระจาย 3 ทิศทุกครั้งที่ยิง',     apply: P => { P.spreadShot++; } },
  { id:'laser',    tag:'weapon', icon:'🔴', name:'LASER BEAM',      desc:'คานเลเซอร์ทะลุทุกตัวตลอดเส้น',      apply: P => { P.laserLv++; } },
  { id:'homing',   tag:'weapon', icon:'🧿', name:'HOMING MISSILE',  desc:'กระสุนล็อกเป้าไล่ศัตรู',             apply: P => { P.homingLv++; } },
  { id:'rapid',    tag:'weapon', icon:'⚡', name:'RAPID FIRE',      desc:'อัตราการยิงเพิ่ม +30%',               apply: P => { P.fireRateMult *= 0.70; } },
  { id:'chain',    tag:'weapon', icon:'⛓️', name:'CHAIN LIGHTNING', desc:'กระสุนแตก chain ศัตรูใกล้ +2 ตัว',  apply: P => { P.chainLv++; } },
  { id:'crit',     tag:'weapon', icon:'💢', name:'CRITICAL HIT',    desc:'crit 25% → x2.5 ดาเมจ',              apply: P => { P.critChance += 0.25; } },
  { id:'atk',      tag:'weapon', icon:'💥', name:'COSMIC ATK',      desc:'ดาเมจ +35%',                          apply: P => { P.atkMult += 0.35; } },
  { id:'vamp',     tag:'weapon', icon:'🩸', name:'VAMPIRIC',        desc:'ดูดเลือด 10% ต่อดาเมจ',               apply: P => { P.lifeSteal += 0.1; } },

  { id:'tail',     tag:'misc',   icon:'🪱', name:'TAIL MUTANT',     desc:'ความเร็ว +22%',                        apply: P => { P.speed *= 1.22; P.tailLv++; } },
  { id:'spike',    tag:'misc',   icon:'🌵', name:'SPIKE SHELL',     desc:'หนาม +1 ดอก รอบตัว (สามเหลี่ยม)',    apply: P => { P.spikes += 1; } },
  { id:'wings',    tag:'misc',   icon:'🪽', name:'ENERGY WINGS',    desc:'คลื่นระเบิดรอบตัวทุก 4 วิ',           apply: P => { P.wings++; } },
  { id:'armor',    tag:'misc',   icon:'🛡️', name:'NANO SHIELD',     desc:'HP +30% ฟื้นทันที',                   apply: P => { P.maxHp = Math.floor(P.maxHp * 1.3); P.hp = P.maxHp; } },
  { id:'regen',    tag:'misc',   icon:'🧬', name:'REGEN NUCLEUS',   desc:'ฟื้น HP ทุก 3 วิ',                    apply: P => { P.regenLv++; } },
  { id:'magnet',   tag:'misc',   icon:'🧲', name:'GRAVITY PULL',    desc:'รัศมีดูด EXP +70%',                   apply: P => { P.magnetR *= 1.7; } },
  { id:'barrier',  tag:'misc',   icon:'🔵', name:'PHASE BARRIER',   desc:'ภูมิคุ้มกัน 2 วิ หลังโดนโจมตี',     apply: P => { P.barrierLv++; } },
  { id:'thorns',   tag:'misc',   icon:'🌹', name:'THORN AURA',      desc:'หนามสะท้อนดาเมจ 30% กลับศัตรู',      apply: P => { P.thornPct += 0.30; } },
  { id:'dash',     tag:'misc',   icon:'💨', name:'CELL DASH',       desc:'dash หลีกเลี่ยงทุก 3 วิ อัตโนมัติ',  apply: P => { P.dashLv++; } },
  { id:'clone',    tag:'misc',   icon:'👥', name:'SHADOW CLONE',    desc:'clone หลอก ดึงศัตรู 1 ตัว/10 วิ',    apply: P => { P.cloneLv++; } },
  { id:'shield',   tag:'misc',   icon:'🌐', name:'ORBITAL SHIELD',  desc:'โล่โคจรรับดาเมจ 1 ดอก',              apply: P => { P.orbShields = Math.min(P.orbShields + 1, 4); } },
  { id:'freeze',   tag:'misc',   icon:'❄️', name:'CRYO BURST',      desc:'ชะลอศัตรูรอบตัว 50% ทุก 8 วิ',       apply: P => { P.freezeLv++; } },
  { id:'leech',    tag:'misc',   icon:'🕸️', name:'LEECH FIELD',     desc:'ดูด HP ศัตรูรอบตัวช้าๆ ต่อเนื่อง',   apply: P => { P.leechLv++; } },
  { id:'nova',     tag:'misc',   icon:'🌟', name:'NOVA PULSE',      desc:'ระเบิด nova รอบตัวทุก 6 วิ',          apply: P => { P.novaLv++; } },
  { id:'expboost', tag:'misc',   icon:'🔮', name:'EXP SURGE',       desc:'EXP จากศัตรู +50%',                   apply: P => { P.expMult += 0.5; } },
  { id:'size',     tag:'misc',   icon:'🔺', name:'CELL MASS',       desc:'ขนาด +15% ดาเมจสัมผัส +20%',         apply: P => { P.r = Math.min(P.r * 1.15, 60); P.contactDmg += 0.2; } },
  { id:'invis',    tag:'misc',   icon:'👻', name:'GHOST MEMBRANE',  desc:'ลดความเร็วศัตรูที่ไล่ตาม -20%',      apply: P => { P.ghostLv++; } },
  { id:'twin',     tag:'misc',   icon:'⚛️', name:'TWIN NUCLEUS',    desc:'กระสุนขนาด 2x เมื่อ crit ไม่ crit',  apply: P => { P.twinShot = true; } },
  { id:'repulse',  tag:'misc',   icon:'🌊', name:'REPULSE WAVE',    desc:'ผลักศัตรูออกทุก 5 วิ',                apply: P => { P.repulseLv++; } },
  { id:'overload', tag:'misc',   icon:'⚠️', name:'OVERLOAD',        desc:'ดาเมจ +60% แต่ HP max -20%',          apply: P => { P.atkMult += 0.6; P.maxHp = Math.max(20, Math.floor(P.maxHp * 0.8)); if(P.hp > P.maxHp) P.hp = P.maxHp; } },
  { id:'syphon',   tag:'misc',   icon:'🫀', name:'HP SYPHON',       desc:'HP สูงสุด +5 ทุกครั้งที่ kill ศัตรู', apply: P => { P.syphonLv++; } },
  { id:'memb',     tag:'misc',   icon:'🔶', name:'DENSE MEMBRANE',  desc:'รับดาเมจ -15%',                       apply: P => { P.dmgReduce += 0.15; } },
];

export const BOSS_UPGRADES = [
  { id:'b_colossus', icon:'💠', name:'COLOSSUS FORM',   desc:'ขนาดใหญ่ขึ้น 20% HP max +50%',
    apply: P => { P.r = Math.min(P.r * 1.2, 80); P.maxHp = Math.floor(P.maxHp * 1.5); P.hp = Math.min(P.hp + P.maxHp * 0.3, P.maxHp); } },
  { id:'b_void',     icon:'🌌', name:'VOID CANNON',      desc:'กระสุนดำ ดาเมจ x3 ทะลุทั้งหมด',
    apply: P => { P.voidCannon++; P.atkMult += 0.5; P.piercing += 3; } },
  { id:'b_corona',   icon:'☀️', name:'SOLAR CORONA',     desc:'ลำแสงแดดรอบตัว 360° ทุก 3 วิ',
    apply: P => { P.coronaLv++; } },
  { id:'b_absorb',   icon:'🫁', name:'MASS ABSORBER',    desc:'kill ศัตรูฟื้น HP 5% max',
    apply: P => { P.absorbLv++; } },
  { id:'b_entropy',  icon:'🌀', name:'ENTROPY FIELD',    desc:'ศัตรูรอบตัวสูญเสียความเร็ว -40% ถาวร',
    apply: P => { P.entropyLv++; } },
];

export const ENEMY_TYPES = [
  // dmg = HP/วิ ที่โดนสัมผัส (คูณ dt ใน loop)
  // ตั้งไว้ต่ำ เพราะศัตรูทับผู้เล่นต่อเนื่องหลายวิ
  { type:'basic',    r:12, hpBase:2,   speed:70,  color:'#ff6644', expVal:6,  score:20,  emoji:'●', dmg:6   },
  { type:'speeder',  r:9,  hpBase:1.5, speed:130, color:'#ff44aa', expVal:8,  score:25,  emoji:'◆', dmg:5   },
  { type:'tank',     r:22, hpBase:5,   speed:45,  color:'#ff3333', expVal:18, score:55,  emoji:'■', dmg:9   },
  { type:'zigzag',   r:10, hpBase:1.8, speed:90,  color:'#ffaa00', expVal:10, score:30,  emoji:'★', dmg:6   },
  { type:'splitter', r:16, hpBase:3.5, speed:55,  color:'#aa44ff', expVal:14, score:45,  emoji:'✦', dmg:7   },
];
// NOTE: speed ทุกตัวเป็น px/s แล้ว (เดิม px/frame ×60)

const BOSS_CFG = {
  r:36, hpBase:180, speed:55, color:'#ff0055',
  expVal:120, score:500, emoji:'👾', dmg:15,
};

/* ==================== STATE ==================== */
const bcCv  = document.getElementById('bc-canvas');
const bcCtx = bcCv.getContext('2d');
let bcW = 800, bcH = 500;
let bcRunning = false, bcRAF = null, bcTimerInt = null;
let bcScore = 0, bcTime = 0;          // bcTime ยังเป็น int วินาที (แสดง HUD)
let globalGrowthFactor = 1.0;
let growthAccum = 0;                  // float accumulator วิ — นับตาม dt จริง

// delta-time state
let prevTimestamp = 0;                // ms จาก rAF ล่าสุด

let P = {};
let bullets = [], enemies = [], expOrbs = [], particles = [], shockwaves = [], dmgNumbers = [];
let clones = [];

// timers ทุกตัวเป็น seconds ที่เหลือ (countdown) หรือ elapsed (count-up)
let spikeAngle   = 0;    // radian — สะสมตาม dt (rad/s)
let spawnTimer   = 0;    // วิ ที่รอ spawn ถัดไป
let shootTimer   = 0;    // วิ ที่รอยิงถัดไป
let wingsTimer   = 0;
let regenTimer   = 0;
let freezeTimer  = 0;
let novaTimer    = 0;
let repulseTimer = 0;
let coronaTimer  = 0;
let nextBossAt   = BOSS_SPAWN_EVERY; // วิ

/* ==================== INPUT ==================== */
const keys = { ArrowUp:false, ArrowDown:false, ArrowLeft:false, ArrowRight:false, w:false, a:false, s:false, d:false };
let mouseTarget  = { x:0, y:0, active:false };
let vjInput      = { x:0, y:0, active:false };
let gamepadInput = { x:0, y:0, active:false };
let ctrlMode     = 'none';

let dynJoystickEnabled = true;
let dynJoystickActive  = false;
let dynTouchId   = null;
let dynOrigin    = { x:0, y:0 };
let dynElement   = null;
let dynStick     = null;

function createDynamicJoystickDiv() {
  const div = document.createElement('div');
  div.id = 'dynamic-joystick';
  div.style.cssText = `position:fixed;width:120px;height:120px;border-radius:50%;background:rgba(0,255,180,0.2);border:2px solid rgba(0,255,180,0.7);backdrop-filter:blur(4px);display:none;pointer-events:none;z-index:200;touch-action:none;`;
  const stick = document.createElement('div');
  stick.id = 'dynamic-stick';
  stick.style.cssText = `width:44px;height:44px;border-radius:50%;background:rgba(0,255,180,0.95);border:2px solid white;position:absolute;top:38px;left:38px;transition:transform 0.02s linear;`;
  div.appendChild(stick);
  document.body.appendChild(div);
  return { div, stick };
}
function showDynamicJoystick(cx, cy) {
  if (!dynJoystickEnabled) return;
  if (!dynElement) { const { div, stick } = createDynamicJoystickDiv(); dynElement = div; dynStick = stick; }
  dynElement.style.display = 'block';
  dynElement.style.left = (cx - 60) + 'px';
  dynElement.style.top  = (cy - 60) + 'px';
  dynStick.style.left = '38px'; dynStick.style.top = '38px';
  dynOrigin = { x:cx, y:cy };
  dynJoystickActive = true;
}
function updateDynamicJoystick(cx, cy) {
  if (!dynElement || dynElement.style.display !== 'block') return;
  let dx = cx - dynOrigin.x, dy = cy - dynOrigin.y;
  const maxDist = 50, dist = Math.hypot(dx, dy);
  let nx = 0, ny = 0;
  if (dist > maxDist) { dx = dx/dist*maxDist; dy = dy/dist*maxDist; nx = dx/maxDist; ny = dy/maxDist; }
  else if (dist > 0)  { nx = dx/maxDist; ny = dy/maxDist; }
  dynStick.style.left = (38 + dx) + 'px'; dynStick.style.top = (38 + dy) + 'px';
  vjInput = { x:nx, y:ny, active:true }; ctrlMode = 'joystick';
}
function hideDynamicJoystick() {
  if (dynElement) dynElement.style.display = 'none';
  vjInput = { x:0, y:0, active:false }; dynJoystickActive = false; dynTouchId = null;
}
function toggleDynamicJoystick() {
  dynJoystickEnabled = !dynJoystickEnabled;
  const btn = document.getElementById('toggle-joystick-btn');
  if (btn) { btn.textContent = dynJoystickEnabled ? '🎮 JOY ON' : '🎮 JOY OFF'; btn.style.opacity = dynJoystickEnabled ? '1' : '0.5'; }
  if (!dynJoystickEnabled) hideDynamicJoystick();
}

export function setVjInput(input) { vjInput = input; ctrlMode = 'joystick'; }

document.addEventListener('keydown', e => { if (e.key in keys) { keys[e.key] = true; ctrlMode = 'keyboard'; } });
document.addEventListener('keyup',   e => { if (e.key in keys) keys[e.key] = false; });

function attachCanvasEvents() {
  bcCv.addEventListener('mousemove', e => {
    if (!bcRunning || dynJoystickActive) return;
    const rect = bcCv.getBoundingClientRect();
    mouseTarget = { x:(e.clientX-rect.left)*(bcW/rect.width), y:(e.clientY-rect.top)*(bcH/rect.height), active:true };
    ctrlMode = 'mouse';
  });
  bcCv.addEventListener('touchstart', e => {
    if (!bcRunning || !dynJoystickEnabled || dynTouchId !== null) return;
    e.preventDefault();
    const t = e.touches[0]; dynTouchId = t.identifier;
    showDynamicJoystick(t.clientX, t.clientY);
  }, { passive:false });
  bcCv.addEventListener('touchmove', e => {
    if (!bcRunning || !dynJoystickActive || dynTouchId === null) return;
    e.preventDefault();
    for (let i = 0; i < e.touches.length; i++)
      if (e.touches[i].identifier === dynTouchId) { updateDynamicJoystick(e.touches[i].clientX, e.touches[i].clientY); break; }
  }, { passive:false });
  bcCv.addEventListener('touchend', e => {
    if (!bcRunning || dynTouchId === null) return;
    e.preventDefault();
    let still = false;
    for (let i = 0; i < e.touches.length; i++) if (e.touches[i].identifier === dynTouchId) still = true;
    if (!still) hideDynamicJoystick();
  }, { passive:false });
  bcCv.addEventListener('touchcancel', () => { if (dynTouchId !== null) hideDynamicJoystick(); });
}
attachCanvasEvents();

/* ==================== HELPERS ==================== */
function resetPlayer() {
  P = {
    x:bcW/2, y:bcH/2, r:18,
    hp:100, maxHp:100,
    speed:150,
    exp:0, expNext:40, lv:1,
    iFrames:0,           // วิ invincibility หลังโดนดาเมจ (ป้องกัน dmg ทุก frame)
    atkMult:1, critChance:0, lifeSteal:0,
    regenLv:0,
    magnetR:90, spikes:0, wings:0, eyeLv:0, tailLv:0,
    piercing:0, bomb:0, bulletRange:1, bulletSpd:1,
    spreadShot:0, laserLv:0, homingLv:0,
    fireRateMult:1, chainLv:0,
    barrierLv:0, barrierTimer:0, barrierCooldown:0,
    thornPct:0, dashLv:0, cloneLv:0, orbShields:0,
    freezeLv:0, leechLv:0, novaLv:0,
    expMult:1, contactDmg:0, ghostLv:0,
    twinShot:false, repulseLv:0, syphonLv:0, dmgReduce:0,
    voidCannon:0, coronaLv:0, absorbLv:0, entropyLv:0,
  };
}

function resizeBC() {
  const outer = document.getElementById('bc-outer');
  bcW = bcCv.width  = outer.clientWidth  || 800;
  bcH = bcCv.height = outer.clientHeight || 500;
}

function showScreen(id) {
  ['bc-start','evo-screen','boss-upgrade-screen','dead-screen'].forEach(s => {
    const el = document.getElementById(s); if(el) el.classList.remove('show');
  });
  const t = document.getElementById(id); if(t) t.classList.add('show');
}
function hideScreens() {
  ['bc-start','evo-screen','boss-upgrade-screen','dead-screen'].forEach(s => {
    const el = document.getElementById(s); if(el) el.classList.remove('show');
  });
}

/* ==================== GROWTH ==================== */
function applyGrowthTick() {
  globalGrowthFactor *= 1.2;
  for (const e of enemies) {
    e.hp    *= 1.5; e.maxHp *= 1.5;
    e.speed *= 1.5;
    e.dmg   *= 1.5;
  }
  spawnParticles(bcW/2, bcH/2, '#ff8800', 30);
  addDmgNum(bcW/2, bcH/2 - 30, '⚠ GROWTH x1.5', false, true);
}

/* ==================== SPAWN ==================== */
function scalingAt(t) {
  const hpMult  = globalGrowthFactor * (1 + Math.floor(t / 30) * 0.15);
  const spdMult = globalGrowthFactor * Math.min(2.5, 1 + Math.floor(t / 20) * 0.08);
  return { hpMult, spdMult };
}

function spawnEnemy() {
  const side = Math.floor(Math.random() * 4);
  let x, y;
  if      (side===0) { x=Math.random()*bcW; y=-25; }
  else if (side===1) { x=bcW+25; y=Math.random()*bcH; }
  else if (side===2) { x=Math.random()*bcW; y=bcH+25; }
  else               { x=-25; y=Math.random()*bcH; }

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
  const slowMult = P.entropyLv > 0 ? Math.max(0.2, 1 - P.entropyLv * 0.4) : 1;
  enemies.push({
    x, y, r:T.r, hp, maxHp:hp,
    speed: T.speed * spdMult * slowMult,   // px/s
    type:T.type, color:T.color, expVal:T.expVal, score:T.score,
    emoji:T.emoji, dmg:T.dmg * globalGrowthFactor,
    zigDir:0, zigTimer:0,                  // zigTimer เป็น วิ
    angle:Math.atan2(P.y-y, P.x-x),
    frozenTimer:0,                         // วิ ที่เหลือ frozen (countdown)
  });
}

function spawnCount() {
  if (bcTime < 30)  return 1;
  if (bcTime < 90)  return Math.random() < 0.4 ? 2 : 1;
  if (bcTime < 180) return Math.random() < 0.6 ? 2 : 1;
  return Math.random() < 0.5 ? 3 : 2;
}

function spawnBoss() {
  const side = Math.floor(Math.random() * 4);
  let x, y;
  if      (side===0) { x=Math.random()*bcW; y=-50; }
  else if (side===1) { x=bcW+50; y=Math.random()*bcH; }
  else if (side===2) { x=Math.random()*bcW; y=bcH+50; }
  else               { x=-50; y=Math.random()*bcH; }

  const wave = Math.floor(bcTime / BOSS_CFG.spawnEvery || 0);
  const hp   = Math.ceil(BOSS_CFG.hpBase * (1 + wave * 0.6) * globalGrowthFactor);
  const slowMult = P.entropyLv > 0 ? Math.max(0.2, 1 - P.entropyLv * 0.4) : 1;
  enemies.push({
    x, y, r:BOSS_CFG.r, hp, maxHp:hp,
    speed: BOSS_CFG.speed * (1 + wave * 0.1) * globalGrowthFactor * slowMult,
    type:'boss', color:BOSS_CFG.color,
    expVal: BOSS_CFG.expVal*(1+wave), score: BOSS_CFG.score*(1+wave),
    emoji:BOSS_CFG.emoji, dmg: BOSS_CFG.dmg * globalGrowthFactor,
    zigDir:0, zigTimer:0,
    angle:Math.atan2(P.y-y, P.x-x),
    frozenTimer:0,
  });
}

/* ==================== SHOOT ==================== */
// dt คือ seconds ตั้งแต่ frame ก่อน
function autoShoot(dt) {
  if (!enemies.length) return;

  // fireInterval เป็น วิ
  const fireInterval = Math.max(0.1, FIRE_BASE_INTERVAL * P.fireRateMult - P.eyeLv * 0.04);
  shootTimer += dt;
  if (shootTimer < fireInterval) return;
  shootTimer -= fireInterval;   // ลบออกแทน reset → เก็บ remainder ไว้ ไม่ drift

  const count  = 1 + P.eyeLv;
  const sorted = [...enemies].sort((a,b) => Math.hypot(a.x-P.x,a.y-P.y) - Math.hypot(b.x-P.x,b.y-P.y));
  const bulletLife = 1.5 * P.bulletRange;   // วิ (เดิม 90 frame ÷ 60 = 1.5s)
  const spd  = 450 * P.bulletSpd;           // px/s (เดิม 7.5 px/frame × 60)

  for (let i = 0; i < Math.min(count, sorted.length); i++) {
    const e   = sorted[i];
    const ang = Math.atan2(e.y-P.y, e.x-P.x);
    const crit = Math.random() < P.critChance;
    const baseDmg = Math.max(1, (crit ? 2.5 : 1) * Math.round(7 * P.atkMult));
    const dmg = P.voidCannon > 0 ? baseDmg * (1 + P.voidCannon * 2) : baseDmg;
    const isVoid = P.voidCannon > 0;

    const mkBullet = (angle, extra={}) => ({
      x:P.x, y:P.y, vx:Math.cos(angle)*spd, vy:Math.sin(angle)*spd,
      r:5+i, dmg, crit, pierce: P.piercing + (isVoid?99:0),
      life:bulletLife, hitEnemies:new Set(),
      homing: P.homingLv > 0, chain: P.chainLv,
      isVoid, ...extra
    });

    bullets.push(mkBullet(ang));
    if (P.twinShot && !crit) bullets.push(mkBullet(ang, { r:8+i, dmg:dmg*2 }));

    if (P.spreadShot > 0) {
      const sp = 0.3;
      for (let s = 1; s <= P.spreadShot; s++) {
        bullets.push(mkBullet(ang + sp*s));
        bullets.push(mkBullet(ang - sp*s));
      }
    }
  }
}

/* ==================== LASER ==================== */
function drawLaser(ctx, dt) {
  if (!P.laserLv || !enemies.length) return;
  const sorted = [...enemies].sort((a,b) => Math.hypot(a.x-P.x,a.y-P.y) - Math.hypot(b.x-P.x,b.y-P.y));
  const target = sorted[0];
  const ang = Math.atan2(target.y-P.y, target.x-P.x);
  const len = Math.max(bcW, bcH) * 1.5;
  const ex  = P.x + Math.cos(ang)*len, ey = P.y + Math.sin(ang)*len;

  // dmg เป็น per-second × dt
  const laserDps = 9 * P.atkMult * P.laserLv;   // 0.15/frame × 60 = 9/s
  for (const e of enemies) {
    const dx = e.x-P.x, dy = e.y-P.y;
    const t  = Math.max(0, dx*Math.cos(ang) + dy*Math.sin(ang));
    const px = P.x + Math.cos(ang)*t, py = P.y + Math.sin(ang)*t;
    if (Math.hypot(e.x-px, e.y-py) < e.r + 4) {
      e.hp -= laserDps * dt;
      if (e.hp <= 0) killEnemy(e);
    }
  }

  const grd = ctx.createLinearGradient(P.x, P.y, ex, ey);
  grd.addColorStop(0, `rgba(255,50,50,${0.6*P.laserLv})`);
  grd.addColorStop(1, 'rgba(255,50,50,0)');
  ctx.beginPath(); ctx.moveTo(P.x, P.y); ctx.lineTo(ex, ey);
  ctx.strokeStyle = grd; ctx.lineWidth = 3*P.laserLv; ctx.stroke();
}

/* ==================== EFFECTS ==================== */
function spawnParticles(x, y, color, n) {
  for (let i = 0; i < n; i++)
    particles.push({ x, y, vx:(Math.random()-.5)*300, vy:(Math.random()-.5)*300,
      r:Math.random()*3+1, life:0.5, maxLife:0.5, color });
  // vx/vy เป็น px/s; life เป็น วิ
}
function addDmgNum(x, y, val, crit, big=false) {
  dmgNumbers.push({ x, y, val, crit, big, life:big?1.2:0.75, maxLife:big?1.2:0.75, vy:-90 }); // vy px/s
}
function doShockwave() {
  // maxR px, life วิ
  shockwaves.push({ x:P.x, y:P.y, r:0, maxR:140, life:0.37, maxLife:0.37, dmg:Math.round(18*P.atkMult) });
}
function spawnBombs(x, y) {
  for (let i = 0; i < 6; i++) {
    const a = i*(Math.PI/3);
    bullets.push({ x, y, vx:Math.cos(a)*300, vy:Math.sin(a)*300, r:4,
      dmg:Math.round(5*P.atkMult), crit:false, pierce:0, life:0.67,
      hitEnemies:new Set(), isBomb:true, homing:false, chain:0, isVoid:false });
  }
}
function doNova() {
  const rad = 150 + P.novaLv * 30;
  for (const e of [...enemies]) {
    if (Math.hypot(e.x-P.x, e.y-P.y) < rad) {
      e.hp -= 20 * P.atkMult * P.novaLv;
      spawnParticles(e.x, e.y, '#ffdd00', 5);
    }
  }
  shockwaves.push({ x:P.x, y:P.y, r:0, maxR:rad, life:0.3, maxLife:0.3, dmg:0 });
}
function doFreeze() {
  for (const e of enemies) e.frozenTimer = FREEZE_DURATION;
}
function doRepulse() {
  for (const e of enemies) {
    const dx = e.x-P.x, dy = e.y-P.y, d = Math.hypot(dx,dy)||1;
    e.x += dx/d * 80; e.y += dy/d * 80;
  }
  spawnParticles(P.x, P.y, '#00aaff', 20);
}
function doCorona(ctx, dt) {
  if (!P.coronaLv) return;
  const rad   = P.r + 30 + P.coronaLv * 10;
  const pulse = 0.5 + 0.5*Math.sin(Date.now()*0.01);
  ctx.beginPath(); ctx.arc(P.x, P.y, rad, 0, Math.PI*2);
  ctx.strokeStyle = `rgba(255,200,0,${0.3*pulse})`; ctx.lineWidth = 8*pulse; ctx.stroke();
  const coronaDps = 15 * P.atkMult * P.coronaLv;  // 0.25/frame × 60
  for (const e of [...enemies])
    if (Math.hypot(e.x-P.x, e.y-P.y) < rad + e.r)
      e.hp -= coronaDps * dt;
}

/* ==================== KILL ==================== */
function killEnemy(e, hintIdx) {
  // หา index จาก object reference — ป้องกัน splice ผิดตัวหลัง array เลื่อน
  const j = (hintIdx !== undefined && enemies[hintIdx] === e) ? hintIdx : enemies.indexOf(e);
  if (j < 0) return;
  const expGain = Math.floor(e.expVal * P.expMult);
  expOrbs.push({ x:e.x, y:e.y, r:5, val:expGain });
  bcScore += e.score;
  if (P.bomb > 0)      spawnBombs(e.x, e.y);
  if (P.absorbLv > 0)  P.hp = Math.min(P.maxHp, P.hp + P.maxHp * 0.05 * P.absorbLv);
  if (P.syphonLv > 0)  P.maxHp += 0.1 * P.syphonLv;
  if (e.type === 'boss') onBossKilled(e);
  enemies.splice(j, 1);
}

/* ==================== BOSS KILLED ==================== */
function onBossKilled(e) {
  P.r = Math.min(P.r * 1.2, 80);
  spawnParticles(e.x, e.y, '#ffd700', 40);
  bcRunning = false;
  const pool = [...BOSS_UPGRADES]; const picks = [];
  while (picks.length < 3 && pool.length) picks.push(pool.splice(Math.floor(Math.random()*pool.length),1)[0]);
  const c = document.getElementById('boss-evo-cards'); if (!c) { bcRunning=true; return; }
  c.innerHTML = '';
  picks.forEach(m => {
    const d = document.createElement('div'); d.className = 'evo-card boss-evo-card';
    d.innerHTML = `<div class="ec-icon" style="font-size:2em">${m.icon}</div><h3 style="color:#ffd700">${m.name}</h3><p>${m.desc}</p>`;
    d.onclick = () => { m.apply(P); hideScreens(); bcRunning=true; updateHUD(); prevTimestamp=0; bcLoop(); };
    c.appendChild(d);
  });
  showScreen('boss-upgrade-screen');
}

/* ==================== LEVEL UP ==================== */
function doLevelUp() {
  P.lv++; P.exp -= P.expNext;
  P.expNext = Math.floor(P.expNext * (P.lv<=5 ? 1.6 : 1.2));
  updateHUD(); bcRunning = false;

  const weapons = MUTATIONS.filter(m => m.tag==='weapon');
  const miscs   = MUTATIONS.filter(m => m.tag==='misc');
  const pool = [];
  while (pool.length < 6) {
    if (Math.random() < 0.5) pool.push(weapons[Math.floor(Math.random()*weapons.length)]);
    else                     pool.push(miscs[Math.floor(Math.random()*miscs.length)]);
  }
  const seen = new Set(); const picks = [];
  for (const m of pool) { if (!seen.has(m.id)) { seen.add(m.id); picks.push(m); if (picks.length===3) break; } }

  const c = document.getElementById('evo-cards'); c.innerHTML = '';
  picks.forEach(m => {
    const d = document.createElement('div'); d.className = 'evo-card';
    const tagColor = m.tag==='weapon' ? '#ff6644' : '#00ffb4';
    const tagLabel = m.tag==='weapon' ? 'WEAPON' : 'MISC';
    d.innerHTML = `<div class="ec-tag" style="color:${tagColor};font-size:10px;font-weight:900;font-family:'Orbitron';letter-spacing:1px">${tagLabel}</div><div class="ec-icon">${m.icon}</div><h3>${m.name}</h3><p>${m.desc}</p>`;
    d.onclick = () => { m.apply(P); hideScreens(); bcRunning=true; updateHUD(); prevTimestamp=0; bcLoop(); };
    c.appendChild(d);
  });
  showScreen('evo-screen');
}

/* ==================== HUD ==================== */
function updateHUD() {
  const hpEl = document.getElementById('hud-hp');
  if (hpEl) {
    hpEl.style.width = Math.max(0,(P.hp/P.maxHp)*100)+'%';
    hpEl.style.background = P.hp < P.maxHp*0.3
      ? 'linear-gradient(90deg,#ff4466,#ff2244)'
      : 'linear-gradient(90deg,#00ffb4,#00cc88)';
  }
  const hpText = document.getElementById('hud-hp-txt');
  if (hpText) hpText.textContent = `${Math.max(0,Math.round(P.hp))}/${P.maxHp}`;
  const lvEl = document.getElementById('hud-lv');
  if (lvEl) lvEl.textContent = `LV.${P.lv}`;
  const expEl = document.getElementById('hud-exp');
  if (expEl) expEl.style.width = Math.min(100,(P.exp/P.expNext)*100)+'%';
  const scoreEl = document.getElementById('hud-score');
  if (scoreEl) scoreEl.textContent = bcScore.toLocaleString();
  const timeEl = document.getElementById('hud-time');
  if (timeEl) timeEl.textContent = bcTime+'s';
  const growthEl = document.getElementById('hud-growth');
  if (growthEl) growthEl.textContent = `x${globalGrowthFactor.toFixed(1)}`;
  const ctrlEl = document.getElementById('ctrl-indicator');
  if (ctrlEl) { const labels={none:'',mouse:'🖱️',touch:'👆',keyboard:'⌨️',joystick:'🕹️',gamepad:'🎮'}; ctrlEl.textContent=labels[ctrlMode]||''; }
}

/* ==================== GAMEPAD ==================== */
function pollGamepad() {
  const gamepads = navigator.getGamepads?.();
  if (!gamepads) return;
  for (const gp of gamepads) {
    if (!gp) continue;
    const lx=gp.axes[0]||0, ly=gp.axes[1]||0, dead=0.12;
    const active = Math.abs(lx)>dead || Math.abs(ly)>dead;
    gamepadInput = active ? {x:lx,y:ly,active:true} : {x:0,y:0,active:false};
    if (active) ctrlMode = 'gamepad';
    break;
  }
}

/* ==================== MAIN LOOP ==================== */
function bcLoop(timestamp = 0) {
  if (!bcRunning) return;
  bcRAF = requestAnimationFrame(bcLoop);
  pollGamepad();

  // ── DELTA TIME ──
  if (prevTimestamp === 0) prevTimestamp = timestamp;
  let dt = (timestamp - prevTimestamp) / 1000;
  prevTimestamp = timestamp;
  dt = Math.min(dt, 0.1);   // cap: ป้องกัน spike เวลา tab ซ่อน

  const ctx = bcCtx;

  // ── BACKGROUND ──
  ctx.fillStyle = '#0d101a'; ctx.fillRect(0,0,bcW,bcH);
  ctx.strokeStyle = 'rgba(0,180,255,0.04)'; ctx.lineWidth=1;
  for (let x=0;x<bcW;x+=50){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,bcH);ctx.stroke();}
  for (let y=0;y<bcH;y+=50){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(bcW,y);ctx.stroke();}

  // ── GROWTH (float accumulator — ไม่ trigger ซ้ำ) ──
  if (bcTime > 0) {
    growthAccum += dt;
    if (growthAccum >= GROWTH_INTERVAL) {
      growthAccum -= GROWTH_INTERVAL;
      applyGrowthTick();
    }
  }

  // ── PLAYER MOVEMENT (px/s × dt) ──
  let dx=0, dy=0;
  if      (vjInput.active)      { dx=vjInput.x;     dy=vjInput.y; }
  else if (gamepadInput.active) { dx=gamepadInput.x; dy=gamepadInput.y; }
  else {
    if (keys.w||keys.ArrowUp)    dy-=1;
    if (keys.s||keys.ArrowDown)  dy+=1;
    if (keys.a||keys.ArrowLeft)  dx-=1;
    if (keys.d||keys.ArrowRight) dx+=1;
  }
  const dlen = Math.hypot(dx,dy);
  if (dlen>0) {
    P.x += dx/dlen * P.speed * dt;
    P.y += dy/dlen * P.speed * dt;
  } else if (mouseTarget.active && ctrlMode==='mouse') {
    const mdx=mouseTarget.x-P.x, mdy=mouseTarget.y-P.y, md=Math.hypot(mdx,mdy);
    if (md>4) { P.x+=mdx/md*P.speed*dt; P.y+=mdy/md*P.speed*dt; }
  }
  P.x = Math.max(P.r, Math.min(bcW-P.r, P.x));
  P.y = Math.max(P.r, Math.min(bcH-P.r, P.y));

  // ── SPAWN ──
  // interval ลดตามเวลา: 2.0s → 0.4s (ช้ากว่าเดิมตอนต้น)
  const spawnInterval = Math.max(0.4, 2.0 - bcTime * 0.005);
  spawnTimer += dt;
  if (spawnTimer >= spawnInterval) {
    spawnTimer = 0;   // reset ไม่ลบ — ป้องกัน dt spike spawn ซ้ำ
    const n = spawnCount();
    for (let i=0;i<n;i++) spawnEnemy();
  }

  // ── BOSS ──
  if (bcTime >= nextBossAt) {
    nextBossAt += BOSS_SPAWN_EVERY;
    spawnBoss();
  }
  const warnStart = nextBossAt - 10;
  if (bcTime >= warnStart && bcTime < nextBossAt && Math.floor(Date.now()/300)%2===0) {
    ctx.fillStyle='rgba(255,0,85,0.07)'; ctx.fillRect(0,0,bcW,bcH);
    ctx.fillStyle='rgba(255,0,85,0.8)'; ctx.font='bold 18px Orbitron';
    ctx.textAlign='center'; ctx.textBaseline='middle';
    ctx.fillText('⚠ BOSS INCOMING ⚠', bcW/2, 36);
  }

  // ── SHOOT ──
  autoShoot(dt);

  // ── ABILITY TIMERS (all dt-based) ──
  if (P.freezeLv>0)  { freezeTimer  += dt; if(freezeTimer  >= FREEZE_INTERVAL)  { freezeTimer  -= FREEZE_INTERVAL;  doFreeze(); } }
  if (P.novaLv>0)    { novaTimer    += dt; if(novaTimer    >= NOVA_INTERVAL)     { novaTimer    -= NOVA_INTERVAL;    doNova(); } }
  if (P.repulseLv>0) { repulseTimer += dt; if(repulseTimer >= REPULSE_INTERVAL)  { repulseTimer -= REPULSE_INTERVAL; doRepulse(); } }
  if (P.coronaLv>0)  { coronaTimer  += dt; if(coronaTimer  >= CORONA_INTERVAL)   { coronaTimer  -= CORONA_INTERVAL; } }
  doCorona(ctx, dt);   // corona draw+dmg ทุก frame แต่ dmg คูณ dt เสมอ

  // ── LEECH (per-second × dt) ──
  if (P.leechLv > 0) {
    const leechDps  = 3 * P.leechLv;   // 0.05/frame × 60
    const healRate  = 1.2 * P.leechLv;
    for (const e of enemies) {
      const d = Math.hypot(e.x-P.x, e.y-P.y);
      if (d < 120 + P.leechLv*20) {
        e.hp -= leechDps * dt;
        P.hp  = Math.min(P.maxHp, P.hp + healRate * dt);
      }
    }
  }

  // ── BARRIER COUNTDOWN ──
  if (P.barrierTimer > 0) {
    P.barrierTimer -= dt;
    if (P.barrierTimer <= 0) P.barrierCooldown = BARRIER_COOLDOWN; // เริ่ม cooldown ทันทีหลัง barrier หมด
  }
  if (P.barrierCooldown > 0) P.barrierCooldown -= dt;

  // ── REGEN ──
  if (P.regenLv>0) {
    regenTimer += dt;
    if (regenTimer >= REGEN_INTERVAL) {
      regenTimer -= REGEN_INTERVAL;
      P.hp = Math.min(P.maxHp, P.hp + P.regenLv);
    }
  }

  // ── WINGS ──
  if (P.wings>0) {
    wingsTimer += dt;
    if (wingsTimer >= WINGS_INTERVAL) { wingsTimer -= WINGS_INTERVAL; doShockwave(); }
  }

  // ── SPIKE ANGLE (rad/s) ──
  spikeAngle += 3 * dt;   // ~3 rad/s ≈ เดิม 0.05 rad/frame × 60

  // ── SPIKES ── สามเหลี่ยมเล็กๆ โคจรรอบ player
  if (P.spikes > 0) {
    const orbitR  = P.r + 22;   // ระยะห่างจากขอบ player
    const spikeSize = 7;        // ขนาดสามเหลี่ยม
    const spikeDps  = 48 * dt;
    for (let i = 0; i < P.spikes; i++) {
      const a  = spikeAngle + i * (Math.PI*2 / P.spikes);
      const cx = P.x + Math.cos(a) * orbitR;  // จุดกึ่งกลางสามเหลี่ยม
      const cy = P.y + Math.sin(a) * orbitR;
      // สามเหลี่ยมชี้ออกจาก player (tip ชี้ตาม angle)
      const tipX = cx + Math.cos(a) * spikeSize;
      const tipY = cy + Math.sin(a) * spikeSize;
      const la   = a + Math.PI*2/3;
      const ra   = a - Math.PI*2/3;
      const lx = cx + Math.cos(la) * spikeSize;
      const ly = cy + Math.sin(la) * spikeSize;
      const rx = cx + Math.cos(ra) * spikeSize;
      const ry = cy + Math.sin(ra) * spikeSize;
      ctx.beginPath(); ctx.moveTo(tipX,tipY); ctx.lineTo(lx,ly); ctx.lineTo(rx,ry); ctx.closePath();
      ctx.fillStyle = '#ff2222'; ctx.fill();
      ctx.strokeStyle = '#ff8888'; ctx.lineWidth = 1; ctx.stroke();
      // damage ศัตรูที่อยู่ใกล้จุดกึ่งกลางสามเหลี่ยม
      for (const e of enemies)
        if (Math.hypot(cx-e.x, cy-e.y) < e.r + spikeSize) {
          e.hp -= spikeDps;
          spawnParticles(e.x, e.y, '#ff2222', 1);
        }
    }
  }

  // ── ORBITAL SHIELDS ──
  if (P.orbShields > 0) {
    for (let i=0; i<P.orbShields; i++) {
      const oa = spikeAngle*0.6 + i*(Math.PI*2/P.orbShields);
      const ox = P.x+Math.cos(oa)*(P.r+28), oy = P.y+Math.sin(oa)*(P.r+28);
      ctx.beginPath(); ctx.arc(ox,oy,9,0,Math.PI*2);
      ctx.fillStyle='rgba(0,180,255,0.8)'; ctx.fill();
      ctx.strokeStyle='#fff'; ctx.lineWidth=1.5; ctx.stroke();
    }
  }

  // ── SHOCKWAVES ──
  for (let i=shockwaves.length-1; i>=0; i--) {
    const sw = shockwaves[i];
    sw.r += (sw.maxR / sw.maxLife) * dt;
    sw.life -= dt;
    ctx.beginPath(); ctx.arc(sw.x,sw.y,sw.r,0,Math.PI*2);
    ctx.strokeStyle=`rgba(119,102,255,${Math.max(0,sw.life/sw.maxLife)})`; ctx.lineWidth=4; ctx.stroke();
    for (const e of enemies)
      if (Math.hypot(e.x-sw.x,e.y-sw.y) < sw.r+e.r)
        e.hp -= sw.dmg * dt * 6;   // 0.1/frame × 60 = 6/s × dt
    if (sw.life <= 0) shockwaves.splice(i,1);
  }

  // ── LASER ──
  drawLaser(ctx, dt);

  // ── BULLETS ──
  for (let i=bullets.length-1; i>=0; i--) {
    const b = bullets[i];

    // homing steering
    if (b.homing && enemies.length) {
      const target = enemies.reduce((best,e) =>
        Math.hypot(e.x-b.x,e.y-b.y) < Math.hypot(best.x-b.x,best.y-b.y) ? e : best, enemies[0]);
      const ang  = Math.atan2(target.y-b.y, target.x-b.x);
      const spd2 = Math.hypot(b.vx,b.vy);
      const steer = 24 * dt;   // 0.4/frame × 60 = 24/s
      b.vx += Math.cos(ang)*steer; b.vy += Math.sin(ang)*steer;
      const newSpd = Math.hypot(b.vx,b.vy);
      if (newSpd > spd2*1.2) { b.vx=b.vx/newSpd*spd2*1.2; b.vy=b.vy/newSpd*spd2*1.2; }
    }

    b.x += b.vx * dt; b.y += b.vy * dt;
    b.life -= dt;

    let killed = false;
    for (let j=enemies.length-1; j>=0; j--) {
      const e = enemies[j];
      if (b.hitEnemies.has(e)) continue;   // ← เก็บ object reference ไม่ใช่ index
      if (Math.hypot(b.x-e.x,b.y-e.y) < b.r+e.r) {
        b.hitEnemies.add(e);               // ← object reference
        e.hp -= b.dmg;
        if (P.lifeSteal>0) P.hp = Math.min(P.maxHp, P.hp + b.dmg*P.lifeSteal);
        spawnParticles(e.x,e.y, b.crit?'#ffd700':b.isVoid?'#aa00ff':'#ff6644', b.crit?10:4);
        addDmgNum(e.x, e.y-e.r, b.dmg, b.crit);
        bcScore += b.dmg;
        if (e.hp <= 0) {
          if (b.chain > 0) {
            const near = enemies.filter(en=>en!==e).sort((a,x)=>Math.hypot(a.x-e.x,a.y-e.y)-Math.hypot(x.x-e.x,x.y-e.y));
            for (let ci=0; ci<Math.min(b.chain,near.length); ci++) {
              near[ci].hp -= b.dmg*0.6;
              ctx.beginPath(); ctx.moveTo(e.x,e.y); ctx.lineTo(near[ci].x,near[ci].y);
              ctx.strokeStyle='rgba(100,200,255,0.8)'; ctx.lineWidth=2; ctx.stroke();
              spawnParticles(near[ci].x,near[ci].y,'#66aaff',3);
            }
          }
          killEnemy(e, j);
        }
        if (b.pierce<=0 || b.hitEnemies.size>b.pierce) { killed=true; break; }
      }
    }
    if (killed || b.life<=0 || b.x<-20||b.x>bcW+20||b.y<-20||b.y>bcH+20)
      bullets.splice(i,1);
  }

  // ── EXP ORBS ──
  const orbSpd = 300;   // px/s (เดิม 5 px/frame × 60)
  for (let i=expOrbs.length-1; i>=0; i--) {
    const o = expOrbs[i];
    const d = Math.hypot(P.x-o.x, P.y-o.y);
    if (d < P.magnetR && d > 0.1) {
      const sp = orbSpd * (P.magnetR/90);
      o.x += (P.x-o.x)/d*sp*dt;
      o.y += (P.y-o.y)/d*sp*dt;
    }
    if (d < P.r+o.r) {
      P.exp += o.val;
      expOrbs.splice(i,1);
      if (P.exp >= P.expNext) { doLevelUp(); return; }
    }
  }

  // ── ENEMIES MOVE + DMG ──
  const zigInterval = 0.33;   // วิ (เดิม 20 frame ÷ 60)
  for (let ei=enemies.length-1; ei>=0; ei--) {
    const e = enemies[ei];

    if (e.frozenTimer > 0) { e.frozenTimer -= dt; continue; }

    if (e.type==='zigzag') {
      e.zigTimer += dt;
      if (e.zigTimer > zigInterval) { e.zigTimer -= zigInterval; e.zigDir = (e.zigDir+1)%2; }
      e.angle = Math.atan2(P.y-e.y, P.x-e.x) + (e.zigDir ? 0.6 : -0.6);
    } else {
      e.angle = Math.atan2(P.y-e.y, P.x-e.x);
    }
    e.x += Math.cos(e.angle) * e.speed * dt;
    e.y += Math.sin(e.angle) * e.speed * dt;

    if (Math.hypot(e.x-P.x, e.y-P.y) < e.r+P.r) {
      if (P.barrierLv>0 && P.barrierTimer<=0 && P.barrierCooldown<=0) {
        P.barrierTimer = BARRIER_DURATION * P.barrierLv;
      } else if (P.barrierTimer<=0 && P.iFrames<=0) {
        let dmgTaken = (e.dmg||6);          // dmg ต่อครั้ง (ไม่คูณ dt)
        dmgTaken *= (1 - Math.min(0.8, P.dmgReduce));
        if (P.orbShields>0) { P.orbShields--; dmgTaken=0; }
        P.hp -= dmgTaken;
        P.iFrames = 0.5;                    // invincible 0.5 วิ หลังโดน
        if (P.thornPct>0) e.hp -= dmgTaken * P.thornPct;
      }
      if (P.hp <= 0) { gameOver(); return; }
    }
  }
  if (P.iFrames > 0) P.iFrames -= dt;

  // ── DRAW ENEMIES ──
  for (const e of enemies) {
    if (e.type==='boss') {
      const pulse = 0.4+0.3*Math.sin(Date.now()*0.006);
      ctx.beginPath(); ctx.arc(e.x,e.y,e.r+10,0,Math.PI*2);
      ctx.strokeStyle=`rgba(255,0,85,${pulse})`; ctx.lineWidth=4; ctx.stroke();
    }
    ctx.beginPath(); ctx.arc(e.x,e.y,e.r,0,Math.PI*2);
    ctx.fillStyle = (e.frozenTimer>0?'#4488ff22':e.color+'22'); ctx.fill();
    ctx.beginPath(); ctx.arc(e.x,e.y,e.r,0,Math.PI*2);
    ctx.strokeStyle = e.frozenTimer>0?'#88ccff':e.color;
    ctx.lineWidth = e.type==='boss'?4:e.type==='tank'?3:2; ctx.stroke();
    const hpRatio = Math.max(0, Math.min(1, e.hp/e.maxHp));
    const barW = e.type==='boss' ? e.r*3 : e.r*2;
    const barH = e.type==='boss' ? 6 : 4;
    ctx.fillStyle='#0d1525'; ctx.fillRect(e.x-barW/2, e.y-e.r-10, barW, barH);
    ctx.fillStyle = hpRatio>0.5?'#00ffb4':hpRatio>0.25?'#ffaa00':'#ff4466';
    ctx.fillRect(e.x-barW/2, e.y-e.r-10, barW*hpRatio, barH);
    ctx.fillStyle='#fff'; ctx.font=`${e.r}px sans-serif`;
    ctx.textAlign='center'; ctx.textBaseline='middle';
    ctx.fillText(e.emoji,e.x,e.y);
  }

  // ── PARTICLES ──
  for (let i=particles.length-1; i>=0; i--) {
    const p = particles[i];
    p.x += p.vx*dt; p.y += p.vy*dt;
    p.vx *= Math.pow(0.001, dt);   // drag: 0.88^60 ≈ 0.001^1 ต่อวินาที
    p.vy *= Math.pow(0.001, dt);
    p.life -= dt;
    if (p.life <= 0) { particles.splice(i,1); continue; }  // splice ก่อน draw
    ctx.beginPath(); ctx.arc(p.x, p.y, Math.max(0, p.r*(p.life/p.maxLife)), 0, Math.PI*2);
    ctx.fillStyle=p.color+Math.round(p.life/p.maxLife*200).toString(16).padStart(2,'0');
    ctx.fill();
    if (p.life<=0) particles.splice(i,1);
  }

  // ── EXP ORBS DRAW ──
  for (const o of expOrbs) {
    ctx.beginPath(); ctx.arc(o.x,o.y,o.r,0,Math.PI*2);
    ctx.fillStyle='#7766ff'; ctx.fill();
  }

  // ── BARRIER FLASH ──
  if (P.barrierTimer>0 && Math.floor(P.barrierTimer*10)%2===0) {
    ctx.beginPath(); ctx.arc(P.x,P.y,P.r+12,0,Math.PI*2);
    ctx.strokeStyle='rgba(0,200,255,0.8)'; ctx.lineWidth=4; ctx.stroke();
  }

  // ── MAGNET RING ──
  ctx.beginPath(); ctx.arc(P.x,P.y,P.magnetR,0,Math.PI*2);
  ctx.strokeStyle='rgba(119,102,255,0.07)'; ctx.lineWidth=1; ctx.stroke();

  // ── PLAYER DRAW ──
  ctx.beginPath(); ctx.arc(P.x,P.y,P.r+5,0,Math.PI*2); ctx.fillStyle='rgba(0,255,180,0.06)'; ctx.fill();
  ctx.beginPath(); ctx.arc(P.x,P.y,P.r,0,Math.PI*2); ctx.fillStyle='#0d2030'; ctx.fill();
  ctx.strokeStyle='#00ffb4'; ctx.lineWidth=2.5; ctx.stroke();
  ctx.beginPath(); ctx.arc(P.x,P.y,P.r*.45,0,Math.PI*2); ctx.fillStyle='rgba(0,255,180,0.65)'; ctx.fill();

  // ── BULLETS DRAW ──
  for (const b of bullets) {
    ctx.beginPath(); ctx.arc(b.x,b.y,b.r,0,Math.PI*2);
    ctx.fillStyle = b.isVoid?'#cc00ff':b.isBomb?'#ffaa00':b.crit?'#ffd700':'#00ffb4';
    ctx.fill();
    if (b.homing) { ctx.strokeStyle='rgba(255,255,100,0.5)'; ctx.lineWidth=1; ctx.stroke(); }
  }

  // ── DAMAGE NUMBERS ──
  for (let i=dmgNumbers.length-1; i>=0; i--) {
    const dn = dmgNumbers[i];
    dn.y += dn.vy * dt;
    dn.life -= dt;
    const a = dn.life / dn.maxLife;
    if (dn.big) {
      ctx.fillStyle=`rgba(255,140,0,${a})`;
      ctx.font='bold 16px Orbitron'; ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.fillText(dn.val, dn.x, dn.y);
    } else {
      ctx.fillStyle = dn.crit?`rgba(255,215,0,${a})`:`rgba(255,200,100,${a})`;
      ctx.font = dn.crit?'bold 14px Orbitron':'12px Orbitron';
      ctx.textAlign='center'; ctx.textBaseline='middle';
      ctx.fillText(dn.crit?`★${dn.val}`:dn.val, dn.x, dn.y);
    }
    if (dn.life<=0) dmgNumbers.splice(i,1);
  }

  updateHUD();
}

/* ==================== LIFECYCLE ==================== */
function gameOver() {
  bcRunning = false; clearInterval(bcTimerInt);
  document.getElementById('dead-score').textContent = bcScore.toLocaleString();
  document.getElementById('dead-info').textContent  = `LV.${P.lv} · ${bcTime}s · Growth x${globalGrowthFactor.toFixed(1)}`;
  showScreen('dead-screen');
  hideDynamicJoystick();
}

function onOpen() {
  resizeBC(); resetPlayer();
  bullets=[]; enemies=[]; expOrbs=[]; particles=[]; shockwaves=[]; dmgNumbers=[]; clones=[];
  bcScore=0; bcTime=0; spikeAngle=0;
  spawnTimer=0; shootTimer=0; wingsTimer=0; regenTimer=0;
  freezeTimer=0; novaTimer=0; repulseTimer=0; coronaTimer=0;
  globalGrowthFactor=1.0; growthAccum=0; prevTimestamp=0;
  nextBossAt=BOSS_SPAWN_EVERY;
  showScreen('bc-start'); updateHUD();
}

function onClose() {
  bcRunning=false; clearInterval(bcTimerInt);
  if(bcRAF) cancelAnimationFrame(bcRAF);
  hideDynamicJoystick();
}

export function startBC() {
  resizeBC(); resetPlayer();
  bullets=[]; enemies=[]; expOrbs=[]; particles=[]; shockwaves=[]; dmgNumbers=[]; clones=[];
  bcScore=0; bcTime=0; spikeAngle=0;
  spawnTimer=0; shootTimer=0; wingsTimer=0; regenTimer=0;
  freezeTimer=0; novaTimer=0; repulseTimer=0; coronaTimer=0;
  globalGrowthFactor=1.0; growthAccum=0; prevTimestamp=0;
  nextBossAt=BOSS_SPAWN_EVERY;
  hideScreens(); bcRunning=true;

  if(bcTimerInt) clearInterval(bcTimerInt);
  bcTimerInt = setInterval(() => {
    if (!bcRunning) return;
    bcTime++;
    updateHUD();
  }, 1000);

  if(bcRAF) cancelAnimationFrame(bcRAF);
  requestAnimationFrame(bcLoop);

  const toggleBtn = document.getElementById('toggle-joystick-btn');
  if (toggleBtn && !toggleBtn._listenerAttached) {
    toggleBtn.addEventListener('click', toggleDynamicJoystick);
    toggleBtn._listenerAttached = true;
  }
}

window.startBC = startBC;
window.addEventListener('resize', () => { if(bcRunning) resizeBC(); });

registerGame('bc', onOpen, onClose);