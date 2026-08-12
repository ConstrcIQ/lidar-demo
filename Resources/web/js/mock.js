/* Efterligning af serveren.
 *
 * Den indbyggede udgave har ingen Python bagved, så denne fil svarer på appens
 * kald med troværdige tal og lader tilstandene udvikle sig i realistisk tempo.
 * Formålet er ét: at alle skærme kan gennemgås og mærkes på en rigtig telefon.
 *
 * Alt herinde er OPDIGTET. De rigtige målinger kommer fra Python-serveren i
 * reps-repoet. Filen indlæses kun i den indbyggede udgave. */

(function () {
  "use strict";

  /* En fejl i JavaScript efterlader ellers bare en tom flade — sort i mørkt
   * tema — og på en telefon er der ingen konsol at kigge i. Derfor males
   * fejlen på skærmen. Det er grimt, og det er meningen. */
  function report(kind, detail) {
    const box = document.createElement("pre");
    box.style.cssText =
      "position:fixed;inset:0;z-index:9999;margin:0;padding:44px 16px;overflow:auto;" +
      "background:#fff;color:#111;font:400 11px ui-monospace,monospace;white-space:pre-wrap";
    box.textContent = `REPS kunne ikke starte\n\n${kind}\n\n${detail}`;
    (document.body || document.documentElement).appendChild(box);
  }

  window.addEventListener("error", (e) => {
    report(e.message || "Fejl", `${e.filename || "?"}:${e.lineno || "?"}\n\n${e.error?.stack || ""}`);
  });
  window.addEventListener("unhandledrejection", (e) => {
    report("Uafsluttet løfte", String(e.reason?.stack || e.reason));
  });

  /* Kommer grænsefladen slet ikke i gang, siger vi det efter tre sekunder
   * frem for at stå med en tom skærm på ubestemt tid. */
  setTimeout(() => {
    const anyVisible = [...document.querySelectorAll(".screen")].some((s) => !s.hidden);
    if (!anyVisible) {
      report("Ingen skærm blev vist", "Modulet app.js kørte formentlig aldrig.");
    }
  }, 3000);

  const QUESTIONS = [
    { key: "goal", title: "Hvad træner du for?", hint: "Det afgør, hvor hårdt appen dømmer dig.", multi: false,
      options: [
        { value: "styrke", label: "Styrke", note: "Færre, dybere reps" },
        { value: "udholdenhed", label: "Udholdenhed", note: "Flere reps, jævnt tempo" },
        { value: "teknik", label: "Teknik", note: "Form før tal" },
        { value: "sporing", label: "Bare sporing", note: "Tæl, uden at dømme" }]},
    { key: "level", title: "Hvor mange armbøjninger i ét sæt?", hint: "Så mange du kan tage uden pause, med rimelig form.", multi: false,
      options: [
        { value: "0-5", label: "0–5", note: "Nybegynder" },
        { value: "6-15", label: "6–15", note: "Øvet" },
        { value: "16-30", label: "16–30", note: "Erfaren" },
        { value: "30+", label: "Over 30", note: "Stærk" }]},
    { key: "frequency", title: "Hvor ofte træner du?", hint: "Gange om ugen, cirka.", multi: false,
      options: [
        { value: "1-2", label: "1–2", note: "Nu og da" },
        { value: "3-4", label: "3–4", note: "Fast rutine" },
        { value: "5+", label: "5 eller flere", note: "Næsten dagligt" }]},
    { key: "limits", title: "Noget der gør ondt?", hint: "Vælg alt der passer. Ingenting er også et svar.", multi: true,
      options: [
        { value: "haandled", label: "Håndled", note: "" },
        { value: "skuldre", label: "Skuldre", note: "" },
        { value: "laend", label: "Lænd", note: "" }]},
  ];

  const LEVELS = { "0-5": [5, "Nybegynder"], "6-15": [12, "Øvet"],
                   "16-30": [20, "Erfaren"], "30+": [30, "Stærk"] };
  const GOALS = { styrke: "Styrke — færre, tungere, dybere reps",
                  udholdenhed: "Udholdenhed — flere reps, jævnt tempo",
                  teknik: "Teknik — form før tal",
                  sporing: "Sporing — bare tæl, døm mig ikke" };
  const LIMITS = { haandled: "Håndled", skuldre: "Skuldre", laend: "Lænd" };

  /* Samme udledning som coaching.py. Ændres den ene, skal den anden med. */
  function derive(a) {
    const s = { depth_full: 95, depth_partial: 115, hip_neutral: 8, hip_strong: 16,
                target_reps: 10, target_sets: 3, focus: ["hip", "depth"] };
    const why = [];
    const [maxReps, levelLabel] = LEVELS[a.level] || LEVELS["6-15"];
    s.target_reps = Math.max(3, Math.round(maxReps * 0.7));

    if (a.level === "0-5") {
      s.depth_full = 105; s.depth_partial = 125;
      why.push("Dybdekravet er lempet, indtil du har bygget bevægeligheden op.");
    } else if (a.level === "16-30") { s.depth_full = 92; s.depth_partial = 112; }
    else if (a.level === "30+") {
      s.depth_full = 88; s.depth_partial = 108; s.target_sets = 4;
      why.push("Dybdekravet er strammet — på dit niveau er en rep til 95° ikke en fuld rep.");
    }

    if (a.goal === "styrke") {
      s.target_reps = Math.max(3, Math.round(s.target_reps * 0.6)); s.target_sets = 5; s.depth_full -= 3;
      why.push("Færre reps pr. sæt og et strammere dybdekrav, fordi målet er styrke.");
    } else if (a.goal === "udholdenhed") {
      s.target_reps = Math.round(s.target_reps * 1.4);
      why.push("Flere reps pr. sæt. Dybden bedømmes som normalt — udholdenhed er ikke en undskyldning for halve reps.");
    } else if (a.goal === "teknik") {
      s.hip_neutral = 6; s.hip_strong = 13; s.focus = ["hip", "depth", "tempo"];
      why.push("Hoftekravet er strammet, fordi du har valgt teknik som mål.");
    } else if (a.goal === "sporing") {
      s.hip_neutral = 11; s.hip_strong = 20; s.focus = ["depth"];
      why.push("Appen holder sig tilbage og tæller. Kun tydelige fejl nævnes.");
    }

    const limits = a.limits || [];
    if (limits.includes("laend")) {
      s.hip_neutral = Math.min(s.hip_neutral, 5); s.hip_strong = Math.min(s.hip_strong, 11);
      s.focus = ["hip"].concat(s.focus.filter((f) => f !== "hip"));
      why.push("Hoften vurderes hårdere: hængende ryg er dét, der belaster lænden.");
    }
    if (limits.includes("skuldre")) {
      s.depth_full = Math.max(s.depth_full, 100); s.depth_partial = Math.max(s.depth_partial, 120);
      why.push("Der presses ikke på for maksimal dybde af hensyn til dine skuldre.");
    }
    if (limits.includes("haandled")) {
      why.push("Håndled: overvej greb på knytnæver eller håndtag. Appen måler det samme.");
    }
    if (a.frequency === "1-2") s.target_sets = Math.max(2, s.target_sets - 1);

    const program = {
      level_label: levelLabel,
      goal_label: GOALS[a.goal] || a.goal,
      limits: limits.map((k) => LIMITS[k]).filter(Boolean),
      prescription: `${s.target_sets} sæt × ca. ${s.target_reps} reps`,
      why,
      thresholds: {
        "Fuld dybde ved": `≤ ${s.depth_full}°`,
        "For kort over": `${s.depth_partial}°`,
        "Hofte: neutral under": `${s.hip_neutral}°`,
        "Hofte: tydelig over": `${s.hip_strong}°`,
      },
    };
    return { settings: s, program };
  }

  /* ------------------------------------------------------------ tilstand */

  const store = {
    screening: load("demo.screening", null),
    athlete: load("demo.athlete", null),
    sets: load("demo.sets", seedSets()),
  };

  function load(key, fallback) {
    try { const raw = localStorage.getItem(key); return raw ? JSON.parse(raw) : fallback; }
    catch { return fallback; }
  }
  function save(key, value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch {}
  }

  function seedSets() {
    const day = 86400;
    const now = Date.now() / 1000;
    return [
      { id: "d1", started_at: now - day * 0.2, total: 14, good: 12, eccentric: 2.1, concentric: 0.9, duration: 72, algo_version: "demo" },
      { id: "d2", started_at: now - day * 2, total: 11, good: 11, eccentric: 2.4, concentric: 1.0, duration: 61, algo_version: "demo" },
      { id: "d3", started_at: now - day * 4, total: 13, good: 6, eccentric: 1.6, concentric: 1.2, duration: 58, algo_version: "demo" },
      { id: "d4", started_at: now - day * 6, total: 10, good: 9, eccentric: 2.2, concentric: 1.0, duration: 55, algo_version: "demo" },
    ];
  }

  function stats() {
    const good = store.sets.map((s) => s.good);
    return {
      best_clean: good.length ? Math.max(...good) : 0,
      streak: store.sets.length ? 3 : 0,
      week_delta: 3,
      trend: good.slice().reverse(),
      sessions: store.sets.length,
      faults: store.sets.length ? [
        { name: "gled hofterne", share: 0.41 },
        { name: "blev de korte", share: 0.22 },
        { name: "kom der studs i bunden", share: 0.09 },
      ] : [],
    };
  }

  function athleteResult() {
    return {
      complete: true, coverage: 1, frames: 612, calibrated: true, stature_cm: 178,
      note: "Kalibreret mod din opgivne højde.",
      expected_travel_cm: 36.4,
      measures: [
        { key: "upper_arm_l", label: "Overarm v.", cm: 31.6, spread_cm: 0.3, sectors: 8 },
        { key: "upper_arm_r", label: "Overarm h.", cm: 33.1, spread_cm: 0.4, sectors: 8 },
        { key: "forearm_l", label: "Underarm v.", cm: 26.3, spread_cm: 0.2, sectors: 8 },
        { key: "forearm_r", label: "Underarm h.", cm: 26.4, spread_cm: 0.3, sectors: 8 },
        { key: "thigh_l", label: "Lår v.", cm: 44.0, spread_cm: 0.5, sectors: 8 },
        { key: "thigh_r", label: "Lår h.", cm: 44.0, spread_cm: 0.4, sectors: 8 },
        { key: "shin_l", label: "Underben v.", cm: 42.1, spread_cm: 0.4, sectors: 8 },
        { key: "shin_r", label: "Underben h.", cm: 42.2, spread_cm: 0.3, sectors: 8 },
        { key: "shoulder_w", label: "Skulderbredde", cm: 40.0, spread_cm: 0.6, sectors: 8 },
        { key: "hip_w", label: "Hoftebredde", cm: 30.1, spread_cm: 0.5, sectors: 8 },
        { key: "torso", label: "Overkrop", cm: 52.0, spread_cm: 0.4, sectors: 8 },
      ],
      asymmetry: [
        { key: "upper_arm", label: "Overarm", diff_pct: 4.6, notable: true },
        { key: "forearm", label: "Underarm", diff_pct: 0.2, notable: false },
        { key: "thigh", label: "Lår", diff_pct: 0.0, notable: false },
        { key: "shin", label: "Underben", diff_pct: 0.2, notable: false },
      ],
      ratios: [
        { label: "Arm mod højde", value: 0.328, note: "Lange arme giver længere vej i en armbøjning" },
        { label: "Overkrop mod ben", value: 0.605, note: "Påvirker hvor meget hoften skal arbejde for at holde linjen" },
        { label: "Skulder mod hofte", value: 1.329, note: "Brede skuldre giver mere sving i albuerne" },
      ],
      scanned_at: Date.now() / 1000,
    };
  }

  /* ------------------------------------------------------------ fetch */

  const realFetch = window.fetch.bind(window);
  window.fetch = function (input, init) {
    const url = typeof input === "string" ? input : input.url;
    const path = url.replace(/^https?:\/\/[^/]+/, "");
    const method = (init && init.method) || "GET";

    const reply = (body) =>
      Promise.resolve(new Response(JSON.stringify(body),
        { status: 200, headers: { "Content-Type": "application/json" } }));

    if (path.startsWith("/api/health")) return reply({ ok: true, algo: "1.0.0-demo", time: Date.now() / 1000 });
    if (path.startsWith("/api/questions")) return reply(QUESTIONS);

    if (path.startsWith("/api/screening")) {
      if (method === "POST") {
        const answers = JSON.parse(init.body);
        const { settings, program } = derive(answers);
        store.screening = { id: "demo", created_at: Date.now() / 1000, answers, settings, program };
        save("demo.screening", store.screening);
        return reply({ id: "demo", settings, program });
      }
      return reply(store.screening || {});
    }

    if (path.startsWith("/api/athlete")) return reply(store.athlete || {});
    if (path.startsWith("/api/stats")) return reply(stats());
    if (path.startsWith("/api/sets")) return reply(store.sets);
    if (path.startsWith("/api/scans")) return reply([]);

    return realFetch(input, init);
  };

  /* ------------------------------------------------------- WebSocket */

  const RealWebSocket = window.WebSocket;

  class FakeSocket {
    constructor(url) {
      this.url = url;
      this.readyState = 0;
      this._listeners = {};
      this._timers = [];
      this._count = 0;
      this._angle = 172;
      this._phase = "top";
      this._sectors = [false, false, false, false, false, false, false, false];
      this._frames = 0;
      this._yaw = 0;

      setTimeout(() => {
        this.readyState = 1;
        this._emit("open", {});
        this.url.includes("/ws/scan") ? this._runScan() : this._runLive();
      }, 120);
    }

    addEventListener(type, handler) {
      (this._listeners[type] = this._listeners[type] || []).push(handler);
    }

    _emit(type, event) {
      (this._listeners[type] || []).forEach((h) => h(event));
    }

    _push(payload) {
      this._emit("message", { data: JSON.stringify(payload) });
    }

    /* Et sæt der udvikler sig: først søges der efter en person, så bliver den
     * klar, og derefter tælles reps med et menneskeligt tempo. */
    _runLive() {
      const t0 = Date.now();
      let state = "searching";
      let lastRep = 0;

      this._timers.push(setInterval(() => {
        const elapsed = (Date.now() - t0) / 1000;
        if (elapsed > 1.4 && state === "searching") state = "ready";
        if (elapsed > 3.0 && state === "ready") state = "active";

        if (state === "active") {
          // Albuevinklen svinger som en rigtig armbøjning: ~2,4 sek pr. rep.
          // Plus og ikke minus: ved p=0 er armen strakt (178°, toppen), ved
          // p=0,5 er den bøjet (82°, bunden). Med det modsatte fortegn viste
          // skærmen "BOTTOM" samtidig med en strakt arm.
          const p = ((Date.now() - t0) / 1000) % 2.4 / 2.4;
          this._angle = 130 + 48 * Math.cos(p * 2 * Math.PI);
          this._phase = p < 0.45 ? "descending" : p < 0.55 ? "bottom" : "ascending";
          if (elapsed - lastRep > 2.4) { lastRep = elapsed; this._count += 1; }
        }

        const events = [];
        if (state === "active" && Math.abs(elapsed - lastRep) < 0.05 && this._count > 0) {
          events.push({ type: "rep" });
        }

        this._push({
          state, count: this._count,
          angle: Math.round(this._angle * 10) / 10,
          velocity: 0, hip: state === "active" ? (this._count > 8 ? 9.4 : 2.1) : null,
          phase: this._phase,
          thresholds: { low: 145.7, high: 161.5, top: 172, bottom: 84.3 },
          checks: { person: elapsed > 0.6, horizontal: elapsed > 1.0, full: elapsed > 1.4 },
          events,
        });
      }, 1000 / 15));
    }

    _runScan() {
      this._timers.push(setInterval(() => {
        this._frames += 1;
        this._yaw = (this._yaw + 2.6) % 360;
        this._sectors[Math.floor(this._yaw / 45) % 8] = true;
        const covered = this._sectors.filter(Boolean).length;
        this._push({
          frames: this._frames, yaw: Math.round(this._yaw * 10) / 10,
          sectors: this._sectors.slice(), coverage: covered / 8, complete: covered === 8,
        });
      }, 1000 / 15));
    }

    send(raw) {
      let message = {};
      try { message = JSON.parse(raw); } catch { return; }

      if (message.type === "finish") {
        if (this.url.includes("/ws/scan")) {
          store.athlete = athleteResult();
          save("demo.athlete", store.athlete);
          this._push({ done: true, result: store.athlete, scan_id: "demo" });
        } else {
          const summary = this._summary();
          store.sets.unshift({
            id: "s" + Date.now(), started_at: Date.now() / 1000,
            total: summary.total, good: summary.good, eccentric: summary.eccentric,
            concentric: summary.concentric, duration: summary.duration, algo_version: "demo",
          });
          save("demo.sets", store.sets);
          this._push({ state: "summary", summary, set_id: "demo", events: [] });
        }
        this._stop();
      }
    }

    _summary() {
      const total = Math.max(this._count, 6);
      const reps = [];
      for (let i = 1; i <= total; i += 1) {
        // Formen skrider mod slutningen — det er dét, striben skal kunne vise.
        const late = i > total - 3;
        const veryLate = i > total - 2;
        reps.push({
          index: i,
          quality: veryLate ? "low" : late ? "partial" : "full",
          hip: veryLate ? "strong_sag" : late ? "sag" : "neutral",
          bottom_angle: veryLate ? 118.4 : late ? 104.2 : 82.6,
          eccentric: late ? 1.4 : 2.1,
          concentric: late ? 1.3 : 0.9,
          bounced: false,
          fault: veryLate || late ? "gled hofterne" : null,
        });
      }
      const good = reps.filter((r) => r.quality === "full").length;
      return {
        total, good, eccentric: 2.1, concentric: 0.9, duration: total * 2.4,
        reps,
        sentence: `Formen holdt i ${good} reps, så gled hofterne.`,
      };
    }

    _stop() {
      this._timers.forEach(clearInterval);
      this._timers = [];
    }

    close() {
      this._stop();
      this.readyState = 3;
      this._emit("close", {});
    }
  }

  FakeSocket.CONNECTING = 0;
  FakeSocket.OPEN = 1;
  FakeSocket.CLOSING = 2;
  FakeSocket.CLOSED = 3;

  window.WebSocket = FakeSocket;
  window.__RealWebSocket = RealWebSocket;

  console.info("Reps: indbygget demo-udgave. Alle tal er opdigtede.");
})();
