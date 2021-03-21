#=============================================================================================================================================================================================
# Patcher By     :  Admentus
# Concept By     :  Bighead
# Testing By     :  Admentus, GhostlyDark



#==============================================================================================================================================================================================
if ( (Get-ExecutionPolicy) -eq "Restricted") {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
    Write-Host "Execution Policy for the current user has been set to Unrestricted to allow usage of PowerShell scripts such as Patcher64+"
}



#==============================================================================================================================================================================================
Add-Type -AssemblyName 'System.Windows.Forms'
Add-Type -AssemblyName 'System.Drawing'
[Windows.Forms.Application]::EnableVisualStyles()



#==============================================================================================================================================================================================
$HidePSConsole = @"
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
"@
Add-Type -Namespace Console -Name Window -MemberDefinition $HidePSConsole



#==============================================================================================================================================================================================
# Setup global variables

$global:ScriptName = "Patcher64+ Tool"
$global:VersionDate = "2021-03-21"
$global:Version     = "v13.0.6"

$global:CommandType = $MyInvocation.MyCommand.CommandType.ToString()
$global:Definition  = $MyInvocation.MyCommand.Definition.ToString()

$global:GameConsole = $global:GameType = $global:GamePatch = $global:CheckHashSum = $null
$global:GameFiles = $global:Settings = @{}
$global:IsWiiVC = $global:MissingFiles = $False
$global:VCTitleLength = 40
$global:Bootup = $global:GameIsSelected = $global:IsActiveGameField = $False
$global:Last = $global:Fonts = @{}
$global:FatalError = $global:WarningError = $False



