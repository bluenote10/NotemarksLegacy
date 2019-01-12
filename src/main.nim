import jsffi
import sugar
import karax/karax # kout

{.emit: """
const electron = require('electron')
const path = require('path')
const url = require('url')
const net = require('net');
""".}

var
  electron {. importc, nodecl .}: JsObject
  path {. importc, nodecl .}: JsObject
  url {. importc, nodecl .}: JsObject
  console {. importc, nodecl .}: JsObject
  process {.importc, nodecl.}: JsObject
  net {.importc, nodecl.}: JsObject
  dirname {.importc: "__dirname", nodecl.}: cstring

let app = electron.app
let globalShortcut = electron.globalShortcut

let browserWindow = electron.BrowserWindow

var mainWindow: JsObject


proc createWindow() =
  mainWindow = jsnew electron.BrowserWindow(JsObject{width: 1000, height: 800, webPreferences: JsObject{
    devTools: true
    }})

  #[
  mainWindow.loadURL(url.format(JsObject{
    pathname: dirname.to(cstring) & "/index.html",
    protocol: "file".cstring,
    slashes: true
  }))
  ]#
  mainWindow.loadFile(dirname & "/index.html")

  mainWindow.on("closed", proc () =
    mainWindow = nil
  )

  var devToolsOpened = true
  mainWindow.webContents.openDevTools()

  globalShortcut.register("CommandOrControl+Shift+I", proc () =
    console.log("Toggeling dev tools")
    if devToolsOpened:
      mainWindow.webContents.closeDevTools()
      devToolsOpened = false
    else:
      mainWindow.webContents.openDevTools()
      devToolsOpened = true
  )


app.on("ready", createWindow)

app.on("window-all-closed", proc () =
  if process.platform.to(cstring) != "darwin":
    app.quit()
)

app.on("activate", proc() =
  if mainWindow == nil:
    createWindow()
)
