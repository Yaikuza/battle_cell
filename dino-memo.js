/* dino-memo.js — Dino Memory card-matching game
   Depends on: shared.js (registerGame)
   Edit DINO_EMOJIS to swap card faces.
   Edit DEFAULT_PAIRS / DEFAULT_TIME_SEC to change defaults.
*/

import { registerGame } from './shared.js';

/* ==================== CONSTANTS — edit freely ==================== */
export const DINO_EMOJIS = ['🦕','🦖','🦎','🐊','🐉','🦴','🥚','🦷','🌋','🏔️','🦅','🐢'];
const DEFAULT_PAIRS    = 6;   // 4 / 6 / 8 / 10 / 12
const DEFAULT_TIME_SEC = 90;  // 0 = unlimited

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
  document.getElementById('memo-result-box').style.display = 'none';

  const pool = DINO_EMOJIS.slice(0, mPairs);
  mCards = shuffle([...pool, ...pool]);

  /* responsive grid */
  const cols     = mPairs <= 6 ? 4 : mPairs <= 10 ? 5 : 6;
  const avail    = Math.min(window.innerWidth, 700) - cols * 8 - 48;
  const cardSize = Math.min(80, Math.floor(avail / cols));
  const fs       = Math.round(cardSize * 0.45);

  const g = document.getElementById('memo-grid');
  g.style.gridTemplateColumns = `repeat(${cols}, ${cardSize}px)`;
  g.innerHTML = '';

  mCards.forEach((d, i) => {
    const card = document.createElement('div');
    card.className = 'memo-card';
    card.style.cssText = `width:${cardSize}px;height:${cardSize}px;`;
    card.innerHTML = `<div class="mc-face" style="font-size:${fs}px">${d}</div><div class="mc-back" style="font-size:${Math.round(fs * .55)}px">?</div>`;
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
  card.classList.add('open');
  mFlipped.push({ i, card, d });

  if (mFlipped.length === 2) {
    mMoves++;
    document.getElementById('m-moves').textContent = mMoves;
    const [a, b] = mFlipped;
    if (a.d === b.d) {
      mMatched++;
      document.getElementById('m-pairs').textContent = mMatched + '/' + mPairs;
      a.card.classList.add('matched'); b.card.classList.add('matched');
      mFlipped = [];
      if (mMatched === mPairs) { clearInterval(mTimer); showMemoResult(true); }
    } else {
      mLocked = true;
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

registerGame('memo', onOpen, onClose);
