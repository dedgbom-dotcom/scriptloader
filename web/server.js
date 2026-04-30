// ============================================================
//  SCRIPTLOADER v5 — Full Featured
// ============================================================
require('dotenv').config();
const express    = require('express');
const crypto     = require('crypto');
const fs         = require('fs');
const path       = require('path');
const https      = require('https');

const app = express();

// ── CONFIG ───────────────────────────────────────────────────
const OWNER_TOKEN      = process.env.OWNER_TOKEN      || 'owner_token_rahasia';
const OWNER_USERNAME   = process.env.OWNER_USERNAME   || 'Owner';
const PORT             = process.env.PORT             || 3000;
const BASE_URL         = process.env.BASE_URL         || '';
const GITHUB_TOKEN     = process.env.GITHUB_TOKEN     || '';
const GITHUB_REPO      = process.env.GITHUB_REPO      || '';
const GITHUB_BRANCH    = process.env.GITHUB_BRANCH    || 'main';
const USE_GITHUB       = !!(GITHUB_TOKEN && GITHUB_REPO);
// Max ukuran script — default 10MB (cukup untuk script hasil obfuskasi besar)
const MAX_SCRIPT_MB    = parseInt(process.env.MAX_SCRIPT_SIZE_MB || '10');
const MAX_SCRIPT_BYTES = MAX_SCRIPT_MB * 1024 * 1024;
const MAX_VERSIONS     = 5; // simpan 5 versi terakhir per script
const ALLOWED_ORIGINS  = (process.env.ALLOWED_ORIGINS || '').split(',').map(s => s.trim()).filter(Boolean);



// ── JSON body parser dengan limit besar ──────────────────────
app.use(express.json({ limit: `${MAX_SCRIPT_MB + 5}mb` }));
app.use(express.static(path.join(__dirname, 'public')));

// ── CORS ─────────────────────────────────────────────────────
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (ALLOWED_ORIGINS.length === 0) {
    // Tidak ada whitelist = hanya izinkan same-origin (tidak set header)
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
  } else if (origin && ALLOWED_ORIGINS.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type,X-Token');
  }
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// ── LOCAL PATH ───────────────────────────────────────────────
const DATA_DIR     = path.join(__dirname, 'data');
const DB_PATH      = path.join(DATA_DIR, 'scripts.json');
const HUB_PATH     = path.join(DATA_DIR, 'hubs.json');
const ADMINS_PATH  = path.join(DATA_DIR, 'admins.json');
const OWNER_PATH   = path.join(DATA_DIR, 'owner.json');
const SCRIPTS_DIR  = path.join(__dirname, 'scripts');
const VERSIONS_DIR = path.join(__dirname, 'versions');
const BACKUP_DIR   = path.join(__dirname, 'backups');

const GH = {
  scripts: 'database/scripts.json',
  hubs:    'database/hubs.json',
  admins:  'database/admins.json',
  owner:   'database/owner.json',
  lua:     id => `scripts/${id}.lua`,
};

[DATA_DIR, SCRIPTS_DIR, VERSIONS_DIR, BACKUP_DIR].forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

// ============================================================
//  SAVE STATUS + WRITE QUEUE
// ============================================================
const saveStatus = { lastOk: null, pending: 0, lastError: null };
const saveQueues = {};
function queueSave(key, asyncFn) {
  if (!saveQueues[key]) saveQueues[key] = Promise.resolve();
  saveStatus.pending++;
  const p = saveQueues[key].then(async () => {
    await asyncFn();
    saveStatus.lastOk = Date.now();
    saveStatus.lastError = null;
  }).catch(e => {
    saveStatus.lastError = e.message;
    console.error(`[Queue] ${key}:`, e.message);
  }).finally(() => { saveStatus.pending = Math.max(0, saveStatus.pending - 1); });
  saveQueues[key] = p.catch(() => {});
  return p;
}

// ============================================================
//  BACKUP OTOMATIS (harian)
// ============================================================
function doBackup() {
  try {
    const ts  = new Date().toISOString().slice(0, 10);
    const dir = path.join(BACKUP_DIR, ts);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    [[DB_PATH,'scripts.json'],[HUB_PATH,'hubs.json'],[ADMINS_PATH,'admins.json']].forEach(([src, dst]) => {
      if (fs.existsSync(src)) fs.copyFileSync(src, path.join(dir, dst));
    });
    // Hapus backup > 7 hari
    const dirs = fs.readdirSync(BACKUP_DIR).sort();
    while (dirs.length > 7) {
      const old = dirs.shift();
      fs.rmSync(path.join(BACKUP_DIR, old), { recursive: true, force: true });
    }
    console.log(`[Backup] Berhasil: ${dir}`);
  } catch(e) { console.error('[Backup] Gagal:', e.message); }
}
// Backup saat startup + tiap 24 jam
doBackup();
setInterval(doBackup, 24 * 60 * 60 * 1000);

