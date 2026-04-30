const express = require("express");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

const app = express();
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
app.use(express.static(path.join(__dirname, "public")));

// Path ke folder Prometheus (sesuaikan jika berbeda)
const PROMETHEUS_DIR = path.join(__dirname, "..");
const CLI_PATH = path.join(PROMETHEUS_DIR, "cli.lua");

app.post("/obfuscate", (req, res) => {
  const { code, preset } = req.body;

  if (!code || !code.trim()) {
    return res.status(400).json({ error: "Kode Lua tidak boleh kosong." });
  }

  const validPresets = ["Minify", "Weak", "Medium", "Strong"];
  const selectedPreset = validPresets.includes(preset) ? preset : "Medium";

  // Buat file temp
  const tmpInput = path.join(os.tmpdir(), `prometheus_in_${Date.now()}.lua`);
  const tmpOutput = tmpInput.replace(".lua", ".obfuscated.lua");

  fs.writeFileSync(tmpInput, code, "utf8");

  const cmd = `lua5.1 "${CLI_PATH}" --preset ${selectedPreset} "${tmpInput}"`;

  exec(cmd, { cwd: PROMETHEUS_DIR, timeout: 300000, maxBuffer: 100 * 1024 * 1024 }, (err, stdout, stderr) => {
    // Cleanup input
    try { fs.unlinkSync(tmpInput); } catch {}

    if (err) {
      try { fs.unlinkSync(tmpOutput); } catch {}
      // Ambil pesan error yang relevan
      const errMsg = stderr || stdout || err.message;
      const match = errMsg.match(/PROMETHEUS:.*Error.*/);
      return res.status(500).json({
        error: match ? match[0].replace("PROMETHEUS: ", "") : errMsg.split("\n")[0],
      });
    }

    // Baca output
    if (!fs.existsSync(tmpOutput)) {
      return res.status(500).json({ error: "File output tidak ditemukan." });
    }

    const result = fs.readFileSync(tmpOutput, "utf8");
    try { fs.unlinkSync(tmpOutput); } catch {}

    // Hitung ukuran
    const inputSize = Buffer.byteLength(code, "utf8");
    const outputSize = Buffer.byteLength(result, "utf8");
    const ratio = ((outputSize / inputSize) * 100).toFixed(1);

    return res.json({ result, ratio, preset: selectedPreset });
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Prometheus Web UI berjalan di http://localhost:${PORT}`);
});