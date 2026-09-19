(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Prefer public GitHub Pages URL when hosted; else LAN for local preview
  const host = location.hostname;
  const isLocal =
    host === "localhost" || host === "127.0.0.1" || host === "[::1]";
  const isPages = host.endsWith("github.io");
  const lanHost = "192.168.0.107";
  const publicOrigin = isLocal
    ? `${location.protocol}//${lanHost}:${location.port || "5500"}`
    : location.origin;
  const siteUrl = isPages
    ? `${location.origin}${location.pathname.replace(/\/index\.html$/, "/").replace(/\/?$/, "/")}`
    : `${publicOrigin}${location.pathname.replace(/\/index\.html$/, "/").replace(/\/?$/, "/")}`;
  const webAppUrl = `${siteUrl}app/`;

  const lanEl = document.getElementById("lan-url");
  if (lanEl) {
    lanEl.textContent = isPages
      ? `Open on any phone: ${siteUrl}`
      : `Open on phone (same Wi‑Fi): ${siteUrl}`;
  }

  const qrImg = document.getElementById("dl-qr");
  const qrTargets = {
    site: siteUrl,
    play: "https://play.google.com/store/apps/details?id=com.nfbot.nfbot_app",
    apple: "https://apps.apple.com/app/nfl-bot",
    web: webAppUrl,
  };
  const qrSrc = (url) =>
    `https://api.qrserver.com/v1/create-qr-code/?size=220x220&bgcolor=0A0908&color=E2C4A4&data=${encodeURIComponent(url)}`;

  if (qrImg) qrImg.src = qrSrc(qrTargets.site);

  document.querySelectorAll(".qr-switch [data-qr]").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".qr-switch [data-qr]").forEach((b) =>
        b.classList.toggle("is-on", b === btn)
      );
      const key = btn.dataset.qr;
      if (qrImg && qrTargets[key]) qrImg.src = qrSrc(qrTargets[key]);
    });
  });

  // Talk animation on mascots
  const talkers = () => document.querySelectorAll("[data-talking]");
  const setTalking = (on) => {
    talkers().forEach((el) => el.classList.toggle("is-talking", on));
    const btn = document.getElementById("make-talk");
    if (btn) {
      btn.innerHTML = on
        ? "<span></span> Bot is talking…"
        : "<span></span> Make Bot talk";
    }
  };
  let talkTimer;
  document.getElementById("make-talk")?.addEventListener("click", () => {
    clearTimeout(talkTimer);
    setTalking(true);
    talkTimer = setTimeout(() => setTalking(false), 3400);
  });
  if (!reduce) {
    setTimeout(() => {
      setTalking(true);
      talkTimer = setTimeout(() => setTalking(false), 2800);
    }, 1600);
    setInterval(() => {
      const active = document.querySelector(".phone.is-active[data-panel='bot']");
      if (!active || document.hidden) return;
      setTalking(true);
      clearTimeout(talkTimer);
      talkTimer = setTimeout(() => setTalking(false), 2400);
    }, 9000);
  }

  // Screen carousel
  const panels = [...document.querySelectorAll(".screens__phones [data-panel]")];
  const tabs = [...document.querySelectorAll("#screen-tabs [data-go]")];
  let idx = 0;
  let locked = false;
  let autoTimer;

  const show = (name) => {
    panels.forEach((p) => p.classList.toggle("is-active", p.dataset.panel === name));
    tabs.forEach((t) => {
      const on = t.dataset.go === name;
      t.classList.toggle("is-on", on);
      t.setAttribute("aria-selected", on ? "true" : "false");
    });
    idx = Math.max(0, panels.findIndex((p) => p.dataset.panel === name));
    if (name === "map") {
      document.querySelectorAll(".count-up").forEach((el) => {
        const target = Number(el.dataset.count || 0);
        const start = performance.now();
        const dur = 900;
        const step = (now) => {
          const t = Math.min(1, (now - start) / dur);
          el.textContent = Math.round(target * (1 - Math.pow(1 - t, 3))).toLocaleString();
          if (t < 1) requestAnimationFrame(step);
        };
        requestAnimationFrame(step);
      });
    }
  };

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      locked = true;
      show(tab.dataset.go);
      clearInterval(autoTimer);
      setTimeout(() => {
        locked = false;
        startAuto();
      }, 12000);
    });
  });

  const startAuto = () => {
    clearInterval(autoTimer);
    if (reduce || panels.length < 2) return;
    autoTimer = setInterval(() => {
      if (locked || document.hidden) return;
      idx = (idx + 1) % panels.length;
      show(panels[idx].dataset.panel);
    }, 4500);
  };

  if (panels.length) {
    show(panels[0].dataset.panel);
    startAuto();
  }

  // Scroll reveals
  const targets = document.querySelectorAll(
    ".story__inner, .guide-step, .guide-loop, .block__intro, .close, .download__grid"
  );
  targets.forEach((el) => el.classList.add("reveal"));
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((en) => {
          if (en.isIntersecting) {
            en.target.classList.add("is-in");
            io.unobserve(en.target);
          }
        });
      },
      { threshold: 0.12 }
    );
    targets.forEach((el) => io.observe(el));
  } else {
    targets.forEach((el) => el.classList.add("is-in"));
  }

  const nav = document.querySelector(".nav");
  window.addEventListener(
    "scroll",
    () => {
      if (!nav) return;
      nav.style.background =
        window.scrollY > 48
          ? "rgba(10, 9, 8, 0.92)"
          : "linear-gradient(to bottom, rgba(10, 9, 8, 0.95), transparent)";
    },
    { passive: true }
  );
})();