// ============================================================
//  GRACEFUL SHUTDOWN — tunggu write queue selesai
// ============================================================
async function gracefulShutdown(sig) {
  console.log(`\n[Shutdown] ${sig} — menunggu antrian selesai...`);
  const pending = Object.values(saveQueues);
  await Promise.allSettled(pending);
  console.log('[Shutdown] Semua data tersimpan. Bye!');
  process.exit(0);
}
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT',  () => gracefulShutdown('SIGINT'));

// ============================================================
//  STORAGE (GitHub)
// ============================================================
const ghShaCache = {};
function githubRequest(method, apiPath, body) {
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.github.com', path: apiPath, method,
      headers: { 'Authorization': `token ${GITHUB_TOKEN}`, 'User-Agent': 'ScriptLoader/5.0', 'Content-Type': 'application/json', 'Accept': 'application/vnd.github+json' },
    }, res => { let d=''; res.on('data',c=>d+=c); res.on('end',()=>{ try{resolve({status:res.statusCode,data:JSON.parse(d)});}catch{resolve({status:res.statusCode,data:d});} }); });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}
async function githubGetFile(fp) {
  if (!USE_GITHUB) return null;
  try {
    const r = await githubRequest('GET', `/repos/${GITHUB_REPO}/contents/${fp}?ref=${GITHUB_BRANCH}`, null);
    if (r.status === 404) return null;
    if (r.status !== 200) throw new Error(`${r.status}`);
    ghShaCache[fp] = r.data.sha;
    return Buffer.from(r.data.content.replace(/\n/g,''),'base64').toString('utf8');
  } catch(e) { console.error(`[Storage] GET ${fp}:`, e.message); return null; }
}
async function githubPutFile(fp, content, retried=false) {
  if (!USE_GITHUB) return;
  try {
    const body = { message: `update ${fp}`, content: Buffer.from(content,'utf8').toString('base64'), branch: GITHUB_BRANCH };
    if (ghShaCache[fp]) body.sha = ghShaCache[fp];
    const r = await githubRequest('PUT', `/repos/${GITHUB_REPO}/contents/${fp}`, body);
    if (r.status===200||r.status===201) { ghShaCache[fp]=r.data.content?.sha; }
    else if ((r.status===409||r.status===422) && !retried) { await githubGetFile(fp); return githubPutFile(fp,content,true); }
    else throw new Error(`${r.status}: ${JSON.stringify(r.data).slice(0,100)}`);
  } catch(e) { console.error(`[Storage] PUT ${fp}:`, e.message); throw e; }
}
async function githubDeleteFile(fp) {
  if (!USE_GITHUB) return;
  try {
    let sha=ghShaCache[fp];
    if (!sha) { const r=await githubRequest('GET',`/repos/${GITHUB_REPO}/contents/${fp}?ref=${GITHUB_BRANCH}`,null); if(r.status===404)return; sha=r.data.sha; }
    await githubRequest('DELETE',`/repos/${GITHUB_REPO}/contents/${fp}`,{ message:`delete ${fp}`, sha, branch:GITHUB_BRANCH });
    delete ghShaCache[fp];
  } catch(e) { console.error(`[Storage] DELETE ${fp}:`, e.message); }
}
async function githubListDir(dir) {
  if (!USE_GITHUB) return [];
  try { const r=await githubRequest('GET',`/repos/${GITHUB_REPO}/contents/${dir}?ref=${GITHUB_BRANCH}`,null); return Array.isArray(r.data)?r.data:[]; }
  catch { return []; }
}

// ── STARTUP LOAD ─────────────────────────────────────────────
async function loadFromStorage() {
  if (!USE_GITHUB) { console.log('[Storage] Mode lokal aktif.'); return; }
  console.log('[Storage] Memuat...');
  const files = [{gh:GH.scripts,local:DB_PATH},{gh:GH.hubs,local:HUB_PATH},{gh:GH.admins,local:ADMINS_PATH},{gh:GH.owner,local:OWNER_PATH}];
  for (const {gh,local} of files) {
    const content = await githubGetFile(gh);
    if (content) { fs.mkdirSync(path.dirname(local),{recursive:true}); fs.writeFileSync(local,content,'utf8'); console.log(`[Storage] ✓ ${gh}`); }
  }
  const luaFiles = (await githubListDir('scripts')).filter(f=>f.name.endsWith('.lua'));
  for (const file of luaFiles) {
    const id=file.name.replace('.lua',''); const c=await githubGetFile(GH.lua(id));
    if(c) fs.writeFileSync(path.join(SCRIPTS_DIR,file.name),c,'utf8');
  }
  if(luaFiles.length) console.log(`[Storage] ✓ ${luaFiles.length} script`);
  console.log('[Storage] Selesai.');
}

