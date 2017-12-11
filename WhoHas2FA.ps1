## Connect to Echange Online

$credential = Get-Credential
Import-Module MsOnline
Connect-MsolService -Credential $credential
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $exchangeSession -DisableNameChecking

## Get all users, and then check 2fa status then output to csv

Measure-Command -Expression {
    
Get-msoluser -All | select DisplayName,@{N='Email';E={$_.UserPrincipalName}},@{N='StrongAuthenticationRequirements';E={($_.StrongAuthenticationRequirements.State)}} | Export-Csv -NoTypeInformation C:\scripts\whohas2fa.csv
}
#Get-msoluser -All | select DisplayName,@{N='Email';E={$_.UserPrincipalName}},@{N='StrongAuthenticationRequirements';E={($_.StrongAuthenticationRequirements.State)}} | Export-Csv -NoTypeInformation C:\scripts\whohas2fa.csv