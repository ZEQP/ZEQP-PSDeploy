# New-DomainBind -ComputerName 127.0.0.1 -WebSiteName Blog -HostHeader blog.liuju.cc -Subject *.liuju.cc
function New-DomainBind {
    param (
        [string]$ComputerName = "localhost",
        [PSCredential]$Credential = "Administrator",
        [string]$WebSiteName,
        [string]$HostHeader,
        [string]$IPAddress = "*",
        [string]$Subject
    )
    Write-Host 'Domain Bindding Starting' -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green
        Invoke-Command -Session $Session -ScriptBlock {
            Param($siteName, $subject, $hostHeader, $ipAddress)
            New-WebBinding -Name $siteName -Protocol "http" -IPAddress $ipAddress -Port 80 -HostHeader $hostHeader
            if ($cert = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like $subject } | Select-Object -First 1) {
                New-WebBinding -Name $siteName -Protocol "https" -IPAddress $ipAddress -HostHeader $hostHeader -Port 443 -SslFlags 0
                $binding = Get-WebBinding -Name $siteName -Protocol "https" -HostHeader $hostHeader
                $binding.AddSslCertificate($cert.Thumbprint, "My")
            }
        } -ArgumentList $WebSiteName, $Subject, $HostHeader, $IPAddress
        Write-Host 'Disconnected from server' -ForegroundColor Yellow
        Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Write-Host 'Domain Bindding Completed' -ForegroundColor Green
}