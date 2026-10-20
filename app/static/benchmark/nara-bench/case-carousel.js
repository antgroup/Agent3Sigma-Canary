// Native scrolling with bounded duplicate buffers; no autoplay or scroll interception.
export function setupCaseCarousel(instance) {
  const root = instance.element, rail = root.querySelector('.story-case-rail');
  const track = rail.querySelector('.story-case-track');
  const originals = [...track.children];
  const signal = instance.controller.signal;
  const count = originals.length;
  const modulo = (value,size) => ((value % size) + size) % size;
  let step = 1, period = 1, origin = 0, radius = 0;
  let drag = null, suppressClick = false, frame = null, rebaseFrame = null, settleTimer = null, destination = null;

  function rebase(left) {
    const shift = left - rail.scrollLeft;
    if (Math.abs(shift) < .5) return;
    rail.classList.add('is-rebasing');
    rail.scrollTo({left,behavior:'instant'});
    if(drag)drag.scroll += shift;
    if(destination !== null)destination += shift;
    if(rebaseFrame !== null)window.cancelAnimationFrame(rebaseFrame);
    rebaseFrame = window.requestAnimationFrame(() => {rebaseFrame = null;rail.classList.remove('is-rebasing');});
  }
  function normalize() {
    if (signal.aborted) return;
    rebase(origin + modulo(rail.scrollLeft-origin,period));
  }
  function install() {
    if(signal.aborted)return;
    const logicalPosition = radius ? modulo((rail.scrollLeft-origin) / step,count) : 0;
    step = Math.max(1,(originals[1]?.offsetLeft-originals[0].offsetLeft) || originals[0].offsetWidth);
    period = step * count;
    const nextRadius = Math.max(1,Math.ceil(rail.clientWidth / period));
    if (nextRadius !== radius) {
      const copy = () => originals.map(original => {
        const clone = original.cloneNode(true);
        clone.setAttribute('data-case-clone','');
        clone.setAttribute('aria-hidden','true');
        clone.inert = true;
        return clone;
      });
      const before = [],after = [];
      for(let i=0;i<nextRadius;i++) {before.push(...copy());after.push(...copy());}
      track.replaceChildren(...before,...originals,...after);
      radius = nextRadius;
    }
    origin = originals[0].offsetLeft;
    destination = null;
    rebase(origin + logicalPosition * step);
    schedule();
  }
  function update() {
    frame = null;
    if (signal.aborted) return;
    if(drag?.moved)normalize();
    const index = modulo(Math.round((rail.scrollLeft-origin) / step),count);
    const label = `${index + 1} / ${count}`;
    const counter = root.querySelector('[data-case-count]');
    if(counter.textContent !== label)counter.textContent = label;
    const candidates = [...track.querySelectorAll(`.story-case[data-case-index="${index}"] .story-case-safety`)];
    instance.caseDockAnchor = candidates.reduce((closest,candidate) => {
      const distance = element => {const rect = element.getBoundingClientRect();return Math.abs(rect.left + rect.width/2 - window.innerWidth/2);};
      return !closest || distance(candidate) < distance(closest) ? candidate : closest;
    },null);
    // The word is now on the picture frames while their contents are being read.
    const bounds = rail.getBoundingClientRect();
    root.classList.toggle('story-reading-cases',bounds.top < window.innerHeight && bounds.bottom > 0);
  }
  function schedule() {
    if(frame === null && !signal.aborted)frame = window.requestAnimationFrame(update);
  }
  function settle() {
    clearTimeout(settleTimer);
    settleTimer = setTimeout(() => {if(!drag){normalize();destination = null;}},120);
  }
  function go(direction,instant) {
    if(drag)return;
    const from = destination ?? rail.scrollLeft;
    const index = Math.round((from-origin) / step) + direction;
    let left = origin + index * step;
    const max = rail.scrollWidth-rail.clientWidth;
    if(left < step || left > max-step) {
      // Rebase queued moves before reaching either physical end of the buffers.
      const shift = -Math.floor(index / count) * period;
      rebase(rail.scrollLeft + shift);left += shift;
    }
    destination = left;
    rail.scrollTo({left,behavior:instant || instance.media.matches ? 'instant' : 'smooth'});
    settle();
  }
  root.querySelectorAll('[data-case-direction]').forEach(button => {
    button.disabled = false;
    button.addEventListener('click',event => go(Number(button.dataset.caseDirection),event.detail === 0),{signal});
  });
  rail.addEventListener('keydown',event => {
    if(event.target !== rail || !['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;
    event.preventDefault();
    if(event.key === 'Home' || event.key === 'End') {
      destination = null;rail.scrollTo({left:origin + (event.key === 'Home' ? 0 : count-1)*step,behavior:'instant'});settle();
    } else go(event.key === 'ArrowLeft' ? -1 : 1,true);
  },{signal});
  rail.addEventListener('scroll',() => {schedule();settle();},{passive:true,signal});
  rail.addEventListener('scrollend',() => {if(!drag){normalize();destination = null;}},{signal});
  rail.addEventListener('pointerdown',event => {
    destination = null;
    if(event.pointerType !== 'mouse' || event.button !== 0 || event.target.closest('a,button'))return;
    clearTimeout(settleTimer);
    drag = {x:event.clientX,scroll:rail.scrollLeft,id:event.pointerId,moved:false};
    suppressClick = false;
  },{signal});
  rail.addEventListener('pointermove',event => {
    if(!drag || event.pointerId !== drag.id)return;
    const delta = event.clientX-drag.x;
    if(!drag.moved && Math.abs(delta)<5)return;
    if(!drag.moved){drag.moved = true;rail.setPointerCapture?.(drag.id);rail.classList.add('is-dragging');}
    event.preventDefault();rail.scrollLeft = drag.scroll-delta;
    normalize();schedule();
  },{signal});
  const finish = () => {
    if(!drag)return;
    const completed = drag;drag = null;suppressClick = completed.moved;
    if(rail.hasPointerCapture?.(completed.id))rail.releasePointerCapture(completed.id);
    rail.classList.remove('is-dragging');
    if(!signal.aborted){normalize();schedule();settle();}
  };
  window.addEventListener('pointerup',finish,{signal});
  rail.addEventListener('pointercancel',finish,{signal});
  rail.addEventListener('lostpointercapture',finish,{signal});
  rail.addEventListener('click',event => {if(suppressClick){event.preventDefault();suppressClick = false;}},{capture:true,signal});
  window.addEventListener('scroll',schedule,{passive:true,signal});
  window.addEventListener('resize',install,{passive:true,signal});
  let observer;
  if(window.ResizeObserver){observer = new window.ResizeObserver(install);observer.observe(rail);}
  document.fonts?.ready.then(() => {if(!signal.aborted)install();});
  install();update();
  instance.galleryCleanup = () => {
    finish();clearTimeout(settleTimer);
    if(frame !== null)window.cancelAnimationFrame(frame);
    if(rebaseFrame !== null)window.cancelAnimationFrame(rebaseFrame);
    observer?.disconnect();
    root.classList.remove('story-reading-cases');
    instance.caseDockAnchor = null;
    rail.classList.remove('is-rebasing');
    track.querySelectorAll('[data-case-clone]').forEach(clone=>clone.remove());
  };
}
