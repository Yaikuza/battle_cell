/* dino-memo.js — Dino Memory card-matching game
   Depends on: shared.js (registerGame)
   Edit DINO_EMOJIS to swap card faces.
   Edit DEFAULT_PAIRS / DEFAULT_TIME_SEC to change defaults.
*/

import { registerGame } from './shared.js';

/* ==================== CONSTANTS — edit freely ==================== */

// 64 unique emojis — ธีมไดโนเสาร์ + ธรรมชาติ + space + สัตว์
export const DINO_EMOJIS = [
  // ไดโนเสาร์ & สัตว์ดึกดำบรรพ์
  '🦕','🦖','🦎','🐊','🐉','🦴','🥚','🦷',
  // ธรรมชาติ & ภูมิศาสตร์
  '🌋','🏔️','🌿','🍃','🌊','🪨','🌵','🌴',
  // สัตว์บก
  '🦅','🐢','🦒','🦏','🐘','🦛','🦁','🐆',
  // สัตว์ทะเล
  '🦈','🐋','🦑','🐙','🦀','🐠','🐡','🦞',
  // แมลง & สัตว์เล็ก
  '🦋','🐛','🐜','🪲','🦗','🕷️','🦂','🐝',
  // อวกาศ
  '🌍','🌙','⭐','☄️','🪐','🌞','🔭','🛸',
  // ผลไม้ & อาหาร (ง่ายสำหรับเด็กเล็ก)
  '🍎','🍊','🍋','🍇','🍓','🫐','🍉','🥝',
  // ของเล่น & สนุก
  '🎈','🎯','🎲','🧩','🚀','🎪','🎠','🏆',
];

const DEFAULT_PAIRS    = 6;
const DEFAULT_TIME_SEC = 90;  // 0 = unlimited

/* จำนวน cols และ card size ตามจำนวน pairs
   pairs →  4   6   8  10  12  16  20  24  32  40  48  56  64 */
function gridCols(pairs) {
  if (pairs <=  6) return 4;
  if (pairs <=  8) return 4;
  if (pairs <= 12) return 6;
  if (pairs <= 16) return 8;
  if (pairs <= 20) return 8;
  if (pairs <= 24) return 8;
  if (pairs <= 32) return 8;
  if (pairs <= 48) return 8;
  return 8; // 64 pairs = 128 cards, 8 cols x 16 rows
}

/* ==================== STATE ==================== */
let mCards = [], mFlipped = [], mMatched = 0, mMoves = 0;
let mTimer = null, mTimeLeft = 0, mLocked = false;
let mPairs = DEFAULT_PAIRS, mTimeSetting = DEFAULT_TIME_SEC;

/* ==================== SETTINGS ==================== */
export function setMemoPairs(n) {
  mPairs = n;
  document.querySelectorAll('#opts-pairs .opt-btn')
    .forEach(b => b.classList.toggle('active', +b.dataset.v === n));
}
export function setMemoTime(t) {
  mTimeSetting = t;
  document.querySelectorAll('#opts-time .opt-btn')
    .forEach(b => b.classList.toggle('active', +b.dataset.v === t));
}
export function toggleMemoSettings() {
  document.getElementById('memo-settings').classList.toggle('open');
}
export function closeMemoSettings() {
  document.getElementById('memo-settings').classList.remove('open');
}

