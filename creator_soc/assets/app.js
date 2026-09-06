/**
 * NFL BOT · Creator SOC — seeded mock ops data + UI
 * Standalone; no Flutter dependency. Linked to member app by URL only.
 */
(function () {
  "use strict";

  // —— Config: member app URL (local Flutter web or build output) ——
  const MEMBER_APP_URL =
    window.NFLBOT_MEMBER_APP_URL ||
    (location.hostname === "localhost" || location.hostname === "127.0.0.1"
      ? "http://localhost:8080"
      : "../build/web/index.html");

  // —— Seeded PRNG for stable mock data ——
  function mulberry32(a) {
    return function () {
      let t = (a += 0x6d2b79f5);
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  const rnd = mulberry32(20260906);

  function pick(arr) {
    return arr[Math.floor(rnd() * arr.length)];
  }

  function randInt(min, max) {
    return min + Math.floor(rnd() * (max - min + 1));
  }

  // —— Mock datasets ——
  const FIRST = [
    "Adam", "Kasia", "Marek", "Ola", "Tomek", "Ania", "Piotr", "Natalia",
    "Jakub", "Zuzanna", "Bartek", "Magda", "Krzysztof", "Ewa", "Michał",
    "Julia", "Paweł", "Karolina", "Łukasz", "Weronika",
  ];
  const LAST = [
    "Kowalski", "Nowak", "Wiśniewski", "Wójcik", "Kowalczyk", "Kamiński",
    "Lewandowski", "Zieliński", "Szymański", "Woźniak", "Dąbrowski",
    "Kozłowski", "Jankowski", "Mazur", "Kwiatkowski",
  ];
  const COUNTRIES = [
    { code: "PL", name: "Poland", weight: 42 },
    { code: "DE", name: "Germany", weight: 18 },
    { code: "UK", name: "United Kingdom", weight: 12 },
    { code: "US", name: "United States", weight: 10 },
    { code: "CZ", name: "Czechia", weight: 8 },
    { code: "NL", name: "Netherlands", weight: 5 },
    { code: "SE", name: "Sweden", weight: 5 },
  ];
  const PLANS = ["Free", "Pro", "Ultra"];

  function weightedCountry() {
    const total = COUNTRIES.reduce((s, c) => s + c.weight, 0);
    let r = rnd() * total;
    for (const c of COUNTRIES) {
      r -= c.weight;
      if (r <= 0) return c;
    }
    return COUNTRIES[0];
  }

  function weightedPlan() {
    const r = rnd();
    if (r < 0.62) return "Free";
    if (r < 0.88) return "Pro";
    return "Ultra";
  }

  function relativeActive() {
    const mins = randInt(2, 60 * 72);
    if (mins < 60) return `${mins}m ago`;
    if (mins < 1440) return `${Math.floor(mins / 60)}h ago`;
    return `${Math.floor(mins / 1440)}d ago`;
  }

  const users = Array.from({ length: 48 }, (_, i) => {
    const country = weightedCountry();
    return {
      id: `u_${1000 + i}`,
      name: `${pick(FIRST)} ${pick(LAST)}`,
      country: country.code,
      countryName: country.name,
      plan: weightedPlan(),
      lastActive: relativeActive(),
      lastActiveSort: rnd(),
    };
  }).sort((a, b) => a.lastActiveSort - b.lastActiveSort);

  const foods = [
    { barcode: "5901234123457", name: "Jogurt naturalny 2%", brand: "Mlekovita", kcal: 60, protein: 5.2, unit: "100g" },
    { barcode: "5900820001234", name: "Pierś z kurczaka", brand: "Sokołów", kcal: 110, protein: 23.0, unit: "100g" },
    { barcode: "4008400401124", name: "Owsianka Instant", brand: "Quaker", kcal: 367, protein: 13.0, unit: "100g" },
    { barcode: "5900397001123", name: "Banan świeży", brand: "—", kcal: 89, protein: 1.1, unit: "100g" },
    { barcode: "5906485100015", name: "Whey Protein Isolate", brand: "KFD", kcal: 370, protein: 85.0, unit: "100g" },
    { barcode: "5901234567890", name: "Ryż basmati", brand: "Kupiec", kcal: 350, protein: 7.5, unit: "100g" },
    { barcode: "3045320012345", name: "Tofu naturalne", brand: "Vemondo", kcal: 120, protein: 12.0, unit: "100g" },
    { barcode: "5900987654321", name: "Jajko kurze L", brand: "Fermy", kcal: 155, protein: 12.6, unit: "100g" },
    { barcode: "5902222333444", name: "Masło orzechowe", brand: "GoOn", kcal: 588, protein: 25.0, unit: "100g" },
    { barcode: "5901111222333", name: "Łosoś wędzony", brand: "Suempol", kcal: 180, protein: 22.0, unit: "100g" },
    { barcode: "5903333444555", name: "Chleb żytni", brand: "Putka", kcal: 230, protein: 6.8, unit: "100g" },
    { barcode: "5904444555666", name: "Ser twarogowy chudy", brand: "Piątnica", kcal: 97, protein: 18.0, unit: "100g" },
  ];

  const exercises = [
    { name: "Barbell Back Squat", muscle: "Quads", equipment: "Barbell" },
    { name: "Romanian Deadlift", muscle: "Hamstrings", equipment: "Barbell" },
    { name: "Bench Press", muscle: "Chest", equipment: "Barbell" },
    { name: "Pull-Up", muscle: "Lats", equipment: "Bodyweight" },
    { name: "Overhead Press", muscle: "Shoulders", equipment: "Barbell" },
    { name: "Dumbbell Row", muscle: "Back", equipment: "Dumbbell" },
    { name: "Leg Press", muscle: "Quads", equipment: "Machine" },
    { name: "Cable Face Pull", muscle: "Rear delts", equipment: "Cable" },
    { name: "Hip Thrust", muscle: "Glutes", equipment: "Barbell" },
    { name: "Walking Lunge", muscle: "Legs", equipment: "Dumbbell" },
    { name: "Plank", muscle: "Core", equipment: "Bodyweight" },
    { name: "Farmer Carry", muscle: "Grip / Core", equipment: "Dumbbell" },
  ];

  const challengesSeed = [
    {
      id: "ch_01",
      title: "7-day protein streak",
      goal: "Hit protein target 7 days",
      starts: "2026-09-01",
      ends: "2026-09-07",
      enrolled: 1240,
      status: "Active",
    },
    {
      id: "ch_02",
      title: "Voice check-in week",
      goal: "Log 5 voice turns",
      starts: "2026-09-05",
      ends: "2026-09-12",
      enrolled: 680,
      status: "Active",
    },
    {
      id: "ch_03",
      title: "Plate scan marathon",
      goal: "Scan 10 meals",
      starts: "2026-08-20",
      ends: "2026-08-31",
      enrolled: 2104,
      status: "Ended",
    },
  ];

  const flags = [
    {
      id: "flg_8841",
      type: "ai_safety",
      user: "u_1023",
      detail: "Medical advice deflection triggered (weight-loss extreme)",
      status: "Open",
      created: "2026-09-06 01:12",
    },
    {
      id: "flg_8838",
      type: "content",
      user: "u_1007",
      detail: "Reported inaccurate plate scan macros",
      status: "In review",
      created: "2026-09-05 22:41",
    },
    {
      id: "flg_8829",
      type: "billing",
      user: "u_1041",
      detail: "Double charge on Pro monthly — refund pending",
      status: "Open",
      created: "2026-09-05 18:05",
    },
    {
      id: "flg_8812",
      type: "ai_safety",
      user: "u_1015",
      detail: "Self-harm phrase filter — conversation blocked",
      status: "Resolved",
      created: "2026-09-04 14:22",
    },
    {
      id: "flg_8801",
      type: "abuse",
      user: "u_1033",
      detail: "Spam voice turns from automation script",
      status: "Resolved",
      created: "2026-09-03 09:50",
    },
  ];

  // KPIs (snapshot)
  const kpis = {
    members: 18420,
    activeToday: 3128,
    voiceTurns: 48210,
    plateScans: 19640,
    workouts: 8742,
    mrr: 42850,
    aiRequests: 91200,
    safetyFlags: 14,
  };

  // Voice by hour (0–23), peak evening
  const voiceByHour = Array.from({ length: 24 }, (_, h) => {
    const base =
      h < 6 ? 40 + rnd() * 60 : h < 12 ? 180 + rnd() * 220 : h < 18 ? 320 + rnd() * 280 : 400 + rnd() * 350;
    return Math.round(base);
  });

  // Signups by region
  const signupsByRegion = [
    { name: "Poland", count: 842 },
    { name: "Germany", count: 312 },
    { name: "UK", count: 198 },
    { name: "USA", count: 156 },
    { name: "Czechia", count: 94 },
    { name: "Other", count: 128 },
  ];

  // Plan mix
  const planMix = { Free: 11420, Pro: 4980, Ultra: 2020 };

  // Event feed types
  const EVENT_TYPES = [
    "voice_turn",
    "plate_scan",
    "workout_complete",
    "subscribe",
    "watch_pair",
    "ai_error",
  ];

  function eventMessage(type) {
    const u = pick(users);
    switch (type) {
      case "voice_turn":
        return { user: u.name, text: `Voice turn · “${pick(["ile białka dziś", "co na obiad", "log training", "ile kcal zostało"])}”` };
      case "plate_scan":
        return { user: u.name, text: `Plate scan · ${pick(foods).name} · conf ${randInt(72, 98)}%` };
      case "workout_complete":
        return { user: u.name, text: `Workout done · ${pick(exercises).name} · ${randInt(25, 75)} min` };
      case "subscribe":
        return { user: u.name, text: `Subscribed · ${pick(["Pro", "Ultra"])} monthly` };
      case "watch_pair":
        return { user: u.name, text: `Watch paired · ${pick(["Apple Watch", "Galaxy Watch", "Garmin", "Wear OS"])}` };
      case "ai_error":
        return { user: u.name, text: `AI error · ${pick(["timeout 8s", "rate limit", "empty vision response", "tool schema mismatch"])}` };
      default:
        return { user: u.name, text: type };
    }
  }

  function pad(n) {
    return String(n).padStart(2, "0");
  }

  function formatTime(d) {
    return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  }

  function buildInitialFeed(n) {
    const now = Date.now();
    const items = [];
    for (let i = 0; i < n; i++) {
      const type = pick(EVENT_TYPES);
      // bias fewer ai_errors
      const t = type === "ai_error" && rnd() > 0.25 ? pick(EVENT_TYPES.filter((x) => x !== "ai_error")) : type;
      const when = new Date(now - i * randInt(8, 95) * 1000);
      const msg = eventMessage(t);
      items.push({ type: t, time: formatTime(when), ...msg });
    }
    return items;
  }

  let feed = buildInitialFeed(28);
  let challenges = challengesSeed.slice();

  // —— Formatting ——
  function fmt(n) {
    return n.toLocaleString("pl-PL");
  }

  function fmtZł(n) {
    return `${fmt(n)} zł`;
  }

  // —— DOM helpers ——
  function $(sel, root) {
    return (root || document).querySelector(sel);
  }

  function $$(sel, root) {
    return Array.from((root || document).querySelectorAll(sel));
  }

  // —— Render KPIs ——
  function renderKpis() {
    const map = {
      members: { value: fmt(kpis.members), delta: "+128 this week", deltaClass: "up" },
      activeToday: { value: fmt(kpis.activeToday), delta: "17% of members", deltaClass: "" },
      voiceTurns: { value: fmt(kpis.voiceTurns), delta: "+6.2% vs yesterday", deltaClass: "up" },
      plateScans: { value: fmt(kpis.plateScans), delta: "+3.1% vs yesterday", deltaClass: "up" },
      workouts: { value: fmt(kpis.workouts), delta: "−1.4% vs yesterday", deltaClass: "down" },
      mrr: { value: fmtZł(kpis.mrr), delta: "+2.8k zł MoM", deltaClass: "up" },
      aiRequests: { value: fmt(kpis.aiRequests), delta: "avg 2.4 / active user", deltaClass: "" },
      safetyFlags: { value: fmt(kpis.safetyFlags), delta: "4 open · 2 in review", deltaClass: "down" },
    };
    Object.keys(map).forEach((key) => {
      const el = $(`[data-kpi="${key}"]`);
      if (!el) return;
      $(".kpi-value", el).textContent = map[key].value;
      const d = $(".kpi-delta", el);
      d.textContent = map[key].delta;
      d.className = "kpi-delta " + map[key].deltaClass;
    });
  }

  // —— Charts ——
  function renderVoiceChart() {
    const host = $("#chart-voice");
    if (!host) return;
    const max = Math.max(...voiceByHour);
    host.innerHTML = "";
    voiceByHour.forEach((v, h) => {
      const col = document.createElement("div");
      col.className = "bar-col";
      const bar = document.createElement("div");
      bar.className = "bar";
      bar.style.height = `${Math.max(2, (v / max) * 100)}%`;
      bar.title = `${pad(h)}:00 — ${fmt(v)} turns`;
      const lab = document.createElement("div");
      lab.className = "bar-label";
      lab.textContent = h % 3 === 0 ? String(h) : "";
      col.appendChild(bar);
      col.appendChild(lab);
      host.appendChild(col);
    });
  }

  function renderRegions() {
    const host = $("#chart-regions");
    if (!host) return;
    const max = Math.max(...signupsByRegion.map((r) => r.count));
    host.innerHTML = signupsByRegion
      .map(
        (r) => `
      <div class="region-row">
        <span class="region-name">${r.name}</span>
        <div class="region-track"><div class="region-fill" style="width:${(r.count / max) * 100}%"></div></div>
        <span class="region-val">${fmt(r.count)}</span>
      </div>`
      )
      .join("");
  }

  function renderPlanMix() {
    const host = $("#chart-plans");
    if (!host) return;
    const total = planMix.Free + planMix.Pro + planMix.Ultra;
    host.innerHTML = ["Free", "Pro", "Ultra"]
      .map((p) => {
        const pct = ((planMix[p] / total) * 100).toFixed(1);
        return `
        <div class="plan-row">
          <div class="plan-meta"><span>${p}</span><span>${fmt(planMix[p])} · ${pct}%</span></div>
          <div class="plan-track"><div class="plan-fill ${p.toLowerCase()}" style="width:${pct}%"></div></div>
        </div>`;
      })
      .join("");
  }

  // —— Live feed ——
  function renderFeed() {
    const host = $("#live-feed");
    if (!host) return;
    host.innerHTML = feed
      .map(
        (e) => `
      <div class="feed-item">
        <span class="feed-time">${e.time}</span>
        <span class="feed-type ${e.type}">${e.type}</span>
        <span class="feed-msg"><strong>${e.user}</strong> — ${e.text}</span>
      </div>`
      )
      .join("");
  }

  function pushLiveEvent() {
    const weights = [
      ["voice_turn", 35],
      ["plate_scan", 25],
      ["workout_complete", 18],
      ["subscribe", 8],
      ["watch_pair", 8],
      ["ai_error", 6],
    ];
    let r = rnd() * weights.reduce((s, w) => s + w[1], 0);
    let type = "voice_turn";
    for (const [t, w] of weights) {
      r -= w;
      if (r <= 0) {
        type = t;
        break;
      }
    }
    const msg = eventMessage(type);
    feed.unshift({ type, time: formatTime(new Date()), ...msg });
    if (feed.length > 40) feed.pop();
    renderFeed();
  }

  // —— Users table ——
  function renderUsers(filter) {
    const q = (filter || "").trim().toLowerCase();
    const rows = users.filter(
      (u) =>
        !q ||
        u.name.toLowerCase().includes(q) ||
        u.country.toLowerCase().includes(q) ||
        u.countryName.toLowerCase().includes(q) ||
        u.plan.toLowerCase().includes(q) ||
        u.id.toLowerCase().includes(q)
    );
    const tbody = $("#users-tbody");
    if (!tbody) return;
    tbody.innerHTML = rows
      .map(
        (u) => `
      <tr>
        <td>${u.name}</td>
        <td>${u.country}</td>
        <td><span class="badge ${u.plan.toLowerCase()}">${u.plan}</span></td>
        <td>${u.lastActive}</td>
        <td style="color:var(--text-dim);font-family:var(--mono);font-size:0.75rem">${u.id}</td>
      </tr>`
      )
      .join("");
    const meta = $("#users-count");
    if (meta) meta.textContent = `${rows.length} of ${users.length} members`;
  }

  // —— Food / exercises ——
  function renderFoods(filter) {
    const q = (filter || "").trim().toLowerCase();
    const rows = foods.filter(
      (f) =>
        !q ||
        f.name.toLowerCase().includes(q) ||
        f.barcode.includes(q) ||
        f.brand.toLowerCase().includes(q)
    );
    const tbody = $("#foods-tbody");
    if (!tbody) return;
    tbody.innerHTML = rows
      .map(
        (f) => `
      <tr>
        <td style="font-family:var(--mono);font-size:0.78rem">${f.barcode}</td>
        <td>${f.name}</td>
        <td>${f.brand}</td>
        <td>${f.kcal}</td>
        <td>${f.protein.toFixed(1)} g</td>
        <td>${f.unit}</td>
      </tr>`
      )
      .join("");
  }

  function renderExercises(filter) {
    const q = (filter || "").trim().toLowerCase();
    const rows = exercises.filter(
      (e) =>
        !q ||
        e.name.toLowerCase().includes(q) ||
        e.muscle.toLowerCase().includes(q) ||
        e.equipment.toLowerCase().includes(q)
    );
    const tbody = $("#exercises-tbody");
    if (!tbody) return;
    tbody.innerHTML = rows
      .map(
        (e) => `
      <tr>
        <td>${e.name}</td>
        <td>${e.muscle}</td>
        <td>${e.equipment}</td>
      </tr>`
      )
      .join("");
  }

  // —— Challenges ——
  function renderChallenges() {
    const tbody = $("#challenges-tbody");
    if (!tbody) return;
    tbody.innerHTML = challenges
      .map(
        (c) => `
      <tr>
        <td>${c.title}</td>
        <td>${c.goal}</td>
        <td>${c.starts} → ${c.ends}</td>
        <td>${fmt(c.enrolled)}</td>
        <td><span class="badge ${c.status === "Active" ? "ultra" : "free"}">${c.status}</span></td>
      </tr>`
      )
      .join("");
  }

  function onCreateChallenge(e) {
    e.preventDefault();
    const title = $("#ch-title").value.trim();
    const goal = $("#ch-goal").value.trim();
    const starts = $("#ch-starts").value;
    const ends = $("#ch-ends").value;
    if (!title || !goal || !starts || !ends) return;
    challenges.unshift({
      id: `ch_${Date.now().toString(36)}`,
      title,
      goal,
      starts,
      ends,
      enrolled: 0,
      status: "Active",
    });
    e.target.reset();
    renderChallenges();
  }

  // —— Support flags ——
  function renderFlags() {
    const tbody = $("#flags-tbody");
    if (!tbody) return;
    tbody.innerHTML = flags
      .map((f) => {
        const st =
          f.status === "Open" ? "open" : f.status === "Resolved" ? "resolved" : "review";
        return `
      <tr>
        <td style="font-family:var(--mono);font-size:0.75rem">${f.id}</td>
        <td>${f.type}</td>
        <td style="font-family:var(--mono);font-size:0.75rem">${f.user}</td>
        <td>${f.detail}</td>
        <td><span class="badge ${st}">${f.status}</span></td>
        <td>${f.created}</td>
      </tr>`;
      })
      .join("");
  }

  // —— Navigation ——
  function showSection(id) {
    $$(".section").forEach((s) => s.classList.toggle("active", s.id === `section-${id}`));
    $$(".nav-item").forEach((n) => n.classList.toggle("active", n.dataset.section === id));
    history.replaceState(null, "", `#${id}`);
  }

  // —— Init ——
  function init() {
    const link = $("#member-app-link");
    if (link) {
      link.href = MEMBER_APP_URL;
      link.title = MEMBER_APP_URL;
    }

    renderKpis();
    renderVoiceChart();
    renderRegions();
    renderPlanMix();
    renderFeed();
    renderUsers("");
    renderFoods("");
    renderExercises("");
    renderChallenges();
    renderFlags();

    $$(".nav-item").forEach((btn) => {
      btn.addEventListener("click", () => showSection(btn.dataset.section));
    });

    const hash = (location.hash || "#overview").replace("#", "");
    const valid = $$(".nav-item").map((n) => n.dataset.section);
    showSection(valid.includes(hash) ? hash : "overview");

    const userSearch = $("#user-search");
    if (userSearch) userSearch.addEventListener("input", () => renderUsers(userSearch.value));

    const foodSearch = $("#food-search");
    if (foodSearch) foodSearch.addEventListener("input", () => renderFoods(foodSearch.value));

    const exSearch = $("#exercise-search");
    if (exSearch) exSearch.addEventListener("input", () => renderExercises(exSearch.value));

    const form = $("#challenge-form");
    if (form) form.addEventListener("submit", onCreateChallenge);

    // Live feed tick ~ every 3.5–6s
    setInterval(pushLiveEvent, 4200);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
