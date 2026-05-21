/* shared.js — starfield, banner animations, leaderboard, navigation */

/* ==================== BG STARFIELD ==================== */
const bgC = document.getElementById('bg');
const bgX = bgC.getContext('2d');
let bW, bH, stars = [];

export function resizeBg() {
  bW = bgC.width = window.innerWidth;
  bH = bgC.height = window.innerHeight;
  stars = [];
  const n = Math.floor(bW * bH / 5000);
  for (let i = 0; i < n; i++)
    stars.push({ x: Math.random() * bW, y: Math.random() * bH, r: Math.random() * 1.2, sp: Math.random() * .15 + .05, ph: Math.random() * Math.PI * 2 });
}

export function drawBg(t) {
  bgX.fillStyle = '#070913'; bgX.fillRect(0, 0, bW, bH);
  bgX.strokeStyle = 'rgba(0,180,255,0.025)'; bgX.lineWidth = .5;
  for (let x = 0; x < bW; x += 80) { bgX.beginPath(); bgX.moveTo(x, 0); bgX.lineTo(x, bH); bgX.stroke(); }
  for (let y = 0; y < bH; y += 80) { bgX.beginPath(); bgX.moveTo(0, y); bgX.lineTo(bW, y); bgX.stroke(); }
  for (let s of stars) {
    s.y -= s.sp;
    if (s.y < -2) { s.y = bH + 2; s.x = Math.random() * bW; }
    const a = .3 + .5 * Math.abs(Math.sin(s.ph + t * .001));
    bgX.beginPath(); bgX.arc(s.x, s.y, s.r, 0, Math.PI * 2);
    bgX.fillStyle = `rgba(180,220,255,${a})`; bgX.fill();
  }
}

/* ==================== BANNER ANIMATIONS ==================== */
const cc = document.getElementById('cellCanvas');
const cx = cc?.getContext('2d');
let cp = [];
export function initCellBanner() {
  cp = [];
  for (let i = 0; i < 15; i++)
    cp.push({ x: Math.random() * 300, y: Math.random() * 160, vx: (Math.random() - .5) * .6, vy: (Math.random() - .5) * .6, r: Math.random() * 12 + 4, h: Math.random() > .5 ? '0,255,180' : '0,140,255', ph: Math.random() * Math.PI * 2, a: Math.random() * .3 + .1 });
}
export function drawCellBanner(t) {
  if (!cx) return;
  cx.clearRect(0, 0, 300, 160);
  for (let p of cp) {
    p.x += p.vx; p.y += p.vy;
    if (p.x < -20) p.x = 320; if (p.x > 320) p.x = -20;
    if (p.y < -20) p.y = 180; if (p.y > 180) p.y = -20;
    const pu = .5 + .5 * Math.sin(p.ph + t * .002), a = p.a * (.6 + .4 * pu);
    cx.beginPath(); cx.arc(p.x, p.y, p.r * (.9 + .1 * pu), 0, Math.PI * 2);
    cx.strokeStyle = `rgba(${p.h},${a})`; cx.lineWidth = 1; cx.stroke();
    cx.beginPath(); cx.arc(p.x, p.y, p.r * .3, 0, Math.PI * 2);
    cx.fillStyle = `rgba(${p.h},${a * 1.5})`; cx.fill();
  }
}

const dc = document.getElementById('dinoCanvas');
const dx = dc?.getContext('2d');
let dp = [];
const DC = ['#FFD600', '#FF8C42', '#7CB342', '#29B6F6', '#EC407A'];
export function initDinoBanner() {
  dp = [];
  for (let i = 0; i < 18; i++)
    dp.push({ x: Math.random() * 300, y: Math.random() * 160, vx: (Math.random() - .5) * .4, vy: (Math.random() - .5) * .4, r: Math.random() * 8 + 3, c: DC[Math.floor(Math.random() * DC.length)], ph: Math.random() * Math.PI * 2 });
}
export function drawDinoBanner(t) {
  if (!dx) return;
  dx.clearRect(0, 0, 300, 160);
  for (let p of dp) {
    p.x += p.vx; p.y += p.vy;
    if (p.x < -10) p.x = 310; if (p.x > 310) p.x = -10;
    if (p.y < -10) p.y = 170; if (p.y > 170) p.y = -10;
    const pu = .6 + .4 * Math.sin(p.ph + t * .0015), a = .12 * pu;
    dx.beginPath(); dx.arc(p.x, p.y, p.r * pu, 0, Math.PI * 2);
    dx.fillStyle = p.c + Math.round(a * 255).toString(16).padStart(2, '0'); dx.fill();
  }
}

