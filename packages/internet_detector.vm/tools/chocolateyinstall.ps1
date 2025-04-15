$ErrorActionPreference = 'Stop'
Import-Module vm.common -Force -DisableNameChecking

$toolName = 'internet_detector'
$category = VM-Get-Category($MyInvocation.MyCommand.Definition)
$packageToolDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

# Modify fakenet's configuration to ignore the internet detector traffic
$fakenetConfig = "$Env:RAW_TOOLS_DIR\fakenet\fakenet3.5\configs\default.ini"
VM-Assert-Path $fakenetConfig

$IcmpID = Get-Random -Maximum 0x10000
$config = Get-Content -Path $fakenetConfig
$config = $config -replace '^.*BlackListIDsICMP.*$', "BlackListIDsICMP: $IcmpID"
Set-Content -Path $fakenetConfig -Value $config -Encoding ASCII -Force

# Create tool directory
$toolDir = Join-Path ${Env:RAW_TOOLS_DIR} $toolName
New-Item -Path $toolDir -ItemType Directory -Force -ea 0
VM-Assert-Path $toolDir

# Install pyinstaller 6.11.1 (needed to build the Python executable with a version capable of executing in admin cmd) and tool dependencies ('pywin32')
$dependencies = "pyinstaller==6.11.1,pywin32==308,icmplib==3.0.4"
VM-Pip-Install $dependencies

# Set the ICMP ID at the tool script
$scriptPath = "$packageToolDir\internet_detector.pyw"
$tempScript = Join-Path ${Env:TEMP} "temp_$([guid]::NewGuid())"
$script = Get-Content -Path $scriptPath
$script = $script -replace '^ICMP_ID.*$', "ICMP_ID = $IcmpID"
Set-Content -Path $tempScript -Value $script -Encoding ASCII -Force

# This wrapper is needed because PyInstaller emits an error when running as admin and this mitigates the issue.
Start-Process -FilePath 'cmd.exe' -WorkingDirectory "$toolDir" -ArgumentList "/c pyinstaller --onefile -w --log-level FATAL --distpath `"$toolDir`" --workpath `"$packageToolDir`" --specpath `"$packageToolDir`" --name `"$toolName.exe`" `"$tempScript`"" -Wait

# Move images to %VM_COMMON_DIR% directory
$imagesPath = Join-Path $packageToolDir "images"
Copy-Item "$imagesPath\*" ${Env:VM_COMMON_DIR} -Force

VM-Install-Shortcut -toolName $toolName -category $category -executablePath "$toolDir\$toolName.exe"

# Create scheduled task for tool to run every 2 minutes.
$action = New-ScheduledTaskAction -Execute "$toolDir\$toolName.exe"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'Internet Detector' -Force