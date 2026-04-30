/**
 * ScriptLoader Platform - Backend Server
 * Terinspirasi dari Luarmor/Junkie
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

// ============================================================
// CONFIG
// ============================================================
const PROMETHEUS_DIR = path.join(__dirname, "..");
const CLI_PATH = path.join(PROMETHEUS_DIR, "cli.lua");
const DATA_DIR = path.join(__dirname, "..", "data");
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || "admin-secret-2024"; // Ganti di production!

// Pastikan folder data ada
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

// ============================================================
// DATABASE (JSON file-based, bisa diganti ke SQLite/MySQL)
// ============================================================
const DB = {
  file: (name) => path.join(DATA_DIR, `${name}.json`),

  read(name) {
    const f = this.file(name);
    if (!fs.existsSync(f)) return [];
    try { return JSON.parse(fs.readFileSync(f, "utf8")); } catch { return []; }
  },

  write(name, data) {
    fs.writeFileSync(this.file(name), JSON.stringify(data, null, 2), "utf8");
  },

  readOne(name) {
    const f = this.file(name);
    if (!fs.existsSync(f)) return {};
    try { return JSON.parse(fs.readFileSync(f, "utf8")); } catch { return {}; }
  },

  writeOne(name, data) {
    fs.writeFileSync(this.file(name), JSON.stringify(data, null, 2), "utf8");
  }
};

// ============================================================
// HELPERS
// ============================================================
function generateKey(prefix = "SCR") {
  const rand = crypto.randomBytes(12).toString("hex").toUpperCase();
  return `${prefix}-${rand.slice(0,4)}-${rand.slice(4,8)}-${rand.slice(8,12)}-${rand.slice(12)}`;
}

function generateId() {
  return crypto.randomBytes(8).toString("hex");
}

function authMiddleware(req, res, next) {
  const token = req.headers["x-admin-token"] || req.query.token;
  if (token !== ADMIN_TOKEN) {
    return res.status(401).json({ error: "Unauthorized. Token admin salah." });
  }
  next();
}

function checkKeyExpiry(key) {
  if (!key.expiresAt) return true; // Permanent
  return new Date() < new Date(key.expiresAt);
}

// ============================================================
// OBFUSCATION (Prometheus Integration)
// ============================================================
function obfuscateCode(code, preset = "Medium") {
  return new Promise((resolve, reject) => {
    const tmpInput = path.join(os.tmpdir(), `sl_in_${Date.now()}.lua`);
    const tmpOutput = tmpInput.replace(".lua", ".obfuscated.lua");
    fs.writeFileSync(tmpInput, code, "utf8");

    const cmd = `lua5.1 "${CLI_PATH}" --preset ${preset} "${tmpInput}"`;
    exec(cmd, { cwd: PROMETHEUS_DIR, timeout: 120000, maxBuffer: 50 * 1024 * 1024 }, (err, stdout, stderr) => {
      try { fs.unlinkSync(tmpInput); } catch {}
      if (err) {
        try { fs.unlinkSync(tmpOutput); } catch {}
        return reject(new Error(stderr || stdout || err.message));
      }
      if (!fs.existsSync(tmpOutput)) return reject(new Error("Output file tidak ditemukan."));
      const result = fs.readFileSync(tmpOutput, "utf8");
      try { fs.unlinkSync(tmpOutput); } catch {}
      resolve(result);
    });
  });
}

// ============================================================
// STATS
// ============================================================
function getStats() {
  const scripts = DB.read("scripts");
  const keys = DB.read("keys");
  const games = DB.read("games");
  const logs = DB.read("execute_logs");

  return {
    totalScripts: scripts.length,
    activeScripts: scripts.filter(s => s.active).length,
    totalKeys: keys.length,
    activeKeys: keys.filter(k => k.active && checkKeyExpiry(k)).length,
    totalGames: games.length,
    totalExecutions: logs.length,
    executionsToday: logs.filter(l => {
      const today = new Date();
      const logDate = new Date(l.timestamp);
      return logDate.toDateString() === today.toDateString();
    }).length
  };
}

// ============================================================
// API ROUTES
// ============================================================

// -- Dashboard Stats
app.get("/api/stats", authMiddleware, (req, res) => {
  res.json(getStats());
});

// ============================================================
// GAME MANAGEMENT
// ============================================================
app.get("/api/games", authMiddleware, (req, res) => {
  res.json(DB.read("games"));
});

app.post("/api/games", authMiddleware, (req, res) => {
  const { name, placeId, description } = req.body;
  if (!name || !placeId) return res.status(400).json({ error: "name dan placeId wajib diisi." });

  const games = DB.read("games");
  const game = {
    id: generateId(),
    name,
    placeId: String(placeId),
    description: description || "",
    active: true,
    createdAt: new Date().toISOString()
  };
  games.push(game);
  DB.write("games", games);
  res.json(game);
});

app.delete("/api/games/:id", authMiddleware, (req, res) => {
  let games = DB.read("games");
  games = games.filter(g => g.id !== req.params.id);
  DB.write("games", games);
  res.json({ success: true });
});

// ============================================================
// SCRIPT MANAGEMENT
// ============================================================
app.get("/api/scripts", authMiddleware, (req, res) => {
  res.json(DB.read("scripts"));
});

app.post("/api/scripts", authMiddleware, async (req, res) => {
  const { name, gameId, code, obfuscate, obfuscatePreset, requireKey } = req.body;
  if (!name || !gameId || !code) return res.status(400).json({ error: "name, gameId, code wajib diisi." });

  let finalCode = code;
  if (obfuscate) {
    try {
      finalCode = await obfuscateCode(code, obfuscatePreset || "Medium");
    } catch (e) {
      return res.status(500).json({ error: "Obfuscation gagal: " + e.message });
    }
  }

  const scripts = DB.read("scripts");
  const script = {
    id: generateId(),
    name,
    gameId,
    code: finalCode,
    originalCode: code,
    obfuscated: !!obfuscate,
    requireKey: requireKey !== false,
    token: crypto.randomBytes(24).toString("hex"), // ← token untuk loadstring
    active: true,
    executions: 0,
    createdAt: new Date().toISOString()
  };
  scripts.push(script);
  DB.write("scripts", scripts);
  const baseUrl = `${req.protocol}://${req.get("host")}`;
  res.json({ ...script, code: undefined, originalCode: undefined, loader: `loadstring(game:HttpGet("${baseUrl}/api/serve/${script.token}"))()` });
});

app.put("/api/scripts/:id", authMiddleware, (req, res) => {
  const scripts = DB.read("scripts");
  const idx = scripts.findIndex(s => s.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Script tidak ditemukan." });

  const { name, active, requireKey } = req.body;
  if (name !== undefined) scripts[idx].name = name;
  if (active !== undefined) scripts[idx].active = active;
  if (requireKey !== undefined) scripts[idx].requireKey = requireKey;
  scripts[idx].updatedAt = new Date().toISOString();

  DB.write("scripts", scripts);
  res.json({ ...scripts[idx], code: undefined });
});

app.delete("/api/scripts/:id", authMiddleware, (req, res) => {
  let scripts = DB.read("scripts");
  scripts = scripts.filter(s => s.id !== req.params.id);
  DB.write("scripts", scripts);
  res.json({ success: true });
});

// ============================================================
// KEY MANAGEMENT
// ============================================================
app.get("/api/keys", authMiddleware, (req, res) => {
  res.json(DB.read("keys"));
});

app.post("/api/keys/generate", authMiddleware, (req, res) => {
  const { gameId, expireDays, note, prefix, count } = req.body;
  const amount = Math.min(parseInt(count) || 1, 100); // max 100 per request

  const keys = DB.read("keys");
  const generated = [];

  for (let i = 0; i < amount; i++) {
    const key = {
      id: generateId(),
      key: generateKey(prefix || "SCR"),
      gameId: gameId || null, // null = berlaku semua game
      note: note || "",
      active: true,
      hwid: null, // akan diisi saat pertama kali digunakan
      uses: 0,
      expiresAt: expireDays ? new Date(Date.now() + parseInt(expireDays) * 86400000).toISOString() : null,
      createdAt: new Date().toISOString()
    };
    keys.push(key);
    generated.push(key);
  }

  DB.write("keys", keys);
  res.json(generated);
});

app.delete("/api/keys/:id", authMiddleware, (req, res) => {
  let keys = DB.read("keys");
  keys = keys.filter(k => k.id !== req.params.id);
  DB.write("keys", keys);
  res.json({ success: true });
});

app.post("/api/keys/:id/revoke", authMiddleware, (req, res) => {
  const keys = DB.read("keys");
  const idx = keys.findIndex(k => k.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Key tidak ditemukan." });
  keys[idx].active = false;
  DB.write("keys", keys);
  res.json({ success: true });
});

app.post("/api/keys/:id/reset-hwid", authMiddleware, (req, res) => {
  const keys = DB.read("keys");
  const idx = keys.findIndex(k => k.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Key tidak ditemukan." });
  keys[idx].hwid = null;
  DB.write("keys", keys);
  res.json({ success: true });
});

// ============================================================
// LOADER ENDPOINTS (dipanggil dari Roblox/game)
// ============================================================

// Validasi key & ambil script
// GET /load?key=SCR-XXXX-XXXX-XXXX-XXXX&game=PLACEID&hwid=HWID
app.get("/load", (req, res) => {
  const { key: keyStr, game: placeId, hwid } = req.query;

  if (!keyStr || !placeId) {
    return res.status(400).send("-- Error: Key dan PlaceID wajib.");
  }

  const keys = DB.read("keys");
  const scripts = DB.read("scripts");
  const games = DB.read("games");
  const logs = DB.read("execute_logs");

  // Cari key
  const keyData = keys.find(k => k.key === keyStr);

  // Cari game
  const gameData = games.find(g => g.placeId === String(placeId));

  if (!gameData) {
    return res.status(403).send('-- Error: Game tidak terdaftar di platform ini.');
  }

  // Cari script untuk game ini (yang aktif)
  const gameScripts = scripts.filter(s => s.gameId === gameData.id && s.active);

  if (gameScripts.length === 0) {
    return res.status(404).send('-- Error: Tidak ada script aktif untuk game ini.');
  }

  // Periksa apakah script butuh key
  const requiresKey = gameScripts.some(s => s.requireKey);

  if (requiresKey) {
    if (!keyData) {
      return res.status(403).send('-- Error: Key tidak valid. Dapatkan key di: https://your-domain.com');
    }
    if (!keyData.active) {
      return res.status(403).send('-- Error: Key sudah dinonaktifkan.');
    }
    if (!checkKeyExpiry(keyData)) {
      return res.status(403).send('-- Error: Key sudah kadaluwarsa.');
    }
    if (keyData.gameId && keyData.gameId !== gameData.id) {
      return res.status(403).send('-- Error: Key tidak berlaku untuk game ini.');
    }

    // HWID Check
    if (hwid) {
      if (!keyData.hwid) {
        // Bind HWID pertama kali
        const idx = keys.findIndex(k => k.key === keyStr);
        keys[idx].hwid = hwid;
        keys[idx].uses = (keys[idx].uses || 0) + 1;
        DB.write("keys", keys);
      } else if (keyData.hwid !== hwid) {
        return res.status(403).send('-- Error: HWID tidak cocok. Key sudah terikat ke perangkat lain.\n-- Reset HWID di dashboard.');
      }
    }
  }

  // Gabungkan semua script untuk game ini
  const combinedCode = gameScripts.map(s => s.code).join("\n\n");

  // Log eksekusi
  logs.push({
    id: generateId(),
    gameId: gameData.id,
    gameName: gameData.name,
    keyUsed: keyStr || "no-key",
    hwid: hwid || "unknown",
    ip: req.ip,
    timestamp: new Date().toISOString()
  });
  // Keep max 10000 logs
  if (logs.length > 10000) logs.splice(0, logs.length - 10000);
  DB.write("execute_logs", logs);

  // Update script executions
  gameScripts.forEach(s => {
    const idx = scripts.findIndex(sc => sc.id === s.id);
    if (idx !== -1) scripts[idx].executions = (scripts[idx].executions || 0) + 1;
  });
  DB.write("scripts", scripts);

  res.setHeader("Content-Type", "text/plain");
  res.send(combinedCode);
});

// Validasi key saja (untuk checkpoint)
app.get("/validate", (req, res) => {
  const { key: keyStr, game: placeId } = req.query;
  const keys = DB.read("keys");
  const games = DB.read("games");

  const keyData = keys.find(k => k.key === keyStr);
  const gameData = games.find(g => g.placeId === String(placeId));

  if (!keyData || !keyData.active || !checkKeyExpiry(keyData)) {
    return res.json({ valid: false, reason: "Key tidak valid atau kadaluwarsa." });
  }
  if (keyData.gameId && gameData && keyData.gameId !== gameData.id) {
    return res.json({ valid: false, reason: "Key tidak berlaku untuk game ini." });
  }

  res.json({ valid: true, expiresAt: keyData.expiresAt });
});

// Execute Logs (admin)
app.get("/api/logs", authMiddleware, (req, res) => {
  const logs = DB.read("execute_logs");
  res.json(logs.slice(-200).reverse()); // 200 log terbaru
});

// ============================================================
// OBFUSCATE STANDALONE (dari web UI)
// ============================================================
app.post("/obfuscate", authMiddleware, async (req, res) => {
  const { code, preset } = req.body;
  if (!code?.trim()) return res.status(400).json({ error: "Kode tidak boleh kosong." });

  const validPresets = ["Minify", "Weak", "Medium", "Strong"];
  const selectedPreset = validPresets.includes(preset) ? preset : "Medium";

  try {
    const result = await obfuscateCode(code, selectedPreset);
    const inputSize = Buffer.byteLength(code, "utf8");
    const outputSize = Buffer.byteLength(result, "utf8");
    res.json({ result, ratio: ((outputSize / inputSize) * 100).toFixed(1), preset: selectedPreset });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// SERVE ENDPOINT (loadstring style — seperti file 2)
// GET /api/serve/:token  →  loadstring(game:HttpGet("URL/api/serve/TOKEN"))()
// ============================================================
app.get("/api/serve/:token", (req, res) => {
  res.type("text");
  const scripts = DB.read("scripts");
  const script = scripts.find(s => s.token === req.params.token);
  if (!script || !script.active) return res.send("-- Invalid or disabled");
  if (!script.code) return res.send("-- Script kosong");

  // Log
  const logs = DB.read("execute_logs");
  logs.push({ id: generateId(), scriptId: script.id, scriptName: script.name, ip: req.ip, timestamp: new Date().toISOString() });
  if (logs.length > 10000) logs.splice(0, logs.length - 10000);
  DB.write("execute_logs", logs);

  // Update executions
  const idx = scripts.findIndex(s => s.token === req.params.token);
  if (idx !== -1) scripts[idx].executions = (scripts[idx].executions || 0) + 1;
  DB.write("scripts", scripts);

  res.setHeader("Cache-Control", "no-store");
  res.send(script.code);
});

// Regenerate token script
app.post("/api/scripts/:id/token", authMiddleware, (req, res) => {
  const scripts = DB.read("scripts");
  const idx = scripts.findIndex(s => s.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Script tidak ditemukan." });
  scripts[idx].token = crypto.randomBytes(24).toString("hex");
  DB.write("scripts", scripts);
  res.json({ token: scripts[idx].token, loader: `loadstring(game:HttpGet("${req.protocol}://${req.get("host")}/api/serve/${scripts[idx].token}"))()` });
});

// ============================================================
// HUB SYSTEM — routing per PlaceId
// loadstring(game:HttpGet("URL/api/serve/hub/TOKEN?placeId=" .. tostring(game.PlaceId)))()
// ============================================================

// Buat hub baru
app.post("/api/hubs", authMiddleware, (req, res) => {
  const { name, routes = {}, fallbackScriptId = null } = req.body;
  if (!name) return res.status(400).json({ error: "name wajib" });
  const hubs = DB.read("hubs");
  const hub = {
    id: generateId(),
    token: crypto.randomBytes(24).toString("hex"),
    name,
    routes,           // { "placeId": "scriptId", ... }
    fallbackScriptId, // script default jika placeId tidak ada di routes
    active: true,
    createdAt: new Date().toISOString()
  };
  hubs.push(hub);
  DB.write("hubs", hubs);
  const baseUrl = `${req.protocol}://${req.get("host")}`;
  res.json({ ...hub, loader: `loadstring(game:HttpGet("${baseUrl}/api/serve/hub/${hub.token}?placeId=" .. tostring(game.PlaceId)))()` });
});

// Daftar semua hub
app.get("/api/hubs", authMiddleware, (req, res) => {
  res.json(DB.read("hubs"));
});

// Detail hub
app.get("/api/hubs/:id", authMiddleware, (req, res) => {
  const hub = DB.read("hubs").find(h => h.id === req.params.id);
  if (!hub) return res.status(404).json({ error: "Hub tidak ditemukan." });
  res.json(hub);
});

// Update hub (nama, routes, fallback, active)
app.put("/api/hubs/:id", authMiddleware, (req, res) => {
  const hubs = DB.read("hubs");
  const idx = hubs.findIndex(h => h.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: "Hub tidak ditemukan." });
  const { name, routes, fallbackScriptId, active } = req.body;
  if (name !== undefined) hubs[idx].name = name;
  if (routes !== undefined) hubs[idx].routes = routes;
  if (fallbackScriptId !== undefined) hubs[idx].fallbackScriptId = fallbackScriptId;
  if (active !== undefined) hubs[idx].active = active;
  DB.write("hubs", hubs);
  res.json(hubs[idx]);
});

// Hapus hub
app.delete("/api/hubs/:id", authMiddleware, (req, res) => {
  let hubs = DB.read("hubs");
  hubs = hubs.filter(h => h.id !== req.params.id);
  DB.write("hubs", hubs);
  res.json({ success: true });
});

// Serve hub — dipanggil dari Roblox
// GET /api/serve/hub/:token?placeId=PLACE_ID
app.get("/api/serve/hub/:token", (req, res) => {
  res.type("text");
  const hubs = DB.read("hubs");
  const hub = hubs.find(h => h.token === req.params.token);
  if (!hub || !hub.active) return res.send("-- Hub not found or disabled");

  const placeId = String(req.query.placeId || "0");
  const scripts = DB.read("scripts");

  // Cari script: cek routes dulu, lalu fallback
  const scriptId = (hub.routes && hub.routes[placeId]) || hub.fallbackScriptId;
  if (!scriptId) return res.send(`game:GetService("Players").LocalPlayer:Kick("⛔ Game ini belum terdaftar.")`);

  const script = scripts.find(s => s.id === scriptId);
  if (!script || !script.active) return res.send("-- Script disabled");
  if (!script.code) return res.send("-- Script kosong");

  // Log
  const logs = DB.read("execute_logs");
  logs.push({ id: generateId(), hubId: hub.id, hubName: hub.name, scriptId: script.id, scriptName: script.name, placeId, ip: req.ip, timestamp: new Date().toISOString() });
  if (logs.length > 10000) logs.splice(0, logs.length - 10000);
  DB.write("execute_logs", logs);

  // Update executions
  const idx = scripts.findIndex(s => s.id === scriptId);
  if (idx !== -1) scripts[idx].executions = (scripts[idx].executions || 0) + 1;
  DB.write("scripts", scripts);

  res.setHeader("Cache-Control", "no-store");
  res.send(script.code);
});

// ============================================================
// SERVER START
// ============================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 ScriptLoader Platform running at http://localhost:${PORT}`);
  console.log(`🔑 Admin Token: ${ADMIN_TOKEN}`);
  console.log(`📁 Data dir: ${DATA_DIR}\n`);
});