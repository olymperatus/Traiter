import QtQuick
import qs.modules.common

Item {
    id: root

    property color c1: Appearance.m3colors.m3primary
    property color c2: Appearance.m3colors.m3tertiary
    property color c3: Appearance.m3colors.m3secondaryContainer
    property bool running: true
    property int waveCount: 6
    property real minDist: 40

    readonly property var _colors: [c1, c2, c3, c2, c1, c2]

    property var _activeBars: []

    function _isValidX(x) {
        for (var i = 0; i < root._activeBars.length; i++) {
            if (Math.abs(root._activeBars[i] - x) < root.minDist) return false
        }
        return true
    }

    function _findValidX() {
        for (var attempt = 0; attempt < 20; attempt++) {
            var x = Math.random() * (root.width - 20) + 10
            if (_isValidX(x)) return x
        }
        return -1
    }

    function _barDied(x) {
        var idx = root._activeBars.indexOf(x)
        if (idx >= 0) root._activeBars.splice(idx, 1)
    }

    function createBar(props) {
        var comp = Qt.createComponent("AssistantBar.qml")
        if (comp.status !== Component.Ready) return
        var x = props.x
        if (!x || x < 0) {
            x = _findValidX()
            if (x < 0) return
        }
        root._activeBars.push(x)
        var bar = comp.createObject(root, {
            color: props.color || _colors[0],
            x: x,
            barWidth: props.barWidth || Math.random() * 5 + 4,
            maxHeight: props.maxHeight || Math.random() * root.height * 0.45 + root.height * 0.2,
            riseDuration: props.riseDuration || Math.random() * 400 + 400,
            holdDuration: props.holdDuration || Math.random() * 1000 + 800,
            fadeDuration: props.fadeDuration || 600,
            peakOpacity: props.peakOpacity || Math.random() * 0.15 + 0.08
        })
        bar.x = x
        bar.animate()
    }

    function spawnWave() {
        var colors = root._colors
        var totalWidth = root.width
        var spacing = totalWidth / (waveCount + 1)
        for (var i = 0; i < waveCount; i++) {
            var x = spacing * (i + 1) + (Math.random() - 0.5) * spacing * 0.3
            createBar({
                color: colors[i % colors.length],
                x: x,
                barWidth: Math.random() * 5 + 3,
                maxHeight: Math.random() * root.height * 0.4 + root.height * 0.25,
                riseDuration: 500 + i * 80,
                holdDuration: 1200,
                peakOpacity: Math.random() * 0.12 + 0.06
            })
        }
    }

    Timer {
        interval: 2500
        running: root.running
        repeat: true
        onTriggered: root.spawnWave()
    }

    Timer {
        interval: 350
        running: root.running
        repeat: true
        onTriggered: {
            createBar({
                color: root._colors[Math.floor(Math.random() * root._colors.length)],
                barWidth: Math.random() * 4 + 2,
                maxHeight: Math.random() * root.height * 0.2 + root.height * 0.1,
                riseDuration: 250,
                holdDuration: 200,
                fadeDuration: 300,
                peakOpacity: Math.random() * 0.06 + 0.03
            })
        }
    }

    Component.onCompleted: root.spawnWave()
}
