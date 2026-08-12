/* Stedfortræder for kameraet.
 *
 * I den indbyggede udgave er der ingen MediaPipe og intet webcam: browsere —
 * også den inde i en app — giver kun kameraadgang over HTTPS, og filerne her
 * ligger lokalt. I stedet leverer efterligningen i mock.js bevægelsen, så alle
 * skærme kan gennemgås.
 *
 * Den rigtige pose.js ligger i reps-repoet og bruges, når appen kører mod
 * serveren på computeren. */

export class PoseSource {
  constructor(video, canvas) {
    this.video = video;
    this.canvas = canvas;
    this.onResult = () => {};
    this.onError = () => {};
    this._timer = null;
  }

  async start() {
    this._paint("DEMO — INGEN KAMERA");
    // Serveren efterlignes af mock.js; her sendes bare et hjerteslag,
    // så billedfrekvensen i systemlinjen viser noget realistisk.
    this._timer = setInterval(() => {
      this.onResult({ t: performance.now() / 1000, landmarks: [], screen: null });
    }, 1000 / 30);
  }

  stop() {
    clearInterval(this._timer);
    this._timer = null;
  }

  _paint(text) {
    const { canvas } = this;
    if (!canvas) return;
    canvas.width = 640;
    canvas.height = 480;
    const ctx = canvas.getContext("2d");
    const ink = getComputedStyle(document.documentElement)
      .getPropertyValue("--ink3").trim() || "#9B9DA5";

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.strokeStyle = ink;
    ctx.lineWidth = 2;
    ctx.setLineDash([6, 6]);
    ctx.strokeRect(60, 60, canvas.width - 120, canvas.height - 120);
    ctx.setLineDash([]);
    ctx.fillStyle = ink;
    ctx.font = "600 22px ui-monospace,monospace";
    ctx.textAlign = "center";
    // Teksten spejlvendes, fordi elementet er spejlet i CSS.
    ctx.save();
    ctx.translate(canvas.width, 0);
    ctx.scale(-1, 1);
    ctx.fillText(text, canvas.width / 2, canvas.height / 2);
    ctx.restore();
  }
}
