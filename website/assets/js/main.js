(() => {
  document.documentElement.classList.add("js");

  const nav = document.getElementById("site-nav");
  const menu = document.querySelector(".menu");
  const greet = document.getElementById("greet");

  if (window.ArnovaSecure) {
    window.ArnovaSecure.hardenExternalLinks(document);
    window.ArnovaSecure.initReveals(document);
  }

  if (greet) {
    const hour = new Date().getHours();
    window.ArnovaSecure
      ? window.ArnovaSecure.text(
          greet,
          hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening",
        )
      : (greet.textContent = hour < 12
          ? "Good morning"
          : hour < 17
            ? "Good afternoon"
            : "Good evening");
  }

  const closeNav = () => {
    if (!nav || !menu) return;
    nav.classList.remove("is-open");
    menu.setAttribute("aria-expanded", "false");
    menu.querySelector(".menu__label").textContent = "Menu";
  };

  if (nav && menu) {
    menu.addEventListener("click", () => {
      const open = menu.getAttribute("aria-expanded") === "true";
      menu.setAttribute("aria-expanded", open ? "false" : "true");
      nav.classList.toggle("is-open", !open);
      menu.querySelector(".menu__label").textContent = open ? "Menu" : "Close";
    });

    nav.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", closeNav);
    });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") closeNav();
    });
  }

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (!reduceMotion && "IntersectionObserver" in window) {
    const rises = Array.from(document.querySelectorAll(".rule, .block, .open, .ledger li"));
    const reveal = (el) => el.classList.add("is-in");
    rises.forEach((el, i) => {
      el.classList.add("rise");
      el.style.setProperty("--rise-delay", `${Math.min(i % 6, 5) * 70}ms`);
    });
    const visibleNow = (el) => {
      const box = el.getBoundingClientRect();
      return box.top < window.innerHeight * 0.92 && box.bottom > 0;
    };
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        reveal(entry.target);
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.08 });
    rises.forEach((el) => {
      if (visibleNow(el)) reveal(el);
      else observer.observe(el);
    });
    window.setTimeout(() => rises.forEach(reveal), 1800);
  }

  /* Parallax ember wash on hero specimen */
  const specimen = document.querySelector(".specimen__screen");
  if (specimen && !reduceMotion) {
    window.addEventListener(
      "pointermove",
      (event) => {
        const x = (event.clientX / window.innerWidth - 0.5) * 8;
        const y = (event.clientY / window.innerHeight - 0.5) * 8;
        specimen.style.transform = `translate3d(${x}px, ${y}px, 0)`;
      },
      { passive: true },
    );
  }

  const signal = document.getElementById("signal");
  const signalState = document.getElementById("signal-state");
  const pause = document.getElementById("signal-pause");
  const reduce = reduceMotion;

  if (!signal || !signalState || !pause) return;

  const states = [
    ["listening", "Listening", "Elvora signal mark, shown listening"],
    ["thinking", "Thinking", "Elvora signal mark, shown thinking"],
    ["speaking", "Speaking", "Elvora signal mark, shown speaking"],
  ];
  let index = 0;
  let timer = 0;

  const apply = (i) => {
    const [name, label, aria] = states[i];
    signal.dataset.state = name;
    signal.setAttribute("aria-label", aria);
    signalState.textContent = label;
  };

  const stop = () => {
    window.clearInterval(timer);
    timer = 0;
  };

  const start = () => {
    stop();
    if (reduce || pause.getAttribute("aria-pressed") === "true") return;
    timer = window.setInterval(() => {
      index = (index + 1) % states.length;
      apply(index);
    }, 3600);
  };

  if (reduce) {
    pause.hidden = true;
    apply(0);
    return;
  }

  pause.addEventListener("click", () => {
    const paused = pause.getAttribute("aria-pressed") === "true";
    pause.setAttribute("aria-pressed", paused ? "false" : "true");
    pause.textContent = paused ? "Pause motion" : "Play motion";
    signal.dataset.paused = paused ? "false" : "true";
    if (paused) start();
    else stop();
  });

  start();
})();
