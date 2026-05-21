/* virtual-joystick.js — wires the on-screen joystick to battle-cell.js
   Depends on: battle-cell.js (setVjInput)
*/

import { setVjInput } from './battle-cell.js';

const vjZone  = document.getElementById('vj-zone');
const vjStick = document.getElementById('vj-stick');
const VJ_R    = 55;   // radius of the zone in px
const STICK_R = 20;   // radius of the stick thumb

let vjActive = false, vjId = -1, vjOrigin = { x: 0, y: 0 };

function center() {
  vjStick.style.left = (VJ_R - STICK_R) + 'px';
  vjStick.style.top  = (VJ_R - STICK_R) + 'px';
  setVjInput({ x: 0, y: 0, active: false });
}
center();

vjZone.addEventListener('touchstart', e => {
  e.preventDefault();
  vjActive = true; vjId = e.touches[0].identifier;
  const r = vjZone.getBoundingClientRect();
  vjOrigin = { x: r.left + VJ_R, y: r.top + VJ_R };
}, { passive: false });

document.addEventListener('touchmove', e => {
  if (!vjActive) return;
  for (const t of e.touches) {
    if (t.identifier !== vjId) continue;
    const dx = t.clientX - vjOrigin.x, dy = t.clientY - vjOrigin.y;
    const d  = Math.hypot(dx, dy);
    const cl = Math.min(d, VJ_R - STICK_R);
    const nx = d === 0 ? 0 : dx / d, ny = d === 0 ? 0 : dy / d;
    vjStick.style.left = (VJ_R - STICK_R + nx * cl) + 'px';
    vjStick.style.top  = (VJ_R - STICK_R + ny * cl) + 'px';
    setVjInput({ x: nx * (cl / (VJ_R - STICK_R)), y: ny * (cl / (VJ_R - STICK_R)), active: true });
  }
}, { passive: false });

document.addEventListener('touchend', e => {
  for (const t of e.changedTouches)
    if (t.identifier === vjId) { vjActive = false; center(); }
});
