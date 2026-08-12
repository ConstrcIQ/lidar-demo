/* Grænsefladen. Ingen signalbehandling herinde — den bor på serveren, så der
 * kun findes én udgave af algoritmen, og den kan afprøves uden webcam.
 *
 * Navigationen følger ét princip: enten er du i et FORLØB (opstilling, sæt,
 * scanning) og har præcis ét næste skridt — eller du er i en FANE og kan gå
 * hvorhen du vil. Aldrig begge dele. */

import { getJSON, LiveSocket } from "./api.js";
import { PoseSource } from "./pose.js";

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
const bind = (name) => $(`[data-bind="${name}"]`);

const TABS = ["home", "profile", "log"];
const SYS = { searching: "SØGER", ready: "KLAR", active: "AKTIV",
              lost: "MISTET", error: "FEJL", idle: "INAKTIV" };

const state = { screen: null, pose: null, socket: null, rates: [], program: null, settings: null };
const scan = { pose: null, socket: null };
const quiz = { questions: [], step: 0, answers: {} };

/* ------------------------------------------------------------ navigation */

function show(name) {
  $$(".screen").forEach((s) => (s.hidden = s.dataset.screen !== name));
  const tabbed = TABS.includes(name);
  bind("tabs").hidden = !tabbed;
  $$("[data-tab]").forEach((b) => b.classList.toggle("on", b.dataset.tab === name));
  state.screen = name;
  $(".content", $(`[data-screen="${name}"]`))?.scrollTo(0, 0);
}

async function go(target) {
  /* Forlader man et forløb, skal kameraet slukkes. Ellers bliver det ved med
   * at køre bag en fane, og maskinen bliver varm uden grund. */
  if (["home", "profile", "log", "program"].includes(target)) await stopCapture();

  switch (target) {
    case "home": await loadHome(); show("home"); break;
    case "profile": await loadProfile(); show("profile"); break;
    case "log": await loadLog(); show("log"); break;
    case "placement": show("placement"); await startCapture(); break;
    case "live": bind("count").textContent = "0"; show("live"); break;
    case "summary": state.socket?.finish(true); show("summary"); break;
    case "scan": show("scan"); await startScan(); break;
    case "scanresult": scan.socket?.send({ type: "finish", save: true }); show("scanresult"); break;
    case "program": show("program"); break;
    default: show(target);
  }
}

$$("[data-go]").forEach((el) => el.addEventListener("click", () => go(el.dataset.go)));
$$("[data-tab]").forEach((el) => el.addEventListener("click", () => go(el.dataset.tab)));

function setSys(key, rate) {
  bind("sysState").textContent = SYS[key] || String(key).toUpperCase();
  const lamp = bind("lamp");
  lamp.className = "lamp" + (key === "active" ? " on" : key === "lost" ? " warn" : "");
  bind("rate").textContent = rate ? `${rate} B/S` : "—";
}

/* ══════════════════════════════════════════════════════ screening */

async function startQuiz(existing) {
  quiz.questions = await getJSON("/api/questions");
  quiz.step = 0;
  quiz.answers = existing ? { ...existing } : {};
  renderQuestion();
  show("onboarding");
}

function renderQuestion() {
  const q = quiz.questions[quiz.step];
  bind("steps").innerHTML = quiz.questions
    .map((_, i) => `<i class="${i <= quiz.step ? "on" : ""}"></i>`).join("");
  bind("qTitle").textContent = q.title;
  bind("qHint").textContent = q.hint;

  const chosen = quiz.answers[q.key];
  bind("opts").innerHTML = q.options.map((o) => {
    const on = q.multi ? (chosen || []).includes(o.value) : chosen === o.value;
    return `<button class="opt${on ? " on" : ""}" data-value="${o.value}">` +
           `<span>${o.label}</span>${o.note ? `<em>${o.note}</em>` : ""}</button>`;
  }).join("");

  $$(".opt", bind("opts")).forEach((el) =>
    el.addEventListener("click", () => choose(q, el.dataset.value)));

  bind("qBack").textContent = quiz.step === 0 ? "Spring over" : "Tilbage";
  bind("qNext").textContent = quiz.step === quiz.questions.length - 1 ? "Færdig" : "Videre";
  updateNext(q);
}

