$host.ui.RawUI.WindowTitle = "Beau is #1"
##[console]::ForegroundColor = "Green"
##[console]::BackgroundColor = "black"
##Set-ItemProperty -Path HKCU:\console -Name WindowAlpha -Value 205


Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
set-location c:\PowerShell
Write-Output "Please don't tap on the glass. It scares the IT guys"

function Get-Excuse {

If ( !( Get-Variable -Scope Global -Name Excuses -ErrorAction SilentlyContinue ) ) {
$Global:Excuses = (Invoke-WebRequest http://pages.cs.wisc.edu/~ballard/bofh/excuses).Content.Split([Environment]::NewLine)
}
Get-Random $Global:Excuses
}

function o365 {
$credential = Get-Credential
Import-Module MsOnline
Connect-MsolService -Credential $credential
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $exchangeSession -DisableNameChecking
}




function o365d {
Remove-PSSession $exchangeSession
}

##function sync {
##invoke-command -ComputerName awcc-ut1-us -scriptblock {Start-ADSyncSyncCycle -PolicyType Delta}
##}


function sync {
Write-Host "Initializing Azure AD Delta Sync..." -ForegroundColor Yellow

invoke-command -ComputerName awcc-ut1-us -scriptblock {Start-ADSyncSyncCycle -PolicyType Delta}

#Wait 10 seconds for the sync connector to wake up.
Start-Sleep -Seconds 10

#Display a progress indicator and hold up the rest of the script while the sync completes.
	While(invoke-command -ComputerName awcc-ut1-us -scriptblock {Get-ADSyncConnectorRunStatus}){
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 10
}

Write-Host " | Complete!" -ForegroundColor Green
}

function newuser {
c:\users\beau\NewADUser-v15.ps1
}


function food {
c:\users\beau\food.ps1
}

function 2fa {
c:\PowerShell\WhoHas2fa.ps1
}