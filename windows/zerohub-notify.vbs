' ZeroHub Notification Launcher - hides the PS console but lets the form render
Dim args, title, msg, ntype
title = "ZeroHub"
msg = ""
ntype = "Info"

' Parse command line args
Set objArgs = WScript.Arguments
For i = 0 To objArgs.Count - 1
    Select Case objArgs(i)
        Case "-Title"
            If i + 1 < objArgs.Count Then title = objArgs(i + 1)
        Case "-Message"
            If i + 1 < objArgs.Count Then msg = objArgs(i + 1)
        Case "-Type"
            If i + 1 < objArgs.Count Then ntype = objArgs(i + 1)
    End Select
Next

Dim cmd
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Program Files\ZeroHub\zerohub-notify.ps1"" -Title """ & title & """ -Message """ & msg & """ -Type " & ntype
CreateObject("Wscript.Shell").Run cmd, 0, False

