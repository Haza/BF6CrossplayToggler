#SingleInstance Force

; Define possible file paths
filePath1 := A_MyDocuments . "\Battlefield 6\settings\PROFSAVE_profile"
filePath2 := A_MyDocuments . "\Battlefield 6\settings\steam\PROFSAVE_profile"
activeFilePath := ""

; Create GUI
myGui := Gui()
myGui.Title := "Battlefield 6 Crossplay Toggle"
myGui.OnEvent("Close", (*) => ExitApp())

; Status text - increased height
statusText := myGui.Add("Text", "w300 h30 Center", "Reading status...")
statusText.SetFont("s12 bold")

; File location text (smaller, for info)
fileLocationText := myGui.Add("Text", "w300 h20 Center", "")
fileLocationText.SetFont("s8")

; Add spacing
myGui.Add("Text", "h15")

; Buttons - made slightly larger
disableBtn := myGui.Add("Button", "w130 h35 x10", "Disable Crossplay")
disableBtn.OnEvent("Click", (*) => SetCrossPlay(0))

enableBtn := myGui.Add("Button", "x+20 w130 h35", "Enable Crossplay")
enableBtn.OnEvent("Click", (*) => SetCrossPlay(1))

; Add bottom margin
myGui.Add("Text", "h10")

; Show GUI with specific size
myGui.Show("w320 h150")
UpdateStatus()

; Function to find the active file path
FindActiveFile() {
    global filePath1, filePath2, activeFilePath, fileLocationText
    
    ; Check first path
    if FileExist(filePath1) {
        activeFilePath := filePath1
        fileLocationText.Text := "Using: Default profile"
        return true
    }
    
    ; Check second path (steam)
    if FileExist(filePath2) {
        activeFilePath := filePath2
        fileLocationText.Text := "Using: Steam profile"
        return true
    }
    
    ; No file found
    activeFilePath := ""
    fileLocationText.Text := "Profile file not found!"
    return false
}

; Function to update the status display
UpdateStatus() {
    global statusText, activeFilePath, disableBtn, enableBtn
    
    try {
        ; Find which file exists
        if !FindActiveFile() {
            statusText.Text := "File not found!"
            statusText.SetFont("s12 bold cRed")
            disableBtn.Enabled := false
            enableBtn.Enabled := false
            return
        }
        
        fileContent := FileRead(activeFilePath)
        
        ; Search for the crossplay setting
        if RegExMatch(fileContent, "GstGameplay\.CrossPlayEnable\s+(\d)", &match) {
            value := match[1]
            if (value = "1") {
                statusText.Text := "CrossPlay is ON"
                statusText.SetFont("s12 bold cGreen")
                enableBtn.Enabled := false
                disableBtn.Enabled := true
            } else {
                statusText.Text := "CrossPlay is OFF"
                statusText.SetFont("s12 bold cRed")
                enableBtn.Enabled := true
                disableBtn.Enabled := false
            }
        } else {
            ; Setting not found - default to OFF state
            statusText.Text := "CrossPlay is OFF (not set)"
            statusText.SetFont("s12 bold cOrange")
            ; Enable the enable button, disable the disable button (since it's already effectively off)
            enableBtn.Enabled := true
            disableBtn.Enabled := true  ; Allow setting it explicitly to 0
        }
    } catch as err {
        statusText.Text := "Error reading file!"
        statusText.SetFont("s12 bold cRed")
        MsgBox("Error: " . err.Message, "Error", "Icon!")
    }
}

; Function to set crossplay value
SetCrossPlay(newValue) {
    global activeFilePath
    
    ; Make sure we have a valid file path
    if !FindActiveFile() {
        MsgBox("Cannot find profile file in either location:`n`n" . 
               "• Documents\Battlefield 6\settings\PROFSAVE_profile`n" .
               "• Documents\Battlefield 6\settings\steam\PROFSAVE_profile", 
               "Error", "Icon!")
        return
    }
    
    try {
        ; Read the file
        fileContent := FileRead(activeFilePath)
        
        ; Check if the setting exists
        if RegExMatch(fileContent, "GstGameplay\.CrossPlayEnable\s+\d") {
            ; Replace existing setting
            fileContent := RegExReplace(fileContent, 
                "GstGameplay\.CrossPlayEnable\s+\d", 
                "GstGameplay.CrossPlayEnable " . newValue)
        } else {
            ; Add the setting if it doesn't exist
            ; Make sure there's a newline at the end of file first
            if (SubStr(fileContent, -1) != "`n" && SubStr(fileContent, -2) != "`r`n") {
                fileContent .= "`r`n"
            }
            fileContent .= "GstGameplay.CrossPlayEnable " . newValue
        }
        
        ; Write back to file
        FileDelete(activeFilePath)
        FileAppend(fileContent, activeFilePath)
        
        ; Update the status display
        UpdateStatus()
        
    } catch as err {
        MsgBox("Error writing file: " . err.Message, "Error", "Icon!")
    }
}

; Auto-refresh every 5 seconds to catch external changes
SetTimer(UpdateStatus, 5000)

; Hotkey for quick toggle (Ctrl+Shift+X)
^+x:: {
    global statusText
    ; Check current status and toggle
    if InStr(statusText.Text, "OFF")
        SetCrossPlay(1)
    else if InStr(statusText.Text, "ON")
        SetCrossPlay(0)
}