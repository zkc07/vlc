/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick 2.12
import QtQuick.Layouts 1.12

import org.videolan.vlc 0.1

import "qrc:///util/" as Util
import "qrc:///util/Helpers.js" as Helpers
import "qrc:///widgets/" as Widgets
import "qrc:///main/" as MainInterface
import "qrc:///style/"

MainInterface.MainViewLoader {
    id: root

    // Properties

    property var providerModel
    property var contextMenu
    property var tree

    readonly property var currentIndex: _currentView.currentIndex

    readonly property bool isViewMultiView: true

     // 'parsingPending' property is not available with NetworkDevicesModel
    readonly property bool parsing: Helpers.get(providerModel, "parsingPending", false)

    property var sortModel: [
        { text: I18n.qtr("Alphabetic"), criteria: "name"},
        { text: I18n.qtr("Url"), criteria: "mrl" },
        { text: I18n.qtr("File size"), criteria: "fileSizeRaw64" },
        { text: I18n.qtr("File modified"), criteria: "fileModified" }
    ]

    // fixme remove this
    property Item _currentView: currentItem

    signal browse(var tree, int reason)

    Navigation.cancelAction: function() {
        History.previous()
    }

    model: SortFilterProxyModel {
        id: filterModel

        sourceModel: providerModel
        searchRole: "name"
    }

    // override the default currentComponent assignment from MainViewLoader
    // because we need to not show empty label when model is parsing
    currentComponent: {
        if (filterModel.count == 0 && !root.parsing)
            return emptyLabelComponent
        else if (MainCtx.gridView)
            return gridComponent
        else
            return tableComponent
    }


    onTreeChanged: providerModel.tree = tree

    function playSelected() {
        providerModel.addAndPlay(filterModel.mapIndexesToSource(selectionModel.selectedIndexes))
    }

    function playAt(index) {
        providerModel.addAndPlay(filterModel.mapIndexToSource(index))
    }

    function _actionAtIndex(index) {
        if ( selectionModel.selectedIndexes.length > 1 ) {
            playSelected()
        } else {
            var data = filterModel.getDataAt(index)
            if (data.type === NetworkMediaModel.TYPE_DIRECTORY
                    || data.type === NetworkMediaModel.TYPE_NODE)  {
                browse(data.tree, Qt.TabFocusReason)
            } else {
                playAt(index)
            }
        }
    }

    Widgets.DragItem {
        id: networkDragItem

        indexes: selectionModel.selectedIndexes

        titleRole: "name"

        defaultText:  I18n.qtr("Unknown Share")

        coverProvider: function(index, data) {
            return {artwork: data.artwork, cover: custom_cover, type: data.type}
        }

        onRequestData: {
            setData(identifier, selectionModel.selectedIndexes.map(function (x){
                return filterModel.getDataAt(x.row)
            }))
        }

        function getSelectedInputItem(cb) {
            //directly call the callback
            cb(providerModel.getItemsForIndexes(filterModel.mapIndexesToSource(selectionModel.selectedIndexes)))
        }

        Component {
            id: custom_cover

            NetworkCustomCover {
                networkModel: model
                width: networkDragItem.coverSize / 2
                height: networkDragItem.coverSize / 2
            }
        }
    }


    Widgets.BusyIndicatorExt {
        id: busyIndicator

        runningDelayed: root.parsing
        anchors.centerIn: parent
        z: 1
    }

    Component{
        id: gridComponent

        MainInterface.MainGridView {
            id: gridView

            selectionDelegateModel: selectionModel
            model: filterModel

            headerDelegate: FocusScope {
                id: headerId

                width: root.width
                height: layout.implicitHeight + VLCStyle.margin_large + VLCStyle.margin_normal

                Navigation.navigable: btn.visible
                Navigation.parentItem: root
                Navigation.downAction: function() {
                    focus = false
                    gridView.forceActiveFocus(Qt.TabFocusReason)
                }

                RowLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.topMargin: VLCStyle.margin_large
                    anchors.bottomMargin: VLCStyle.margin_normal
                    anchors.rightMargin: VLCStyle.margin_small

                    Widgets.SubtitleLabel {
                        text: providerModel.name
                        leftPadding: gridView.rowX
                        color: gridView.colorContext.fg.primary

                        Layout.fillWidth: true
                    }

                    Widgets.ButtonExt {
                        id: btn

                        focus: true
                        iconTxt: providerModel.indexed ? VLCIcons.remove : VLCIcons.add
                        text:  providerModel.indexed ?  I18n.qtr("Remove from medialibrary") : I18n.qtr("Add to medialibrary")
                        visible: !providerModel.is_on_provider_list && !!providerModel.canBeIndexed
                        onClicked: providerModel.indexed = !providerModel.indexed

                        Layout.preferredWidth: implicitWidth

                        Navigation.parentItem: headerId
                    }
                }
            }

            cellWidth: VLCStyle.gridItem_network_width
            cellHeight: VLCStyle.gridCover_network_height + VLCStyle.margin_xsmall + VLCStyle.fontHeight_normal

            delegate: NetworkGridItem {
                id: delegateGrid

                subtitle: ""
                height: VLCStyle.gridCover_network_height + VLCStyle.margin_xsmall + VLCStyle.fontHeight_normal
                dragItem: networkDragItem

                onPlayClicked: playAt(index)
                onItemClicked : gridView.leftClickOnItem(modifier, index)

                onItemDoubleClicked: {
                    if (model.type === NetworkMediaModel.TYPE_NODE || model.type === NetworkMediaModel.TYPE_DIRECTORY)
                        browse(model.tree, Qt.MouseFocusReason)
                    else
                        playAt(index)
                }

                onContextMenuButtonClicked: {
                    gridView.rightClickOnItem(index)
                    contextMenu.popup(filterModel.mapIndexesToSource(selectionModel.selectedIndexes), globalMousePos)
                }
            }

            onActionAtIndex: _actionAtIndex(index)

            Navigation.parentItem: root
            Navigation.upItem: gridView.headerItem
        }
    }

    Component{
        id: tableComponent

        MainInterface.MainTableView {
            id: tableView

            readonly property int _nbCols: VLCStyle.gridColumnsForWidth(tableView.availableRowWidth)
            readonly property int _nameColSpan: Math.max((_nbCols - 1) / 2, 1)
            property Component thumbnailHeader: Widgets.IconLabel {
                height: VLCStyle.listAlbumCover_height
                width: VLCStyle.listAlbumCover_width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: VLCStyle.icon_tableHeader
                text: VLCIcons.album_cover
                color: tableView.colorContext.fg.secondary
            }

            property Component thumbnailColumn: NetworkThumbnailItem {
                onPlayClicked: playAt(index)
            }

            property var _modelSmall: [{
                size: Math.max(2, _nbCols),

                model: ({
                    criteria: "name",

                    title: "name",

                    subCriterias: [ "mrl" ],

                    text: I18n.qtr("Name"),

                    headerDelegate: thumbnailHeader,
                    colDelegate: thumbnailColumn
                })
            }]

            property var _modelMedium: [{
                size: 1,

                model: {
                    criteria: "thumbnail",

                    text: I18n.qtr("Cover"),

                    headerDelegate: thumbnailHeader,
                    colDelegate: thumbnailColumn
                }
            }, {
                size: tableView._nameColSpan,

                model: {
                    criteria: "name",

                    text: I18n.qtr("Name")
                }
            }, {
                size: Math.max(_nbCols - _nameColSpan - 1, 1),

                model: {
                    criteria: "mrl",

                    text: I18n.qtr("Url"),

                    showContextButton: true
                }
            }]

            dragItem: networkDragItem

            model: filterModel

            sortModel: (availableRowWidth < VLCStyle.colWidth(4)) ? _modelSmall
                                                                  : _modelMedium

            selectionDelegateModel: selectionModel
            focus: true

            Navigation.parentItem: root
            Navigation.upItem: tableView.headerItem

            rowHeight: VLCStyle.tableCoverRow_height

            header: FocusScope {
                id: head

                width: root.width
                height: layout.implicitHeight + VLCStyle.margin_large + VLCStyle.margin_small

                Navigation.navigable: btn.visible
                Navigation.parentItem: root

                RowLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.topMargin: VLCStyle.margin_large
                    anchors.bottomMargin: VLCStyle.margin_small
                    anchors.rightMargin: VLCStyle.margin_small

                    Widgets.SubtitleLabel {
                        text: providerModel.name
                        leftPadding: VLCStyle.margin_large
                        color: tableView.colorContext.fg.primary

                        Layout.fillWidth: true
                    }

                    Widgets.ButtonExt {
                        id: btn

                        focus: true
                        iconTxt: providerModel.indexed ? VLCIcons.remove : VLCIcons.add
                        text:  providerModel.indexed ?  I18n.qtr("Remove from medialibrary") : I18n.qtr("Add to medialibrary")
                        visible: !providerModel.is_on_provider_list && !!providerModel.canBeIndexed
                        onClicked: providerModel.indexed = !providerModel.indexed

                        Navigation.parentItem: root
                        Navigation.downAction: function() {
                            head.focus = false
                            tableView.forceActiveFocus(Qt.TabFocusReason)
                        }

                        Layout.preferredWidth: implicitWidth
                    }
                }
            }

            onActionForSelection: _actionAtIndex(selection[0].row)
            onItemDoubleClicked: _actionAtIndex(index)
            onContextMenuButtonClicked: contextMenu.popup(filterModel.mapIndexesToSource(selectionModel.selectedIndexes), globalMousePos)
            onRightClick: contextMenu.popup(filterModel.mapIndexesToSource(selectionModel.selectedIndexes), globalMousePos)
        }
    }

    Component {
        id: emptyLabelComponent

        Widgets.EmptyLabelHint {
            // FIXME: find better cover
            cover: VLCStyle.noArtVideoCover
            coverWidth : VLCStyle.dp(182, VLCStyle.scale)
            coverHeight: VLCStyle.dp(114, VLCStyle.scale)

            text: I18n.qtr("Nothing to see here, go back.")
        }
    }
}
