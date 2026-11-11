// Pages d'accueil qutebrowser : graphe réseau du portfolio (nœuds, liens, paquets), texte tapé à la machine, horloge.
// Animation plafonnée à 20 images/s, mouvement calculé en temps réel, à l'arrêt quand l'onglet est caché.
(() => {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const $ = id => document.getElementById(id);

  // ---- graphe réseau ----
  const cv = $('net'), ctx = cv.getContext('2d');
  const O = { maxNodes: 90, area: 16000, link: 150, speed: 7.5, fps: 20, maxPackets: 12, rate: 0.036 };
  const mouse = { x: -999, y: -999 };
  let w = 0, h = 0, nodes = [], packets = [], last = 0, timer = 0, raf = 0;
  function resize() {
    w = innerWidth; h = innerHeight; cv.width = w; cv.height = h;      // 1 px CSS = 1 px : un fond doux n'a pas besoin de plus
    const n = Math.round(Math.min(O.maxNodes, w * h / O.area));
    nodes = Array.from({ length: n }, () => ({ x: Math.random() * w, y: Math.random() * h,
      vx: (Math.random() - 0.5) * 2 * O.speed, vy: (Math.random() - 0.5) * 2 * O.speed, r: Math.random() * 1.6 + 0.8 }));
    packets = [];
  }
  function draw(dt) {
    ctx.clearRect(0, 0, w, h);
    for (const n of nodes) {
      n.x += n.vx * dt; n.y += n.vy * dt;
      if (n.x < 0 || n.x > w) { n.vx *= -1; n.x = Math.max(0, Math.min(w, n.x)); }
      if (n.y < 0 || n.y > h) { n.vy *= -1; n.y = Math.max(0, Math.min(h, n.y)); }
    }
    ctx.lineWidth = 0.8; ctx.strokeStyle = '#7d8898';
    for (let i = 0; i < nodes.length; i++) for (let j = i + 1; j < nodes.length; j++) {
      const a = nodes[i], b = nodes[j], dx = a.x - b.x;
      if (dx > O.link || dx < -O.link) continue;
      const d = Math.hypot(dx, a.y - b.y);
      if (d >= O.link) continue;
      ctx.globalAlpha = (1 - d / O.link) * 0.5;
      ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
      if (packets.length < O.maxPackets && Math.random() < O.rate * dt) packets.push({ a, b, t: 0 });
    }
    packets = packets.filter(p => (p.t += 0.72 * dt) < 1 && Math.hypot(p.a.x - p.b.x, p.a.y - p.b.y) < O.link);
    ctx.globalAlpha = 0.9; ctx.fillStyle = '#00e5ff';
    for (const p of packets) { ctx.beginPath(); ctx.arc(p.a.x + (p.b.x - p.a.x) * p.t, p.a.y + (p.b.y - p.a.y) * p.t, 2, 0, 7); ctx.fill(); }
    for (const n of nodes) {
      const near = Math.hypot(n.x - mouse.x, n.y - mouse.y) < 120;
      ctx.globalAlpha = near ? 1 : 0.7; ctx.fillStyle = near ? '#00ff9c' : '#7d8898';
      ctx.beginPath(); ctx.arc(n.x, n.y, near ? n.r + 1 : n.r, 0, 7); ctx.fill();
    }
    ctx.globalAlpha = 1;
  }
  // une minuterie par image voulue, puis un seul requestAnimationFrame (pas de boucle à la fréquence de l'écran)
  function frame(now) { draw(Math.min(now - last, 250) / 1000); last = now; timer = setTimeout(() => { raf = requestAnimationFrame(frame); }, 1000 / O.fps - 4); }
  function run() { cancelAnimationFrame(raf); clearTimeout(timer); if (reduced || document.hidden) return; last = performance.now(); raf = requestAnimationFrame(frame); }
  let rt; addEventListener('resize', () => { clearTimeout(rt); rt = setTimeout(() => { resize(); draw(0); }, 150); });
  addEventListener('pointermove', e => { mouse.x = e.clientX; mouse.y = e.clientY; });
  document.addEventListener('visibilitychange', run);
  resize(); draw(0); run();

  // ---- machine à écrire (mêmes temps que le portfolio) ----
  const typed = $('typed'), words = (typed.dataset.words || '').split('|').map(s => s.trim()).filter(Boolean);
  if (words.length) typed.textContent = words[0];
  if (words.length > 1 && !reduced) {
    let wi = 0, i = words[0].length, erasing = true;
    const tick = () => {
      const word = words[wi]; i += erasing ? -1 : 1; typed.textContent = word.slice(0, i);
      let wait = erasing ? 35 : 70;
      if (!erasing && i === word.length) { erasing = true; wait = 2200; }
      else if (erasing && i === 0) { erasing = false; wi = (wi + 1) % words.length; wait = 300; }
      setTimeout(tick, wait);
    };
    setTimeout(tick, 2400);
  }

  // ---- horloge du pied de page ----
  const clock = $('clock');
  const tickClock = () => { const d = new Date();
    clock.textContent = d.toLocaleTimeString('fr-FR') + '  ·  UTC ' + d.toISOString().slice(11, 16) + '  ·  ' + d.toLocaleDateString('fr-FR', { weekday: 'short', day: '2-digit', month: 'short' }); };
  tickClock(); setInterval(tickClock, 1000);

  requestAnimationFrame(() => document.body.classList.add('ready'));
  // « / » ou toute lettre hors champ : rien de spécial, qutebrowser garde ses raccourcis ; Tab donne le focus à la recherche.
})();
