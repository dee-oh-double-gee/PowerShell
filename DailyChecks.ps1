# Daily Checks. Eventually I will automate this and format it as html and send in an email

## Checks all of the DNS servers in the domain. The test can take a few minutes.

Invoke-command -ComputerName IS-DC1 <# Change to one of your Windows based DNS servers's #> -ScriptBlock {dcdiag /test:DNS /e}

## Checks what users are "Domain Admins"
Get-ADGroupMember -Identity 'Domain Admins' | Select-Object samAccountName

## Runs a command on all the servers to check and see if backups are done
$servers = Get-Content -Path C:\PowerShell\serverlist.txt
Invoke-command -ComputerName $servers -ScriptBlock {Get-WBSummary} | Format-Table PSComputerName,LastBackupTime,LastBackupResultHR,LastSuccessfulBackupTime

## Gets some AD information
$numberofadusers = (get-aduser –filter *).count
$numberofenabledusers = (get-aduser -filter *|where {$_.enabled -eq "True"}).count
$numberofdisabledusers = (get-aduser -filter *|where {$_.enabled -ne "False"}).count
$numberofcomputers = (get-adcomputer –filter *).count
$enabledcomputers = (get-adcomputer -filter *|where {$_.enabled -eq "True"}).count
$disabledcomputers = (get-adcomputer -filter *|where {$_.enabled -ne "False"}).count
"Total Number of AD Users: $numberofadusers"
"Total Number of Active AD Users: $numberofenabledusers"
"Total Number of Disabled AD Users: $numberofdisabledusers"
"Total Number of Computers in AD: $numberofcomputers"
"Total Number of Enabled Computers: $enabledcomputers"
"Total Number of Disabled Computers: $disabledcomputers"


