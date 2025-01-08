local DefecationFunctions = {}
DefecationFunctions.options = PZAPI.ModOptions:create("1436878551", "Defecation")
DefecationFunctions.options:addSeparator()
DefecationFunctions.options.DefecationStatus = DefecationFunctions.options:addKeyBind("DefecationStatus", getText("UI_options_1436878551DefecationStatus_keybind"), Keyboard.KEY_COMMA, getText("UI_options_1436878551DefecationStatus_keybind_tooltip"))
DefecationFunctions.options.ShowNumericStatus = DefecationFunctions.options:addTickBox("ShowNumericStatus", getText("UI_options_1436878551ShowNumericStatus_checkBox"), true, getText("UI_options_1436878551ShowNumericStatus_checkBox_tooltip"))

return DefecationFunctions