#==============================================================================================================================================================================================
function GetScriptPath() {
    
    if ($CommandType -eq "ExternalScript") { # This is the command that should have been stored
        $SplitDef  = $Definition.Split('\') # Split the path on every "\" and grab the last one
        $InputFile = $SplitDef[$SplitDef.Count-1]
        $global:ExternalScript = $True
        $Path = $Definition.Replace(($InputFile), '')
        $Path = $Path.substring(0, $Path.length-1)
        return $Path # If it was, the definition will hold the full path to the script
    }

    $FullPath  = ([Environment]::GetCommandLineArgs()[0]).ToString() # Split the path on every "\" and grab the last one
    $SplitDef  = $FullPath.Split('\')
    $InputFile = $SplitDef[$SplitDef.Count-1].Substring(0, $SplitDef[$SplitDef.Count-1].Length - 4) + '.exe'
    $global:ExternalScript = $False
    if ($ScriptPath) { $ScriptPath = $FullPath.Replace(($InputFile), '') } else { $ScriptPath = "." } # If running via an executable, the command will be different so get the path through an argument
    $Paths.FullBase = $FullPath.Replace(($InputFile), '')
    $Paths.FullBase = $Paths.Fullbase.substring(0, $Paths.Fullbase.length-1)
    return $ScriptPath # Return whatever we got in the above.

}



#==============================================================================================================================================================================================
function ImportModule([string]$Name) {
    
    if (Test-Path -LiteralPath ($Paths.Scripts + "\" + $Name + ".psm1") -PathType Leaf)   { Import-Module ($Paths.Scripts + "\" + $Name + ".psm1") }
    else                                                                                  { CreateErrorDialog -Error "Missing Modules" -Exit }

}



#==================================================================================================================================================================================================================================================================
# Paths

$global:Paths = @{}

# Set all paths
$Paths.Base            = GetScriptPath
if ($Paths.FullBase -eq $null) { $Paths.FullBase = $Paths.Base }
$Paths.Master          = $Paths.Base   + "\Files"
$Paths.Registry        = $Paths.Master + "\Registry"
$Paths.Games           = $Paths.Master + "\Games"
$Paths.Main            = $Paths.Master + "\Main"
$Paths.Tools           = $Paths.Master + "\Tools"
$Paths.WiiVC           = $Paths.Tools  + "\Wii VC"
$Paths.Scripts         = $Paths.Master + "\Scripts"
$Paths.Temp            = $Paths.Master + "\Temp"
$Paths.Settings        = $Paths.Master + "\Settings"
$Paths.Logs            = $Paths.Master + "\Logs"
$Paths.cygdrive        = $Paths.Master + "\cygdrive"



#==================================================================================================================================================================================================================================================================
# Load modules

foreach ($Script in Get-ChildItem -LiteralPath $Paths.Scripts -Force) {
    if ( !$Script.PSIsContainer -and $Script.Extension -eq ".psm1") { ImportModule $Script.BaseName }
}



#==============================================================================================================================================================================================
# Run Patcher64+ Tool

# Retrieve settings
$global:Settings = GetSettings ($Paths.Settings + "\Core.ini")
if (!(IsSet $Settings.Core))   { $Settings.Core  = @{} }
if (!(IsSet $Settings.Debug))  { $Settings.Debug = @{} }

# Hi-DPI Mode
$global:DisableHighDPIMode = $Settings.Core.HiDPIMode -eq $False
InitializeHiDPIMode
$global:ColumnWidth = DPISize 180

# Check if restricted
if (IsRestrictedFolder $Paths.FullBase) { CreateErrorDialog -Error "Restricted" -Exit }

# Set paths to all the files stored in the script
SetFileParameters

# Enable sounds
LoadSoundEffects ($Settings.Core.EnableSounds -eq $True)

# Visual Style
SetModernVisualStyle ($Settings.Core.ModernStyle -eq $True)

# Font
if ($Settings.Core.ClearType -eq $True)   { $Font = "Segoe UI" }
else                                      { $Font = "Microsoft Sans Serif" }
$Fonts.Medium         = New-Object System.Drawing.Font($Font, 12, [System.Drawing.FontStyle]::Bold)
$Fonts.Small          = New-Object System.Drawing.Font($Font, 8,  [System.Drawing.FontStyle]::Regular)
$Fonts.SmallBold      = New-Object System.Drawing.Font($Font, 8,  [System.Drawing.FontStyle]::Bold)
$Fonts.SmallUnderline = New-Object System.Drawing.Font($Font, 8,  [System.Drawing.FontStyle]::Underline)
$Fonts.TextFile       = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Regular)

# Hide the PowerShell console from the user
ShowPowerShellConsole ($Settings.Debug.Console -eq $True)

# Create the dialogs to show to the user
CreateMainDialog     | Out-Null
CreateCreditsDialog  | Out-Null
CreateSettingsDialog | Out-Null

# Logging
if (!$ExternalScript) { $global:TranscriptTime = Get-Date -Format yyyy-MM-dd-hh-mm-ss }
SetLogging (IsChecked $GeneralSettings.Logging)

# Set default game mode
ChangeConsolesList   | Out-Null
GetFilePaths         | Out-Null

# Restore Last Custom Title and GameID
$CustomHeader.Title.Add_TextChanged({           if (IsChecked $CustomHeader.EnableHeader)   { $Settings["Core"]["CustomHeader.Title"]  = $this.Text } })
$CustomHeader.GameID.Add_TextChanged({          if (IsChecked $CustomHeader.EnableHeader)   { $Settings["Core"]["CustomHeader.GameID"] = $this.Text } })
$CustomHeader.Region.Add_SelectedIndexChanged({ if (IsChecked $CustomHeader.EnableRegion)   { $Settings["Core"]["CustomHeader.Region"] = $this.SelectedIndex } })
$CustomHeader.EnableHeader.Add_CheckedChanged({ RestoreCustomHeader })
$CustomHeader.EnableRegion.Add_CheckedChanged({ RestoreCustomRegion })
RestoreCustomHeader
RestoreCustomRegion

# Restore last settings
if ($GameConsole -eq $null) { ChangeGamesList | Out-Null }
ChangeGameMode    | Out-Null
ChangePatchPanel  | Out-Null
ChangePatch       | Out-Null
SetMainScreenSize | Out-Null
SetVCPanel        | Out-Null
CheckVCOptions    | Out-Null
ChangeGamesList

# Active GUI events
InitializeEvents

# Show the dialog to the user
if (!$FatalError) { $MainDialog.ShowDialog() | Out-Null }

# Exit
Out-IniFile -FilePath $Files.settings -InputObject $Settings | Out-Null
if ($GameType.save -gt 0) { Out-IniFile -FilePath (GetGameSettingsFile) -InputObject $GameSettings | Out-Null }
RemovePath $Paths.Registry
[System.GC]::Collect() | Out-Null
SetLogging $False
Exit