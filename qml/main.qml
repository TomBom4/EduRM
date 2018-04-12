import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.0

ApplicationWindow {
    id: window
    visible: true
    title: "EduRM"
    minimumWidth: 640
    minimumHeight: 480
    width: Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight

    Connections
    {
        property var idMap: ({
                                // -------------------------------------------
                                // List all the ids here, you have to access
                                // from Go. This is needed for
                                // string to object mapping.
                                // -------------------------------------------
                                window:window,
                                sliderText:sliderText,
                                filesColumn:filesColumn,
                                filepath:filepath,
                                textEdit:textEdit,
                                bpList:bpList,
                                bpInput:bpInput,
                                instructionCounterText:instructionCounterText,
                                currentCmdText: currentCmdText,
                                accumulatorText:accumulatorText,
                                registerGrid:registerGrid,
                                bpSwitch:bpSwitch,
                                notificationColumn:notificationColumn,
                                bpBarHider:bpBarHider
                            })
        target: hermes
        onSendToQml:
        {
            var data = ""
            if (jsondata != "") {
                data = JSON.parse(jsondata)
            }
            switch(mode) {
            case 0:
                for(var key in data) {
                    this.idMap[target][key.toString()] = data[key.toString()]
                }
                break;
            case 1:
                insertElement(target, data, data.template)
                break;
            case 2:
                // open file
                var request = new XMLHttpRequest();
                request.open("GET", data.template, false);
                request.send(null);
                var template = request.responseText;
                insertElement(target, data, template)
                break;
            case 3:
                this.idMap[target].destroy()
                delete this.idMap[target]
                break;
            case 4:
                var request = {}
                for (var i = 0; i < data.properties.length; i++){
                    request[data.properties[i]] = this.idMap[target][data.properties[i]]
                }
                hermes.sendToGo(data.eventListener, target, JSON.stringify(request))
                break;
            default:
                // -------------------------------------------
                // Insert your ModeCustom-implementation here.
                // -------------------------------------------
                break;
            }
        }
        function insertElement(target, data, template) {
            // insert variables
            var qmlElement = template.replace(/<\w+>/g, function(match){
                return data.variables[match.replace("<","").replace(">","")]
            })
            // get element id
            var elementId = ""
            qmlElement = qmlElement.replace(/{[^{]*(id\s*:\s*[^\s^;.]+)/i, function(match, p1){
                elementId = p1.replace(/\s+/g, "").replace("id:","")
                return match
            })
            // create and register element
            this.idMap[elementId] = Qt.createQmlObject(qmlElement, this.idMap[target], data.template)
        }
    }

    Component.onCompleted: {
        hermes.sendToGo("event_windowloaded", "", "")
    }

    onActiveChanged: {
        if (active === false && textEdit.visible === true) {
            hermes.sendToGo("event_storecurrent", "", '{"text":"'+textEdit.text.replace(/"/g, '\\"').replace(/\t/g,"\\t")+'"}')
        }
    }

    Action {
        id: saveAction
        shortcut: StandardKey.Save
        onTriggered: {
            hermes.sendToGo("event_savefile","",'{"text":"'+textEdit.text.replace(/"/g, '\\"').replace(/\t/g,"\\t")+'"}')
        }
    }

    Action {
        id: saveAllAction
        shortcut: StandardKey.SaveAs
        onTriggered: {
            hermes.sendToGo("event_saveallfiles","",'{"text":"'+textEdit.text.replace(/"/g, '\\"').replace(/\t/g,"\\t")+'"}')
        }

    }

    ToolBar {
        id: toolBar
        position: ToolBar.Header
        height: 50
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top

        Row {
            anchors.leftMargin: 10
            anchors.left: parent.left
            height: parent.height
            width: parent.width * .7
            ToolButton {
                id: runButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/run.png"
                }
                action: runAction

                Action {
                    id: runAction
                    shortcut: "F5"
                    onTriggered: hermes.sendToGo("event_run","loadButton", '{"text":"'+textEdit.text.replace(/"/g, '\\"').replace(/\t/g,"\\t")+'"}')
                }
		ToolTip.visible: hovered
		ToolTip.delay: 1000
		ToolTip.text: "Run the current program or Continue (F5)"
            }
            ToolButton {
                id: stepButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/step.png"
                }
                action: stepAction

                Action {
                    id: stepAction
                    shortcut: "F6"
                    onTriggered: hermes.sendToGo("event_step","","")
                }
		ToolTip.visible: hovered
		ToolTip.delay: 1000
		ToolTip.text: "Step: execute one step (F6)"
            }
            ToolButton {
                id: pauseButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/pause.png"
                }
                action: pauseAction

                Action {
                    id: pauseAction
                    shortcut: "F7"
                    onTriggered: hermes.sendToGo("event_pause","","")
                }
		ToolTip.visible: hovered
		ToolTip.delay: 1000
		ToolTip.text: "Pause: pause execution (F7)"
            }
            ToolButton {
                id: stopButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: 'img/stop.png'
                }
                action: stopAction

                Action {
                    id: stopAction
                    shortcut: "F8"
                    onTriggered: hermes.sendToGo("event_stop","","")
                }
		ToolTip.visible: hovered
		ToolTip.delay: 1000
		ToolTip.text: "Stop: cancel execution (F8)"
            }
            Item {
                height: parent.height
                width: 40
            }
            Slider {
                id: speedSlider
                width: 100
                onMoved: hermes.sendToGo("event_slidermoved", "speedSlider", '{"value":'+value+'}')
		ToolTip.visible: hovered
		ToolTip.delay: 1000
		ToolTip.text: "The interval to wait between single steps"
            }
            Text {
                height: parent.height
                id: sliderText
                text: (speedSlider.value * 5).toLocaleString(Qt.locale("en_US"), "f",1) + " s"
                color: "#ffffff"
                styleColor: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }            
        }
        Row {
            anchors.right: parent.right
            height: parent.height
            width: parent.width * .3
            Text {
                id: instructionCounterText
                height: parent.height
                color: "#ffffff"
                styleColor: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 18
            }
            Text {
                padding: 5
                height: parent.height
                color: "#ffffff"
                text: ":"
                styleColor: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 18
            }
            Text {
                id: currentCmdText
                padding: 5
                height: parent.height
                color: "#ffffff"
                styleColor: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 18
            }
        }
        Text {
            id: accumulatorText
            anchors.right: parent.right
            anchors.rightMargin: 15
            height: parent.height
            color: "#ffffff"
            styleColor: "#ffffff"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 18
        }
    }

    Row {
        anchors.topMargin: toolBar.height
        anchors.fill: parent
        anchors.bottomMargin: bpBar.height

        Column {
            width: parent.width * .2
            height: parent.height

            Row{
                width: parent.width
                height: 50
                padding: 15

                TextField {
                    id: filepath
                    focus: true
                    padding: 5
                    placeholderText: "filepath"
                    width: parent.width - 30 - 2 * height
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    layer.enabled: true
                    font.pointSize: 14
                    Keys.onReturnPressed: {
                        hermes.sendToGo("event_addfile", "addFileFromFilepath", '{ "path": "' + filepath.text + '", "text":"'+textEdit.text.replace(/"/g, '\\"').replace(/\t/g,"\\t")+'"}')
                    }
                }
                ToolButton {
                    id: addFileFromFilepath
                    height: parent.height
                    width: height
                    Image{
                        anchors.fill: parent
                        scale: 0.5
                        source: "img/add.png"
                    }
                    onClicked: hermes.sendToGo("event_addfile", "addFileFromFilepath", '{ "path": "' + filepath.text + '", "text":"'+textEdit.text.replace(/"/g, '\\"').replace(/\t/g,"\\t")+'"}')
                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "New File (leave text field empty to create a temporary file)"
                }
                ToolButton {
                    height: parent.height
                    width: height
                    Image{
                        anchors.fill: parent
                        scale: 0.5
                        source: "img/open.png"
                    }
		            ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Open File"

                    onClicked: openFileDialog.open()
                }
            }
            Item{
                width: parent.width
                height: 30
            }

            Flickable {
                width: parent.width
                height: (parent.height - 125) / 2
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: filesColumn.implicitHeight
                clip: true

                Column{
                    id: filesColumn
                    width: parent.width
                }
            }

            Item{
                width: parent.width
                height: 30
            }

            Flickable {
                width: parent.width
                height: (parent.height - 125) / 2
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: notificationColumn.implicitHeight
                clip: true

                Column {
                    id: notificationColumn
                    width: parent.width
                    spacing: 15
                }
            }

            Item{
                width: parent.width
                height: 15
            }
        }
        



        Flickable {
            id: flick
            width: parent.width * .5
            height: parent.height
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds


            TextArea.flickable: Asmtextedit {
                id: textEdit
                hidden: "true"
            }

            ScrollBar.vertical: ScrollBar {}
        }

        Flickable {
            clip: true
            width: parent.width * .3
            height: parent.height
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: registerGrid.implicitHeight + 30

            flickableDirection: Flickable.VerticalFlick

            Grid {
                id: registerGrid
                columns: width / 85
                width: parent.width            
            }


            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }



    ToolBar {
        id: bpBar
        position: ToolBar.Footer
        height: 50
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        Row{
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Switch {
                id: bpSwitch
                scale: 0.8
                checked: true
                height: parent.height
                onClicked: hermes.sendToGo("event_togglebreakpoints", "", "")

                ToolTip.visible: hovered
                ToolTip.delay: 1000
                ToolTip.text: "Enable/disable breakpoints for the next run"
            }
            Item {
                height: parent.height
                width: 40
            }
            TextField {
                id: bpInput
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                color: "#ffffff"
                validator: IntValidator{bottom: 1;}
                placeholderText: "instruction counter"
                Keys.onReturnPressed: {
                    hermes.sendToGo("event_addbreakpoint", "", '{"instructioncounter":"' + bpInput.text + '"}')
                }
            }
            ToolButton {
                height: parent.height
                width: height

                ToolTip.visible: hovered
                ToolTip.delay: 1000
                ToolTip.text: "Add a breakpoint"

                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/add.png"
                }
                onClicked: hermes.sendToGo("event_addbreakpoint", "", '{"instructioncounter":"' + bpInput.text + '"}')
            }
            Item {
                height: parent.height
                width: 40
            }
            Flickable {
                clip: true
                width: parent.width - 80 - (3 * parent.height) - bpInput.width - bpSwitch.width - 10
                height: parent.height
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: bpList.implicitWidth
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: bpList
                    height: parent.height
                }
            }
            Item {
                height: parent.height
                width: 10
            }
            ToolButton {
                onClicked: hermes.sendToGo("event_addregister", "", "")

                ToolTip.visible: hovered
                ToolTip.delay: 1000
                ToolTip.text: "Add a register"

                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: 'img/add.png'
                }
            }

            ToolButton {
                padding: 5
                onClicked: hermes.sendToGo("event_removeregister", "", "")

                ToolTip.visible: hovered
                ToolTip.delay: 1000
                ToolTip.text: "Delete a register"

                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: 'img/remove.png'
                }
            } 
        }
    }

    Breakpointsbarhider {
        id: bpBarHider
        hide: "false"
    }

    FileDialog {
        id: openFileDialog
        visible: false
        title: qsTr("Select your assembly file")
        selectMultiple: false
        selectFolder: false
        nameFilters: [ "Assembly Files (*.spasm *.spaen)", "All files (*)" ]
        selectedNameFilter: "Assembly Files (*.spasm *.spaen)"
        sidebarVisible: true
        onAccepted: {
            hermes.sendToGo("event_addfile", "fileDialog", '{ "path": "' + fileUrl + '", "text":"'+textEdit.text.replace(/"/g, '\\"').replace(/\t/g,"\\t")+'" }')
        }
        onRejected: {}
    }

    Saveasfiledialog {
        id: saveAsFileDialog
    }
}
