const { app, Tray, Menu, BrowserWindow, ipcMain, nativeImage, Notification } = require('electron');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const gotLock = app.requestSingleInstanceLock();
if (!gotLock) { app.quit(); }

const CONFIG_PATH = path.join(app.getPath('userData'), 'config.json');
const LOG_PATH = path.join(require('os').homedir(), 'zerohub-listener.log');
const TASK_NAME = 'ZeroHub Listener Service';

let tray = null;
let settingsWindow = null;
let config = { piIP: '192.168.0.181' };
let lastLogSize = 0;
let hubOnline = false;
let connectedDevices = {};
let pollInterval = null;
let initialReadDone = false;

function loadConfig() {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
    }
  } catch (e) {}
}

function saveConfig() {
  const dir = path.dirname(CONFIG_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
}

function showNotify(title, body) {
  const notifyVbs = path.join(require('os').homedir(), 'Documents', 'ZeroHub', 'zerohub-notify.vbs');
  try {
    execSync(`wscript.exe "${notifyVbs}" -Title "${title}" -Message "${body}" -Type Info`, { windowsHide: true, timeout: 5000 });
  } catch (e) {}
}

function isServiceRunning() {
  try {
    const result = execSync(`powershell -Command "(Get-ScheduledTask -TaskName '${TASK_NAME}' -ErrorAction SilentlyContinue).State"`, { encoding: 'utf8', windowsHide: true }).trim();
    return result === 'Running';
  } catch (e) { return false; }
}

function startService() {
  try { execSync(`powershell -Command "Start-ScheduledTask -TaskName '${TASK_NAME}'"`, { windowsHide: true }); } catch (e) {}
}

function stopService() {
  try {
    execSync(`powershell -Command "Stop-ScheduledTask -TaskName '${TASK_NAME}'"`, { windowsHide: true });
    execSync(`powershell -Command "Get-Process powershell | Where-Object { $_.CommandLine -match 'usbip-listener' } | Stop-Process -Force -ErrorAction SilentlyContinue"`, { windowsHide: true });
  } catch (e) {}
}

function restartService() {
  stopService();
  setTimeout(() => startService(), 2000);
}

function parseLog() {
  try {
    if (!fs.existsSync(LOG_PATH)) return;
    const stats = fs.statSync(LOG_PATH);
    if (stats.size === lastLogSize) return;

    // Read new bytes only (for notifications)
    let newLines = [];
    if (initialReadDone && stats.size > lastLogSize) {
      const newSize = stats.size - lastLogSize;
      if (newSize > 0 && newSize < 50000) {
        const fd = fs.openSync(LOG_PATH, 'r');
        const buf = Buffer.alloc(newSize);
        fs.readSync(fd, buf, 0, newSize, lastLogSize);
        fs.closeSync(fd);
        newLines = buf.toString('utf8').split('\n').filter(l => l.trim());
      }
    }

    // Read tail of log for state
    const fd = fs.openSync(LOG_PATH, 'r');
    const readSize = Math.min(4096, stats.size);
    const buffer = Buffer.alloc(readSize);
    fs.readSync(fd, buffer, 0, readSize, Math.max(0, stats.size - readSize));
    fs.closeSync(fd);

    const lines = buffer.toString('utf8').split('\n').filter(l => l.trim());
    const newDevices = {};
    let newHubOnline = false;

    for (const line of lines) {
      if (line.includes('Hub announced')) newHubOnline = true;
      if (line.includes('Listener starting')) newHubOnline = false;

      const attachMatch = line.match(/ATTACHING (\S+) \((.+?)\) from/);
      if (attachMatch) {
        newDevices[attachMatch[1]] = { name: attachMatch[2], status: 'attaching' };
      }
      if (line.includes('succesfully attached')) {
        const lastKey = Object.keys(newDevices).pop();
        if (lastKey) newDevices[lastKey].status = 'connected';
      }
      if (line.match(/Result:.*error|Result:.*fail/i)) {
        const lastKey = Object.keys(newDevices).pop();
        if (lastKey) newDevices[lastKey].status = 'failed';
      }
      const removeMatch = line.match(/Device removed.*busid=(\S+)/);
      if (removeMatch) delete newDevices[removeMatch[1]];
    }

    connectedDevices = {};
    for (const [id, dev] of Object.entries(newDevices)) {
      if (dev.status === 'connected') connectedDevices[id] = dev.name;
    }

    // Notifications - only for genuinely new log lines
    if (initialReadDone && newLines.length > 0) {
      for (const line of newLines) {
        if (line.includes('Hub announced')) {
          const m = line.match(/Hub announced - (.+)/);
          showNotify('ZeroHub', (m ? m[1] : 'Hub') + ' connected');
        }
        if (line.includes('succesfully attached')) {
          // Look back in newLines for the ATTACHING line
          const idx = newLines.indexOf(line);
          for (let i = idx - 1; i >= Math.max(0, idx - 5); i--) {
            const am = newLines[i].match(/ATTACHING \S+ \((.+?)\) from/);
            if (am) { showNotify('ZeroHub', am[1] + ' connected'); break; }
          }
        }
        if (line.includes('Device removed')) {
          const rm = line.match(/busid=(\S+)/);
          if (rm) showNotify('ZeroHub', (connectedDevices[rm[1]] || rm[1]) + ' disconnected');
        }
      }
    }

    hubOnline = newHubOnline;
    lastLogSize = stats.size;
    initialReadDone = true;
    updateTray();
  } catch (e) {}
}

function createTrayIcon() {
  const iconPath = path.join(__dirname, 'icon.png');
  let img;
  if (fs.existsSync(iconPath)) {
    img = nativeImage.createFromPath(iconPath);
  } else {
    img = nativeImage.createFromDataURL('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAOklEQVQ4T2NkYPj/n4EBCRiRBRgYGBiZkAUYGRkZmNAFGBkZGZnQBRgZGRmZ0AUYGRkZmdAFAAAKZAgRBjsW3QAAAABJRU5ErkJggg==');
  }
  tray = new Tray(img);
  updateTray();
}

function updateTray() {
  const serviceRunning = isServiceRunning();
  const deviceCount = Object.keys(connectedDevices).length;
  const status = !serviceRunning ? 'Service Stopped' : hubOnline ? 'Online' : 'Waiting for Hub';

  tray.setToolTip(`ZeroHub - ${status} | ${deviceCount} device(s)`);

  const deviceItems = Object.entries(connectedDevices).map(([busId, name]) => ({
    label: `  ${name} (${busId})`,
    enabled: false
  }));

  const menuTemplate = [
    { label: `ZeroHub - ${status}`, enabled: false },
    { type: 'separator' },
    { label: 'Connected Devices:', enabled: false },
    ...(deviceItems.length > 0 ? deviceItems : [{ label: '  No devices', enabled: false }]),
    { type: 'separator' },
    { label: `Pi: ${config.piIP}`, enabled: false },
    { label: 'Settings...', click: openSettings },
    { label: 'Open Log', click: () => { require('child_process').exec(`notepad "${LOG_PATH}"`); } },
    { type: 'separator' },
    {
      label: serviceRunning ? 'Stop Service' : 'Start Service',
      click: () => {
        if (serviceRunning) stopService(); else startService();
        setTimeout(updateTray, 3000);
      }
    },
    { label: 'Restart Service', click: () => { restartService(); setTimeout(updateTray, 4000); } },
    { type: 'separator' },
    { label: 'Exit Tray', click: () => { tray.destroy(); app.quit(); } }
  ];

  tray.setContextMenu(Menu.buildFromTemplate(menuTemplate));
}

function openSettings() {
  if (settingsWindow) { settingsWindow.focus(); return; }

  settingsWindow = new BrowserWindow({
    width: 380, height: 240, resizable: false, minimizable: false, maximizable: false,
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
</style></head><body>
<h2>ZeroHub Settings</h2>
<label>Pi IP Address</label>
<input type="text" id="piIP" value="${config.piIP}" placeholder="192.168.0.181" />
<div class="buttons">
  <button class="cancel" onclick="window.close()">Cancel</button>
  <button class="save" onclick="save()">Save & Restart Service</button>
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

ipcMain.on('save-settings', (event, newConfig) => {
  config.piIP = newConfig.piIP;
  saveConfig();
  if (settingsWindow) { settingsWindow.close(); settingsWindow = null; }
  restartService();
  setTimeout(updateTray, 4000);
});

app.setAppUserModelId('ZeroHub Listener');

app.on('ready', () => {
  loadConfig();
  createTrayIcon();
  parseLog();
  pollInterval = setInterval(parseLog, 3000);
  if (!isServiceRunning()) { startService(); setTimeout(updateTray, 3000); }
});

app.on('window-all-closed', (e) => { e.preventDefault(); });
app.on('second-instance', () => {});
app.on('before-quit', () => { if (pollInterval) clearInterval(pollInterval); });