// ── DB HELPERS ────────────────────────────────────────────────
const loadDB      = () => { try{return JSON.parse(fs.readFileSync(DB_PATH,'utf8'));}catch{return{scripts:{}};}};
const saveDB      = async db => { fs.writeFileSync(DB_PATH,JSON.stringify(db,null,2)); return queueSave('scripts',()=>USE_GITHUB?githubPutFile(GH.scripts,JSON.stringify(db,null,2)):Promise.resolve()); };
const loadHubDB   = () => { try{return JSON.parse(fs.readFileSync(HUB_PATH,'utf8'));}catch{return{hubs:{}};}};
const saveHubDB   = async db => { fs.writeFileSync(HUB_PATH,JSON.stringify(db,null,2)); return queueSave('hubs',()=>USE_GITHUB?githubPutFile(GH.hubs,JSON.stringify(db,null,2)):Promise.resolve()); };
const loadAdmins  = () => { try{return JSON.parse(fs.readFileSync(ADMINS_PATH,'utf8'));}catch{return{users:{}};}};
const saveAdmins  = async db => { fs.writeFileSync(ADMINS_PATH,JSON.stringify(db,null,2)); return queueSave('admins',()=>USE_GITHUB?githubPutFile(GH.admins,JSON.stringify(db,null,2)):Promise.resolve()); };
const loadOwnerData = () => { try{return JSON.parse(fs.readFileSync(OWNER_PATH,'utf8'));}catch{return{};}};
const saveOwnerData = async d => { fs.writeFileSync(OWNER_PATH,JSON.stringify(d,null,2)); return queueSave('owner',()=>USE_GITHUB?githubPutFile(GH.owner,JSON.stringify(d,null,2)):Promise.resolve()); };

async function saveLuaFile(id, content) {
  fs.writeFileSync(path.join(SCRIPTS_DIR,`${id}.lua`),content,'utf8');
  if(USE_GITHUB) return queueSave(`lua:${id}`,()=>githubPutFile(GH.lua(id),content));
}
async function deleteLuaFile(id) {
  const fp=path.join(SCRIPTS_DIR,`${id}.lua`);
  if(fs.existsSync(fp)) fs.unlinkSync(fp);
  if(USE_GITHUB) await githubDeleteFile(GH.lua(id)).catch(()=>{});
}


// ── VERSIONING ────────────────────────────────────────────────
function saveVersion(id, content) {
  try {
    const dir = path.join(VERSIONS_DIR, id);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir,{recursive:true});
    const ts = Date.now();
    fs.writeFileSync(path.join(dir,`${ts}.lua`), content, 'utf8');
    // Hapus versi lama, simpan MAX_VERSIONS saja
    const versions = fs.readdirSync(dir).filter(f=>f.endsWith('.lua')).sort();
    while (versions.length > MAX_VERSIONS) {
      fs.unlinkSync(path.join(dir, versions.shift()));
    }
  } catch(e) { console.error('[Version] Gagal simpan:', e.message); }
}
function getVersions(id) {
  try {
    const dir=path.join(VERSIONS_DIR,id);
    if(!fs.existsSync(dir)) return [];
    return fs.readdirSync(dir).filter(f=>f.endsWith('.lua')).sort().reverse()
      .map(f=>({ ts:parseInt(f), name:f }));
  } catch { return []; }
}

// ── MIGRATE ──────────────────────────────────────────────────
async function migrateAdmins() {
  const old=path.join(DATA_DIR,'users.json');
  if(fs.existsSync(old)&&!fs.existsSync(ADMINS_PATH)) fs.copyFileSync(old,ADMINS_PATH);
  const db=loadAdmins(); let changed=false;
  for(const[k,u] of Object.entries(db.users)){if(!u.id){u.id=k;changed=true;}}
  if(changed) await saveAdmins(db);
  const od=loadOwnerData();
  if(!od.username) await saveOwnerData({username:OWNER_USERNAME,createdAt:Date.now()});
}

const genToken = (n=32) => crypto.randomBytes(n).toString('hex');
function findUser(db,id){ return db.users[id]||Object.values(db.users).find(u=>u.id===id||u.username===id)||null; }
function resolveToken(token) {
  if(!token) return null;
  if(token===OWNER_TOKEN) return{role:'owner',username:OWNER_USERNAME,id:'owner'};
  const db=loadAdmins(); const u=Object.values(db.users).find(u=>u.token===token&&u.active);
  if(u) return{role:'admin',username:u.username,id:u.id||u.username};
  return null;
}
function getToken(req){ return req.headers['x-token']||null; } // hapus query token — pakai header saja
function canAccess(user,res){ return user.role==='owner'||res.createdBy===user.username; }

