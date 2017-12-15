## Basic Daily checks script that sends an email
## Can be ran once or ran in a Scheduled task

## Run this command before you run this script for the first time or after you actually add a new domain admin:
## EDIT: After it notifies of a change, you may have to delete C:\scripts\Domainadmins.xml and then run the below command
## (Get-ADGroupMember -server $ADserver -Identity 'Domain Admins').samAccountName | Export-Clixml -Path C:\scripts\Domainadmins.xml -Force
## EDIT: actually let me just run it for you :)  :

## Change to  your AD server. If you don't specify a server it may grab the "Domain Admins" from another DC and then get the same result but in
## a different order and that will make the hash different and then the if statement will flag that the admins have changed even if they have not.
$ADserver = IS-DC1


$CheckFile = Test-Path C:\scripts\Domainadmins.xml
if ($CheckFile){} else {
    (Get-ADGroupMember -server $ADserver -Identity 'Domain Admins').samAccountName | Export-Clixml -Path C:\scripts\Domainadmins.xml -Force
}


## Checks all of the DNS servers in the domain. The test can take a few minutes.

Invoke-command -ComputerName IS-DC1 <# Change to one of your Windows based DNS servers's #> -ScriptBlock {dcdiag /test:DNS /e} | out-File c:\scripts\dns.txt

$dns = gc c:\scripts\dns.txt -Tail 2



## Checks all of AD for Domain Admin accounts and displays them. Even if the account is disabled.

#$domainadmins = Get-ADGroupMember -server $ADserver -Identity 'Domain Admins' | Select-Object samAccountName
$domainadmins = (Get-ADGroupMember -server $ADserver -Identity 'Domain Admins').samAccountName
$domainadmins | Export-Clixml -Path C:\scripts\Newdomainadmins.xml -Force

$oldxml = ("C:\scripts\Domainadmins.xml")
$newxml = ("C:\scripts\Newdomainadmins.xml")
$oldxmlhash = Get-FileHash -Path $oldxml | Select-Object -expandProperty Hash
$newxmlhash = Get-FileHash -Path $newxml | Select-Object -expandProperty Hash

## Checks the hash of both old and new xml files. if they are different then get the difference and put that in the email
## and then change the priority and subject of the email

If ($oldxmlhash -ne $newxmlhash){
    
    $Difference = Compare-Object -ReferenceObject (Get-Content $oldxml) -DifferenceObject (Get-Content $newxml)
    $Priority = 'High'
    $Subject = 'NEW ADMIN Added'
    $uri = "https://api.pushover.net/1/messages.json"
    $parameters = @{
  token = Get-Content C:\scripts\pushtoken.txt
  user = Get-Content C:\scripts\pushuser.txt
  title = "OH BALLS"
  message = "Admin Change!"
    }
    $parameters | Invoke-RestMethod -Uri $uri -Method Post
} else {
 
    $Priority = 'Normal'
    $Subject = 'Daily Checks'
}




## Check for accounts that don't have password expiry set. This includes disabled accounts

#$passnoexpire = Get-ADUser -Filter 'useraccountcontrol -band 65536' -Properties useraccountcontrol | Select SamAccountName | out-string
$passnoexpire = (Get-ADUser -Filter 'useraccountcontrol -band 65536').SamAccountName
## Gets some AD information
$numberofadusers = (get-aduser –filter *).count
$numberofenabledusers = (get-aduser -filter *|where {$_.enabled -eq "True"}).count
$numberofdisabledusers = (get-aduser -filter *|where {$_.enabled -ne "False"}).count
$numberofcomputers = (get-adcomputer –filter *).count
$enabledcomputers = (get-adcomputer -filter *|where {$_.enabled -eq "True"}).count
$disabledcomputers = (get-adcomputer -filter *|where {$_.enabled -ne "False"}).count

## Check for accounts that have no password requirement
# Get-ADUser -Filter 'useraccountcontrol -band 32' -Properties useraccountcontrol | Select SamAccountName

## Builds out the basic email



$body = @()
$body += $Difference

$body += '-'*50
$body += 'DNS Test'
$body += $dns

$body += '-'*50
$body += 'Accounts that the password does not expire:'
$body += $passnoexpire

$body += '-'*50
$body += "Total Number of AD Users: $numberofadusers"
$body += "Total Number of Active AD Users: $numberofenabledusers"
$body += "Total Number of Disabled AD Users: $numberofdisabledusers"
$body += "Total Number of Computers in AD: $numberofcomputers"
$body += "Total Number of Enabled Computers: $enabledcomputers"
$body += "Total Number of Disabled Computers: $disabledcomputers"


$body = $body | out-string



## To Create the cred.txt run: ' Read-Host -Prompt "Enter your password" -AsSecureString | ConvertFrom-SecureString | Out-File "C:\scripts\cred.txt" '

$AdminName = "no-reply@insidesales.com" <# Change to the O365 account used for SMTP#>
$Pass = Get-Content "C:\scripts\cred.txt" | ConvertTo-SecureString
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Pass

## Sends email based on the credentials provided. 
## These settings will only work with Office 365. You may have to change some of the settings depending on your SMTP server

Send-MailMessage -To beau@insidesales.com -from no-reply@insidesales.com -Subject $Subject -Priority $Priority -Body $body -smtpserver smtp.office365.com -usessl -Credential $cred -Port 587 
