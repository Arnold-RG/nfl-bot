(() => {
  const mark = document.getElementById('coach-signal');
  if (!mark) return;

  const states = ['listening', 'thinking', 'speaking', 'listening'];
  let i = 0;
  setInterval(() => {
    i = (i + 1) % states.length;
    mark.dataset.state = states[i];
    mark.style.setProperty('--pulse', states[i] === 'speaking' ? '1.06' : '1');
  }, 2200);

  // Soft scroll for in-page anchors
  document.querySelectorAll('a[href^="#"]').forEach((a) => {
    a.addEventListener('click', (e) => {
      const id = a.getAttribute('href');
      if (!id || id === '#') return;
      const el = document.querySelector(id);
      if (!el) return;
      e.preventDefault();
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
  });
})();
