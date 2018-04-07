import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.0

ApplicationWindow {
    id: window
    visible: true
    title: "EduRM"
    minimumWidth: 640
    minimumHeight: 480
    width: Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight

    Component.onCompleted: {
        hermes.sendToGo("event_windowloaded", "", "")
    }

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
                                registerGrid:registerGrid
                            })
        target: hermes
        onSendToQml:
        {
            var data = ""
            if (jsondata != "") {
                data = JSON.parse(jsondata)
                for (var key in data) {
                    if (data[key.toString()].toString().includes("\\n")) {
                        data[key.toString()] = data[key.toString()].toString().replace(/\\r\\n/g, "\r\n")
                        data[key.toString()] = data[key.toString()].toString().replace(/\\n/g, "\n")
                    }
                }
            }
            switch(mode) {
            case 0:
                for(var key in data) {
                    /*console.log("-----------------")
                    console.log(target)
                    console.log(key.toString())
                    console.log(this.idMap[target])
                    console.log(this.idMap[target][key.toString()])
                    console.log(data[key.toString()])
                    console.log("-----------------")*/
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
                id: loadButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/load.png"
                }
                onClicked: hermes.sendToGo("event_reload","loadButton", '{"text":"'+textEdit.text+'"}')                
            }
            ToolButton {
                id: runButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/run.png"
                }
                onClicked: hermes.sendToGo("event_run","","")
            }
            ToolButton {
                id: stepButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/step.png"
                }
                onClicked: hermes.sendToGo("event_step","","")
            }
            ToolButton {
                id: pauseButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: "img/pause.png"
                }
                onClicked: hermes.sendToGo("event_pause","","")
            }
            ToolButton {
                id: stopButton
                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: 'img/stop.png'
                }
                onClicked: hermes.sendToGo("event_stop","","")
            }
            Item {
                height: parent.height
                width: 40
            }
            Slider {
                id: speedSlider
                width: 100
                onMoved: hermes.sendToGo("event_slidermoved", "speedSlider", '{"value":'+value+'}')
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

        Flickable {
            width: parent.width * .2
            height: parent.height
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: filesColumn.implicitHeight
            clip: true

            Column{
                id: filesColumn
                width: parent.width
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
                            hermes.sendToGo("event_addfile", "addFileFromFilepath", '{ "path": "' + filepath.text + '", "text":"'+textEdit.text+'"}')
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
                        onClicked: hermes.sendToGo("event_addfile", "addFileFromFilepath", '{ "path": "' + filepath.text + '", "text":"'+textEdit.text+'"}')
                    }
                    ToolButton {
                        height: parent.height
                        width: height
                        Image{
                            anchors.fill: parent
                            scale: 0.5
                            source: "img/open.png"
                        }

                        onClicked: fileDialog.open()

                    }
                }
                Item{
                    width: parent.width
                    height: 30
                }
            }
            Item{
                width: parent.width
                height: 30
            }

            ScrollIndicator.vertical: ScrollIndicator{}
        }


        Flickable {
            id: flick
            width: parent.width * .5
            height: parent.height
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds


            TextArea.flickable: TextArea {
                id: textEdit
                font.pointSize: 13
                width: parent.parent.width
                height: parent.parent.height
                selectByMouse: true
                selectByKeyboard: true
                wrapMode: TextArea.Wrap
                padding: 15
                background: null
                font.family: "Menlo, Monaco, 'Courier New', monospace"

                MouseArea {
                    enabled: false
                    cursorShape: Qt.IBeamCursor
                    anchors.top: parent.top
                    anchors.topMargin: parent.padding
                    anchors.bottomMargin: parent.padding
                    height: parent.paintedHeight
                    width: parent.width
                }
            }

            ScrollBar.vertical: ScrollBar {}
        }

        Flickable {
            clip: true
            width: parent.width * .30
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

                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: 'img/add.png'
                }
            }

            ToolButton {
                padding: 5
                onClicked: hermes.sendToGo("event_removeregister", "", "")

                Image{
                    anchors.fill: parent
                    scale: 0.5
                    source: 'img/close.png'
                }
            } 
        }
    }

    FileDialog {
        id: fileDialog
        visible: false
        //modality: fileDialogModal.checked ? Qt.WindowModal : Qt.NonModal
        title: qsTr("Select your assembly file")
        //selectExisting: fileDialogSelectExisting.checked
        selectMultiple: false
        selectFolder: false
        nameFilters: [ "Assembly Files (*.asm *.spaen)", "Raw Text Files (*.txt)", "All files (*)" ]
        selectedNameFilter: "Assembly Files (*.asm *.spaen)"
        sidebarVisible: true
        onAccepted: {
            hermes.sendToGo("event_addfile", "fileDialog", '{ "path": "' + fileUrl + '" }')
        }
        onRejected: {}
    }
}
