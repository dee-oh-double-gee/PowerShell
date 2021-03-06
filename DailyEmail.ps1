﻿
<#
    .SYNOPSIS
    Basic Daily checks script that sends an email

    .DESCRIPTION
    Basic Daily checks script that sends an email. It will change the subjext and priority of the email and send a pushover notification if the list of Domain Admins changes
    Can be ran once or ran in a Scheduled task

    .NOTES
    Some things need to be done and some changes need to be made to the script before you will be able to run it:
    1. Change the name of the $ADserver to the name of a DC on your domain. If you don't specify a server it may grab the list from different DC's and get different hashes. which is bad.
    2. Change all the email settings including creating the cred.txt as instructed and pushover settings if you want to use that
    3. Run the script once manually to create the Domainadmins.xml file. This is what the script uses for a reference. It will also help you test the email settings

    .EXAMPLE
    Scheduled task: Powershell.exe -windowstyle hidden C:\Powershell\DailyEmail.ps1

    .EXAMPLE
    One time: .\DailyEmail.ps1

    .LINK
    https://github.com/dee-oh-double-gee/PowerShell
#>

####### Change these settings: ########
$ADserver = 'IS-DC1'
$SMTPemail = 'no-reply@insidesales.com' # Change to the O365 account used for SMTP
$To = 'helpdesk@insidesales.com'
## To Create the cred.txt run: ' Read-Host -Prompt "Enter your password" -AsSecureString | ConvertFrom-SecureString | Out-File "C:\scripts\cred.txt" '
$Pass = Get-Content "C:\scripts\cred.txt" | ConvertTo-SecureString
$smtpserver = 'smtp.office365.com'
$Port = 587
$usessl = $true

<#Run this command before you run this script for the first time or after you actually add a new domain admin:
    EDIT: After it notifies of a change, you may have to delete C:\scripts\Domainadmins.xml and then run the below command
    (Get-ADGroupMember -server <ServerName> -Identity 'Domain Admins').samAccountName | Export-Clixml -Path C:\scripts\Domainadmins.xml -Force
    EDIT: actually let me just run it for you :)  :
    #>

$CheckFile = Test-Path C:\scripts\Domainadmins.xml
if ($CheckFile){} else {
    (Get-ADGroupMember -server $ADserver -Identity 'Domain Admins').samAccountName | Export-Clixml -Path C:\scripts\Domainadmins.xml -Force
}


## Checks all of the DNS servers in the domain. The test can take a few minutes.

Invoke-command -ComputerName IS-DC1 <# Change to one of your Windows based DNS servers's #> -ScriptBlock {dcdiag /test:DNS /e} | out-File c:\scripts\dns.txt

$dns = Get-Content c:\scripts\dns.txt -Tail 2

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
$numberofenabledusers = (get-aduser -filter * | Where-Object {$_.enabled -eq "True"}).count
$numberofdisabledusers = (get-aduser -filter * | Where-Object {$_.enabled -ne "False"}).count
$numberofcomputers = (get-adcomputer –filter *).count
$enabledcomputers = (get-adcomputer -filter * | Where-Object {$_.enabled -eq "True"}).count
$disabledcomputers = (get-adcomputer -filter * | Where-Object {$_.enabled -ne "False"}).count

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



$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $SMTPemail, $Pass

## Sends email based on the credentials provided. 
## These settings will only work with Office 365. You may have to change some of the settings depending on your SMTP server

$emailparam = @{
    'To' = $To
    'From' = $SMTPemail
    'Subject' = $Subject
    'Priority' = $Priority
    'Body' = $Body
    'smtpserver' = $smtpserver
    'Credential' = $Cred
    'Port' = $Port
    'usessl' = $usessl
}

Send-MailMessage @emailparam