// ── MIDDLEWARE ───────────────────────────────────────────────
function requireOwner(req,res,next){ const u=resolveToken(getToken(req)); if(!u||u.role!=='owner')return res.status(401).json({error:'Owner only'}); req.user=u;next(); }
function requireAny(req,res,next){ const u=resolveToken(getToken(req)); if(!u)return res.status(401).json({error:'Unauthorized'}); req.user=u;next(); }

// ── RATE LIMITERS ─────────────────────────────────────────────
function makeRL(max,window_ms=60000,msg='Too many requests'){
  const map=new Map();
  return(req,res,next)=>{
    const ip=req.headers['x-forwarded-for']?.split(',')[0]||req.socket.remoteAddress;
    const now=Date.now(); const hits=(map.get(ip)||[]).filter(t=>now-t<window_ms);
    if(hits.length>=max) return res.status(429).json({error:msg});
    hits.push(now);map.set(ip,hits);next();
  };
}
const rlServe = makeRL(30,60000,'-- Rate limited');
const rlAdmin = makeRL(20,60000,'Terlalu banyak request. Coba lagi nanti.');
const rlLogin = makeRL(5,60000,'Terlalu banyak percobaan login. Tunggu 1 menit.');

function isRobloxRequest(req){
  const sfs=req.headers['sec-fetch-site'];
  if(sfs&&sfs!=='none') return false;
  if(req.headers['sec-ch-ua']&&req.headers['accept-language']) return false;
  return true;
}
function httpGet(url){
  return new Promise((resolve,reject)=>{
    https.get(url,{headers:{'User-Agent':'ScriptLoader/5.0'}},res=>{let d='';res.on('data',c=>d+=c);res.on('end',()=>{try{resolve(JSON.parse(d));}catch{reject(new Error('JSON'));}});}).on('error',reject);
  });
}
function getBaseUrl(req){ return BASE_URL||`${req.protocol}://${req.get('host')}`; }

// ── VALIDASI SCRIPT ───────────────────────────────────────────
function validateScript(script) {
  if(!script||typeof script!=='string') return 'Script tidak boleh kosong.';
  const bytes=Buffer.byteLength(script,'utf8');
  if(bytes>MAX_SCRIPT_BYTES) return `Script terlalu besar: ${(bytes/1024/1024).toFixed(2)}MB. Maksimal ${MAX_SCRIPT_MB}MB.`;
  return null;
}

// ============================================================
//  ENDPOINTS
// ============================================================
app.post('/api/auth', rlLogin, (req,res)=>{
  const u=resolveToken(req.body.token);
  if(!u) return res.json({ok:false});
  res.json({ok:true,role:u.role,username:u.username});
});
app.get('/api/me', requireAny, (req,res)=>res.json({role:req.user.role,username:req.user.username}));
app.get('/api/sync-status', requireAny, (req,res)=>res.json({...saveStatus,ok:!saveStatus.lastError}));
app.get('/api/config', requireAny, (req,res)=>res.json({
  maxScriptMB: MAX_SCRIPT_MB,
}));



// ── USER MANAGEMENT ───────────────────────────────────────────
app.post('/api/users', requireOwner, rlAdmin, async(req,res)=>{
  const{username}=req.body; if(!username) return res.status(400).json({error:'username wajib'});
  const db=loadAdmins(); const id=genToken(8),token=genToken(24);
  db.users[id]={id,token,username,role:'admin',active:true,createdAt:Date.now()};
  await saveAdmins(db); res.json({success:true,id,token,username});
});
app.get('/api/users', requireOwner, (req,res)=>res.json({users:Object.values(loadAdmins().users).map(u=>({id:u.id,username:u.username,role:u.role,active:u.active,createdAt:u.createdAt,token:u.token}))}));
app.patch('/api/users/:id', requireOwner, rlAdmin, async(req,res)=>{
  const db=loadAdmins(),u=findUser(db,req.params.id); if(!u) return res.status(404).json({error:'tidak ditemukan'});
  if(req.body.active!==undefined) u.active=req.body.active;
  await saveAdmins(db); res.json({success:true});
});
app.post('/api/users/:id/regen', requireOwner, rlAdmin, async(req,res)=>{
  const db=loadAdmins(),u=findUser(db,req.params.id); if(!u) return res.status(404).json({error:'tidak ditemukan'});
  u.token=genToken(24); await saveAdmins(db); res.json({success:true,token:u.token});
});
app.delete('/api/users/:id', requireOwner, rlAdmin, async(req,res)=>{
  const db=loadAdmins(),toDel=findUser(db,req.params.id); if(!toDel) return res.status(404).json({error:'tidak ditemukan'});
  delete db.users[Object.keys(db.users).find(k=>db.users[k]===toDel)];
  await saveAdmins(db); res.json({success:true});
});

