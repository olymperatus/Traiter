import QtQuick
import qs.modules.common

Item {
    id: root

    property color c1: Appearance.m3colors.m3primary
    property color c2: Appearance.m3colors.m3secondary
    property color c3: Appearance.m3colors.m3tertiary
    property bool running: true

    readonly property var _colors: [c1, c2, c3]

    function spawn() {
        var colors = root._colors
        var comp = Qt.createComponent("Particle.qml")
        if (comp.status !== Component.Ready) return
        var count = Math.floor(Math.random() * 3) + 1
        for (var i = 0; i < count; i++) {
            var aspect = Math.random() > 0.5 ? Math.random() * 2 + 1.5 : 1 / (Math.random() * 2 + 1.5)
            var obj = comp.createObject(root, {
                color: colors[Math.floor(Math.random() * colors.length)],
                x: Math.random() * root.width,
                y: root.height + 5,
                targetY: -(Math.random() * root.height * 0.6 + root.height * 0.1),
                driftX: (Math.random() - 0.5) * 120,
                size: Math.random() * 5 + 2,
                aspect: aspect,
                duration: Math.random() * 3500 + 3000,
                opacityPeak: Math.random() * 0.25 + 0.08
            })
            if (obj) obj.animate()
        }
    }

    Timer {
        interval: 100
        running: root.running
        repeat: true
        onTriggered: root.spawn()
    }
}