function choose(q, value) {
  if (q.multi) {
    const set = new Set(quiz.answers[q.key] || []);
    set.has(value) ? set.delete(value) : set.add(value);
    quiz.answers[q.key] = [...set];
  } else {
    quiz.answers[q.key] = value;
    /* Enkeltvalg går videre af sig selv. Et ekstra tryk på "Videre" efter et
     * valg, der allerede er entydigt, er et tryk for meget. */
    renderQuestion();
    setTimeout(() => advance(), 160);
    return;
  }
  renderQuestion();
}

function updateNext(q) {
  const chosen = quiz.answers[q.key];
  /* "Noget der gør ondt" må gerne besvares med ingenting — derfor er
   * flervalg altid gyldigt. */
  bind("qNext").disabled = q.multi ? false : !chosen;
}

async function advance() {
  if (quiz.step < quiz.questions.length - 1) {
    quiz.step += 1;
    renderQuestion();
  } else {
    await submitQuiz();
  }
}

async function submitQuiz() {
  const answers = { ...quiz.answers };
  if (!answers.limits) answers.limits = [];
  const response = await fetch("/api/screening", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(answers),
  }).then((r) => r.json());

  state.program = response.program;
  state.settings = response.settings;
  renderProgram(response.program);
  show("program");
}

bind("qNext").addEventListener("click", advance);
bind("qBack").addEventListener("click", () => {
  if (quiz.step === 0) return go("home");
  quiz.step -= 1;
  renderQuestion();
});

function renderProgram(p) {
  bind("pSets").textContent = p.prescription.split(" ")[0];
  bind("pReps").textContent = p.prescription.match(/(\d+)\s*reps/)?.[1] || "—";
  bind("pLevel").textContent = p.level_label;
  bind("pLimits").textContent = p.limits.length ? p.limits.join(", ") : "ingen";
  bind("pGoal").textContent = p.goal_label;
  bind("pWhy").innerHTML = p.why.length
    ? p.why.map((w) => `<li>${w}</li>`).join("")
    : `<li>Standardkravene bruges — dine svar gav ingen grund til at ændre dem.</li>`;
  bind("pThresholds").innerHTML = Object.entries(p.thresholds)
    .map(([k, v]) => `<tr><td>${k}</td><td class="r">${v}</td></tr>`).join("");
}

/* ══════════════════════════════════════════════════════ optagelse */

async function startCapture() {
  bind("vfLeft").textContent = "STARTER";
  try {
    state.socket = new LiveSocket();
    state.socket.onState = onServerState;
    state.socket.onEvent = onServerEvent;
    await state.socket.connect();

    state.pose = new PoseSource($("#video"), $("#overlay"));
    state.pose.onResult = (r) => { tickRate(); state.socket.sendFrame({ t: r.t, landmarks: r.landmarks }); };
    state.pose.onError = (e) => console.warn("pose:", e);
    await state.pose.start();
  } catch (error) {
    bind("vfLeft").textContent = fejlkode(error);
    bind("hint").textContent = fejltekst(error);
  }
}

async function stopCapture() {
  state.pose?.stop(); state.pose = null;
  state.socket?.close(); state.socket = null;
  state.rates = [];
  scan.pose?.stop(); scan.pose = null;
  scan.socket?.close(); scan.socket = null;
  setSys("idle");
}

const fejlkode = (e) => ({ NotAllowedError: "AFVIST", NotFoundError: "INTET KAMERA" }[e?.name] || "FEJL");
const fejltekst = (e) => e?.name === "NotAllowedError"
  ? "Kameraadgang blev afvist. Giv adgang i browserens adresselinje og prøv igen."
  : "Kunne ikke starte kameraet. Tjek at ingen anden app bruger det.";

function tickRate() {
  const now = performance.now();
  state.rates.push(now);
  while (state.rates.length && now - state.rates[0] > 1000) state.rates.shift();
}