// ── STATS ─────────────────────────────────────────────────────
app.get('/api/stats', requireAny, (req,res)=>{
  const isOwner=req.user.role==='owner';
  const allS=Object.values(loadDB().scripts);
  const allH=Object.values(loadHubDB().hubs);
  const allA=Object.values(loadAdmins().users);
  const myS=isOwner?allS:allS.filter(s=>s.createdBy===req.user.username);
  const myH=isOwner?allH:allH.filter(h=>h.createdBy===req.user.username);
  // Hitung unique IP
  const ipSet=new Set();
  myS.forEach(s=>(s.loadLogs||[]).forEach(l=>{if(l.ip)ipSet.add(l.ip);}));
  res.json({total:myS.length,active:myS.filter(s=>s.active).length,totalLoads:myS.reduce((a,s)=>a+(s.loads||0),0),hubs:myH.length,admins:isOwner?allA.filter(u=>u.active).length:undefined,uniqueIps:ipSet.size});
});

app.get('/api/stats/trend', requireAny, (req,res)=>{
  const isOwner=req.user.role==='owner';
  const myS=Object.values(loadDB().scripts).filter(s=>isOwner||s.createdBy===req.user.username);
  const range=req.query.range||'24h';
  let buckets=[];
  const now=Date.now();
  if(range==='7d'){
    buckets=Array.from({length:7},(_,i)=>{
      const start=new Date(now-(6-i)*86400000); start.setHours(0,0,0,0);
      const end=new Date(start); end.setHours(23,59,59,999);
      const label=['Min','Sen','Sel','Rab','Kam','Jum','Sab'][start.getDay()]+' '+start.getDate();
      let count=0;
      myS.forEach(s=>(s.loadLogs||[]).forEach(l=>{if(l.ts>=start.getTime()&&l.ts<=end.getTime())count++;}));
      return{label,count};
    });
  } else if(range==='30d'){
    buckets=Array.from({length:30},(_,i)=>{
      const d=new Date(now-(29-i)*86400000); d.setHours(0,0,0,0);
      const end=new Date(d); end.setHours(23,59,59,999);
      const label=`${d.getDate()}/${d.getMonth()+1}`;
      let count=0;
      myS.forEach(s=>(s.loadLogs||[]).forEach(l=>{if(l.ts>=d.getTime()&&l.ts<=end.getTime())count++;}));
      return{label,count};
    });
  } else {
    buckets=Array.from({length:24},(_,i)=>{
      const start=now-(23-i)*3600000,end=start+3600000;
      const label=new Date(start).getHours().toString().padStart(2,'0')+':00';
      let count=0;
      myS.forEach(s=>(s.loadLogs||[]).forEach(l=>{if(l.ts>=start&&l.ts<end)count++;}));
      return{label,count};
    });
  }
  res.json({buckets});
});

// Alert: script yang biasanya ramai tapi 0 load hari ini
app.get('/api/stats/alerts', requireAny, (req,res)=>{
  const isOwner=req.user.role==='owner';
  const myS=Object.values(loadDB().scripts).filter(s=>isOwner||s.createdBy===req.user.username);
  const now=Date.now(), day=86400000;
  const alerts=[];
  for(const s of myS){
    if(!s.active) continue;
    const logs=s.loadLogs||[];
    const yesterday=logs.filter(l=>l.ts>=now-2*day&&l.ts<now-day).length;
    const today=logs.filter(l=>l.ts>=now-day).length;
    if(yesterday>=5&&today===0) alerts.push({id:s.id,name:s.name,yesterday,today,msg:`Biasanya ${yesterday}x/hari tapi hari ini 0 load`});
  }
  res.json({alerts});
});

// ── SCRIPT API ────────────────────────────────────────────────
app.post('/api/upload', requireAny, rlAdmin, async(req,res)=>{
  const{name,script,placeIds=[],description='',oneTime=false,customId='',tags=[],notes=''}=req.body;
  if(!name) return res.status(400).json({error:'Nama wajib diisi.'});
  const sErr=validateScript(script);
  if(sErr) return res.status(400).json({error:sErr});
  if(customId&&!/^[a-zA-Z0-9_-]{1,32}$/.test(customId)) return res.status(400).json({error:'Custom ID tidak valid.'});
  const db=loadDB();
  const id=customId||genToken(8),token=genToken(24);
  if(db.scripts[id]) return res.status(409).json({error:`ID "${id}" sudah dipakai.`});
  await saveLuaFile(id,script);
  saveVersion(id,script);
  db.scripts[id]={id,token,name,description,tags:Array.isArray(tags)?tags:[],notes:notes||'',placeIds:placeIds.map(Number),oneTime,active:true,createdAt:Date.now(),createdBy:req.user.username,loads:0,lastLoad:null,loadLogs:[]};
  await saveDB(db);
  res.json({
    success:true, id, token,
    loader:`loadstring(game:HttpGet("${getBaseUrl(req)}/api/serve/${token}"))()`,
    sizeMB:(Buffer.byteLength(script,'utf8')/1024/1024).toFixed(2),
  });
});

