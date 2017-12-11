## This script requires the MsOnline module to be installed. More info here: https://docs.microsoft.com/en-us/powershell/module/msonline/?view=azureadps-1.0

## To Create the o365cred.txt run: ' Read-Host -Prompt "Enter your password" -AsSecureString | ConvertFrom-SecureString | Out-File "C:\scripts\o365cred.txt" '

$AdminName = "service@insidesales.com" <# Change to the O365 account used for SMTP#>
$Pass = Get-Content "C:\scripts\o365cred.txt" | ConvertTo-SecureString
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Pass



## connect to O365
Import-Module MsOnline
Connect-MsolService -Credential $Cred
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Cred -Authentication "Basic" -AllowRedirection
Import-PSSession $ExchangeSession -DisableNameChecking


## Enable Litigation Hold and Archiving for any mailbox without those things

Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"} | Set-Mailbox -LitigationHoldEnabled $true -LitigationHoldDuration Unlimited

Get-Mailbox -Filter {ArchiveStatus -Eq "None" -AND RecipientTypeDetails -eq "UserMailbox"} | Enable-Mailbox -Archive

## Send Pushover notification
## Probably not the safest way to pass the token and user but... eh.
    $Uri = "https://api.pushover.net/1/messages.json"
    $Token = Get-Content C:\scripts\pushtoken.txt
    $User = Get-Content C:\scripts\pushuser.txt
    $Parameters = @{
  token = "$Token"
  user = "$User"
  title = "Lit+Archive finished"
  message = "Yay!"
    }
    $Parameters | Invoke-RestMethod -Uri $Uri -Method Post


## Disconnect

Remove-PSSession $ExchangeSession