function onServerState(data) {
  if (data.state === "summary") return renderSummary(data.summary);
  setSys(data.state, state.rates.length || null);

  if (state.screen === "placement") {
    const checks = data.checks || {};
    let ready = true;
    for (const [key, ok] of Object.entries(checks)) {
      const row = $(`tr[data-check="${key}"]`);
      if (!row) continue;
      row.classList.toggle("ok", !!ok);
      $(".st", row).textContent = ok ? "OK" : "—";
      if (!ok) ready = false;
    }
    $("[data-screen=placement] .viewfinder").classList.toggle("ok", ready);
    bind("vfLeft").textContent = checks.person ? "SPORER" : "INGEN PERSON";
    bind("vfRight").textContent = data.angle != null ? `${data.angle}°` : "—";
    bind("beginBtn").disabled = !ready;
    bind("beginBtn").textContent = ready ? "Begynd" : "Afventer";
  }

  if (state.screen === "live") {
    bind("count").textContent = data.count ?? 0;
    bind("angle").textContent = data.angle != null ? `${data.angle}°` : "—";
    bind("phase").textContent = (data.phase || "—").toUpperCase();
    bind("hip").textContent = data.hip != null ? `${data.hip}°` : "—";
    const t = data.thresholds || {};
    bind("thr").textContent = t.low != null ? `${t.low}° / ${t.high}°` : "—";
    bind("span").textContent = t.top != null ? `${t.top}° / ${t.bottom}°` : "—";
    drawScope(data);
  }
}

function onServerEvent(event) {
  if (event.type === "rep") {
    bind("count").animate([{ opacity: 1 }, { opacity: 0.3 }, { opacity: 1 }], { duration: 120 });
  }
}

/* --------------------------------------------------------------- signal */

function drawScope(data) {
  const canvas = $("#scopeCanvas");
  if (!canvas || !canvas.clientWidth) return;
  const dpr = devicePixelRatio || 1;
  const w = (canvas.width = canvas.clientWidth * dpr);
  const h = (canvas.height = 104 * dpr);
  const ctx = canvas.getContext("2d");

  drawScope.buf = drawScope.buf || [];
  if (data.angle != null) drawScope.buf.push(data.angle);
  if (drawScope.buf.length > 300) drawScope.buf.shift();

  const buf = drawScope.buf;
  const thr = data.thresholds || {};
  const lo = Math.min(60, (thr.bottom ?? 70) - 8);
  const hi = Math.max(180, (thr.top ?? 175) + 4);
  const Y = (v) => h - ((v - lo) / (hi - lo)) * h;

  const css = getComputedStyle(document.documentElement);
  const ink = css.getPropertyValue("--ink").trim() || "#08080A";
  const rule = css.getPropertyValue("--rule").trim() || "#D6D7DC";

  ctx.clearRect(0, 0, w, h);
  ctx.strokeStyle = rule; ctx.lineWidth = dpr;
  ctx.font = `${9 * dpr}px ui-monospace,monospace`; ctx.fillStyle = rule;
  for (let deg = 60; deg <= 180; deg += 30) {
    const y = Math.round(Y(deg)) + 0.5;
    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    ctx.fillText(`${deg}`, 3 * dpr, y - 3 * dpr);
  }

  ctx.setLineDash([3 * dpr, 3 * dpr]); ctx.strokeStyle = ink; ctx.globalAlpha = 0.45;
  for (const key of ["low", "high"]) {
    if (thr[key] == null) continue;
    const y = Math.round(Y(thr[key])) + 0.5;
    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
  }
  ctx.setLineDash([]); ctx.globalAlpha = 1;

  ctx.strokeStyle = ink; ctx.lineWidth = 1.5 * dpr;
  ctx.beginPath();
  buf.forEach((v, i) => {
    const x = (i / Math.max(buf.length - 1, 1)) * w;
    i ? ctx.lineTo(x, Y(v)) : ctx.moveTo(x, Y(v));
  });
  ctx.stroke();
}

/* --------------------------------------------------------- oversigt */

const KVAL = { full: "FULD", partial: "DELVIS", low: "LAV" };
const HOFTE = { neutral: "—", sag: "sænk", strong_sag: "SÆNK", pike: "pukkel",
                strong_pike: "PUKKEL", unknown: "?" };

