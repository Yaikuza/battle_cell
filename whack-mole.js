/* whack-mole.js — Whack-a-Mole 5-stage game
   Depends on: shared.js (registerGame)
   Edit STAGES array to tune holes / time / target score / mole speed per stage.
*/

import { registerGame } from './shared.js';

/* ==================== CONSTANTS — edit freely ==================== */
export const STAGES = [
  { holes:4,  time:30, target:10, speed:1200 },
  { holes:6,  time:32, target:14, speed:980  },
  { holes:9,  time:36, target:20, speed:780  },
  { holes:12, time:38, target:26, speed:620  },
  { holes:16, time:42, target:34, speed:480  },
  // ── ADD MORE STAGES HERE ──
  // { holes:20, time:45, target:42, speed:380 },
];

/* ==================== STATE ==================== */
let wStage = 0, wScore = 0, wTimeLeft = 0;
let wRunning = false, wTimer = null, wSpawnTO = null;
let wActiveMoles = new Set();

/* ==================== BUILD UI ==================== */
export function buildStageBtns() {
  const c = document.getElementById('stage-btns'); c.innerHTML = '';
  STAGES.forEach((s, i) => {
    const b = document.createElement('button');
    b.className = 'stage-btn' + (i === wStage ? ' active' : '');
    b.textContent = `ด่าน ${i + 1} (${s.holes} รู)`;
    c.appendChild(b);
  });
}

export function buildWhackGrid() {
  const g = document.getElementById('whack-grid'); g.innerHTML = ''; wActiveMoles.clear();
  const n = STAGES[wStage].holes;

  // cols ที่สอดคล้องกับแต่ละด่าน
  const cols = n <= 4 ? 4 : n <= 6 ? 3 : n <= 9 ? 3 : n <= 12 ? 4 : 4;  // 16 holes → 4x4

  const avail = Math.min(window.innerWidth - 32, 680);
  const gap   = 12;
  const sz    = Math.min(110, Math.floor((avail - (cols - 1) * gap) / cols));

  // จัดกึ่งกลาง: กำหนด width ของ grid ให้พอดีกับ cols
  const gridW = cols * sz + (cols - 1) * gap;
  g.style.width               = gridW + 'px';
  g.style.gridTemplateColumns = `repeat(${cols}, ${sz}px)`;
  g.style.gap                 = gap + 'px';

  for (let i = 0; i < n; i++) {
    const h = document.createElement('div'); h.className = 'hole';
    h.style.cssText = `width:${sz}px;height:${sz}px;`;
    const m = document.createElement('div'); m.className = 'mole-e';
    m.style.fontSize = Math.round(sz * 0.48) + 'px';
    m.textContent = '🐹';
    h.appendChild(m);
    h.onclick = () => {
      if (!wRunning || !wActiveMoles.has(i)) return;
      m.classList.remove('up'); m.classList.add('hit');
      wActiveMoles.delete(i); wScore++;
      document.getElementById('w-score').textContent = wScore;
      setTimeout(() => m.classList.remove('hit'), 200);
    };
    g.appendChild(h);
  }
}

/* ==================== INIT ==================== */
export function initWhack() {
  wStage = 0; wScore = 0; wRunning = false;
  document.getElementById('w-score').textContent = 0;
  document.getElementById('w-stage').textContent = 1;
  document.getElementById('w-result-box').style.display = 'none';
  document.getElementById('w-start-btn').style.display  = 'block';
  buildStageBtns(); buildWhackGrid();
}

/* ==================== GAMEPLAY ==================== */
export function startWhack() {
  wRunning = true; wScore = 0; wActiveMoles.clear();
  const s = STAGES[wStage]; wTimeLeft = s.time;
  document.getElementById('w-score').textContent  = 0;
  document.getElementById('w-left').textContent   = wTimeLeft;
  document.getElementById('w-target').textContent = s.target;
  document.getElementById('w-result-box').style.display = 'none';
  document.getElementById('w-start-btn').style.display  = 'none';
  buildWhackGrid();
  wTimer = setInterval(() => {
    wTimeLeft--;
    document.getElementById('w-left').textContent = wTimeLeft;
    if (wTimeLeft <= 0) endWhack();
  }, 1000);
  doSpawn();
}

function doSpawn() {
  if (!wRunning) return;
  const s     = STAGES[wStage];
  const holes = document.querySelectorAll('#whack-grid .hole');
  const avail = [];
  holes.forEach((_, i) => { if (!wActiveMoles.has(i)) avail.push(i); });
  if (avail.length > 0) {
    const idx = avail[Math.floor(Math.random() * avail.length)];
    wActiveMoles.add(idx);
    const m = holes[idx]?.querySelector('.mole-e');
    if (m) {
      m.classList.add('up');
      setTimeout(() => {
        if (m.classList.contains('up')) { m.classList.remove('up'); setTimeout(() => wActiveMoles.delete(idx), 150); }
      }, s.speed * .65);
    }
  }
  wSpawnTO = setTimeout(doSpawn, Math.max(150, s.speed * .38 + Math.random() * s.speed * .28));
}

function endWhack() {
  wRunning = false; clearInterval(wTimer); clearTimeout(wSpawnTO);
  document.querySelectorAll('#whack-grid .mole-e').forEach(m => m.classList.remove('up'));
  wActiveMoles.clear();
  const s   = STAGES[wStage];
  const win = wScore >= s.target;
  const rb  = document.getElementById('w-result-box');
  rb.style.display = 'block';
  rb.className = 'whack-result ' + (win ? 'w-win' : 'w-lose');

  if (win) {
    document.querySelectorAll('#stage-btns .stage-btn')[wStage]?.classList.add('cleared');
    const nxt = wStage + 1;
    rb.innerHTML =
      `<div class="wrt ok">🎉 ผ่านด่าน ${wStage + 1}! ตี ${wScore} ตุ่น!</div>` +
      (nxt < STAGES.length
        ? `<button class="wrb" onclick="goNextStage(${nxt})">ด่านต่อไป ➡</button>`
        : `<div style="color:#FFD600;font-size:18px;font-weight:900;font-family:'Nunito';margin:8px 0">🏆 ชนะทุกด่าน!</div>`) +
      `<button class="wrb" onclick="initWhack()">เริ่มใหม่</button>`;
  } else {
    rb.innerHTML =
      `<div class="wrt no">ตี ${wScore}/${s.target} ไม่พอ!</div>` +
      `<button class="wrb" onclick="startWhack()">ลองใหม่</button>` +
      `<button class="wrb" onclick="initWhack()">เลือกด่าน</button>`;
  }
}

export function goNextStage(n) {
  wStage = n;
  wScore = 0; wRunning = false;
  clearInterval(wTimer); clearTimeout(wSpawnTO);
  wActiveMoles.clear();
  document.getElementById('w-score').textContent  = 0;
  document.getElementById('w-stage').textContent  = n + 1;
  document.getElementById('w-left').textContent   = STAGES[n].time;
  document.getElementById('w-target').textContent = STAGES[n].target;
  document.getElementById('w-result-box').style.display = 'none';
  document.getElementById('w-start-btn').style.display  = 'block';
  buildStageBtns();
  buildWhackGrid();
}

/* ==================== LIFECYCLE ==================== */
function stopWhack() { wRunning = false; clearInterval(wTimer); clearTimeout(wSpawnTO); }

/* expose to HTML onclick */
window.initWhack    = initWhack;
window.startWhack   = startWhack;
window.goNextStage  = goNextStage;
window.addEventListener('resize', () => { if (!wRunning) buildWhackGrid(); });

registerGame('whack', initWhack, stopWhack);