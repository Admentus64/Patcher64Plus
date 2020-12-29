function Get-IniContent ([String]$FilePath) {

    $ini = @{}
    switch -regex -file $FilePath {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$"
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini

}



#==============================================================================================================================================================================================
function Out-IniFile([hashtable]$InputObject, [String]$FilePath) {
    
    if (!(TestFile -Path ($Paths.Settings) -Container)) { New-Item -Path $Paths.Master -Name "Settings" -ItemType Directory | Out-Null }
    RemoveFile $FilePath
    $OutFile = New-Item -ItemType File -Path $Filepath
    foreach ($i in $InputObject.keys) {
        if (!($($InputObject[$i].GetType().Name) -eq "Hashtable")) { Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" } # No Sections
        else {
            #Sections
            Add-Content -Path $outFile -Value "[$i]"
            foreach ($j in ($InputObject[$i].keys | Sort-Object)) {
                
                if ($j -match "^Comment[\d]+")   { Add-Content -Path $OutFile -Value "$($InputObject[$i][$j])" }
                else                             { Add-Content -Path $OutFile -Value "$j=$($InputObject[$i][$j])" }
            }
            Add-Content -Path $outFile -Value ""
        }
    }

}



#==============================================================================================================================================================================================
function GetSettings([String]$File) {
    
    if (TestFile $File)   { return Get-IniContent $File }
    else                  { return @{} }

}



#==============================================================================================================================================================================================
function GetGameTypePreset() {
    
    for ($i=0; $i -lt $GeneralSettings.Presets.length; $i++) {
        if ($GeneralSettings.Presets[$i].checked) { return $GameType.mode + " - " + ($i+1) }
    }
    return $null

}



#==============================================================================================================================================================================================
function GetGameSettingsFile() { return $Paths.Settings + "\" + (GetGameTypePreset) + ".ini" }



#==============================================================================================================================================================================================

Export-ModuleMember -Function Get-IniContent
Export-ModuleMember -Function Out-IniFile
Export-ModuleMember -Function GetSettings
Export-ModuleMember -Function GetGameTypePreset
Export-ModuleMember -Function CreateGameTypePreset
Export-ModuleMember -Function GetGameSettingsFile