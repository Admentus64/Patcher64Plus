#==============================================================================================================================================================================================
#  LOCATION OF .NET FRAMEWORK COMPILER "CSC.EXE"
#==============================================================================================================================================================================================
$dotNET  = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
#==============================================================================================================================================================================================
#  PROGRAM CONFIGURATION
#==============================================================================================================================================================================================
$Name   = 'Patcher64+ Tool Launcher.exe'
$Source = 'Code.cs'
$Icon   = 'Icon.ico'
#==============================================================================================================================================================================================
#  COMPILATION
#==============================================================================================================================================================================================
# Get the path to the script and use it to find the base folder.
$ScriptPath = $script:MyInvocation.MyCommand.Path
$BaseFolder = Split-Path $ScriptPath

# Set the output name/path of the program.
$OutputPath = $BaseFolder + '\' + $Name + '.exe'
$OutputFile = '/out:' + $BaseFolder + '\' + $Name

# Set the path to the source code.
$SourceCode = $BaseFolder + '\' + $Source

# Set the icon to the one specified.
$IconFile = '/win32icon:' + $BaseFolder + '\' + $Icon

# Compile the program.
& $dotNET '/t:exe' $IconFile $OutputFile $Source