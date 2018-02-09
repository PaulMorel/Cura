// Copyright (c) 2016 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM

import Cura 1.0 as Cura

UM.PreferencesPage
{
    title: catalog.i18nc("@title:tab", "Setting Visibility");

    property int scrollToIndex: 0

    signal scrollToSection( string key )
    onScrollToSection:
    {
        settingsListView.positionViewAtIndex(definitionsModel.getIndex(key), ListView.Beginning)
    }

    function reset()
    {
        UM.Preferences.resetPreference("general/visible_settings")

        // After calling this function update Setting visibility preset combobox.
        // Reset should set default setting preset ("Basic")
        visibilityPreset.setDefaultPreset()

    }
    resetEnabled: true;

    Item
    {
        id: base;
        anchors.fill: parent;

        property bool inhibitSwitchToCustom: false

        CheckBox
        {
            id: toggleVisibleSettings
            anchors
            {
                verticalCenter: filter.verticalCenter;
                left: parent.left;
                leftMargin: UM.Theme.getSize("default_margin").width
            }
            text: catalog.i18nc("@label:textbox", "Check all")
            checkedState:
            {
                if(definitionsModel.visibleCount == definitionsModel.categoryCount)
                {
                    return Qt.Unchecked
                }
                else if(definitionsModel.visibleCount == definitionsModel.rowCount(null))
                {
                    return Qt.Checked
                }
                else
                {
                    return Qt.PartiallyChecked
                }
            }
            partiallyCheckedEnabled: true

            MouseArea
            {
                anchors.fill: parent;
                onClicked:
                {
                    if(parent.checkedState == Qt.Unchecked || parent.checkedState == Qt.PartiallyChecked)
                    {
                        definitionsModel.setAllVisible(true)
                    }
                    else
                    {
                        definitionsModel.setAllVisible(false)
                    }

                    // After change set "Custom" option

                    // If already "Custom" then don't do nothing
                    if (visibilityPreset.currentIndex != visibilityPreset.model.count - 1)
                    {
                        visibilityPreset.currentIndex = visibilityPreset.model.count - 1
                        UM.Preferences.setValue("cura/active_setting_visibility_preset", visibilityPreset.model.getItem(visibilityPreset.currentIndex).id)
                    }
                }
            }
        }

        TextField
        {
            id: filter;

            anchors
            {
                top: parent.top
                left: toggleVisibleSettings.right
                leftMargin: UM.Theme.getSize("default_margin").width
                right: visibilityPreset.left
                rightMargin: UM.Theme.getSize("default_margin").width
            }

            placeholderText: catalog.i18nc("@label:textbox", "Filter...")

            onTextChanged: definitionsModel.filter = {"i18n_label": "*" + text}
        }

        ComboBox
        {
            function setDefaultPreset()
            {
                visibilityPreset.currentIndex = 0
            }

            id: visibilityPreset
            width: 150 * screenScaleFactor
            anchors
            {
                top: parent.top
                right: parent.right
            }

            model: Cura.SettingVisibilityPresetsModel
            textRole: "name"

            currentIndex:
            {
                // Load previously selected preset.
                var index = model.find("id", model.activePreset);
                if(index == -1)
                {
                    index = 0;
                }

                return index;
            }

            onActivated:
            {
                base.inhibitSwitchToCustom = true;
                model.setActivePreset(model.getItem(index).id);

                UM.Preferences.setValue("general/visible_settings", model.getItem(index).settings.join(";"));
                UM.Preferences.setValue("cura/active_setting_visibility_preset", model.getItem(index).id);
                base.inhibitSwitchToCustom = false;
            }
        }

        ScrollView
        {
            id: scrollView

            frameVisible: true

            anchors
            {
                top: filter.bottom;
                topMargin: UM.Theme.getSize("default_margin").height
                left: parent.left;
                right: parent.right;
                bottom: parent.bottom;
            }
            ListView
            {
                id: settingsListView

                model: UM.SettingDefinitionsModel
                {
                    id: definitionsModel
                    containerId: Cura.MachineManager.activeDefinitionId
                    showAll: true
                    exclude: ["machine_settings", "command_line_settings"]
                    showAncestors: true
                    expanded: ["*"]
                    visibilityHandler: UM.SettingPreferenceVisibilityHandler
                    {
                        onVisibilityChanged:
                        {
                            if(Cura.SettingVisibilityPresetsModel.activePreset != "" && !base.inhibitSwitchToCustom)
                            {
                                Cura.SettingVisibilityPresetsModel.setActivePreset("custom");
                            }
                        }
                    }
                }

                delegate: Loader
                {
                    id: loader

                    width: parent.width
                    height: model.type != undefined ? UM.Theme.getSize("section").height : 0

                    property var definition: model
                    property var settingDefinitionsModel: definitionsModel

                    asynchronous: true
                    active: model.type != undefined
                    sourceComponent:
                    {
                        switch(model.type)
                        {
                            case "category":
                                return settingVisibilityCategory
                            default:
                                return settingVisibilityItem
                        }
                    }
                }
            }
        }

        UM.I18nCatalog { name: "cura"; }
        SystemPalette { id: palette; }

        Component
        {
            id: settingVisibilityCategory;

            UM.SettingVisibilityCategory { }
        }

        Component
        {
            id: settingVisibilityItem;

            UM.SettingVisibilityItem { }
        }
    }
}