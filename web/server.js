/**
 * ScriptLoader Platform - Backend Server
 * Hub Edition — No Key System
 * Compatible dengan Prometheus Obfuscator
 */

const express = require("express");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");
const crypto = require("crypto");

const app = express();
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
app.use(express.static(path.join(__dirname, "public")));

const PROMETHEUS_DIR = path.join(__dirname, "..");
const CLI_PATH = path.join(PROMETHEUS_DIR, "cli.lua");
const DATA_DIR = path.join(__dirname, "..", "data");
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || "admin-secret-2024";

if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

const DB = {
  file: (name) => path.join(DATA_DIR, `${name}.json`),
  read(name) {
    const f = this.file(name);
    if (!fs.existsSync(f)) return [];
    try { return JSON.parse(fs.readFileSync(f, "utf8")); } catch { return []; }
  },
  write(name, data) {
    fs.writeFileSync(this.file(name), JSON.stringify(data, null, 2), "utf8");
  }
};

function generateId() {
  return crypto.randomBytes(8).toString("hex");
}

function authMiddleware(req, res, next) {
  const token = req.headers["x-admin-token"] || req.query.token;
  if (token !== ADMIN_TOKEN) return res.status(401).json({ error: "Unauthorized." });
  next();
}

function obfuscateCode(code, preset = "Medium") {
  return new Promise((resolve, reject) => {
    const tmpInput = path.join(os.tmpdir(), `sl_in_${Date.now()}.lua`);
    const tmpOutput = tmpInput.replace(".lua", ".obfuscated.lua");
    fs.writeFileSync(tmpInput, code, "utf8");
    const cmd = `lua5.1 "${CLI_PATH}" --preset ${preset} "${tmpInput}"`;
    exec(cmd, { cwd: PROMETHEUS_DIR, timeout: 120000, maxBuffer: 50 * 1024 * 1024 }, (err, stdout, stderr) => {
      try { fs.unlinkSync(tmpInput); } catch {}
      if (err) { try { fs.unlinkSync(tmpOutput); } catch {} return reject(new Error(stderr || stdout || err.message)); }
      if (!fs.existsSync(tmpOutput)) return reject(new Error("Output file tidak ditemukan."));
      const result = fs.readFileSync(tmpOutput, "utf8");
      try { fs.unlinkSync(tmpOutput); } catch {}
      resolve(result);
    });
  });
}

function getStats() {
  const scripts = DB.read("scripts");
  const games = DB.read("games");
  const logs = DB.read("execute_logs");
  return {
    totalScripts: scripts.length,
    activeScripts: scripts.filter(s => s.active).length,
    totalGames: games.length,
    totalExecutions: logs.length,
    executionsToday: logs.filter(l => new Date(l.timestamp).toDateString() === new Date().toDateString()).length
  };
}

// Stats
app.get("/api/stats", authMiddleware, (req, res) => res.json(getStats()));

// Games
app.get("/api/games", authMiddleware, (req, res) => res.json(DB.read("games")));

app.post("/api/games", authMiddleware, (req, res) => {
  const { name, placeId, description } = req.body;
  if (!name || !placeId) return res.status(400).json({ error: "name dan placeId wajib diisi." });
  const games = DB.read("games");
  const game = { id: generateId(), name, placeId: String(placeId), description: description || "", active: true, createdAt: new Date().toISOString() };
  games.push(game);
  DB.write("games", games);
  res.json(game);
});

app.delete("/api/games/:id", authMiddleware, (req, res) => {
  DB.write("games", DB.read("games").filter(g => g.id !== req.params.id));
  res.json({ success: true });
});

// Scripts
app.get("/api/scripts", authMiddleware, (req, res) => res.json(DB.read("scripts")));

