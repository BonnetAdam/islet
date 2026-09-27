/* Islet website. Plays the real captures of the island in turn on the hero's screen; a chip shows one and stops the
   tour. Everything is readable without this script. */
(() => {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  for (const mac of document.querySelectorAll('[data-mac]')) mac.setAttribute('data-lid', 'still');

  const shots = [...document.querySelectorAll('[data-demo] .shot[data-state]')];
  const chips = [...document.querySelectorAll('.demo-chips .chip')];
  const caption = document.querySelector('.demo-caption');
  if (!shots.length || !chips.length) return;

  let index = 0;
  let tour = null;
  const show = (i) => {
    index = i;
    const state = chips[i].dataset.state;
    shots.forEach((shot) => shot.classList.toggle('on', shot.dataset.state === state));
    chips.forEach((chip, j) => chip.setAttribute('aria-pressed', String(j === i)));
    if (caption) caption.textContent = chips[i].dataset.caption;
  };
  const start = () => {
    if (reduce || tour) return;
    tour = setInterval(() => show((index + 1) % chips.length), 3600);
  };
  chips.forEach((chip, i) => chip.addEventListener('click', () => {
    clearInterval(tour);
    tour = -1;
    show(i);
  }));
  // The tour waits for the Mac to be on screen, and pauses while the tab is hidden.
  const observer = new IntersectionObserver(([entry]) => { if (entry.isIntersecting && tour === null) start(); });
  observer.observe(document.querySelector('.hero'));
  document.addEventListener('visibilitychange', () => {
    if (tour === -1) return;
    if (document.hidden) { clearInterval(tour); tour = null; } else start();
  });

  // Ruben's own page counter (ruben-analytics): one anonymous page view, no cookie, no identifier, sent only from
  // the published site.
  addEventListener('load', () => {
    if (!location.hostname.endsWith('getislet.vercel.app')) return;
    const endpoint = 'https://ruben-analytics.vercel.app/api/hit';
    const body = JSON.stringify({ site: 'islet', path: location.pathname, ref: document.referrer });
    try { if (!navigator.sendBeacon(endpoint, body)) throw new Error('beacon'); }
    catch { fetch(endpoint, { method: 'POST', body, keepalive: true }).catch(() => {}); }
  });
})();
