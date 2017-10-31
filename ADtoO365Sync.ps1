Write-Host "Initializing Azure AD Delta Sync..." -ForegroundColor Yellow

invoke-command -ComputerName awcc-ut1-us <# Change to your server that does the sync #> -scriptblock {Start-ADSyncSyncCycle -PolicyType Delta}

#Wait 10 seconds for the sync connector to wake up.
Start-Sleep -Seconds 10

#Display a progress indicator and hold up the rest of the script while the sync completes.
While(invoke-command -ComputerName awcc-ut1-us <# Change to your server that does the sync #> -scriptblock {Get-ADSyncConnectorRunStatus}){
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 10
}

Write-Host " | Complete!" -ForegroundColor Green