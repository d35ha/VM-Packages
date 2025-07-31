$ErrorActionPreference = 'Stop'
Import-Module vm.common -Force -DisableNameChecking

$toolName = 'vbdec_test'
$category = VM-Get-Category($MyInvocation.MyCommand.Definition)

$exeUrl = 'http://sandsprite.com/flare_vm/VBDEC_Setup_983E127DB204A3E50723E4A30D80EF8C.exe'
$exeSha256 = 'e6fa33f1d8c51214b1b6e49665f1edbcbf05399d57cc2a04ced0a74a194ada63'

$toolDir = Join-Path ${Env:RAW_TOOLS_DIR} $toolName
$executablePath = (Join-Path $toolDir 'vbdec.exe')
VM-Install-With-Installer $toolName $category "EXE" "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /Dir=`"$($toolDir)`"" `
    $executablePath $exeUrl -sha256 $exeSha256