app.get('/api/scripts', requireAny, (req,res)=>{
  const isOwner=req.user.role==='owner';
  const all=Object.values(loadDB().scripts);
  const list=(isOwner?all:all.filter(s=>s.createdBy===req.user.username));
  res.json({scripts:list.map(s=>({id:s.id,name:s.name,description:s.description,tags:s.tags||[],notes:s.notes||'',active:s.active,oneTime:s.oneTime,loads:s.loads,lastLoad:s.lastLoad,createdAt:s.createdAt,placeIds:s.placeIds,token:s.token,createdBy:s.createdBy,uniqueIps:[...new Set((s.loadLogs||[]).map(l=>l.ip).filter(Boolean))].length}))});
});

app.get('/api/scripts/:id', requireAny, (req,res)=>{
  const s=loadDB().scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  res.json({...s,uniqueIps:[...new Set((s.loadLogs||[]).map(l=>l.ip).filter(Boolean))].length});
});

app.get('/api/scripts/:id/content', requireAny, (req,res)=>{
  const s=loadDB().scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  const fp=path.join(SCRIPTS_DIR,`${s.id}.lua`);
  if(!fs.existsSync(fp)) return res.status(404).json({error:'file tidak ada'});
  res.json({content:fs.readFileSync(fp,'utf8')});
});

app.patch('/api/scripts/:id', requireAny, rlAdmin, async(req,res)=>{
  const db=loadDB(),s=db.scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  const{active,name,description,placeIds,oneTime,script,tags,notes}=req.body;
  if(active!==undefined&&req.user.role!=='owner') return res.status(403).json({error:'Hanya owner yang bisa toggle active'});
  if(active!==undefined) s.active=active;
  if(name) s.name=name;
  if(description!==undefined) s.description=description;
  if(placeIds!==undefined) s.placeIds=placeIds.map(Number);
  if(oneTime!==undefined) s.oneTime=oneTime;
  if(tags!==undefined) s.tags=Array.isArray(tags)?tags:[];
  if(notes!==undefined) s.notes=notes;
  if(script){
    const sErr=validateScript(script);
    if(sErr) return res.status(400).json({error:sErr});
    // Simpan versi lama sebelum update
    const oldFp=path.join(SCRIPTS_DIR,`${s.id}.lua`);
    if(fs.existsSync(oldFp)) saveVersion(s.id,fs.readFileSync(oldFp,'utf8'));
    await saveLuaFile(s.id,script);
    s.updatedAt=Date.now();
  }
  await saveDB(db); res.json({success:true});
});

app.delete('/api/scripts/:id', requireAny, rlAdmin, async(req,res)=>{
  const db=loadDB(),s=db.scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  await deleteLuaFile(req.params.id);
  delete db.scripts[req.params.id];
  await saveDB(db); res.json({success:true});
});

// Duplikasi script
app.post('/api/scripts/:id/duplicate', requireAny, rlAdmin, async(req,res)=>{
  const db=loadDB(),s=db.scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  const fp=path.join(SCRIPTS_DIR,`${s.id}.lua`);
  if(!fs.existsSync(fp)) return res.status(404).json({error:'File script tidak ada'});
  const content=fs.readFileSync(fp,'utf8');
  const newId=genToken(8),newToken=genToken(24);
  await saveLuaFile(newId,content);
  db.scripts[newId]={...s,id:newId,token:newToken,name:s.name+' (copy)',active:false,createdAt:Date.now(),createdBy:req.user.username,loads:0,lastLoad:null,loadLogs:[]};
  await saveDB(db);
  res.json({success:true,id:newId});
});