function renderSummary(s) {
  const held = s.total > 0 && s.good / s.total >= 0.5;
  bind("sumTotal").textContent = s.total;
  bind("sumGood").textContent = s.good;
  bind("sumGood").classList.toggle("weak", !held);
  bind("ecc").textContent = s.eccentric ? `~${komma(s.eccentric)}` : "—";
  bind("con").textContent = s.concentric ? `~${komma(s.concentric)}` : "—";
  bind("dur").textContent = klokke(s.duration || 0);
  bind("sentence").textContent = s.sentence || "";

  const strip = bind("strip");
  strip.innerHTML = "";
  (s.reps || []).forEach((rep) => {
    const bar = document.createElement("div");
    bar.className = `bar ${rep.quality}`;
    bar.addEventListener("click", () => selectRep(rep.index));
    strip.appendChild(bar);
  });
  bind("axis").innerHTML = `<span>1</span><span>${s.total || ""}</span>`;

  bind("repTable").innerHTML = (s.reps || []).map((rep) =>
    `<tr data-rep="${rep.index}"><td class="dim">${rep.index}</td>` +
    `<td>${KVAL[rep.quality] || rep.quality}</td>` +
    `<td class="r">${komma(rep.bottom_angle)}°</td>` +
    `<td class="r">${komma(rep.eccentric)}</td>` +
    `<td class="r">${komma(rep.concentric)}</td>` +
    `<td class="fault">${HOFTE[rep.hip] || "—"}</td></tr>`).join("");
}

function selectRep(index) {
  $$(".bar", bind("strip")).forEach((b, i) => b.classList.toggle("sel", i + 1 === index));
  $$("tr", bind("repTable")).forEach((tr) =>
    tr.style.setProperty("background", +tr.dataset.rep === index ? "var(--sunk)" : ""));
}

const komma = (n) => String(n ?? "—").replace(".", ",");
const klokke = (s) => `${Math.floor(s / 60)}:${String(Math.round(s % 60)).padStart(2, "0")}`;

/* ══════════════════════════════════════════════════════ faner */

async function loadHome() {
  const [stats, sets] = await Promise.all([getJSON("/api/stats"), getJSON("/api/sets?limit=30")]);
  const today = sets.filter((s) => sameDay(s.started_at));
  const reps = today.reduce((n, s) => n + s.total, 0);
  const good = today.reduce((n, s) => n + s.good, 0);

  bind("todayReps").textContent = reps;
  bind("todaySub").textContent = today.length
    ? `${today.length} sæt · ${good} rene`
    : "Intet sæt endnu";

  bind("streak").textContent = stats.streak || 0;
  bind("bestClean").textContent = stats.best_clean || 0;
  bind("sessions").textContent = stats.sessions || 0;
  bind("delta").textContent = (stats.week_delta > 0 ? "+" : "") + (stats.week_delta || 0);

  bind("ctaSub").textContent = state.program?.prescription || "Ingen screening";
  bind("ofTarget").textContent = state.settings ? `/ ${state.settings.target_reps}` : "";
}

const sameDay = (epoch) => {
  const d = new Date(epoch * 1000), n = new Date();
  return d.toDateString() === n.toDateString();
};

async function loadProfile() {
  const screening = await getJSON("/api/screening");
  const program = screening.program;
  state.program = program || null;
  state.settings = screening.settings || null;

  bind("profProgram").innerHTML = program
    ? [["Mål", program.goal_label], ["Niveau", program.level_label],
       ["Ordination", program.prescription],
       ["Hensyn", program.limits.length ? program.limits.join(", ") : "ingen"]]
        .map(([k, v]) => `<tr><td>${k}</td><td class="r">${v}</td></tr>`).join("")
    : `<tr class="empty"><td colspan="2">Ikke screenet</td></tr>`;

  bind("profThresholds").innerHTML = program
    ? Object.entries(program.thresholds)
        .map(([k, v]) => `<tr><td>${k}</td><td class="r">${v}</td></tr>`).join("")
    : `<tr class="empty"><td colspan="2">Standardkrav</td></tr>`;

  await loadAthlete();
}

