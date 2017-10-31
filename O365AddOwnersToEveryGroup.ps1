## Connect to O365

$credential = Get-Credential
Import-Module MsOnline
Connect-MsolService -Credential $credential
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $exchangeSession -DisableNameChecking

## Who do you want as an owner of every group

$Owner = read-host "What is the email of the person you want to be an owner over every group?"



Get-DistributionGroup |Set-DistributionGroup -ManagedBy @{Add="$owner"} –BypassSecurityGroupManagerCheck