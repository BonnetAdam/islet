/* Islet website: the MacBook simulation, its sounds and the code samples. No dependencies but Three.js, vendored. */
(() => {
  "use strict";
  const $ = (s, r = document) => r.querySelector(s);
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const wait = (ms) => new Promise((r) => setTimeout(r, reduce ? Math.min(ms, 60) : ms));

  /* ---------- Words ---------- */
  const EN = {
    allow: "Allow", deny: "Deny", terminal: "Answer in terminal", pushing: "Push the release", working: "Working", done: "Done",
    timeUp: "Time’s up", dropped: "Dropped", agentAsk: "wants to run", allowed: "Allowed from Islet", denied: "Denied from Islet", answered: "Answered in the terminal",
    speakers: "MacBook Speakers", inMin: "in 5 min", meeting: "Design review",
    days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
    short: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], apps: { finder: "Finder", music: "Music", term: "Terminal", cal: "Calendar", timer: "Timer, 10 s", islet: "Islet" }
  };
  const lang = "en";
  const t = (k) => EN[k];
  const onLang = [];

  /* ---------- Code samples ---------- */
  const samples = {
    cli: `<span class="c"># Show a build in the notch, then mark it done</span>\n<span class="k">islet push</span> build --title <span class="s">"Build"</span> --symbol hammer.fill \\\n  --tint orange --progress 40%\n<span class="k">islet done</span> build`,
    agent: `<span class="c"># Connect every AI agent on this Mac, once</span>\n<span class="k">islet hooks install</span> --agent all\n<span class="k">islet hooks status</span>\n  Claude Code  connected\n  Codex        connected\n  Gemini CLI   connected\n  Cursor       connected\n\n<span class="c"># Anything else reports with one line</span>\n<span class="k">islet agent</span> Aider working --message <span class="s">"Refactoring"</span>`,
    socket: `curl --unix-socket \\\n  <span class="s">"$HOME/Library/Application Support/Islet/islet.sock"</span> \\\n  -X POST http://islet/v1/activities \\\n  -d <span class="s">'{"id":"deploy","title":"Deploy","progress":0.6}'</span>`
  };
  let codeKey = "agent";
  const renderCode = () => { $("#codebox").innerHTML = samples[codeKey]; };
  document.querySelectorAll("[data-code]").forEach((b) => b.addEventListener("click", () => {
    codeKey = b.dataset.code; document.querySelectorAll("[data-code]").forEach((x) => x.setAttribute("aria-selected", String(x === b))); renderCode();
  }));
  $("#copy").addEventListener("click", async () => {
    try { await navigator.clipboard.writeText($("#codebox").textContent); } catch (e) { const r = document.createRange(); r.selectNodeContents($("#codebox")); getSelection().removeAllRanges(); getSelection().addRange(r); }
    $("#copy").textContent = "Copied"; setTimeout(() => { $("#copy").textContent = "Copy"; }, 1400);
  });
  renderCode();

  /* ---------- Screen scaling ---------- */
  const stage = $("#stage"), screen = $("#screen");
  let scale = 1;
  const fit = () => { scale = stage.clientWidth / 1440; screen.style.transform = `scale(${scale})`; };
  new ResizeObserver(fit).observe(stage); fit();
  const toScreen = (e) => { const r = stage.getBoundingClientRect(); return { x: (e.clientX - r.left) / scale, y: (e.clientY - r.top) / scale }; };

  /* ---------- Wallpaper: layered dunes of coral light ---------- */
  (function paint() {
    const c = $("#wallpaper").getContext("2d"), W = 1440, H = 900;
    const sky = c.createLinearGradient(0, 0, 0, H);
    sky.addColorStop(0, "#1a0c1f"); sky.addColorStop(.45, "#5a1d2c"); sky.addColorStop(.75, "#c4452f"); sky.addColorStop(1, "#ff9a6b");
    c.fillStyle = sky; c.fillRect(0, 0, W, H);
    const sun = c.createRadialGradient(980, 560, 0, 980, 560, 520);
    sun.addColorStop(0, "rgba(255,214,180,.75)"); sun.addColorStop(.4, "rgba(255,140,100,.35)"); sun.addColorStop(1, "rgba(255,120,80,0)");
    c.fillStyle = sun; c.fillRect(0, 0, W, H);
    const layers = [["#3a1224", 520, 70, .0022], ["#2a0d1d", 610, 60, .0031], ["#1b0914", 700, 50, .0026], ["#10060d", 790, 40, .0035]];
    layers.forEach(([color, base, amp, freq], i) => {
      c.beginPath(); c.moveTo(0, H);
      for (let x = 0; x <= W; x += 8) c.lineTo(x, base + Math.sin(x * freq + i * 1.7) * amp + Math.sin(x * freq * 2.3 + i) * amp * .35);
      c.lineTo(W, H); c.closePath();
      const g = c.createLinearGradient(0, base - amp, 0, H); g.addColorStop(0, color); g.addColorStop(1, "#07030a");
      c.fillStyle = g; c.fill();
    });
    for (let i = 0; i < 90; i++) { c.fillStyle = `rgba(255,255,255,${Math.random() * .5})`; c.fillRect(Math.random() * W, Math.random() * 360, 1.4, 1.4); }
  })();

  /* ---------- Clock ---------- */
  const two = (n) => String(n).padStart(2, "0");
  function tick() {
    const d = new Date(), time = `${two(d.getHours())}:${two(d.getMinutes())}`, days = t("days"), months = t("months");
    $("#clock").textContent = time; $("#lockTime").textContent = time;
    $("#date").textContent = `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`;
    $("#lockDate").textContent = `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`;
    $("#menuclock").textContent = `${t("short")[d.getDay()]} ${d.getDate()} ${months[d.getMonth()].slice(0, 3)}  ${time}`;
    const soon = new Date(d.getTime() + 5 * 60000); $("#ev1t").textContent = `${two(soon.getHours())}:${two(soon.getMinutes())}`; $("#calT1").textContent = `${two(soon.getHours())}:${two(soon.getMinutes())}`;
  }
  setInterval(tick, 10000); onLang.push(tick);

  /* ---------- Sound, all synthesised ---------- */
  let ctx = null, master = null, musicBus = null, analyser = null, volume = 0.5;
  function audio() {
    if (!ctx) {
      const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return null;
      ctx = new AC(); master = ctx.createGain(); master.gain.value = volume * 0.6; master.connect(ctx.destination);
      analyser = ctx.createAnalyser(); analyser.fftSize = 128; analyser.smoothingTimeConstant = .7;
      musicBus = ctx.createGain(); musicBus.gain.value = .85;
      const lp = ctx.createBiquadFilter(); lp.type = "lowpass"; lp.frequency.value = 5200;
      musicBus.connect(lp); lp.connect(analyser); analyser.connect(master);
    }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }
  function tone(f, when, dur, { type = "sine", gain = .2, attack = .005, dest = null, detune = 0 } = {}) {
    const o = ctx.createOscillator(), g = ctx.createGain(); o.type = type; o.frequency.value = f; o.detune.value = detune;
    g.gain.setValueAtTime(0, when); g.gain.linearRampToValueAtTime(gain, when + attack); g.gain.exponentialRampToValueAtTime(.0001, when + dur);
    o.connect(g); g.connect(dest || master); o.start(when); o.stop(when + dur + .05);
  }
  function noiseBurst(when, dur, gain, freq, type = "highpass", dest = null) {
    const b = ctx.createBuffer(1, Math.max(1, ctx.sampleRate * dur), ctx.sampleRate), d = b.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / d.length, 2);
    const s = ctx.createBufferSource(), f = ctx.createBiquadFilter(), g = ctx.createGain(); f.type = type; f.frequency.value = freq; g.gain.value = gain;
    s.buffer = b; s.connect(f); f.connect(g); g.connect(dest || master); s.start(when);
  }
  const sfx = {
    tick() { if (!audio()) return; tone(1400, ctx.currentTime, .04, { gain: .09 }); },
    key() { if (!audio()) return; noiseBurst(ctx.currentTime, .03, .12, 2500, "bandpass"); },
    pop() { if (!audio()) return; const n = ctx.currentTime; tone(620, n, .09, { gain: .1 }); tone(930, n + .025, .08, { gain: .05 }); },
    unlock() { if (!audio()) return; const n = ctx.currentTime; noiseBurst(n, .5, .08, 1800, "bandpass"); tone(880, n + .05, .35, { gain: .06, type: "triangle" }); tone(1318.5, n + .14, .5, { gain: .05, type: "triangle" }); },
    connect() { if (!audio()) return; const n = ctx.currentTime; [659.3, 987.8, 1318.5].forEach((f, i) => tone(f, n + i * .085, 1.1, { gain: .09, type: "sine" })); },
    chime() { if (!audio()) return; const n = ctx.currentTime; [1046.5, 1318.5, 1568].forEach((f, i) => tone(f, n + i * .09, .9, { gain: .08, type: "triangle" })); },
    done() { if (!audio()) return; const n = ctx.currentTime; tone(784, n, .35, { gain: .1, type: "triangle" }); tone(1175, n + .1, .6, { gain: .09, type: "triangle" }); },
    deny() { if (!audio()) return; const n = ctx.currentTime; tone(330, n, .2, { gain: .09, type: "square" }); tone(247, n + .12, .3, { gain: .08, type: "square" }); },
    plug() { if (!audio()) return; const n = ctx.currentTime; tone(523.3, n, .25, { gain: .1 }); tone(784, n + .08, .6, { gain: .1 }); },
    alarm() { if (!audio()) return; const n = ctx.currentTime; for (let i = 0; i < 3; i++) { tone(1568, n + i * .32, .25, { gain: .09, type: "triangle" }); tone(2093, n + i * .32 + .1, .25, { gain: .06, type: "triangle" }); } },
    drop() { if (!audio()) return; const n = ctx.currentTime; tone(420, n, .12, { gain: .12 }); tone(840, n + .06, .2, { gain: .07 }); }
  };

  /* ---------- Music: a lo-fi band, played live ---------- */
  const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);
  const TRACKS = [
    { title: "Low Tide", artist: "The Shallows", bpm: 78, chords: [[53, 57, 60, 64], [52, 55, 59, 62], [50, 53, 57, 60], [48, 52, 55, 59]], art: "linear-gradient(135deg,#ffb38a,#e2472d 55%,#3a1440)", tint: "#ff8a66" },
    { title: "Night Ferry", artist: "The Shallows", bpm: 86, chords: [[57, 60, 64, 67], [53, 57, 60, 64], [48, 52, 55, 59], [55, 59, 62, 65]], art: "linear-gradient(160deg,#7b5cff,#1d1147)", tint: "#9b85ff" },
    { title: "Coral Hours", artist: "Islet Sessions", bpm: 72, chords: [[50, 54, 57, 61], [47, 50, 54, 57], [43, 47, 50, 54], [45, 49, 52, 55]], art: "linear-gradient(145deg,#ffe0b8,#ff7a59 60%,#8a1e3a)", tint: "#ffb27a" },
    { title: "Glass Harbour", artist: "Islet Sessions", bpm: 82, chords: [[48, 52, 55, 59], [45, 48, 52, 55], [53, 57, 60, 64], [55, 59, 62, 65]], art: "linear-gradient(145deg,#9ff5de,#128a7a 60%,#07262b)", tint: "#6ff2d6" },
    { title: "Sand & Static", artist: "The Shallows", bpm: 90, chords: [[52, 55, 59, 62], [48, 52, 55, 59], [50, 53, 57, 60], [47, 50, 53, 57]], art: "linear-gradient(145deg,#f7e8c8,#c49a6c 55%,#3b2a1c)", tint: "#e8c79a" },
    { title: "Afterglow", artist: "Islet Sessions", bpm: 76, chords: [[55, 59, 62, 66], [52, 55, 59, 62], [48, 52, 55, 59], [50, 54, 57, 60]], art: "linear-gradient(145deg,#ff9ad0,#b02d6b 55%,#2a0a20)", tint: "#ff8ac2" }
  ];
  const music = { playing: false, track: 0, step: 0, next: 0, timer: null, started: 0, offset: 0, length: 168 };
  function ep(m, when, dur, gain) {
    // An electric piano: a sine carrier with a decaying bell-like modulator.
    const car = ctx.createOscillator(), mod = ctx.createOscillator(), mg = ctx.createGain(), g = ctx.createGain();
    car.frequency.value = midi(m); mod.frequency.value = midi(m) * 2; mg.gain.setValueAtTime(midi(m) * 1.4, when); mg.gain.exponentialRampToValueAtTime(1, when + .6);
    mod.connect(mg); mg.connect(car.frequency);
    g.gain.setValueAtTime(0, when); g.gain.linearRampToValueAtTime(gain, when + .01); g.gain.exponentialRampToValueAtTime(.0001, when + dur);
    car.connect(g); g.connect(musicBus); car.start(when); mod.start(when); car.stop(when + dur + .1); mod.stop(when + dur + .1);
  }
  function kick(w) { const o = ctx.createOscillator(), g = ctx.createGain(); o.frequency.setValueAtTime(110, w); o.frequency.exponentialRampToValueAtTime(40, w + .2); g.gain.setValueAtTime(.55, w); g.gain.exponentialRampToValueAtTime(.001, w + .32); o.connect(g); g.connect(musicBus); o.start(w); o.stop(w + .35); }
  function schedule() {
    const tr = TRACKS[music.track], s16 = 60 / tr.bpm / 4;
    while (music.next < ctx.currentTime + .25) {
      const s = music.step % 64, bar = Math.floor(s / 16), chord = tr.chords[bar], swing = (s % 2) ? s16 * .18 : 0, w = music.next + swing;
      if (s % 16 === 0) chord.forEach((m, i) => ep(m, w + i * .012, s16 * 14, .045));
      if (s % 16 === 10) chord.slice(1).forEach((m, i) => ep(m + 12, w + i * .01, s16 * 5, .02));
      if (s % 16 === 0 || s % 16 === 7 || s % 16 === 10) kick(w);
      if (s % 8 === 4) noiseBurst(w, .16, .22, 1600, "bandpass", musicBus);
      if (s % 2 === 0) noiseBurst(w, .035, s % 4 ? .05 : .09, 8000, "highpass", musicBus);
      if (s % 8 === 0) tone(midi(chord[0] - 12), w, s16 * 7, { gain: .13, attack: .02, dest: musicBus });
      if ([3, 6, 11, 14].includes(s % 16) && Math.random() > .35) ep(chord[(s + bar) % 4] + 12, w, s16 * 3, .025);
      if (s % 16 === 0) noiseBurst(w, s16 * 16, .012, 3000, "bandpass", musicBus);
      music.step++; music.next += s16;
    }
  }
  function playMusic() { if (!audio()) return; music.playing = true; music.next = ctx.currentTime + .05; music.started = ctx.currentTime - music.offset; clearInterval(music.timer); music.timer = setInterval(schedule, 40); schedule(); mediaChanged(false); }
  function pauseMusic() { music.playing = false; clearInterval(music.timer); music.offset = position(); mediaChanged(false); }
  const position = () => (music.playing && ctx ? (ctx.currentTime - music.started) % music.length : music.offset);
  function changeTrack(delta, absolute) {
    music.track = absolute ?? (music.track + delta + TRACKS.length) % TRACKS.length; music.step = 0; music.offset = 0;
    if (music.playing && ctx) { music.started = ctx.currentTime; music.next = ctx.currentTime + .05; }
    mediaChanged(true);
  }

  /* ---------- The island: the app's outline and its springs ---------- */
  const CX = 720, NOTCH = { w: 190, h: 34 };
  const island = $("#island"), ipath = $("#ipath"), ishadow = $("#ishadow"), iclip = $("#iclip"), hit = $("#hit");
  const OPEN = { w: 520, h: 192, ear: 14, r: 36 };
  const shapeFor = (s, w) => s === "expanded" ? OPEN : s === "peek" ? { w: NOTCH.w + w * 2 + 18, h: NOTCH.h + 5, ear: 6, r: 13 } : { w: NOTCH.w + w * 2, h: NOTCH.h, ear: w ? 6 : 4, r: w ? 12 : 9 };
  function outline(s) {
    const ear = Math.max(0, Math.min(s.ear, s.h / 3)), L = CX - s.w / 2, R = CX + s.w / 2, B = s.h;
    const reach = Math.max(0, Math.min(s.r * 1.28, B - ear, s.w / 2)), hd = reach * .36, f = (n) => n.toFixed(2);
    return `M${f(L - ear)} 0Q${f(L)} 0 ${f(L)} ${f(ear)}L${f(L)} ${f(B - reach)}C${f(L)} ${f(B - hd)} ${f(L + hd)} ${f(B)} ${f(L + reach)} ${f(B)}L${f(R - reach)} ${f(B)}C${f(R - hd)} ${f(B)} ${f(R)} ${f(B - hd)} ${f(R)} ${f(B - reach)}L${f(R)} ${f(ear)}Q${f(R)} 0 ${f(R + ear)} 0Z`;
  }
  const spring = { cur: { ...shapeFor("collapsed", 0) }, vel: { w: 0, h: 0, ear: 0, r: 0 }, target: shapeFor("collapsed", 0), k: 300, c: 25, running: false };
  function setTarget(shape, feel) {
    spring.target = shape;
    const p = { open: [250, .68], close: [340, 1], peek: [380, .6], wing: [320, .8] }[feel] || [320, .8];
    spring.k = p[0]; spring.c = 2 * Math.sqrt(p[0]) * p[1];
    if (reduce) { spring.cur = { ...shape }; draw(); return; }
    if (!spring.running) { spring.running = true; spring.last = performance.now(); requestAnimationFrame(step); }
  }
  function step(now) {
    let dt = Math.min((now - spring.last) / 1000, .05); spring.last = now; let moving = false;
    while (dt > 0) { const h = Math.min(dt, 1 / 240); dt -= h; for (const k of ["w", "h", "ear", "r"]) { const x = spring.cur[k] - spring.target[k]; spring.vel[k] += (-spring.k * x - spring.c * spring.vel[k]) * h; spring.cur[k] += spring.vel[k] * h; } }
    for (const k of ["w", "h", "ear", "r"]) if (Math.abs(spring.cur[k] - spring.target[k]) > .05 || Math.abs(spring.vel[k]) > .05) moving = true;
    if (!moving) spring.cur = { ...spring.target };
    draw(); if (moving) requestAnimationFrame(step); else spring.running = false;
  }
  function draw() { const d = outline(spring.cur); ipath.setAttribute("d", d); ishadow.setAttribute("d", d); iclip.style.clipPath = `path("${d}")`; }

  /* Activities: the highest priority wins, then the most recent. */
  const PRI = { ambient: 0, standard: 1, alert: 2, transient: 3 };
  const board = new Map();
  let wings = 0, state = "collapsed", expiry = null;
  const post = (a) => { a.updated = performance.now(); board.set(a.id, a); refresh(); };
  const removeActivity = (id) => { board.delete(id); refresh(); };
  function current() { const now = performance.now(); let b = null; for (const a of board.values()) { if (a.expires && a.expires <= now) continue; if (!b || PRI[a.pri] > PRI[b.pri] || (PRI[a.pri] === PRI[b.pri] && a.updated > b.updated)) b = a; } return b; }
  const measure = (() => { const c = document.createElement("canvas").getContext("2d"); c.font = "600 13.5px -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif"; return (s) => c.measureText(s).width; })();
  const itemWidth = (i) => !i ? 0 : i.kind === "text" ? Math.min(Math.ceil(measure(i.text)) + 6, 128) : i.kind === "level" ? 50 : i.kind === "battery" ? 29 : 21;
  function refresh() {
    const now = performance.now();
    for (const [id, a] of board) if (a.expires && a.expires <= now) board.delete(id);
    clearTimeout(expiry);
    const next = Math.min(...[...board.values()].filter((a) => a.expires).map((a) => a.expires));
    if (isFinite(next)) expiry = setTimeout(refresh, next - now + 5);
    const a = current(), w = a ? Math.max(itemWidth(a.left), itemWidth(a.right)) + 20 : 0;
    renderSlot($("#slotL"), a && a.left, w, true); renderSlot($("#slotR"), a && a.right, w, false);
    if (w !== wings) { wings = w; if (state !== "expanded") reshape(); }
  }
  const ICON = {
    sparkle: '<svg viewBox="0 0 24 24" fill="#FF7A59"><path d="M12 2.5 14 10l7.5 2L14 14l-2 7.5L10 14l-7.5-2L10 10l2-7.5Z"/></svg>',
    hand: '<svg viewBox="0 0 24 24" fill="#ff9f0a"><path d="M8 11V5a1.5 1.5 0 0 1 3 0v5-7a1.5 1.5 0 0 1 3 0v7-5.5a1.5 1.5 0 0 1 3 0V13l.5-2a1.5 1.5 0 0 1 2.9.8L19 17a6 6 0 0 1-5.8 4.5H12a6 6 0 0 1-5-2.7L4.3 14.6a1.5 1.5 0 0 1 2.5-1.6L8 14.5V11Z"/></svg>',
    check: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#33d666"/><path d="m7.5 12.5 3 3 6-6.5" fill="none" stroke="#000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    cross: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#ff453a"/><path d="m8.5 8.5 7 7m0-7-7 7" stroke="#000" stroke-width="2.4" stroke-linecap="round"/></svg>',
    timer: '<svg viewBox="0 0 24 24" fill="none" stroke="#ff9f0a" stroke-width="2.4" stroke-linecap="round"><circle cx="12" cy="13" r="7.5"/><path d="M12 13V9M10 2.5h4"/></svg>',
    bell: '<svg viewBox="0 0 24 24" fill="#ff9f0a"><path d="M12 3a6 6 0 0 0-6 6v4l-2 3h16l-2-3V9a6 6 0 0 0-6-6Zm-2.5 15a2.5 2.5 0 0 0 5 0h-5Z"/></svg>',
    hammer: '<svg viewBox="0 0 24 24" fill="#ff9f0a"><path d="m14 3 7 7-2.5 2.5L16 10l-9.5 9.5a2 2 0 0 1-3-3L13 7l-1.5-1.5L14 3Z"/></svg>',
    tray: '<svg viewBox="0 0 24 24" fill="#FF7A59"><path d="M4 13h4.5l1.5 2.5h4l1.5-2.5H20v5.5A1.5 1.5 0 0 1 18.5 20h-13A1.5 1.5 0 0 1 4 18.5V13Zm1.7-8.2A1.5 1.5 0 0 1 7.1 4h9.8a1.5 1.5 0 0 1 1.4.8L20 11h-5.5L13 13.5h-2L9.5 11H4l1.7-6.2Z"/></svg>',
    pods: '<svg viewBox="0 0 24 24" fill="#fff"><rect x="3" y="3" width="7" height="8" rx="3.5"/><rect x="5" y="9" width="3" height="11" rx="1.5"/><rect x="14" y="3" width="7" height="8" rx="3.5"/><rect x="16" y="9" width="3" height="11" rx="1.5"/></svg>',
    laptop: '<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"><rect x="4" y="5" width="16" height="11" rx="1.5"/><path d="M2 19h20"/></svg>',
    cal: '<svg viewBox="0 0 24 24" fill="none" stroke="#FF7A59" stroke-width="2.2" stroke-linecap="round"><rect x="3.5" y="5" width="17" height="15" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4"/></svg>',
    sun: '<svg viewBox="0 0 24 24" fill="none" stroke="#ffd60a" stroke-width="2.2" stroke-linecap="round"><circle cx="12" cy="12" r="4" fill="#ffd60a"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8"/></svg>'
  };
  function speaker(v) {
    const w = v <= .001 ? '<path d="m15 9 5 6m0-6-5 6" stroke="#fff" stroke-width="2" stroke-linecap="round"/>' : `<path d="M15.5 9.5a3.5 3.5 0 0 1 0 5" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"/>${v > .34 ? '<path d="M18 7a7 7 0 0 1 0 10" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"/>' : ""}${v > .67 ? '<path d="M20.5 4.8a10 10 0 0 1 0 14.4" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"/>' : ""}`;
    return `<svg viewBox="0 0 24 24"><path d="M3 9.5h3.5L11 5v14l-4.5-4.5H3v-5Z" fill="#fff"/>${w}</svg>`;
  }
  function renderSlot(el, item, w, left) {
    el.style.left = `${CX + (left ? -1 : 1) * (NOTCH.w / 2 + w / 2)}px`;
    const key = item ? JSON.stringify(item) : ""; if (el.dataset.key === key) return; el.dataset.key = key;
    if (!item) { el.innerHTML = ""; return; }
    if (item.kind === "level" && el.querySelector(".lvl")) { el.querySelector(".lvl b").style.width = `${item.value * 100}%`; el.querySelector(".lvl").style.color = item.tint || "#fff"; return; }
    let h = "";
    switch (item.kind) {
      case "icon": h = ICON[item.name]; break;
      case "speaker": h = speaker(item.value); break;
      case "art": h = `<div class="art" style="background:${item.art}"></div>`; break;
      case "eq": h = `<div class="eq" style="color:${item.tint}" id="eq">${"<i></i>".repeat(4)}</div>`; break;
      case "text": h = `<span class="txt" style="color:${item.tint || "#fff"}">${item.text}</span>`; break;
      case "level": h = `<div class="lvl" style="color:${item.tint || "#fff"}"><b style="width:${item.value * 100}%"></b></div>`; break;
      case "spin": h = '<div class="spin"></div>'; break;
      case "battery": h = `<div class="batt"><b style="width:${item.value * 100}%;background:${item.tint || "#33d666"}"></b></div>`; break;
      case "ring": h = `<svg class="ring" viewBox="0 0 20 20"><circle cx="10" cy="10" r="8" stroke="${item.tint}40"/><circle cx="10" cy="10" r="8" stroke="${item.tint}" stroke-dasharray="50.27" stroke-dashoffset="${50.27 * (1 - item.value)}" style="transition:stroke-dashoffset .4s linear"/></svg>`; break;
    }
    el.innerHTML = h;
    if (item.kind === "ring" && item.drain) { const c = el.querySelectorAll("circle")[1]; requestAnimationFrame(() => requestAnimationFrame(() => { c.style.transitionDuration = `${item.drain}s`; c.style.strokeDashoffset = "50.27"; })); }
  }

  /* Opening and closing, as in the app. */
  let inside = false, hoverTimer = null, exitTimer = null, byRequest = false, pending = null, dragging = false;
  function reshape() {
    const s = shapeFor(state, state === "expanded" ? 0 : wings);
    setTarget(s, state === "expanded" ? "open" : state === "peek" ? "peek" : "close");
    island.classList.toggle("open", state === "expanded");
    Object.assign(hit.style, { left: `${CX - s.w / 2 - s.ear - 6}px`, top: "0px", width: `${s.w + 2 * s.ear + 12}px`, height: `${s.h + 8}px`, pointerEvents: state === "expanded" ? "none" : "auto" });
  }
  const setState = (n) => { if (state !== n) { state = n; reshape(); } };
  function open(request) { clearTimeout(hoverTimer); clearTimeout(exitTimer); if (state !== "expanded") { byRequest = !!request; sfx.pop(); } setState("expanded"); }
  const close = () => { byRequest = false; setState("collapsed"); };
  const closeSoon = (ms) => setTimeout(() => { if (!inside && !pending && !dragging) close(); }, ms);
  hit.addEventListener("pointerenter", (e) => { if (e.pointerType === "touch") return; inside = true; byRequest = false; clearTimeout(exitTimer); if (state === "collapsed") { setState("peek"); hoverTimer = setTimeout(() => { if (inside) open(); }, 180); } });
  hit.addEventListener("pointerleave", (e) => { if (e.pointerType === "touch") return; inside = false; clearTimeout(hoverTimer); if (state === "peek") setState("collapsed"); });
  hit.addEventListener("click", () => { audio(); if (state !== "expanded") open(); });
  $("#panel").addEventListener("pointerenter", () => { inside = true; clearTimeout(exitTimer); });
  $("#panel").addEventListener("pointerleave", () => { inside = false; exitTimer = setTimeout(() => { if (!inside && !(byRequest && pending) && !dragging) close(); }, 240); });
  stage.addEventListener("pointerdown", (e) => { if (state === "expanded" && !e.target.closest("#panel") && !dragging) { if (!pending) close(); } });

  /* Pages and tabs */
  const PAGES = [["home", '<path d="M11.3 3.3a1 1 0 0 1 1.4 0l8 7.6c.6.6.2 1.6-.7 1.6H19v7a1.5 1.5 0 0 1-1.5 1.5H15v-6h-6v6H6.5A1.5 1.5 0 0 1 5 19.5v-7H4c-.9 0-1.3-1-.7-1.6l8-7.6Z"/>'], ["shelf", '<path d="M4 13h4.5l1.5 2.5h4l1.5-2.5H20v5.5A1.5 1.5 0 0 1 18.5 20h-13A1.5 1.5 0 0 1 4 18.5V13Zm1.7-8.2A1.5 1.5 0 0 1 7.1 4h9.8a1.5 1.5 0 0 1 1.4.8L20 11h-5.5L13 13.5h-2L9.5 11H4l1.7-6.2Z"/>'], ["live", '<circle cx="12" cy="12" r="2.5"/><path d="M8 8a5.5 5.5 0 0 0 0 8m8-8a5.5 5.5 0 0 1 0 8M5 5a10 10 0 0 0 0 14m14-14a10 10 0 0 1 0 14" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>']];
  $("#tabs").innerHTML = PAGES.map(([p, d]) => `<button class="tab" type="button" data-page="${p}" aria-label="${p}"><svg viewBox="0 0 24 24" fill="currentColor">${d}</svg></button>`).join("");
  let page = "home";
  function showPage(p) {
    page = p;
    const media = music.playing || music.offset > 0;
    $("#pHome").hidden = !(p === "home" && !media); $("#pPlayer").hidden = !(p === "home" && media);
    $("#pLive").hidden = p !== "live"; $("#pShelf").hidden = p !== "shelf"; $("#pPods").hidden = p !== "pods";
    document.querySelectorAll(".tab").forEach((b) => b.classList.toggle("on", b.dataset.page === p || (p === "pods" && b.dataset.page === "home")));
  }
  document.querySelectorAll(".tab").forEach((b) => b.addEventListener("click", () => { sfx.tick(); showPage(b.dataset.page); }));

  /* ---------- Music ---------- */
  $("#albums").innerHTML = TRACKS.map((tr, i) => `<button class="album" type="button" data-track="${i}"><div class="art" style="background:${tr.art}"></div><div>${tr.title}<small>${tr.artist}</small></div></button>`).join("");
  document.querySelectorAll(".album").forEach((b) => b.addEventListener("click", () => { audio(); changeTrack(0, +b.dataset.track); if (!music.playing) playMusic(); }));
  let eqFrame = null;
  function mediaChanged(trackChanged) {
    const tr = TRACKS[music.track], had = board.has("media");
    post({ id: "media", pri: "ambient", left: { kind: "art", art: tr.art }, right: { kind: "eq", tint: tr.tint }, expires: music.playing ? null : performance.now() + 10000 });
    if (had && trackChanged && music.playing) post({ id: "track", pri: "transient", left: { kind: "art", art: tr.art }, right: { kind: "text", text: tr.title }, expires: performance.now() + 3200 });
    $("#cover").style.background = tr.art; $("#cover").style.boxShadow = `0 10px 34px ${tr.tint}88`;
    $("#ttitle").textContent = tr.title; $("#tartist").textContent = tr.artist; $("#tprog").style.background = tr.tint;
    $("#pPlayer").classList.toggle("paused", !music.playing);
    $("#toggleIcon").innerHTML = music.playing ? '<path d="M7 5h3.5v14H7zM13.5 5H17v14h-3.5z"/>' : '<path d="M7 4.5v15l12.5-7.5L7 4.5Z"/>';
    document.querySelectorAll(".album").forEach((b) => b.classList.toggle("on", +b.dataset.track === music.track));
    dockApp("music").toggleAttribute("data-running", music.playing || !$("#wMusic").classList.contains("closed"));
    showPage(page); cancelAnimationFrame(eqFrame); eqFrame = requestAnimationFrame(animateEq);
  }
  const bins = new Uint8Array(64);
  function animateEq() {
    const eq = document.getElementById("eq");
    if (eq) { const bars = eq.children; if (music.playing && analyser) { analyser.getByteFrequencyData(bins); [2, 5, 9, 15].forEach((b, i) => { bars[i].style.height = `${4 + (bins[b] / 255) * 16}px`; }); } else for (const b of bars) b.style.height = "4px"; }
    const pos = position(), fmt = (s) => `${Math.floor(s / 60)}:${two(Math.floor(s % 60))}`;
    $("#tprog").style.width = `${(pos / music.length) * 100}%`; $("#tel").textContent = fmt(pos); $("#trem").textContent = `-${fmt(music.length - pos)}`;
    if (music.playing) eqFrame = requestAnimationFrame(animateEq);
  }
  $("#toggle").addEventListener("click", () => (music.playing ? pauseMusic() : playMusic()));
  $("#next").addEventListener("click", () => changeTrack(1)); $("#prev").addEventListener("click", () => changeTrack(-1));

  /* ---------- Windows and the Dock ---------- */
  const APPS = [
    ["finder", "linear-gradient(180deg,#6ec6ff,#1e7cf0)", '<svg viewBox="0 0 24 24"><rect x="2" y="3" width="20" height="18" rx="4" fill="#fff"/><path d="M12 3v18" stroke="#1e7cf0" stroke-width="1.5"/><circle cx="8" cy="10" r="1.3" fill="#1e7cf0"/><circle cx="16" cy="10" r="1.3" fill="#1e7cf0"/><path d="M7 15q5 3.5 10 0" stroke="#1e7cf0" stroke-width="1.6" fill="none" stroke-linecap="round"/></svg>'],
    ["music", "linear-gradient(160deg,#ff6b8b,#e0245e)", '<svg viewBox="0 0 24 24" fill="#fff"><path d="M9 17.5V6.2l10-2.2v11.3a2.7 2.7 0 1 1-1.6-2.5V7.3L10.6 8.8v8.7A2.7 2.7 0 1 1 9 15v2.5Z"/></svg>'],
    ["term", "linear-gradient(180deg,#3a3d42,#15171a)", '<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m5 8 4 4-4 4M12 16h7"/></svg>'],
    ["cal", "#fff", '<svg viewBox="0 0 24 24"><text x="12" y="8" text-anchor="middle" font-size="5.5" font-weight="700" fill="#ff453a" font-family="-apple-system,sans-serif" id="calDay">SUN</text><text x="12" y="20" text-anchor="middle" font-size="12" font-weight="300" fill="#1c1c1e" font-family="-apple-system,sans-serif" id="calNum">27</text></svg>'],
    ["timer", "linear-gradient(160deg,#ffb340,#ff7a1a)", '<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"><circle cx="12" cy="13" r="7.5"/><path d="M12 13V9M10 2.5h4"/></svg>'],
    ["islet", "#000", '<img src="assets/brand/icon-128.png" alt="">']
  ];
  $("#dock").innerHTML = APPS.map(([id, bg, svg], i) => `${i === 5 ? '<div class="sep"></div>' : ""}<button class="app" type="button" data-app="${id}"><span class="tip" data-tip="${id}"></span><span class="ico" style="background:${bg}">${svg}</span></button>`).join("");
  const dockApp = (id) => $(`.app[data-app="${id}"]`);
  const setTips = () => { document.querySelectorAll("[data-tip]").forEach((el) => { el.textContent = t("apps")[el.dataset.tip]; }); const d = new Date(); $("#calDay").textContent = t("short")[d.getDay()].replace(".", "").toUpperCase().slice(0, 3); $("#calNum").textContent = d.getDate(); };
  onLang.push(setTips);
  // Magnification, like the real Dock.
  const dock = $("#dock");
  dock.addEventListener("pointermove", (e) => { const p = toScreen(e); dock.querySelectorAll(".app").forEach((a) => { const r = a.getBoundingClientRect(), cx = (r.left + r.width / 2 - stage.getBoundingClientRect().left) / scale, d = Math.abs(p.x - cx), s = 60 + Math.max(0, 1 - d / 150) * 26; a.style.width = a.style.height = `${s}px`; }); });
  dock.addEventListener("pointerleave", () => dock.querySelectorAll(".app").forEach((a) => { a.style.width = a.style.height = ""; }));
  let z = 20;
  function openWin(id) { const w = $(id); w.classList.remove("closed"); w.style.zIndex = ++z; }
  function launch(id, fn) { const a = dockApp(id); audio(); if (!a.hasAttribute("data-running")) { a.classList.add("bounce"); setTimeout(() => a.classList.remove("bounce"), 1100); } a.setAttribute("data-running", ""); fn(); }
  document.querySelectorAll(".win").forEach((w) => {
    w.addEventListener("pointerdown", () => { w.style.zIndex = ++z; });
    w.querySelector("[data-close]").addEventListener("click", (e) => { e.stopPropagation(); w.classList.add("closed"); sfx.tick(); });
    const bar = w.querySelector(".bar"); let start = null;
    bar.addEventListener("pointerdown", (e) => { if (e.target.closest(".lights")) return; bar.setPointerCapture(e.pointerId); const p = toScreen(e); start = { x: p.x - w.offsetLeft, y: p.y - w.offsetTop }; });
    bar.addEventListener("pointermove", (e) => { if (!start) return; const p = toScreen(e); w.style.left = `${Math.max(-200, Math.min(1300, p.x - start.x))}px`; w.style.top = `${Math.max(34, Math.min(760, p.y - start.y))}px`; });
    bar.addEventListener("pointerup", () => { start = null; });
  });
  dock.addEventListener("click", (e) => {
    const a = e.target.closest(".app"); if (!a) return;
    ({
      finder: () => launch("finder", () => openWin("#wFinder")),
      music: () => launch("music", () => { openWin("#wMusic"); if (!music.playing) playMusic(); }),
      term: () => launch("term", () => { openWin("#wTerm"); if (!body.children.length) promptLine(); }),
      cal: () => launch("cal", () => { openWin("#wCal"); meetingSoon(); }),
      timer: () => launch("timer", startTimer),
      islet: () => { audio(); if (state === "expanded") close(); else { showPage("home"); open(true); closeSoon(3500); } }
    })[a.dataset.app]();
  });

  /* ---------- Lock screen ---------- */
  const lock = $("#lock");
  let unlocked = false;
  lock.addEventListener("click", async () => {
    if (unlocked) return; unlocked = true; audio(); sfx.unlock(); lock.classList.add("open");
    await wait(900); tour();
  });

  /* ---------- The tour: a short story of the features, until the visitor takes over ---------- */
  let touring = 0;
  const stopTour = () => { touring++; };
  async function tour() {
    const id = ++touring, alive = () => id === touring;
    if (!podsOpen) togglePods();
    await wait(6200); if (!alive()) return;
    await runAgent(); if (!alive()) return;
    await wait(3800); if (alive() && pending) await answer("allow");
    await wait(4200); if (!alive()) return;
    openWin("#wCal"); dockApp("cal").setAttribute("data-running", ""); meetingSoon();
    await wait(4200); if (!alive()) return;
    dockApp("timer").setAttribute("data-running", ""); startTimer();
    await wait(4000); if (!alive()) return;
    if (!charging) plug();
    await wait(3600); if (!alive()) return;
    for (const k of ["vup", "vup", "vup"]) { keyActions[k](); await wait(260); }
  }
  ["pointerdown", "wheel", "keydown"].forEach((ev) => stage.addEventListener(ev, (e) => { if (e.isTrusted && unlocked) stopTour(); }, { capture: true }));
  $("#replay").addEventListener("click", async () => {
    stopTour(); audio();
    document.querySelectorAll(".win").forEach((w) => w.classList.add("closed"));
    if (podsOpen) { podsOpen = false; $("#case3d").classList.remove("open"); }
    if (charging) { charging = false; $("#charger").classList.remove("on"); }
    if (!unlocked) { unlocked = true; lock.classList.add("open"); sfx.unlock(); }
    stage.scrollIntoView({ behavior: reduce ? "auto" : "smooth", block: "center" });
    await wait(700); tour();
  });


  /* ---------- AirPods Pro in real 3D (Three.js), with the CSS drawing as a fallback ---------- */
  const Pods3D = (() => {
    if (!window.THREE) return null;
    const T = window.THREE;
    // Studio lighting baked into an environment map: soft boxes around a dim room, for glossy reflections.
    function environment(renderer) {
      const scene = new T.Scene();
      const room = new T.Mesh(new T.BoxGeometry(60, 40, 60), new T.MeshBasicMaterial({ color: 0x1b1614, side: T.BackSide }));
      scene.add(room);
      const panel = (w, h, x, y, z, ry, intensity, color = 0xffffff) => {
        const m = new T.Mesh(new T.PlaneGeometry(w, h), new T.MeshBasicMaterial({ color: new T.Color(color).multiplyScalar(intensity) }));
        m.position.set(x, y, z); m.rotation.y = ry; m.lookAt(0, 0, 0); scene.add(m);
      };
      panel(30, 8, 0, 19, 0, 0, 3.2);          // overhead strip
      panel(14, 20, -28, 4, 8, 0, 2.2);        // key softbox, left
      panel(10, 16, 28, 2, -6, 0, 1.4, 0xffd8c8); // warm fill, right
      panel(40, 6, 0, -8, -28, 0, .9, 0xff8a66);  // coral bounce behind
      const pmrem = new T.PMREMGenerator(renderer);
      const env = pmrem.fromScene(scene, .04).texture; pmrem.dispose();
      return env;
    }
    function roundedShape(w, h, rTop, rBottom) {
      const s = new T.Shape(), x = -w / 2, y = -h / 2;
      s.moveTo(x + rBottom, y); s.lineTo(x + w - rBottom, y);
      s.absarc(x + w - rBottom, y + rBottom, rBottom, -Math.PI / 2, 0, false);
      s.lineTo(x + w, y + h - rTop); s.absarc(x + w - rTop, y + h - rTop, rTop, 0, Math.PI / 2, false);
      s.lineTo(x + rTop, y + h); s.absarc(x + rTop, y + h - rTop, rTop, Math.PI / 2, Math.PI, false);
      s.lineTo(x, y + rBottom); s.absarc(x + rBottom, y + rBottom, rBottom, Math.PI, Math.PI * 1.5, false);
      return s;
    }
    // Dimensions of the AirPods Pro case, in millimetres: 60.6 wide, 45.2 tall, 21.7 deep.
    const W = 60.6, H = 45.2, D = 21.7, bevel = 6.2, lidH = 15.2, bodyH = H - lidH;
    function extruded(shape) {
      const g = new T.ExtrudeGeometry(shape, { depth: D - bevel * 2, bevelEnabled: true, bevelThickness: bevel, bevelSize: bevel - .4, bevelSegments: 14, curveSegments: 48 });
      g.translate(0, 0, -(D - bevel * 2) / 2); g.computeVertexNormals(); return g;
    }
    function build() {
      const gloss = new T.MeshPhysicalMaterial({ color: 0xf6f6f7, roughness: .22, metalness: 0, clearcoat: 1, clearcoatRoughness: .12, envMapIntensity: 1.1 });
      const satin = new T.MeshPhysicalMaterial({ color: 0xe9e9eb, roughness: .55, metalness: 0, envMapIntensity: .8 });
      const dark = new T.MeshStandardMaterial({ color: 0x1a1a1c, roughness: .6, metalness: .2 });
      const tipMat = new T.MeshStandardMaterial({ color: 0xd8d8db, roughness: .85 });
      const group = new T.Group();
      // Body: rounded at the bottom, flat where the lid closes.
      const inset = bevel - .4;
      const body = new T.Mesh(extruded(roundedShape(W - inset * 2, bodyH - inset, 2.6, 18 - inset)), gloss);
      body.position.y = -H / 2 + (bodyH - inset) / 2 + inset / 2; group.add(body);
      const bodyTop = body.position.y + (bodyH - inset) / 2 + inset;
      // Status light on the front.
      const led = new T.Mesh(new T.CircleGeometry(.9, 24), new T.MeshBasicMaterial({ color: 0x33d666 }));
      led.position.set(0, bodyTop - 7, D / 2 + .05); led.material.transparent = true; led.material.opacity = 0; group.add(led);
      // Wells where the stems go, seen when the lid opens.
      [-12.5, 12.5].forEach((x) => { const hole = new T.Mesh(new T.CircleGeometry(4.2, 32), dark); hole.rotation.x = -Math.PI / 2; hole.scale.set(1.5, 1, 1); hole.position.set(x, bodyTop + .02, 0); group.add(hole); });
      // The earbuds: a head with its black grille and silicone tip, and a short stem.
      const buds = new T.Group(); group.add(buds);
      [-1, 1].forEach((side) => {
        const bud = new T.Group();
        const head = new T.Mesh(new T.SphereGeometry(8.2, 48, 32), gloss); head.scale.set(1, .86, .92); bud.add(head);
        const stem = new T.Mesh(new T.CapsuleGeometry(2.9, 12, 12, 24), gloss); stem.position.set(side * 3.4, -11, -1.5); stem.rotation.z = side * .22; bud.add(stem);
        const grille = new T.Mesh(new T.CircleGeometry(2.4, 24), dark); grille.position.set(-side * 3, 2.2, 7.3); grille.rotation.y = -side * .35; bud.add(grille);
        const tip = new T.Mesh(new T.SphereGeometry(5.4, 32, 24), tipMat); tip.scale.set(.75, .9, .75); tip.position.set(-side * 7.2, 1, 0); bud.add(tip);
        bud.position.set(side * 12.5, bodyTop - 9, 0); bud.rotation.y = side * .5; buds.add(bud);
      });
      // Lid: hinged at the back of the body's top edge.
      const hinge = new T.Group(); hinge.position.set(0, bodyTop, -D / 2 + 1.5); group.add(hinge);
      const lid = new T.Mesh(extruded(roundedShape(W - inset * 2, lidH - inset, 18 - inset, 2.6)), gloss);
      lid.position.set(0, (lidH - inset) / 2 + inset / 2 + .25, D / 2 - 1.5); hinge.add(lid);
      // A soft contact shadow under the case.
      const c = document.createElement("canvas"); c.width = c.height = 128; const g2 = c.getContext("2d");
      const rg = g2.createRadialGradient(64, 64, 0, 64, 64, 64); rg.addColorStop(0, "rgba(0,0,0,.55)"); rg.addColorStop(1, "rgba(0,0,0,0)"); g2.fillStyle = rg; g2.fillRect(0, 0, 128, 128);
      const shadow = new T.Mesh(new T.PlaneGeometry(90, 40), new T.MeshBasicMaterial({ map: new T.CanvasTexture(c), transparent: true, depthWrite: false }));
      shadow.rotation.x = -Math.PI / 2; shadow.position.y = -H / 2 - .5; group.add(shadow);
      return { group, hinge, buds, led, bodyTop, shadow };
    }
    return function create(canvas, { zoom = 1, turntable = false } = {}) {
      const renderer = new T.WebGLRenderer({ canvas, antialias: true, alpha: true });
      renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
      renderer.setSize(canvas.clientWidth || canvas.width / 2, canvas.clientHeight || canvas.height / 2, false);
      renderer.toneMapping = T.ACESFilmicToneMapping; renderer.toneMappingExposure = 1.22; renderer.outputColorSpace = T.SRGBColorSpace;
      const scene = new T.Scene(); scene.environment = environment(renderer);
      const key = new T.DirectionalLight(0xffffff, 1.5); key.position.set(-40, 60, 80); scene.add(key);
      const rim = new T.DirectionalLight(0xffb89c, .8); rim.position.set(60, 20, -60); scene.add(rim);
      scene.add(new T.HemisphereLight(0xffffff, 0x2a1a16, .5));
      const camera = new T.PerspectiveCamera(26, canvas.width / canvas.height, 1, 1000); camera.position.set(0, 32, 190 / zoom); camera.lookAt(0, 2, 0);
      const m = build(); scene.add(m.group);
      const state = { lid: 0, lidV: 0, lidTarget: 0, buds: 0, budsV: 0, budsTarget: 0, yaw: -.5, yawTarget: -.5, yawV: 0, spinUntil: 0, running: false, last: 0 };
      function frame(now) {
        const dt = Math.min((now - state.last) / 1000, .05) || .016; state.last = now;
        const spring = (x, v, target, k, c) => { const a = -k * (x - target) - c * v; v += a * dt; return [x + v * dt, v]; };
        [state.lid, state.lidV] = spring(state.lid, state.lidV, state.lidTarget, 60, 10);
        [state.buds, state.budsV] = spring(state.buds, state.budsV, state.budsTarget, 90, 11);
        if (now < state.spinUntil) state.yawTarget += dt * 2.4;
        [state.yaw, state.yawV] = spring(state.yaw, state.yawV, state.yawTarget, 30, 9);
        m.hinge.rotation.x = -state.lid * 1.9;
        m.buds.position.y = state.buds * 7;
        m.led.material.opacity = Math.min(1, state.lid * 1.4);
        m.group.rotation.y = state.yaw + (turntable ? Math.sin(now / 1800) * .08 : 0);
        m.group.position.y = Math.sin(now / 900) * .6;
        renderer.render(scene, camera);
        const settled = Math.abs(state.lid - state.lidTarget) < .002 && Math.abs(state.lidV) < .002 && Math.abs(state.yaw - state.yawTarget) < .002 && Math.abs(state.yawV) < .002 && now > state.spinUntil;
        if (!settled || turntable) requestAnimationFrame(frame); else state.running = false;
      }
      function wake() { if (!state.running) { state.running = true; state.last = performance.now(); requestAnimationFrame(frame); } }
      canvas.hidden = false;
      wake();
      return {
        open() { state.lidTarget = 1; state.budsTarget = 1; state.yawTarget = -.25; wake(); },
        close() { state.lidTarget = 0; state.budsTarget = 0; state.yawTarget = -.5; wake(); },
        spin(seconds = 1.6) { state.spinUntil = performance.now() + seconds * 1000; state.yawTarget = state.yaw; wake(); setTimeout(() => { state.yawTarget = Math.round(state.yawTarget / (Math.PI * 2)) * Math.PI * 2 - .3; wake(); }, seconds * 1000); },
        stop() { turntable = false; }
      };
    };
  })();
  let deckPods = null, islandPods = null;
  if (Pods3D) {
    try {
      deckPods = Pods3D($("#podsGL"), { zoom: 1.05 });
      $("#case3d").style.display = "none";
    } catch (e) { deckPods = null; }
  }

  /* ---------- AirPods ---------- */
  let podsOpen = false;
  function togglePods() {
    audio(); podsOpen = !podsOpen; $("#case3d").classList.toggle("open", podsOpen);
    if (deckPods) podsOpen ? deckPods.open() : deckPods.close();
    if (podsOpen) {
      setTimeout(() => {
        sfx.connect();
        $("#podRings").innerHTML = [["L", 0.92], ["R", 0.88], ["⌂", 0.64]].map(([l, v]) => `<div class="r"><svg class="ring" viewBox="0 0 20 20" style="width:34px;height:34px"><circle cx="10" cy="10" r="8" stroke="#33d66640"/><circle cx="10" cy="10" r="8" stroke="#33d666" stroke-dasharray="50.27" stroke-dashoffset="${50.27 * (1 - v)}"/></svg>${Math.round(v * 100)}%</div>`).join("");
        if (Pods3D && !islandPods) { try { islandPods = Pods3D($("#podsIslandGL"), { zoom: 1.25, turntable: true }); $("#spin3d").style.display = "none"; islandPods.open(); } catch (e) { islandPods = null; } }
        if (islandPods) islandPods.spin(1.8);
        const spin = $("#spin3d"); spin.style.animation = "none"; void spin.offsetWidth; spin.style.animation = "";
        showPage("pods"); open(true);
        post({ id: "audio.output", pri: "transient", left: { kind: "icon", name: "pods" }, right: { kind: "text", text: "AirPods Pro" }, expires: performance.now() + 4200 });
        setTimeout(() => { if (page === "pods" && !inside) { close(); setTimeout(() => showPage("home"), 400); } }, 3200);
        if (!music.playing) setTimeout(playMusic, 1200);
      }, 650);
    } else {
      sfx.tick(); post({ id: "audio.output", pri: "transient", left: { kind: "icon", name: "laptop" }, right: { kind: "text", text: t("speakers") }, expires: performance.now() + 3000 });
    }
  }
  $("#podsBtn").addEventListener("click", togglePods);

  /* ---------- Charger ---------- */
  let charging = false;
  function plug() {
    audio(); charging = !charging; $("#charger").classList.toggle("on", charging); charging ? sfx.plug() : sfx.tick();
    const pct = "82%";
    post({ id: "power", pri: "transient", left: { kind: "text", text: pct, tint: charging ? "#33d666" : "#fff" }, right: { kind: "battery", value: .82, tint: charging ? "#33d666" : "#fff" }, expires: performance.now() + 3200 });
    $("#mbBolt").setAttribute("opacity", charging ? "1" : "0"); $("#mbFill").setAttribute("fill", charging ? "#33d666" : "#fff"); $("#pctbar").style.background = charging ? "#33d666" : "#fff";
  }
  $("#plugBtn").addEventListener("click", plug);

  /* ---------- Keys: volume and brightness ---------- */
  let bright = 1;
  function setVolume(v, muted) {
    volume = Math.max(0, Math.min(1, Math.round(v * 16) / 16)); if (audio()) master.gain.setTargetAtTime((muted ? 0 : volume) * .6, ctx.currentTime, .02);
    sfx.tick(); post({ id: "hud", pri: "transient", left: { kind: "speaker", value: muted ? 0 : volume }, right: { kind: "level", value: muted ? 0 : volume }, expires: performance.now() + 1600 });
  }
  let muted = false;
  function setBright(v) { bright = Math.max(.25, Math.min(1, Math.round(v * 16) / 16)); $("#dim").style.opacity = String((1 - bright) * .75); sfx.key(); post({ id: "hud", pri: "transient", left: { kind: "icon", name: "sun" }, right: { kind: "level", value: bright, tint: "#ffd60a" }, expires: performance.now() + 1600 }); }
  const keyActions = { vup: () => { muted = false; setVolume(volume + 1 / 16); }, vdown: () => { muted = false; setVolume(volume - 1 / 16); }, mute: () => { muted = !muted; setVolume(volume, muted); }, bup: () => setBright(bright + 1 / 16), bdown: () => setBright(bright - 1 / 16) };
  document.querySelectorAll("[data-key]").forEach((k) => k.addEventListener("click", () => { audio(); keyActions[k.dataset.key](); }));
  let demoVisible = false;
  new IntersectionObserver((e) => { demoVisible = e[0].isIntersecting; }, { threshold: .3 }).observe(stage);
  addEventListener("keydown", (e) => {
    if (!demoVisible) return;
    const map = { ArrowUp: "vup", ArrowDown: "vdown", F12: "vup", F11: "vdown", F10: "mute", F1: "bdown", F2: "bup" };
    const k = map[e.key]; if (!k) return; e.preventDefault(); audio(); keyActions[k]();
    const el = $(`[data-key="${k}"]`); el.classList.add("down"); setTimeout(() => el.classList.remove("down"), 120);
  });

  /* ---------- Timer ---------- */
  let timerEnd = null;
  function startTimer() {
    sfx.tick(); clearTimeout(timerEnd);
    post({ id: "timer", pri: "standard", left: { kind: "icon", name: "timer" }, right: { kind: "ring", tint: "#ff9f0a", value: 1, drain: 10, n: Date.now() } });
    timerEnd = setTimeout(() => { dockApp("timer").removeAttribute("data-running"); sfx.alarm(); post({ id: "timer", pri: "alert", left: { kind: "icon", name: "bell" }, right: { kind: "text", text: t("timeUp"), tint: "#ff9f0a" }, expires: performance.now() + 5000 }); }, 10000);
  }

  /* ---------- Calendar ---------- */
  function meetingSoon() { sfx.chime(); post({ id: "meeting", pri: "standard", left: { kind: "icon", name: "cal" }, right: { kind: "text", text: t("inMin"), tint: "#FF7A59" }, expires: performance.now() + 9000 }); }

  /* ---------- Terminal and agents ---------- */
  const body = $("#termbody");
  let busy = false;
  const print = (h) => { const l = document.createElement("div"); l.innerHTML = h; body.appendChild(l); while (body.children.length > 11) body.firstChild.remove(); };
  const promptLine = () => print('<span class="p">~/islet ❯</span> <span class="caret"></span>');
  async function runCommand(cmd) {
    const last = body.lastChild; if (last && last.querySelector && last.querySelector(".caret")) last.remove();
    const l = document.createElement("div"); l.innerHTML = '<span class="p">~/islet ❯</span> '; const s = document.createElement("span"); l.appendChild(s); body.appendChild(l);
    for (const ch of cmd) { s.textContent += ch; sfx.key(); await wait(26 + Math.random() * 40); }
  }
  async function type(text, cls) { const l = document.createElement("div"); l.className = cls || ""; body.appendChild(l); for (const ch of text) { l.textContent += ch; await wait(12 + Math.random() * 22); } }
  const agent = (kind) => {
    if (kind === "working") post({ id: "agents", pri: "standard", left: { kind: "icon", name: "sparkle" }, right: { kind: "spin" } });
    if (kind === "waiting") post({ id: "agents", pri: "alert", left: { kind: "icon", name: "sparkle" }, right: { kind: "icon", name: "hand" } });
    if (kind === "done") post({ id: "agents", pri: "transient", left: { kind: "icon", name: "sparkle" }, right: { kind: "icon", name: "check" }, expires: performance.now() + 4000 });
    if (kind === "denied") post({ id: "agents", pri: "transient", left: { kind: "icon", name: "sparkle" }, right: { kind: "icon", name: "cross" }, expires: performance.now() + 4000 });
  };
  function renderLive() {
    const el = $("#pLive");
    if (pending) {
      el.innerHTML = `<div class="card"><div class="who">${ICON.hand.replace("<svg", '<svg width="14" height="14"')}<b>islet</b><span>Bash · ${t("pushing")}</span></div><code>git push origin main</code><div class="row"><button class="pill main" type="button" id="allow">${t("allow")}</button><button class="pill" type="button" id="deny">${t("deny")}</button><button class="pill link" type="button" id="interm">${t("terminal")}</button></div></div>`;
      $("#allow").onclick = () => answer("allow"); $("#deny").onclick = () => answer("deny"); $("#interm").onclick = () => answer("ask");
    } else el.innerHTML = `<div class="live-list"><div class="live-item"><span class="dot">${ICON.sparkle}</span><div><b>islet</b><small>${busy ? t("working") : t("done")}</small></div></div></div>`;
  }
  onLang.push(renderLive);
  async function runAgent() {
    if (busy) return; busy = true; body.innerHTML = ""; openWin("#wTerm"); dockApp("term").setAttribute("data-running", "");
    await runCommand('claude "ship the release"'); agent("working"); renderLive();
    await wait(500); await type("✻ Reading CHANGELOG.md", "dim"); await wait(400); await type("✻ Running swift test", "dim");
    await wait(900); print('<span class="ok">  70 tests passed</span>'); await wait(500); await type(`✻ Claude ${t("agentAsk")}: git push origin main`, "warn");
    pending = true; agent("waiting"); renderLive(); showPage("live"); sfx.chime(); open(true);
  }
  async function answer(kind) {
    if (!pending) return; pending = null;
    if (kind === "allow") { sfx.done(); print(`<span class="ok">✓ ${t("allowed")}</span>`); agent("working"); renderLive(); await wait(900); print('<span class="ok">✓ Pushed to origin/main</span>'); busy = false; agent("done"); }
    else if (kind === "deny") { sfx.deny(); print(`<span class="no">✗ ${t("denied")}</span>`); busy = false; agent("denied"); }
    else { sfx.tick(); print(`<span class="dim">${t("answered")}</span>`); busy = false; agent("done"); }
    renderLive(); promptLine(); if (!inside) setTimeout(close, 700);
  }
  async function runPush() {
    if (busy) return; busy = true; await runCommand("islet push build --progress 40%");
    let p = .4; post({ id: "api.build", pri: "standard", left: { kind: "icon", name: "hammer" }, right: { kind: "ring", tint: "#ff9f0a", value: p } });
    while (p < 1) { await wait(360); p = Math.min(1, p + .1); post({ id: "api.build", pri: "standard", left: { kind: "icon", name: "hammer" }, right: { kind: "ring", tint: "#ff9f0a", value: p } }); }
    print('<span class="p">~/islet ❯</span> islet done build'); sfx.done();
    post({ id: "api.build", pri: "transient", left: { kind: "icon", name: "hammer" }, right: { kind: "icon", name: "check" }, expires: performance.now() + 3000 });
    promptLine(); busy = false;
  }
  $("#runAgent").addEventListener("click", runAgent); $("#runPush").addEventListener("click", runPush);

  /* ---------- Files onto the notch ---------- */
  const shelf = $("#shelf");
  const overNotch = (p) => p.y < 110 && Math.abs(p.x - CX) < 230;
  document.querySelectorAll(".desk-item").forEach((item) => {
    let startP = null, origin = null, ghost = null;
    item.addEventListener("pointerdown", (e) => {
      e.preventDefault(); e.stopPropagation(); audio(); dragging = true; item.setPointerCapture(e.pointerId);
      startP = toScreen(e); const r = item.getBoundingClientRect(), sr = stage.getBoundingClientRect();
      origin = { x: (r.left - sr.left) / scale, y: (r.top - sr.top) / scale };
      ghost = item.cloneNode(true); ghost.id = ""; ghost.classList.add("dragging"); Object.assign(ghost.style, { position: "absolute", left: `${origin.x}px`, top: `${origin.y}px`, right: "auto", opacity: ".92", pointerEvents: "none" }); screen.appendChild(ghost);
    });
    item.addEventListener("pointermove", (e) => {
      if (!ghost) return; const p = toScreen(e);
      ghost.style.left = `${origin.x + p.x - startP.x}px`; ghost.style.top = `${origin.y + p.y - startP.y}px`;
      const near = overNotch(p); if (near && state !== "expanded") { showPage("shelf"); open(true); } shelf.classList.toggle("target", near);
    });
    const end = (e) => {
      if (!ghost) return; const p = toScreen(e); dragging = false; shelf.classList.remove("target");
      if (overNotch(p)) {
        ghost.classList.add("gone"); setTimeout(() => ghost.remove(), 400); sfx.drop();
        if (shelf.querySelector(".drop-note")) shelf.innerHTML = "";
        const kind = item.querySelector(".photo") ? '<div class="photo"></div>' : item.querySelector(".doc").outerHTML;
        shelf.insertAdjacentHTML("beforeend", `<div class="tile">${kind}${item.dataset.name}</div>`);
        showPage("shelf"); post({ id: "shelf", pri: "transient", left: { kind: "icon", name: "tray" }, right: { kind: "text", text: t("dropped"), tint: "#FF7A59" }, expires: performance.now() + 2400 });
        closeSoon(1800);
      } else { ghost.remove(); if (byRequest) close(); }
      ghost = null;
    };
    item.addEventListener("pointerup", end); item.addEventListener("pointercancel", end);
  });
  $("#airdrop").addEventListener("click", () => sfx.chime());

  setTips(); tick(); showPage("home"); reshape(); draw(); renderLive(); mediaChanged(false); removeActivity("media");
})();

/* Ruben's own page counter (ruben-analytics): one anonymous page view, no cookie, no identifier, sent as a beacon
   after load so it never slows the page. Nothing is sent from a local copy. */
window.addEventListener("load", () => {
  const host = location.hostname;
  if (!host.endsWith("getislet.vercel.app")) return;
  const endpoint = "https://ruben-analytics.vercel.app/api/hit";
  const body = JSON.stringify({ site: "islet", path: location.pathname, ref: document.referrer });
  try {
    if (!navigator.sendBeacon(endpoint, body)) throw new Error("beacon");
  } catch (e) {
    fetch(endpoint, { method: "POST", body, keepalive: true }).catch(() => {});
  }
});
