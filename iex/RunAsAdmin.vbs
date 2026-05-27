Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Try installation directory first, then script directory
strInstallDir = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\RuntimeService"
strExePath = strInstallDir & "\WinRTSvcHost.exe"

' If not in install dir, try script directory
If Not fso.FileExists(strExePath) Then
    strScriptPath = fso.GetParentFolderName(WScript.ScriptFullName)
    strExePath = strScriptPath & "\WinRTSvcHost.exe"
End If

' Check if WinRTSvcHost.exe exists
If Not fso.FileExists(strExePath) Then
    ' Silent fail - don't show error on startup
    WScript.Quit
End If

' Run Runtime Service silently (hidden window)
' Task Scheduler already runs this with admin privileges, so no elevation needed
WshShell.Run """" & strExePath & """", 0, False
