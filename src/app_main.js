
'use strict';

const electron = require('electron');
const electronLocalshortcut = require('electron-localshortcut');

const { app, BrowserWindow, globalShortcut, crashReporter, ipcMain, dialog } = electron;
const path = require('path');


function makeHttpAddress(url) {
  let prefix = `file://${__dirname}/"`
  if (url.startsWith(prefix)) {
    return url.replace(prefix, "http://")
  } else {
    return url
  }
}


function createWindow() {
  // Let's get rid of the annying security warning. Yes, we are using
  // nodeIntegration, but we are not allowing remote content anyway.
  // The documentation is totally unclear, why the warning appears
  // for local + nodeIntegration. Some links:
  // - https://electronjs.org/docs/tutorial/security#2-do-not-enable-nodejs-integration-for-remote-content
  // - https://stackoverflow.com/questions/48854265/why-do-i-see-an-electron-security-warning-after-updating-my-electron-project-t
  // - https://stackoverflow.com/questions/51969512/define-csp-http-header-in-electron-app
  process.env.ELECTRON_DISABLE_SECURITY_WARNINGS = 'true';

  // As per https://github.com/electron/electron/issues/16521
  // calling this before creating the browser window is a work-around
  // for the bug that calling setMenu(null) doesn't have an effect.
  // But this also disables all keyboard shortcuts...
  electron.Menu.setApplicationMenu(null)

  // Option to use local shortcuts mentioned here: https://electronjs.org/docs/tutorial/keyboard-shortcuts
  // This doesn't work, because these local shortcuts are only possible
  // if the menu is visible...

  let mainWindow = new BrowserWindow(
    {
      width: 1000,
      height: 800,
      // https://www.christianengvall.se/electron-app-icons/
      icon: path.join(__dirname, "../styles/icons/main.png_64x64.png"),
      webPreferences: {
        nodeIntegration: true,   // required for Electron 5.x
        devTools: true,
      },
    }
  )

  // Currently setMenu(null) has the unfortunate behavior, that it makes its
  // keyboard shortcuts (accelerators) unusable, but still shows the menu.
  // => worst behavior...
  // mainWindow.setMenu(null)    // disable default menu

  // This would be an okay option: Allows to toggle the menu with ALT and
  // all shortcuts are active even if hidden. However there is one big
  // problem: It starts out visible => bad for end users...
  // mainWindow.setAutoHideMenuBar(true);

  mainWindow.maximize()

  //mainWindow.loadFile(__dirname + "/../build/index.html")
  mainWindow.loadFile("./build/index.html")

  mainWindow.on("closed", () => mainWindow = null)

  // State for devtools
  let devToolsOpened = false
  if (devToolsOpened) {
    mainWindow.webContents.openDevTools()
  }
  mainWindow.webContents.on('devtools-opened', () => {
    console.log("Detected devtools opened")
    devToolsOpened = true;
  });
  mainWindow.webContents.on('devtools-closed', () => {
    console.log("Detected devtools closed")
    devToolsOpened = false;
  });

  // For now this seems to be the best work-around for Electron's shortcut mess:
  // https://github.com/parro-it/electron-localshortcut
  electronLocalshortcut.register(mainWindow, "CommandOrControl+Shift+I", () => {
    console.log("Toggeling dev tools")
    if (devToolsOpened) {
      mainWindow.webContents.closeDevTools()
    } else {
      mainWindow.webContents.openDevTools()
    }
  });
  electronLocalshortcut.register(mainWindow, "CommandOrControl+R", () => {
    console.log("Reloading");
    mainWindow.reload();
  });

  /*
  // Global shortcuts suck, because the are active even if the window doesn't have focus.
  globalShortcut.register("CommandOrControl+Shift+I", () => {
    console.log("Toggeling dev tools")
    if (devToolsOpened) {
      mainWindow.webContents.closeDevTools()
      devToolsOpened = false
    } else {
      mainWindow.webContents.openDevTools()
      devToolsOpened = true
    }
  })
  */

  // Redirect hrefs to external browser:
  // - https://stackoverflow.com/a/32415579/1804173
  // - https://github.com/electron/electron/issues/1344#issuecomment-208839713
  let webContents = mainWindow.webContents
  webContents.on("new-window", (event, url) => {
    event.preventDefault()
    electron.shell.openExternal(url);
  })
  webContents.on("will-navigate", (event, url) => {
    event.preventDefault()
    electron.shell.openExternal(makeHttpAddress(url));
  })
}

app.on("ready", createWindow)

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit()
  }
})

app.on("activate", () => {
  if (mainWindow == null) {
    createWindow()
  }
})


/*
// Another work-around for the shortcut problem in Electron.
// From: https://github.com/electron/electron/issues/1334#issuecomment-310920998
// Works, but feels fairly tedious because of all the manual input comparison
// and the lack of direct access to mainWindow.

let devToolsOpened = false

app.on('web-contents-created', function (event, wc) {
  wc.on('before-input-event', function (event, input) {
    console.log(input)
    if (input.type == "keyDown" && input.key === 'I' && input.control && input.shift) {
      if (devToolsOpened) {
        wc.closeDevTools()
        devToolsOpened = false
      } else {
        wc.openDevTools()
        devToolsOpened = true
      }
    }
  })
})
*/

