import QtQuick

Rectangle {
    id: root

    property real targetY: -200
    property real driftX: 0
    property real duration: 3000
    property real opacityPeak: 0.3
    property real size: 4
    property real aspect: 1

    width: size * (aspect >= 1 ? aspect : 1)
    height: size * (aspect < 1 ? 1/aspect : 1)
    radius: Math.min(width, height) / 2
    opacity: 0

    function animate() {
        fadeIn.start()
    }

    SequentialAnimation {
        id: fadeIn
        running: false
        NumberAnimation { target: root; property: "opacity"; from: 0; to: root.opacityPeak; duration: 300 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "y"; to: root.targetY; duration: root.duration; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "x"; to: root.x + root.driftX; duration: root.duration; easing.type: Easing.InOutQuad }
            SequentialAnimation {
                PauseAnimation { duration: Math.max(0, root.duration - 1000) }
                NumberAnimation { target: root; property: "opacity"; to: 0; duration: 600 }
            }
        }
        ScriptAction { script: root.destroy() }
    }
}
