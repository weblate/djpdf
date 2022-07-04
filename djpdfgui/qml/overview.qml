/*
 *    This file is part of djpdf.
 *
 *    djpdf is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    Foobar is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with djpdf.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2018 Unrud <unrud@outlook.com>
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import djpdf 1.0

Page {
    FileDialog {
        id: openDialog
        title: "Open"
        nameFilters: [
            "Images (" + platformIntegration.imageFileExtensions.map(function(s) {return "*." + s}).join(" ") + ")",
            "All files (*)"
        ]
        folder: shortcuts.home
        selectMultiple: true
        onAccepted: pagesModel.extend(openDialog.fileUrls)
    }

    FileDialog {
        id: saveDialog
        title: "Save"
        defaultSuffix: platformIntegration.pdfFileExtension
        nameFilters: [ "PDF (*." + platformIntegration.pdfFileExtension + ")" ]
        folder: shortcuts.home
        selectExisting: false
        onAccepted: pagesModel.save(saveDialog.fileUrl)
    }

    Connections {
        target: platformIntegration
        function onOpened(urls) {
            pagesModel.extend(urls)
        }
        function onSaved(url) {
            pagesModel.save(url)
        }
    }

    MessageDialog {
        id: errorDialog
        title: "Error"
        text: "Failed to create PDF"
    }

    Connections {
        target: pagesModel
        function onSavingError() {
            errorDialog.open()
        }
    }

    Popup {
        parent: stack
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        modal: true
        visible: pagesModel.saving
        closePolicy: Popup.NoAutoClose
        ColumnLayout {
            anchors.fill: parent
            Label {
                text: "Saving..."
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
            ProgressBar {
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: pagesModel.savingProgress
                bottomPadding: 5
            }
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "+"
                onClicked: {
                    if (platformIntegration.enabled) {
                        platformIntegration.openOpenDialog()
                    } else {
                        openDialog.open()
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ToolButton {
                text: "Create"
                enabled: pagesModel.count > 0
                onClicked: {
                    if (platformIntegration.enabled) {
                        platformIntegration.openSaveDialog()
                    } else {
                        saveDialog.open()
                    }
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        background: Rectangle {
            color: paletteActive.base
        }

        GridView {
            property string dragKey: "9e8acb18cd58e838"

            id: pagesView
            focus: true
            model: pagesModel
            highlight: Rectangle {
                color: pagesView.activeFocus ? paletteActive.highlight : "transparent"
            }
            Keys.onSpacePressed: {
                event.accepted = true
                stack.push("detail.qml", {p: pagesView.currentItem.p,
                                          modelIndex: pagesView.currentItem.modelIndex})
            }

            delegate: MouseArea {
                id: pageDelegate

                property int modelIndex: index
                property DjpdfPage p: model.modelData

                onClicked: stack.push("detail.qml", {p: p, modelIndex: modelIndex})

                width: 100
                height: 100
                drag.target: pageItem
                Item {
                    id: pageItem
                    width: pageDelegate.width
                    height: pageDelegate.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter

                    Drag.active: pageDelegate.drag.active
                    Drag.source: pageDelegate
                    Drag.hotSpot.x: width/2
                    Drag.hotSpot.y: height/2
                    Drag.keys: [ pagesView.dragKey ]

                    states: [
                        State {
                            when: pageItem.Drag.active
                            ParentChange {
                                target: pageItem
                                parent: pagesView
                            }

                            AnchorChanges {
                                target: pageItem
                                anchors.horizontalCenter: undefined
                                anchors.verticalCenter: undefined
                            }
                        }
                    ]

                    Image {
                        id: image
                        asynchronous: true
                        source: "image://thumbnails/" + model.modelData.url
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        anchors.margins: 6
                        z: 1
                    }
                    Rectangle {
                        id: imageBorder
                        color: paletteActive.text
                        anchors.centerIn: image
                        width: image.paintedWidth + 2
                        height: image.paintedHeight + 2
                        visible: image.status === Image.Ready
                    }
                    DropShadow {
                        anchors.fill: source
                        cached: true
                        horizontalOffset: 0
                        verticalOffset: 1
                        radius: 8
                        samples: 16
                        color: source.color
                        smooth: true
                        source: imageBorder
                    }

                    BusyIndicator {
                        running: image.status !== Image.Ready
                        anchors.centerIn: parent
                    }
                }

                DropArea {
                    anchors { fill: parent; margins: 15 }
                    keys: [ pagesView.dragKey ]
                    onEntered: pagesModel.swap(drag.source.modelIndex, pageDelegate.modelIndex)
                }
            }
        }
    }
}
