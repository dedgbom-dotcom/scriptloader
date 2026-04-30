# ⚡ ScriptLoader Platform

Platform script loader seperti Luarmor/Junkie — 1 loader untuk banyak game.

> **Attribution**: Based on [Prometheus](https://github.com/prometheus-lua/Prometheus) by Elias Oelschner

---

## 🏗 Arsitektur

```
scriptloader-main/
├── web/
│   ├── server.js          ← Backend API (Express.js)
│   ├── public/
│   │   └── index.html     ← Admin Dashboard
│   └── package.json
├── data/                  ← Storage JSON (auto-generated)
│   ├── games.json
│   ├── scripts.json
│   ├── keys.json
│   └── execute_logs.json
├── src/                   ← Prometheus obfuscator engine
└── cli.lua                ← Prometheus CLI
```

---

## 🚀 Cara Menjalankan

### 1. Install dependencies
```bash
cd web
npm install
```

### 2. Set admin token (penting untuk security!)
```bash
export ADMIN_TOKEN="token-rahasia-kamu-2024"
```

### 3. Jalankan server
```bash
npm start
# atau untuk development:
npm run dev
```

Server berjalan di `http://localhost:3000`

---

## 🔑 API Endpoints

### Admin API (butuh header `x-admin-token`)

| Method | URL | Deskripsi |
|--------|-----|-----------|
| GET | `/api/stats` | Statistik dashboard |
| GET | `/api/games` | List semua game |
| POST | `/api/games` | Tambah game baru |
| DELETE | `/api/games/:id` | Hapus game |
| GET | `/api/scripts` | List semua script |
| POST | `/api/scripts` | Upload script baru |
| PUT | `/api/scripts/:id` | Update script |
| DELETE | `/api/scripts/:id` | Hapus script |
| GET | `/api/keys` | List semua key |
| POST | `/api/keys/generate` | Generate keys |
| POST | `/api/keys/:id/revoke` | Revoke key |
| POST | `/api/keys/:id/reset-hwid` | Reset HWID binding |
| DELETE | `/api/keys/:id` | Hapus key |
| GET | `/api/logs` | Execute logs |
| POST | `/obfuscate` | Obfuscate Lua code |

### Public API (dipanggil dari game)

| Method | URL | Deskripsi |
|--------|-----|-----------|
| GET | `/load?key=KEY&game=PLACEID&hwid=HWID` | Load & execute script |
| GET | `/validate?key=KEY&game=PLACEID` | Validasi key saja |

---

## 🎮 Cara Pakai (Flow Lengkap)

### 1. Setup Game
- Buka Dashboard → Games → Add Game
- Masukkan nama game dan Place ID Roblox

### 2. Upload Script
- Dashboard → Scripts → Upload Script
- Pilih game tujuan
- Paste kode Lua
- Centang "Obfuscate" untuk proteksi kode
- Centang "Wajib Key" untuk key system

### 3. Generate Key
- Dashboard → Key System → Generate Keys
- Atur jumlah, game, prefix, dan expiry
- Share key ke user

### 4. Loader di Roblox
- Dashboard → Loader Template
- Copy script loader
- Ganti PLACE_ID dengan Place ID game kamu
- User ganti KEY dengan key mereka
- Jalankan di executor

---

## 🔐 Fitur Key System

- **HWID Binding**: Key otomatis terikat ke device pertama yang pakai
- **Reset HWID**: Admin bisa reset binding untuk pindah device
- **Expiry**: Key bisa dibuat dengan masa berlaku
- **Per-game key**: Key bisa dibatasi untuk 1 game saja
- **Revoke**: Key bisa dinonaktifkan kapan saja
- **Bulk generate**: Bisa generate banyak key sekaligus (max 100)

---

## 🔒 Production Setup

```bash
# Ganti token default
export ADMIN_TOKEN="GANTI_INI_DENGAN_TOKEN_KUAT"

# Gunakan PM2 untuk keep alive
npm install -g pm2
pm2 start web/server.js --name scriptloader

# Nginx sebagai reverse proxy (opsional)
# Arahkan domain ke port 3000
```

---

## 📝 Contoh Loader Roblox

```lua
local SERVER_URL = "https://domain-kamu.com"
local KEY = "SCR-XXXX-XXXX-XXXX" -- dari user
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()

local ok, result = pcall(function()
    return game:HttpGet(SERVER_URL .. "/load?key=" .. KEY 
        .. "&game=" .. game.PlaceId .. "&hwid=" .. HWID)
end)

if ok and not result:match("^%-%- Error") then
    local fn = loadstring(result)
    if fn then pcall(fn) end
end
```