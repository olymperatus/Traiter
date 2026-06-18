import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool open: false
    property bool _listening: false
    property bool _busy: false
    property bool _cancelled: false
    property string _status: "Iniciando..."
    property string _transcription: ""
    property string _response: ""

    readonly property string _baseUrl: "http://127.0.0.1:58901"

    Process {
        id: backend
        workingDirectory: "/home/olymperatus/projects/Traiter/backend"
        command: [
            "/home/olymperatus/projects/Traiter/backend/venv/bin/python3",
            "main.py"
        ]
        running: true
        onStarted: print("[Assistant] Backend iniciando...")
        onExited: {
            print("[Assistant] Backend detenido (código:", exitCode, ")")
            root._status = "Backend caído"
        }
    }

    function _http(method, path, body, cb) {
        var xhr = new XMLHttpRequest()
        xhr.open(method, root._baseUrl + path, true)
        xhr.timeout = 60000
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (root._cancelled) return
                cb(xhr.status === 0 ? {error: "connection"} : JSON.parse(xhr.responseText || "{}"))
            }
        }
        if (body) {
            xhr.send(JSON.stringify(body))
        } else {
            xhr.send()
        }
    }

    function _get(path, cb) {
        _http("GET", path, null, cb)
    }

    function _post(path, body, cb) {
        _http("POST", path, body, cb)
    }

    function _cancel() {
        root._cancelled = true
        _get("/stop_listen", data => {})
        root._listening = false
        root._busy = false
    }

    function _reset() {
        root._cancelled = false
        root._listening = false
        root._busy = false
        root._status = ""
        root._transcription = ""
        root._response = ""
    }

    Loader {
        id: overlayLoader
        active: root.open

        sourceComponent: PanelWindow {
            id: overlayWindow
            anchors { bottom: true; left: true; right: true }
            height: 420
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:assistant"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            visible: true
            color: "transparent"

            AssistantOverlay {
                id: overlayContent
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                listening: root._listening
                responding: root._busy
                statusText: root._status
                transcriptionText: root._transcription
                responseText: root._response
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(overlayWindow)
                _get("/ping", data => {
                    if (data.status === "ok") {
                        _startListening()
                    } else {
                        root._status = "Esperando backend..."
                        _checkReady()
                    }
                })
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(overlayWindow)
                _cancel()
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() { root.open = false }
            }
        }
    }

    Timer {
        id: readyCheck
        interval: 2000
        repeat: false
        onTriggered: _checkReady()
    }

    function _checkReady() {
        _get("/ping", data => {
            if (data.status === "ok") _startListening()
            else readyCheck.start()
        })
    }

    function _startListening() {
        if (root._busy) return
        root._cancelled = false
        root._busy = true
        root._listening = true
        root._status = "Escuchando..."
        root._transcription = ""
        root._response = ""

        _get("/listen", data => {
            root._listening = false
            root._busy = false
            if (data.error) {
                root._status = "Error: " + data.error
                return
            }
            var text = data.text || ""
            root._transcription = text
            _query(text || "Dime algo")
        })
    }

    function _query(text) {
        root._status = "Pensando..."
        root._busy = true
        _post("/query", {text: text}, data => {
            root._busy = false
            if (data.error) {
                root._status = "Error: " + data.error
                return
            }
            var resp = data.text || ""
            root._response = resp
            root._status = ""
            _speak(resp)
        })
    }

    function _speak(text) {
        root._status = "Hablando..."
        root._busy = true
        _post("/speak", {text: text}, data => {
            root._busy = false
            root._status = ""
        })
    }

    function toggle() {
        if (root.open) {
            _cancel()
            root.open = false
        } else {
            _reset()
            root.open = true
        }
    }

    IpcHandler {
        target: "assistant"
        function toggle(): void { root.toggle() }
    }

    GlobalShortcut {
        name: "assistantToggle"
        description: "Toggle AI Assistant"
        onPressed: root.toggle()
    }
}
