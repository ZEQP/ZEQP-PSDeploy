function Update-DomainBind {
    param (
        [String]$ComputerName = "localhost",
        [PSCredential]$Credential = "Administrator"
    )
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green
        Invoke-Command -Session $Session -ScriptBlock {
            Submit-Renewal -AllOrders -Force | ForEach-Object {
                $cert = $_
                $cert
                $subject = $cert.Subject.Replace("CN=","")
                Write-Host "Subject:$subject" -ForegroundColor Green
                $thumbprint = $cert.Thumbprint
                Write-Host "Thumbprint:$thumbprint" -ForegroundColor Green
                Install-PACertificate -PACertificate $cert
                # Get-PACertificate $subject | Install-PACertificate
                # while ($null -eq (Get-ChildItem "Cert:\LocalMachine\My" | Where-Object Thumbprint -eq $thumbprint | Select-Object -First 1)) {
                #     Write-Host "Wait $subject Install" -ForegroundColor Yellow
                #     Start-Sleep -Seconds 1
                # }
                Get-WebBinding -Protocol https | Where-Object BindingInformation -Like $subject | ForEach-Object {
                    $bind = $_
                    $bind
                    $bind.RebindSslCertificate($thumbprint, "My")
                    # $bind.RemoveSslCertificate()
                    # $bind.AddSslCertificate($thumbprint, "My")
                }
            }
        }
        Write-Host 'Disconnected from server' -ForegroundColor Yellow
        Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Write-Host 'Update Domain Bindding Completed' -ForegroundColor Green
}