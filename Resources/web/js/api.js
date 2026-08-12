/* Forbindelsen til serveren. Al signalbehandling sker derinde — her sendes
 * kun led afsted og tages hændelser imod. */

export async function getJSON(path) {
  const response = await fetch(path);
  if (!response.ok) throw new Error(`${path}: ${response.status}`);
  return response.json();
}

export class LiveSocket {
  /** @param {string} path hvilken kanal på serveren — live-analyse eller scanning */
  constructor(path = "/ws/live") {
    this.path = path;
    this.socket = null;
    this.onState = () => {};
    this.onEvent = () => {};
    this.onClose = () => {};
    /* Uden en spærre ville en langsom forbindelse hobe billeder op, og
     * tælleren ville hænge sekunder efter kroppen. */
    this.inFlight = 0;
    this.maxInFlight = 3;
  }

  connect() {
    const protocol = location.protocol === "https:" ? "wss" : "ws";
    this.socket = new WebSocket(`${protocol}://${location.host}${this.path}`);

    this.socket.addEventListener("message", (message) => {
      this.inFlight = Math.max(0, this.inFlight - 1);
      const data = JSON.parse(message.data);
      this.onState(data);
      for (const event of data.events || []) this.onEvent(event, data);
    });

    this.socket.addEventListener("close", () => this.onClose());

    return new Promise((resolve, reject) => {
      this.socket.addEventListener("open", () => resolve());
      this.socket.addEventListener("error", reject);
    });
  }

  get ready() {
    return this.socket && this.socket.readyState === WebSocket.OPEN;
  }

  sendFrame(payload) {
    if (!this.ready || this.inFlight >= this.maxInFlight) return;
    this.inFlight += 1;
    this.socket.send(JSON.stringify({ type: "frame", ...payload }));
  }

  finish(save = true) {
    if (this.ready) this.socket.send(JSON.stringify({ type: "finish", save }));
  }

  send(payload) {
    if (this.ready) this.socket.send(JSON.stringify(payload));
  }

  reset() {
    if (this.ready) this.socket.send(JSON.stringify({ type: "reset" }));
  }

  close() {
    if (this.socket) this.socket.close();
  }
}