async function loadAthlete() {
  const body = bind("athlete");
  try {
    const a = await getJSON("/api/athlete");
    if (!a || !a.measures) {
      body.innerHTML = `<tr class="empty"><td colspan="2">Ikke scannet</td></tr>`;
      return;
    }
    const skew = (a.asymmetry || []).filter((x) => x.notable);
    body.innerHTML = [
      ["Højde", a.stature_cm ? `${Math.round(a.stature_cm)} cm` : "—"],
      ["Vej pr. rep", a.expected_travel_cm ? `${Math.round(a.expected_travel_cm)} cm` : "—"],
      ["Skævhed", skew.length ? skew.map((s) => s.label).join(", ") : "ingen"],
      ["Skala", a.calibrated ? "kalibreret" : "skøn"],
      ["Scannet", stempel(a.scanned_at)],
    ].map(([k, v]) => `<tr><td>${k}</td><td class="r">${v}</td></tr>`).join("");
  } catch {
    body.innerHTML = `<tr class="empty"><td colspan="2">Ikke scannet</td></tr>`;
  }
}

async function loadLog() {
  const [stats, sets] = await Promise.all([getJSON("/api/stats"), getJSON("/api/sets?limit=40")]);

  const chart = bind("chart");
  const peak = Math.max(...(stats.trend.length ? stats.trend : [1]));
  chart.innerHTML = stats.trend
    .map((v) => `<div class="cbar" style="height:${Math.max((v / peak) * 120, 2)}px"></div>`).join("");
  bind("chartAxis").innerHTML = `<span>ÆLDST</span><span>MAKS ${peak}</span><span>NU</span>`;

  bind("setlog").innerHTML = sets.length
    ? sets.map((s) => {
        const share = s.total ? Math.round((s.good / s.total) * 100) : 0;
        return `<tr><td class="dim">${stempel(s.started_at)}</td>` +
               `<td class="r">${s.total}</td><td class="r">${s.good}</td>` +
               `<td class="r ${share < 50 ? "dim" : ""}">${share}%</td></tr>`;
      }).join("")
    : `<tr class="empty"><td colspan="4">Ingen sæt registreret</td></tr>`;

  bind("faults").innerHTML = stats.faults.length
    ? stats.faults.map((f) =>
        `<tr><td>${f.name}</td><td class="r">${Math.round(f.share * 100)}%</td></tr>`).join("")
    : `<tr class="empty"><td colspan="2">Ingen fejl registreret</td></tr>`;
}

