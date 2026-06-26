import QtQuick
import Quickshell

Item {
    Component.onCompleted: {
        console.log("XHR Type: " + typeof XMLHttpRequest);
        Qt.quit();
    }
}
