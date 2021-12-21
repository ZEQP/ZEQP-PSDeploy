# Remove-Deploy -ComputerName 139.9.69.110 -WebSiteName WMSWeb -WebSitePort 8051
function Remove-Deploy {
    param (
        [string]$ComputerName = "localhost",
        [PSCredential]$Credential = "Administrator",
        [string]$WebSiteName,
        [int]$WebSitePort
    )
    Write-Host 'Deploy Clear Starting' -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green
        Invoke-Command -Session $Session -ScriptBlock {
            Param($siteName, $port)
            Stop-WebAppPool -Name $siteName
            while ((Get-WebAppPoolState -Name $siteName).Value -ne "Stopped") {
                Write-Host "Waiting Stop the AppPool:$siteName" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            Stop-Website -Name $siteName
            while ((Get-Website -Name $siteName).State -ne "Stopped") {
                Write-Host "Waiting Stop the Website:$siteName" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            Remove-Website -Name $siteName
            Remove-WebAppPool -Name $siteName
            Remove-NetFirewallRule -DisplayName "$siteName$port"
        } -ArgumentList $WebSiteName,$WebSitePort
        Write-Host 'Disconnected from server' -ForegroundColor Yellow
	    Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Write-Host 'Deploy Clear Completed' -ForegroundColor Green
}