const mc3 = document.getElementById('moleCanvas');
const mx3 = mc3?.getContext('2d');
let mp3 = [];
export function initMoleBanner() {
  mp3 = [];
  for (let i = 0; i < 12; i++)
    mp3.push({ x: Math.random() * 300, y: Math.random() * 160, r: Math.random() * 10 + 4, ph: Math.random() * Math.PI * 2, sp: Math.random() * .002 + .001 });
}
export function drawMoleBanner(t) {
  if (!mx3) return;
  mx3.clearRect(0, 0, 300, 160);
  for (let p of mp3) {
    const pu = .5 + .5 * Math.sin(p.ph + t * p.sp), a = .08 * pu;
    mx3.beginPath(); mx3.arc(p.x, p.y, p.r * pu, 0, Math.PI * 2);
    mx3.fillStyle = `rgba(124,77,255,${a})`; mx3.fill();
  }
}

/* ==================== LEADERBOARD ==================== */
export function buildLB() {
  const bd = document.getElementById('lb-body'); if (!bd) return;
  const d = [
    { n: 'VOID_DRIFTER', lv: 12, t: 145, sc: 13450 },
    { n: 'MUTANT_X',     lv: 8,  t: 92,  sc: 8920  },
    { n: 'VIRUS_SLAYER', lv: 5,  t: 61,  sc: 5610  },
    { n: 'CELL_OMEGA',   lv: 4,  t: 48,  sc: 4100  },
    { n: 'NANO_GHOST',   lv: 3,  t: 34,  sc: 2780  }
  ];
  const mx = d[0].sc;
  const rc = ['r1','r2','r3','rn','rn'], sc = ['sh','sm','sm','sl2','sl2'];
  d.forEach((r, i) => {
    const p = Math.round(r.sc / mx * 100);
    const row = document.createElement('div'); row.className = 'lb-row';
    row.innerHTML = `<div class="rnk ${rc[i]}">${i === 0 ? '◆' : '#' + (i + 1)}</div><div class="pname">${i === 0 ? '<span class="ng">' + r.n + '</span>' : r.n}</div><div style="color:#4a6080">LV.${r.lv}</div><div style="color:#4a6080">${r.t}s</div><div><div class="lsc ${sc[i]}">${r.sc.toLocaleString()}</div><div class="sbar-w"><div class="sbar" style="width:${p}%"></div></div></div>`;
    bd.appendChild(row);
  });
}

export function startPlayerCountAnim() {
  setInterval(() => {
    const e = document.getElementById('pcnt');
    if (e) e.textContent = 247 + Math.floor(Math.random() * 5) - 2;
  }, 3000);
}

/* ==================== NAVIGATION ==================== */
// Each game registers open/close callbacks here
const _onOpen  = {};
const _onClose = {};

export function registerGame(id, onOpen, onClose) {
  _onOpen[id]  = onOpen  || (() => {});
  _onClose[id] = onClose || (() => {});
}

export function openGame(id) {
  document.getElementById('hub').style.display = 'none';
  document.getElementById('overlay-' + id).classList.add('active');
  _onOpen[id]?.();
}

export function closeGame(id) {
  document.getElementById('overlay-' + id).classList.remove('active');
  document.getElementById('hub').style.display = 'block';
  _onClose[id]?.();
}

// Expose to HTML onclick attributes
window.openGame  = openGame;
window.closeGame = closeGame;