/* ==================== INIT ==================== */
function shuffle(a) {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function initMemo() {
  clearInterval(mTimer);
  mFlipped = []; mMatched = 0; mMoves = 0; mLocked = false; mTimeLeft = mTimeSetting;

  document.getElementById('m-moves').textContent = 0;
  document.getElementById('m-pairs').textContent = '0/' + mPairs;
  document.getElementById('m-time').textContent  = mTimeSetting === 0 ? '∞' : mTimeSetting;
  closeMemoSettings();
  document.getElementById('memo-result-box').style.display = 'none';

  const pool = DINO_EMOJIS.slice(0, mPairs);
  mCards = shuffle([...pool, ...pool]);

  /* responsive grid — card เล็กลงอัตโนมัติเมื่อจำนวนมากขึ้น */
  const cols     = gridCols(mPairs);
  const maxW     = Math.min(window.innerWidth - 32, 720);
  const gap      = mPairs <= 20 ? 8 : mPairs <= 40 ? 6 : 4;
  const cardSize = Math.max(36, Math.floor((maxW - (cols - 1) * gap) / cols));
  const fs       = Math.max(14, Math.round(cardSize * 0.45));

  const g = document.getElementById('memo-grid');
  g.style.gridTemplateColumns = `repeat(${cols}, ${cardSize}px)`;
  g.style.gap = gap + 'px';
  g.innerHTML = '';

  mCards.forEach((d, i) => {
    const card = document.createElement('div');
    card.className = 'memo-card';
    card.style.cssText = `width:${cardSize}px;height:${cardSize}px;`;
    card.innerHTML = `<div class="mc-inner"><div class="mc-face" style="font-size:${fs}px">${d}</div><div class="mc-back" style="font-size:${Math.round(fs * .55)}px">?</div></div>`;
    card.onclick = () => flipCard(i, card, d);
    g.appendChild(card);
  });

  /* timer */
  if (mTimeSetting > 0) {
    mTimer = setInterval(() => {
      mTimeLeft--;
      document.getElementById('m-time').textContent = mTimeLeft;
      if (mTimeLeft <= 0) { clearInterval(mTimer); mLocked = true; if (mMatched < mPairs) showMemoResult(false); }
    }, 1000);
  }
}

function flipCard(i, card, d) {
  if (mLocked || card.classList.contains('matched') || card.classList.contains('open')) return;
  if (mFlipped.length >= 2) return;
  if (mFlipped.length === 1 && mFlipped[0].i === i) return; // กันแตะไพ่ใบเดิม 2 ครั้ง

  card.classList.add('open');
  mFlipped.push({ i, card, d });

  if (mFlipped.length === 2) {
    mLocked = true; // lock ทันที ป้องกัน touch เร็วบนมือถือ
    mMoves++;
    document.getElementById('m-moves').textContent = mMoves;
    const [a, b] = mFlipped;
    if (a.d === b.d) {
      mMatched++;
      document.getElementById('m-pairs').textContent = mMatched + '/' + mPairs;
      a.card.classList.add('matched'); b.card.classList.add('matched');
      mFlipped = [];
      mLocked = false; // match แล้ว unlock เลย
      if (mMatched === mPairs) { clearInterval(mTimer); showMemoResult(true); }
    } else {
      setTimeout(() => {
        a.card.classList.remove('open'); b.card.classList.remove('open');
        mFlipped = []; mLocked = false;
      }, 900);
    }
  }
}

function showMemoResult(win) {
  const rb = document.getElementById('memo-result-box');
  rb.style.display = 'block';
  rb.className = 'memo-result ' + (win ? 'win' : 'lose');
  rb.innerHTML = win
    ? `<div class="result-text ok">🎉 เก่งมาก! จับคู่ครบแล้ว!</div><button class="result-btn" onclick="initMemo()">เล่นอีกครั้ง!</button>`
    : `<div class="result-text no">⏰ หมดเวลา! ลองใหม่นะ!</div><button class="result-btn lose-btn" onclick="initMemo()">เล่นอีกครั้ง!</button>`;
}

/* ==================== LIFECYCLE ==================== */
function onOpen()  { initMemo(); }
function onClose() { clearInterval(mTimer); }

/* expose to HTML onclick */
window.initMemo            = initMemo;
window.setMemoPairs        = setMemoPairs;
window.setMemoTime         = setMemoTime;
window.toggleMemoSettings  = toggleMemoSettings;
window.closeMemoSettings   = closeMemoSettings;

registerGame('memo', onOpen, onClose);