// Bulk action
app.post('/api/scripts/bulk', requireAny, rlAdmin, async(req,res)=>{
  const{action,ids}=req.body;
  if(!Array.isArray(ids)||!ids.length) return res.status(400).json({error:'IDs wajib'});
  if(!['activate','deactivate','delete'].includes(action)) return res.status(400).json({error:'Action tidak valid'});
  const db=loadDB(); let count=0;
  for(const id of ids){
    const s=db.scripts[id]; if(!s||!canAccess(req.user,s)) continue;
    if(action==='activate'){ if(req.user.role==='owner'){s.active=true;count++;} }
    else if(action==='deactivate'){ if(req.user.role==='owner'){s.active=false;count++;} }
    else if(action==='delete'){ await deleteLuaFile(id); delete db.scripts[id]; count++; }
  }
  await saveDB(db); res.json({success:true,count});
});

// Version history
app.get('/api/scripts/:id/versions', requireAny, (req,res)=>{
  const s=loadDB().scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  res.json({versions:getVersions(req.params.id)});
});
app.get('/api/scripts/:id/versions/:ts', requireAny, (req,res)=>{
  const s=loadDB().scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  const fp=path.join(VERSIONS_DIR,req.params.id,`${req.params.ts}.lua`);
  if(!fs.existsSync(fp)) return res.status(404).json({error:'Versi tidak ditemukan'});
  res.json({content:fs.readFileSync(fp,'utf8'),ts:parseInt(req.params.ts)});
});
app.post('/api/scripts/:id/versions/:ts/restore', requireAny, rlAdmin, async(req,res)=>{
  const db=loadDB(),s=db.scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  const fp=path.join(VERSIONS_DIR,req.params.id,`${req.params.ts}.lua`);
  if(!fs.existsSync(fp)) return res.status(404).json({error:'Versi tidak ditemukan'});
  const content=fs.readFileSync(fp,'utf8');
  const curFp=path.join(SCRIPTS_DIR,`${s.id}.lua`);
  if(fs.existsSync(curFp)) saveVersion(s.id,fs.readFileSync(curFp,'utf8'));
  await saveLuaFile(s.id,content);
  s.updatedAt=Date.now(); await saveDB(db);
  res.json({success:true});
});

app.post('/api/scripts/:id/regen', requireAny, rlAdmin, async(req,res)=>{
  const db=loadDB(),s=db.scripts[req.params.id]; if(!s) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,s)) return res.status(403).json({error:'Akses ditolak'});
  s.token=genToken(24); s.loads=0; s.loadLogs=[];
  await saveDB(db);
  res.json({success:true,loader:`loadstring(game:HttpGet("${getBaseUrl(req)}/api/serve/${s.token}"))()` });
});

// ── GAME INFO ─────────────────────────────────────────────────
app.get('/api/roblox/game/:placeId', requireAny, async(req,res)=>{
  const placeId=parseInt(req.params.placeId); if(!placeId) return res.status(400).json({error:'Invalid'});
  try {
    const [info,thumb]=await Promise.all([
      httpGet(`https://games.roblox.com/v1/games/multiget-place-details?placeIds=${placeId}`),
      httpGet(`https://thumbnails.roblox.com/v1/places/gameicons?placeIds=${placeId}&returnPolicy=PlaceHolder&size=256x256&format=Png&isCircular=false`),
    ]);
    const game=Array.isArray(info)?info[0]:null;
    res.json({placeId,name:game?.name||'Unknown',creator:game?.builder||'',thumbnail:thumb?.data?.[0]?.imageUrl||null});
  } catch(e){ res.status(500).json({error:e.message}); }
});

// ── HUB API ───────────────────────────────────────────────────
app.post('/api/hubs', requireAny, rlAdmin, async(req,res)=>{
  const{name,routes={},fallbackScriptId=null}=req.body; if(!name) return res.status(400).json({error:'name wajib'});
  const db=loadHubDB(); const id=genToken(8),token=genToken(24);
  db.hubs[id]={id,token,name,routes,fallbackScriptId,active:true,createdAt:Date.now(),createdBy:req.user.username};
  await saveHubDB(db);
  res.json({success:true,id,token,loader:`loadstring(game:HttpGet("${getBaseUrl(req)}/api/serve/hub/${token}?placeId=" .. tostring(game.PlaceId)))()`});
});
app.get('/api/hubs', requireAny, (req,res)=>{
  const isOwner=req.user.role==='owner'; const all=Object.values(loadHubDB().hubs);
  res.json({hubs:isOwner?all:all.filter(h=>h.createdBy===req.user.username)});
});
app.get('/api/hubs/:id', requireAny, (req,res)=>{
  const h=loadHubDB().hubs[req.params.id]; if(!h) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,h)) return res.status(403).json({error:'Akses ditolak'}); res.json(h);
});
app.patch('/api/hubs/:id', requireAny, rlAdmin, async(req,res)=>{
  const db=loadHubDB(),h=db.hubs[req.params.id]; if(!h) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,h)) return res.status(403).json({error:'Akses ditolak'});
  const{name,routes,fallbackScriptId,active}=req.body;
  if(active!==undefined&&req.user.role!=='owner') return res.status(403).json({error:'Hanya owner yang bisa toggle active hub'});
  if(name!==undefined) h.name=name; if(routes!==undefined) h.routes=routes;
  if(fallbackScriptId!==undefined) h.fallbackScriptId=fallbackScriptId; if(active!==undefined) h.active=active;
  await saveHubDB(db); res.json({success:true,hub:h});
});
app.delete('/api/hubs/:id', requireAny, rlAdmin, async(req,res)=>{
  const db=loadHubDB(),h=db.hubs[req.params.id]; if(!h) return res.status(404).json({error:'tidak ditemukan'});
  if(!canAccess(req.user,h)) return res.status(403).json({error:'Akses ditolak'});
  delete db.hubs[req.params.id]; await saveHubDB(db); res.json({success:true});
});

