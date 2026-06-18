import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property bool listening: false
    property bool responding: false
    property string statusText: ""
    property string responseText: ""
    property string transcriptionText: ""

    signal requestSpeak(text: string)

    height: 420

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: "transparent" }
            GradientStop { position: 0.6; color: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.6) }
            GradientStop { position: 0.85; color: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.5) }
            GradientStop { position: 1.0; color: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.4) }
        }
    }

    Text {
        id: statusLabel
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.verticalCenter; bottomMargin: listening ? 40 : 20 }
        text: {
            if (listening) return transcriptionText || "Escuchando..."
            if (responding) return "Procesando..."
            return statusText
        }
        color: Appearance.m3colors.m3onSurfaceVariant
        font.pixelSize: 13
        font.italic: listening
    }

    property string _fullResponse: ""
    property string _displayedResponse: ""
    property int _charPos: 0

    onResponseTextChanged: {
        _fullResponse = responseText
        _displayedResponse = ""
        _charPos = 0
        respText.opacity = 0
        respScale.xScale = 1.08
        respScale.yScale = 1.08
        if (_fullResponse.length > 0) {
            streamTimer.start()
            entranceAnim.restart()
        }
    }

    Timer {
        id: streamTimer
        interval: 25
        repeat: true
        onTriggered: {
            if (_charPos < _fullResponse.length) {
                _charPos++
                _displayedResponse = _fullResponse.substring(0, _charPos)
            } else {
                stop()
            }
        }
    }

    Text {
        id: respText
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 160 }
        text: _displayedResponse
        visible: _displayedResponse.length > 0
        color: Appearance.m3colors.m3onSurface
        font.pixelSize: 17
        wrapMode: Text.WordWrap
        width: parent.width * 0.7
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.3

        transform: Scale { id: respScale }
        opacity: 0

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation { target: respScale; property: "xScale"; to: 1.0; duration: 600; easing.type: Easing.OutCubic }
            NumberAnimation { target: respScale; property: "yScale"; to: 1.0; duration: 600; easing.type: Easing.OutCubic }
            NumberAnimation { target: respText; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
        }
    }

    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 170
        clip: true

        AssistantBars {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top }
        }

        AssistantParticles {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: parent.top }
        }
    }
}