function stempel(epoch) {
  const d = new Date(epoch * 1000);
  const p = (n) => String(n).padStart(2, "0");
  return `${p(d.getDate())}.${p(d.getMonth() + 1)} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

/* ══════════════════════════════════════════════════════ kropsscanning */

async function startScan() {
  drawDial(new Array(8).fill(false), null);
  bind("scanLeft").textContent = "STARTER";
  try {
    scan.socket = new LiveSocket("/ws/scan");
    scan.socket.onState = onScanState;
    await scan.socket.connect();
    scan.pose = new PoseSource($("#scanVideo"), $("#scanOverlay"));
    scan.pose.onResult = (r) => scan.socket.sendFrame({ landmarks: r.landmarks });
    await scan.pose.start();
  } catch (error) {
    bind("scanLeft").textContent = fejlkode(error);
  }
}

function onScanState(data) {
  if (data.done) return renderScanResult(data.result);
  if (data.error) return;

  const sectors = data.sectors || [];
  const covered = sectors.filter(Boolean).length;
  drawDial(sectors, data.yaw);
  bind("yaw").textContent = data.yaw != null ? `${Math.round(data.yaw)}°` : "—";
  bind("coverage").textContent = `${covered} / 8`;
  bind("scanFrames").textContent = data.frames ?? 0;
  bind("scanLeft").textContent = data.yaw != null ? "SPORER" : "INGEN PERSON";
  bind("scanRight").textContent = `${Math.round((data.coverage || 0) * 100)}%`;

  const button = bind("scanBtn");
  button.disabled = covered < 4;
  button.textContent = data.complete ? "Færdig — beregn"
    : covered < 4 ? `Drej videre (${covered}/8)` : `Beregn (${covered}/8)`;
}

function drawDial(sectors, yaw) {
  const svg = bind("dial");
  const cx = 60, cy = 60, r = 44;
  const point = (deg) => {
    const a = ((deg - 90) * Math.PI) / 180;
    return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
  };
  let markup = "";
  for (let i = 0; i < 8; i += 1) {
    const [x1, y1] = point(i * 45 + 2), [x2, y2] = point(i * 45 + 43);
    markup += `<path class="seg${sectors[i] ? " on" : ""}" d="M ${x1} ${y1} A ${r} ${r} 0 0 1 ${x2} ${y2}"/>`;
  }
  if (yaw != null) {
    const a = ((yaw - 90) * Math.PI) / 180;
    markup += `<line class="needle" x1="${cx}" y1="${cy}" x2="${cx + 30 * Math.cos(a)}" y2="${cy + 30 * Math.sin(a)}"/>`;
  }
  markup += `<text class="hub" x="${cx}" y="${cy + 3}" text-anchor="middle">${sectors.filter(Boolean).length}/8</text>`;
  svg.innerHTML = markup;
}

function renderScanResult(result) {
  bind("rStature").textContent = result.stature_cm ? Math.round(result.stature_cm) : "—";
  const arms = result.measures.filter((m) => m.key.startsWith("upper_arm") || m.key.startsWith("forearm"));
  bind("rArm").textContent = arms.length === 4 ? Math.round(arms.reduce((s, m) => s + m.cm, 0) / 2) : "—";
  bind("rTravel").textContent = result.expected_travel_cm ? Math.round(result.expected_travel_cm) : "—";
  bind("rCover").textContent = `${Math.round(result.coverage * 100)}%`;
  bind("calibNote").textContent = result.note;

  bind("measures").innerHTML = result.measures.map((m) =>
    `<tr><td>${m.label}</td><td class="r">${komma(m.cm)}</td>` +
    `<td class="r dim">${komma(m.spread_cm)}</td><td class="r dim">${m.sectors}</td></tr>`).join("");

  bind("asym").innerHTML = result.asymmetry.length
    ? result.asymmetry.map((a) => {
        const side = a.diff_pct > 0 ? "højre" : "venstre";
        return `<tr class="${a.notable ? "warnrow" : "okrow"}"><td>${a.label}</td>` +
               `<td class="r">${a.notable ? `${komma(Math.abs(a.diff_pct))}% længere ${side}` : "symmetrisk"}</td></tr>`;
      }).join("")
    : `<tr class="empty"><td colspan="2">Ikke nok data</td></tr>`;

  bind("ratios").innerHTML = result.ratios.map((r) =>
    `<tr><td>${r.label}<div class="dim tiny">${r.note}</div></td><td class="r">${komma(r.value)}</td></tr>`).join("");
}

bind("height").addEventListener("change", (event) => {
  const cm = parseFloat(event.target.value);
  scan.socket?.send({ type: "height", cm: Number.isFinite(cm) ? cm : null });
});

bind("redo").addEventListener("click", async () => {
  const existing = await getJSON("/api/screening");
  startQuiz(existing.answers);
});

bind("exportBtn").addEventListener("click", async () => {
  const sets = await getJSON("/api/sets?limit=500");
  const head = "dato,reps,rene,ned_sek,op_sek,varighed_sek,algoritme\n";
  const rows = sets.map((s) =>
    [new Date(s.started_at * 1000).toISOString(), s.total, s.good,
     s.eccentric ?? "", s.concentric ?? "", s.duration ?? "", s.algo_version].join(",")).join("\n");
  const url = URL.createObjectURL(new Blob([head + rows], { type: "text/csv" }));
  const a = document.createElement("a");
  a.href = url; a.download = "reps.csv"; a.click();
  URL.revokeObjectURL(url);
  toast("Eksporteret");
});

function toast(text) {
  const el = bind("toast");
  el.textContent = text;
  el.hidden = false;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => (el.hidden = true), 1600);
}

/* ══════════════════════════════════════════════════════ opstart */

async function boot() {
  getJSON("/api/health").then((h) => (bind("ver").textContent = `v${h.algo}`)).catch(() => {});
  setSys("idle");

  const screening = await getJSON("/api/screening").catch(() => ({}));
  if (!screening.program) {
    /* Første gang: spørg, før der måles. Uden svar ved appen ikke, hvor hårdt
     * den skal dømme — og så gætter den, hvilket er værre end at spørge. */
    await startQuiz();
    return;
  }
  state.program = screening.program;
  state.settings = screening.settings;
  await go("home");
}

boot();
