import jsffi
import sugar
import karax/karax # kout
#import karax/kdom
import jstr_utils

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


proc makeHttpAddress(url: cstring): cstring =
  let prefix = "file://".cstring & dirname & "/"
  if url.startsWith(prefix):
    return url.replace(prefix, "http://")
  else:
    return url


proc createWindow() =
  mainWindow = jsnew electron.BrowserWindow(
    JsObject{
      width: 1000,
      height: 800,
      webPreferences: JsObject{
        devTools: true
      }
    }
  )
  mainWindow.maximize()

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
  # mainWindow.webContents.openDevTools()

  globalShortcut.register("CommandOrControl+Shift+I", proc () =
    console.log("Toggeling dev tools")
    if devToolsOpened:
      mainWindow.webContents.closeDevTools()
      devToolsOpened = false
    else:
      mainWindow.webContents.openDevTools()
      devToolsOpened = true
  )

  # Redirect hrefs to external browser:
  # - https://stackoverflow.com/a/32415579/1804173
  # - https://github.com/electron/electron/issues/1344#issuecomment-208839713
  let webContents = mainWindow.webContents
  webContents.on("new-window", proc (event: JsObject, url: cstring) =
    echo "new-window: ", url, " ", makeHttpAddress(url)
    event.preventDefault()
    electron.shell.openExternal(url);
  )
  webContents.on("will-navigate", proc (event: JsObject, url: cstring) =
    echo "will-navigate: ", url, " ", makeHttpAddress(url)
    event.preventDefault()
    electron.shell.openExternal(makeHttpAddress(url));
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
