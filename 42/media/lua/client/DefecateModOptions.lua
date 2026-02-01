local DefecationFunctions = {}
DefecationFunctions.options = PZAPI.ModOptions:create("1436878551", "Defecation")
DefecationFunctions.options:addSeparator()
DefecationFunctions.options.DefecationStatus = DefecationFunctions.options:addKeyBind("DefecationStatus", getText("UI_options_1436878551DefecationStatus_keybind"), Keyboard.KEY_COMMA, getText("UI_options_1436878551DefecationStatus_keybind_tooltip"))
DefecationFunctions.options.ShowNumericStatus = DefecationFunctions.options:addTickBox("ShowNumericStatus", getText("UI_options_1436878551ShowNumericStatus_checkBox"), true, getText("UI_options_1436878551ShowNumericStatus_checkBox_tooltip"))
DefecationFunctions.options.StomachSounds = DefecationFunctions.options:addTickBox("StomachSounds", getText("UI_options_1436878551StomachSounds_checkBox"), true, getText("UI_options_1436878551StomachSounds_checkBox_tooltip"))
DefecationFunctions.options.DefecateSounds = DefecationFunctions.options:addTickBox("DefecateSounds", getText("UI_options_1436878551DefecateSounds_checkBox"), true, getText("UI_options_1436878551DefecateSounds_checkBox_tooltip"))

return DefecationFunctions