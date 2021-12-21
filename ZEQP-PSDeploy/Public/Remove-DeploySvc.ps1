# Remove-Deploy -ComputerName 139.9.69.110 -WebSiteName WMSWeb -WebSitePort 8051
function Remove-DeploySvc {
    param (
        [string]$ComputerName = "localhost",
        [PSCredential]$Credential = "Administrator",
        [string]$ServiceName,
        [int]$ServicePort
    )
    Write-Host 'Deploy Clear Starting' -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green
        Invoke-Command -Session $Session -ScriptBlock {
            Param($name, $port)
            Stop-Service -Name $name
            while ((Get-Service -Name $name).Status -ne "Stopped") {
				Write-Host "Waiting Stop the Service:$name" -ForegroundColor Yellow
				Start-Sleep -Seconds 1
			}
            Remove-Service -Name $name
            Remove-NetFirewallRule -DisplayName "$name$port"
        } -ArgumentList $ServiceName,$ServicePort
        Write-Host 'Disconnected from server' -ForegroundColor Yellow
	    Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Write-Host 'Deploy Clear Completed' -ForegroundColor Green
}