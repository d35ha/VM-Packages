﻿$ErrorActionPreference = 'Continue'

$toolName = 'cygwin'
$category = VM-Get-Category($MyInvocation.MyCommand.Definition)

$shortcutDir = Join-Path ${Env:TOOL_LIST_DIR} $category
$shortcut = Join-Path $shortcutDir "$toolName.lnk"
Remove-Item $shortcut -Force -ea 0
