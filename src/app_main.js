
'use strict';

const electron = require('electron');
const { app, BrowserWindow, globalShortcut, crashReporter, ipcMain, dialog } = electron;
const fs = require('fs');
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
  mainWindow.setMenu(null)    // disable default menu
  mainWindow.maximize()
  // mainWindow.ELECTRON_DISABLE_SECURITY_WARNINGS = true
  // mainWindow["ELECTRON_DISABLE_SECURITY_WARNINGS"] = "true"

  /*
  mainWindow.loadURL(url.format(JsObject{
    pathname: dirname.to(cstring) & "/index.html",
    protocol: "file".cstring,
    slashes: true
  }))
  */
  mainWindow.loadFile(__dirname + "/../build/index.html")

  mainWindow.on("closed", () => mainWindow = null)

  let devToolsOpened = false
  if (devToolsOpened) {
    mainWindow.webContents.openDevTools()
  }

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

