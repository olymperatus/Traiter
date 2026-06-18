import QtQuick

Rectangle {
    id: root

    property real maxHeight: 80
    property real barWidth: 8
    property real targetX: 0
    property real riseDuration: 800
    property real holdDuration: 1500
    property real fadeDuration: 600
    property real peakOpacity: 0.25

    anchors.bottom: parent.bottom
    width: barWidth
    height: 0
    radius: 4
    opacity: 0

    function animate() {
        anim.start()
    }

    SequentialAnimation {
        id: anim
        ParallelAnimation {
            NumberAnimation { target: root; property: "height"; from: 0; to: root.maxHeight; duration: root.riseDuration; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "opacity"; from: 0; to: root.peakOpacity; duration: root.riseDuration * 0.7; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: root.holdDuration }
        ParallelAnimation {
            NumberAnimation { target: root; property: "height"; to: 0; duration: root.fadeDuration; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: root.fadeDuration; easing.type: Easing.InCubic }
        }
        ScriptAction { script: root.destroy() }
    }
}
