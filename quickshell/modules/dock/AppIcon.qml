pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/services"
import "root:/config"
import "root:/utils"
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property string desktopEntry
    property string directIcon: ""  // Optional: use direct icon name instead of desktop entry
    required property string appName
    required property list<string> command

    implicitWidth: 48
    implicitHeight: 48
    width: implicitWidth
    height: implicitHeight

    CustomMouseArea {
        id: mouse

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPressed: event => {
            // Visual feedback
            const stateY = stateWrapper.y;
            rippleAnim.x = event.x;
            rippleAnim.y = event.y - stateY;

            const dist = (ox, oy) => ox * ox + oy * oy;
            rippleAnim.radius = Math.sqrt(Math.max(
                dist(event.x, event.y + stateY), 
                dist(event.x, stateWrapper.height - event.y), 
                dist(width - event.x, event.y + stateY), 
                dist(width - event.x, stateWrapper.height - event.y)
            ));

            rippleAnim.restart();

            // Launch application
            Quickshell.execDetached(root.command);
        }

        SequentialAnimation {
            id: rippleAnim

            property real x
            property real y
            property real radius

            PropertyAction {
                target: ripple
                property: "x"
                value: rippleAnim.x
            }
            PropertyAction {
                target: ripple
                property: "y"
                value: rippleAnim.y
            }
            PropertyAction {
                target: ripple
                property: "opacity"
                value: 0.12
            }
            NumberAnimation {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            NumberAnimation {
                target: ripple
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        ClippingRectangle {
            id: stateWrapper

            anchors.fill: parent
            color: "transparent"
            radius: Appearance.rounding.small

            StyledRect {
                id: stateLayer

                anchors.fill: parent
                color: Colours.palette.m3primary
                opacity: mouse.pressed ? 0.12 : mouse.hovered ? 0.08 : 0
                radius: parent.radius

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }

            StyledRect {
                id: ripple

                radius: Appearance.rounding.full
                color: Colours.palette.m3primary
                opacity: 0

                transform: Translate {
                    x: -ripple.width / 2
                    y: -ripple.height / 2
                }
            }
        }

        IconImage {
            id: icon

            anchors.centerIn: parent
            source: root.directIcon !== "" 
                ? Quickshell.iconPath(root.directIcon, "application-x-executable")
                : Quickshell.iconPath(Icons.getDesktopEntry(root.desktopEntry)?.icon, "application-x-executable")
            implicitSize: parent.width * 0.7

            scale: mouse.pressed ? 0.9 : mouse.hovered ? 1.1 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.anim.durations.short
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }

    // Tooltip
    StyledText {
        id: tooltip

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.border.rounding / 2

        text: root.appName
        color: Colours.palette.m3onSurface
        font.pointSize: Appearance.font.size.small

        opacity: mouse.hovered ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.short
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        StyledRect {
            anchors.fill: parent
            anchors.margins: -Config.border.rounding / 4
            color: Colours.palette.m3surfaceContainerHighest
            radius: Config.border.rounding / 2
            z: -1
        }
    }
}