app.post("/api/scripts", authMiddleware, async (req, res) => {
  const { name, gameId, code, obfuscate, obfuscatePreset } = req.body;
  if (!name || !gameId || !code) return res.status(400).json({ error: "name, gameId, code wajib diisi." });

  let finalCode = code;
  if (obfuscate) {
    try { finalCode = await obfuscateCode(code, obfuscatePreset || "Medium"); }
    catch (e) { return res.status(500).json({ error: "Obfuscation gagal: " + e.message }); }
  }

  const scripts = DB.read("scripts");
  const script = { id: generateId(), name, gameId, code: finalCode, originalCode: code, obfuscated: !!obfuscate, active: true, executions: 0, createdAt: new Date().toISOString() };
  scripts.push(script);
  DB.write("scripts", scripts);
  res.json({ ...script, code: undefined, originalCode: undefined });
});

app.put("/api/scripts/:id", authMiddleware, (req, res) => {
  const scripts = DB.read("scripts");
  const idx = scripts.findIndex(s => s.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Script tidak ditemukan." });
  const { name, active } = req.body;
  if (name !== undefined) scripts[idx].name = name;
  if (active !== undefined) scripts[idx].active = active;
  scripts[idx].updatedAt = new Date().toISOString();
  DB.write("scripts", scripts);
  res.json({ ...scripts[idx], code: undefined });
});

app.delete("/api/scripts/:id", authMiddleware, (req, res) => {
  DB.write("scripts", DB.read("scripts").filter(s => s.id !== req.params.id));
  res.json({ success: true });
});

// ============================================================
// HUB ENDPOINT — 1 loadstring untuk semua game
// GET /hub?game=PLACEID  (dipanggil dari Roblox)
// ============================================================
app.get("/hub", (req, res) => {
  const placeId = String(req.query.game || req.query.place || "");
  if (!placeId) return res.status(400).send("-- Error: PlaceId tidak dikirim.");

  const scripts = DB.read("scripts");
  const games = DB.read("games");
  const logs = DB.read("execute_logs");

  const gameData = games.find(g => g.placeId === placeId);
  if (!gameData || !gameData.active) {
    return res.status(404).send(`-- Error: Game PlaceId ${placeId} tidak terdaftar.`);
  }

  const gameScripts = scripts.filter(s => s.gameId === gameData.id && s.active);
  if (gameScripts.length === 0) {
    return res.status(404).send(`-- Error: Tidak ada script aktif untuk game ini.`);
  }

  const combinedCode = gameScripts.map(s => s.code).join("\n\n");

  logs.push({ id: generateId(), gameId: gameData.id, gameName: gameData.name, ip: req.ip, timestamp: new Date().toISOString() });
  if (logs.length > 10000) logs.splice(0, logs.length - 10000);
  DB.write("execute_logs", logs);

  gameScripts.forEach(s => {
    const idx = scripts.findIndex(sc => sc.id === s.id);
    if (idx !== -1) scripts[idx].executions = (scripts[idx].executions || 0) + 1;
  });
  DB.write("scripts", scripts);

  res.setHeader("Content-Type", "text/plain");
  res.send(combinedCode);
});

// Logs
app.get("/api/logs", authMiddleware, (req, res) => {
  res.json(DB.read("execute_logs").slice(-200).reverse());
});

// Obfuscate
app.post("/obfuscate", authMiddleware, async (req, res) => {
  const { code, preset } = req.body;
  if (!code?.trim()) return res.status(400).json({ error: "Kode tidak boleh kosong." });
  const validPresets = ["Minify", "Weak", "Medium", "Strong"];
  const selectedPreset = validPresets.includes(preset) ? preset : "Medium";
  try {
    const result = await obfuscateCode(code, selectedPreset);
    const ratio = ((Buffer.byteLength(result) / Buffer.byteLength(code)) * 100).toFixed(1);
    res.json({ result, ratio, preset: selectedPreset });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 ScriptLoader Hub running at http://localhost:${PORT}`);
  console.log(`🔑 Admin Token: ${ADMIN_TOKEN}`);
  console.log(`📡 Hub endpoint: http://localhost:${PORT}/hub?game=PLACEID\n`);
});