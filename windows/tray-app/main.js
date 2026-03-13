const { app, Tray, Menu, BrowserWindow, ipcMain, nativeImage } = require('electron');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const gotLock = app.requestSingleInstanceLock();
if (!gotLock) { app.quit(); process.exit(0); }

const USBIP_EXE = 'C:\\Program Files\\USBip\\usbip.exe';
const LISTENER_PATH = 'C:\\Program Files\\ZeroHub\\zerohub-listener.ps1';
const LOG_PATH = 'C:\\ProgramData\\ZeroHub\\zerohub-listener.log';
const TASK_NAME = 'ZeroHub Auto-Attach Listener';

let tray = null;
let settingsWindow = null;
let pollInterval = null;
let connectedDevices = [];
let hubOnline = false;
let serviceRunning = false;

// ── Read Pi IP from listener script ──
function getPiIP() {
  try {
    const content = fs.readFileSync(LISTENER_PATH, 'utf8');
    const match = content.match(/\$PiIP\s*=\s*"([^"]+)"/);
    return match ? match[1] : 'unknown';
  } catch (e) { return 'unknown'; }
}

// ── Write Pi IP to listener script ──
function setPiIP(newIP) {
  try {
    let content = fs.readFileSync(LISTENER_PATH, 'utf8');
    content = content.replace(/(\$PiIP\s*=\s*")[^"]+(")/, `$1${newIP}$2`);
    fs.writeFileSync(LISTENER_PATH, content, 'utf8');
    return true;
  } catch (e) { return false; }
}

// ── Poll actual device state from usbip port ──
function pollDevices() {
  try {
    const output = execSync(`"${USBIP_EXE}" port`, {
      encoding: 'utf8', timeout: 5000, windowsHide: true
    });
    const devices = [];
    const lines = output.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const portMatch = lines[i].match(/Port\s+(\d+):.+at\s+(.+Speed)/);
      if (portMatch && i + 1 < lines.length) {
        const nameMatch = lines[i + 1].match(/^\s+(.+?)\s*:\s*(.+?)\s*\(([0-9a-f]{4}:[0-9a-f]{4})\)/);
        if (nameMatch) {
          devices.push({ port: portMatch[1], name: nameMatch[2].trim(), vid_pid: nameMatch[3] });
        }
      }
    }
    connectedDevices = devices;
    hubOnline = devices.length > 0;
  } catch (e) {
    connectedDevices = [];
  }

  // Check if listener process is on port 3241
  try {
    const netstat = execSync('netstat -ano', { encoding: 'utf8', timeout: 5000, windowsHide: true });
    serviceRunning = netstat.includes(':3241') && netstat.includes('LISTENING');
  } catch (e) {
    serviceRunning = false;
  }

  updateTray();
}

// ── Service control ──
function startService() {
  try { execSync(`schtasks /run /tn "${TASK_NAME}"`, { windowsHide: true }); } catch (e) {}
  setTimeout(pollDevices, 4000);
}

function stopService() {
  try {
    execSync(`powershell -Command "Get-CimInstance Win32_Process -Filter \\"Name='powershell.exe'\\" | ForEach-Object { if ($_.CommandLine -match 'zerohub-listener') { Stop-Process -Id $_.ProcessId -Force } }"`, { windowsHide: true });
  } catch (e) {}
  setTimeout(pollDevices, 2000);
}

function restartService() {
  stopService();
  setTimeout(startService, 3000);
}

// ── Tray ──
function createTray() {
  const iconPath = path.join(__dirname, 'icon.png');
  let img;
  if (fs.existsSync(iconPath)) {
    img = nativeImage.createFromPath(iconPath);
  } else {
    img = nativeImage.createFromDataURL('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAMklEQVQ4T2P8z8Dwn4EIwMjISJwGjAwMDMRpYGBgYCROAwMDAyNxGhgYGBiJ08DAAAAi5AgR+jAF/QAAAABJRU5ErkJggg==');
  }
  tray = new Tray(img);
  tray.setToolTip('ZeroHub Companion');
  updateTray();
}

function updateTray() {
  if (!tray) return;
  const piIP = getPiIP();
  const status = !serviceRunning ? 'Service Stopped' : hubOnline ? 'Online' : 'Waiting for Hub';
  const deviceCount = connectedDevices.length;

  tray.setToolTip(`ZeroHub - ${status} | ${deviceCount} device(s)`);

  const deviceItems = connectedDevices.map(d => ({
    label: `  ${d.name} (${d.vid_pid})`,
    enabled: false
  }));

  const menu = Menu.buildFromTemplate([
    { label: `ZeroHub - ${status}`, enabled: false },
    { type: 'separator' },
    { label: 'Connected Devices:', enabled: false },
    ...(deviceItems.length > 0 ? deviceItems : [{ label: '  No devices', enabled: false }]),
    { type: 'separator' },
    { label: `Pi: ${piIP}`, enabled: false },
    { label: 'Settings...', click: openSettings },
    { label: 'Open Log', click: () => { require('child_process').exec(`notepad "${LOG_PATH}"`); } },
    { type: 'separator' },
    {
      label: serviceRunning ? 'Restart Service' : 'Start Service',
      click: () => { if (serviceRunning) restartService(); else startService(); }
    },
    ...(serviceRunning ? [{ label: 'Stop Service', click: stopService }] : []),
    { type: 'separator' },
    { label: 'Exit', click: () => { if (pollInterval) clearInterval(pollInterval); tray.destroy(); app.quit(); } }
  ]);

  tray.setContextMenu(menu);
}

// ── Settings window ──
function openSettings() {
  if (settingsWindow) { settingsWindow.focus(); return; }
  const piIP = getPiIP();

  settingsWindow = new BrowserWindow({
    width: 380, height: 220, resizable: false, minimizable: false, maximizable: false,
    title: 'ZeroHub Settings', autoHideMenuBar: true,
    webPreferences: { nodeIntegration: true, contextIsolation: false }
  });

  const html = `<!DOCTYPE html>
<html><head><style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Segoe UI', sans-serif; background: #1e1e1e; color: #ccc; padding: 24px; overflow: hidden; }
label { display: block; font-size: 12px; color: #888; margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
input { width: 100%; padding: 10px 12px; background: #2d2d2d; border: 1px solid #444; border-radius: 4px; color: #fff; font-size: 14px; outline: none; }
input:focus { border-color: #0078d4; }
.buttons { margin-top: 20px; display: flex; gap: 10px; justify-content: flex-end; }
button { padding: 8px 20px; border: none; border-radius: 4px; font-size: 13px; cursor: pointer; }
.save { background: #0078d4; color: white; }
.save:hover { background: #006cbd; }
.cancel { background: #333; color: #ccc; }
.cancel:hover { background: #444; }
h2 { font-size: 16px; color: #fff; margin-bottom: 16px; font-weight: 500; }
.note { font-size: 11px; color: #666; margin-top: 8px; }
</style></head><body>
<h2>ZeroHub Settings</h2>
<label>Pi IP Address</label>
<input type="text" id="piIP" value="${piIP}" placeholder="192.168.0.181" />
<div class="note">Saves to listener script and restarts service.</div>
<div class="buttons">
  <button class="cancel" onclick="window.close()">Cancel</button>
  <button class="save" onclick="save()">Save & Restart</button>
</div>
<script>
const { ipcRenderer } = require('electron');
function save() {
  const ip = document.getElementById('piIP').value.trim();
  if (ip && /^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$/.test(ip)) {
    ipcRenderer.send('save-settings', { piIP: ip });
  } else { document.getElementById('piIP').style.borderColor = '#ff4444'; }
}
document.getElementById('piIP').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') save();
  if (e.key === 'Escape') window.close();
});
</script></body></html>`;

  settingsWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(html)}`);
  settingsWindow.on('closed', () => { settingsWindow = null; });
}

ipcMain.on('save-settings', (event, data) => {
  setPiIP(data.piIP);
  if (settingsWindow) { settingsWindow.close(); settingsWindow = null; }
  restartService();
});

// ── App lifecycle ──
app.setAppUserModelId('ZeroHub Companion');

app.on('ready', () => {
  createTray();
  pollDevices();
  pollInterval = setInterval(pollDevices, 5000);
});

app.on('window-all-closed', (e) => { e.preventDefault(); });
app.on('second-instance', () => {});
app.on('before-quit', () => { if (pollInterval) clearInterval(pollInterval); });
