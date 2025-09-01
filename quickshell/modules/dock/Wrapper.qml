pragma ComponentBehavior: Bound

import "root:/services"
import "root:/config"
import "root:/utils"
import "root:/widgets"
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    visible: true  // Always visible to show indicator
    implicitHeight: root.visibilities.dock ? content.implicitHeight : 6  // Minimal height for indicator
    implicitWidth: content.implicitWidth

    // Remove states since we handle height directly above

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    // Dock indicator - shows when dock is hidden
    StyledRect {
        id: indicator
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        
        width: 8
        height: 2
        radius: height / 2
        
        color: Colours.palette.m3onSurface
        opacity: root.visibilities.dock ? 0 : 0.3
        visible: opacity > 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    Loader {
        id: content

        Component.onCompleted: active = Qt.binding(() => root.visibilities.dock || root.visible)

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        sourceComponent: Content {
            visibilities: root.visibilities
        }
    }
}