// ── SERVE (dari Roblox) ───────────────────────────────────────
app.get('/api/serve/hub/:token', rlServe, async(req,res)=>{
  res.type('text'); if(!isRobloxRequest(req)) return res.send('-- Access denied');
  const hub=Object.values(loadHubDB().hubs).find(h=>h.token===req.params.token);
  if(!hub||!hub.active) return res.send('-- Hub not found');
  const placeId=String(req.query.placeId||'0'); const sdb=loadDB();
  const scriptId=hub.routes?.[placeId]||hub.fallbackScriptId;
  if(!scriptId) return res.send(`game:GetService("Players").LocalPlayer:Kick("⛔ Game ini belum terdaftar.")`);
  const script=sdb.scripts[scriptId]; if(!script||!script.active) return res.send('-- Script disabled');
  const fp=path.join(SCRIPTS_DIR,`${script.id}.lua`);
  if(!fs.existsSync(fp)) return res.send('-- File missing');
  const code=fs.readFileSync(fp,'utf8');
  const ip=req.headers['x-forwarded-for']?.split(',')[0]||req.socket.remoteAddress;
  const now=Date.now();
  script.loads=(script.loads||0)+1; script.lastLoad=now;
  script.loadLogs=script.loadLogs||[];
  script.loadLogs.push({ts:now,ip,ua:req.headers['user-agent']||'',hub:hub.id,placeId});
  if(script.loadLogs.length>500) script.loadLogs=script.loadLogs.slice(-500);
  if(script.oneTime){ script.active=false; console.log(`[OneTime] ${script.id} dipicu!`); }
  sdb.scripts[scriptId]=script; res.setHeader('Cache-Control','no-store'); res.send(code);
  saveDB(sdb).catch(e=>console.error('[serve/hub] saveDB:',e.message));
});
app.get('/api/serve/:token', rlServe, async(req,res)=>{
  res.type('text'); if(!isRobloxRequest(req)) return res.send('-- Access denied');
  const db=loadDB(); const script=Object.values(db.scripts).find(s=>s.token===req.params.token);
  if(!script||!script.active) return res.send('-- Invalid or disabled');
  const fp = path.join(SCRIPTS_DIR, `${script.id}.lua`);
  if(!fs.existsSync(fp)) return res.send('-- [ScriptLoader] File missing');
  const code=fs.readFileSync(fp,'utf8');
  const ip=req.headers['x-forwarded-for']?.split(',')[0]||req.socket.remoteAddress;
  const now=Date.now();
  script.loads=(script.loads||0)+1; script.lastLoad=now;
  script.loadLogs=script.loadLogs||[];
  script.loadLogs.push({ts:now,ip,ua:req.headers['user-agent']||''});
  if(script.loadLogs.length>500) script.loadLogs=script.loadLogs.slice(-500);
  if(script.oneTime){ script.active=false; console.log(`[OneTime] ${script.id} dipicu!`); }
  res.setHeader('Cache-Control','no-store'); res.send(code);
  saveDB(db).catch(e=>console.error('[serve] saveDB:',e.message));
});

// ── START ─────────────────────────────────────────────────────
loadFromStorage().then(async()=>{
  await migrateAdmins();
  app.listen(PORT,()=>{
    console.log(`[ScriptLoader v5] Port ${PORT} | Owner: ${OWNER_USERNAME}`);
    console.log(`  ✅ Max script size: ${MAX_SCRIPT_MB}MB`);
    console.log(`  ✅ Version history: simpan ${MAX_VERSIONS} versi per script`);
    console.log(`  ✅ Backup harian aktif → ${BACKUP_DIR}`);
    console.log(`  ✅ Graceful shutdown aktif`);
    console.log(`  ✅ Token hanya via header X-Token`);
    if(!USE_GITHUB) console.log(`  ⚠️  Storage cloud tidak aktif!`);
  });
});
