﻿if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
write-host "Loading..." -ForegroundColor Green

Function Get_Dell_BIOS_Settings
{
    $i = 0
    $WarningPreference='silentlycontinue'
    If (Get-Module -ListAvailable -Name DellBIOSProvider)
        {} 
    Else 
        {
            Install-Module -Name DellBIOSProvider -Force 
        }
    get-command -module DellBIOSProvider | out-null
    $Script:Get_BIOS_Settings = get-childitem -path DellSmbios:\ | select-object category | 
    foreach {
        get-childitem -path @("DellSmbios:\" + $_.Category)  | select-object attribute, currentvalue, Description, PossibleValues, PSPath                
    } 
                
    $Script:Get_BIOS_Settings = $Get_BIOS_Settings |  % { New-Object psobject -Property @{
        Setting = $_."attribute"
        Value = $_."currentvalue"
        Description = $_."Description"    
        "Possible Values" = $_."PossibleValues"
        PSPath = $_."PSPath"
        UID = $i++                                                 
        }}          
                
    If($ShowDescription)
        {
            $Get_BIOS_Settings | select-object Setting, Value, Description, "Possible values", PSPath 
        }
    Else
        {
            $Get_BIOS_Settings | select-object Setting, Value, "Possible values", PSPath, "UID"
        }
}  

function refresh($pth) {
    write-host "Refreshing BIOS settings" -ForegroundColor DarkMagenta
    $global:settings = $null
    $global:settings = Get_Dell_BIOS_Settings
}



function clean() {
    $prompt = $null
    $prompt2 = $null
}

function Selected() {
    $selected = ($global:settings[$prompt]).Setting
    $PSPath = ((($global:settings[$prompt]).PSPath).substring(33) + ("\"+$selected))
    write-host "`nSelected" $selected -ForegroundColor Yellow
    write-host "[1]: View Details`n[2]: Edit Setting`n[0]: Go Back" -ForegroundColor Yellow
    do{
    $Prompt2 = Read-host "Enter a number"
    Switch ($Prompt2)
         {
           "1" {
           ViewDetails -UID $prompt -PSPATH $PSPath -count 0
            }

           "2" {
            EditSetting -UID $prompt
            }

           "0" {
            write-host "Going Back" -ForegroundColor Gray
            Menu
            }

           Default {write-host "`nInvalid Entry`n" -ForegroundColor Red; continue}
         }

        } 
        while($prompt2 -notmatch "[120]")
}
function Menu() {
    $r=0
    foreach($entry in $global:settings) {
        write-host "["$r "]:"($entry).Setting
        $r++
    }

        do{
    
        $Prompt = Read-host "Enter a number (or 'quit')"
        if($prompt -eq 'quit') {exit(1)}
          if(([int]$prompt -lt $r) -and ([int]$Prompt -gt -1)) {Selected}
          
            else {write-host "`nInvalid Entry`n" -ForegroundColor Red; continue}
        }
        while(!(([int]$prompt -lt $r) -and ([int]$Prompt -gt -1)))
}

function ViewDetails($UID, $PSPATH, $count) {
    if($count -eq 0) {
        write-host "Viewing Details for:" $global:settings[$prompt].Setting -ForegroundColor Gray
        $global:settings[$UID]
        }
    write-host "[1]: More Details`n[0]: Go Back`n"
    do{
    $Prompt4 = Read-host "Enter a number"
    
    if($prompt4 -eq 0) {
        Selected
    }
    if($prompt4 -eq 1) {
        Get-Item -Path $PSPATH | Select *
        ViewDetails -UID $UID -PSPATH $PSPATH -count 1
        }    
    else {
        write-host "`nInvalid Entry`n" -ForegroundColor Red; continue
    }
        }
        while($prompt4 -notmatch "[10]")
    
    Selected
}

function EditBIOS($att, $pth, $val, $uid) {
    write-host "Writing value:"$val" to "$att -ForegroundColor Gray
    $fixedpath = ($pth.substring(33) + ("\"+$att))
    Set-Item -Path $fixedpath -Value $val
    refresh -pth $pth
    Validation -pth $fixedpath -val $val 
    pause
    Selected
}

function EditSetting($UID) {
    write-host "Changing Setting for: "($global:settings[$UID]).Setting -ForegroundColor Yellow
    write-host "Current status: " $global:settings[$UID].Value -ForegroundColor Yellow
    $i = 1
    $optionsArray = @()
    [System.Collections.ArrayList]$optionsArraycomplete = @()
    foreach($entry in (($global:settings[$UID]))) { 
            try {(($entry.'Possible Values').Split(" ") | Foreach { $optionsArray += "$i"; $optionsArray += "$_"; $i++})}
            catch { continue }
            
        }
        
        $r = 0
        foreach ($obj in $optionsArray) {
            
            if( ($optionsArray[$r+1]) -eq $null) {  }
            else {
                $val = [pscustomobject]@{'ID'=$optionsArray[$r]; 'Option'=$optionsArray[$r+1]}
                $optionsArraycomplete.Add($val) | out-Null
                $val =$null
                $r=$r+2
                }
            }
        $val = [pscustomobject]@{'ID'='0'; 'Option'='Cancel'}
            $optionsArraycomplete.Add($val) | out-Null
            $val =$null
            $r=$r+2
            
            [System.Collections.ArrayList]$values = @()
            if(($optionsArraycomplete).Count -lt 2) {
                write-host "`nNo values to update" -ForegroundColor Red
                Selected
                }
            else {
            foreach($setting in $optionsArraycomplete) {
                write-host "["$setting.ID"]: " $setting.Option
                $values.add($setting.ID) | Out-Null }
            
            do{
    $Prompt3 = Read-host "Enter a number"
    
    if($prompt3 -eq 0) {
        write-host "Cancelling" -ForegroundColor Gray
        Selected
    }
    if($values.Contains($prompt3)){
        EditBIOS -att $global:settings[$prompt].Setting -pth $global:settings[$prompt].PSPath -val (($optionsArraycomplete[$Prompt3-1]).Option) -uid $UID
        }
         
    else {
        write-host "`nInvalid Entry`n" -ForegroundColor Red; continue
    }
        }
        while(($values.Contains($prompt3) -eq $false))
    pause
    Selected
}
}



function Validation($pth, $val) {
    $newVal = Get-Item -Path $pth | Select CurrentValue
    IF($newVal.CurrentValue -ne $val) { write-host "Error updating value" -ForegroundColor Red; continue }
    else { write-host "Successfully Updated" -ForegroundColor Green; continue }

}

refresh
Menu

