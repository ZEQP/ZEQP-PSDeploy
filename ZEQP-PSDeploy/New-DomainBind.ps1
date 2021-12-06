# New-DomainBind -ComputerName 139.9.69.110 -WebSiteName WMSWeb -Protocol https -DomainName liuju.cc
function New-DomainBind {
    param (
        [string]$ComputerName = "localhost",
        [PSCredential]$Credential = "Administrator",
        [string]$WebSiteName,
        [string]$Protocol = "http",
        [string]$DomainName
    )
    Write-Host 'Domain Bindding Starting' -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green
        Invoke-Command -Session $Session -ScriptBlock {
            Param($siteName, $proto, $domain)
            $hostHeader = "$siteName.$domain".ToLower()
            New-WebBinding -Name $siteName -Protocol "http" -IPAddress "*" -Port 80 -HostHeader $hostHeader
            if (($cert = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*.$domain" } | Select-Object -First 1) -and ($proto -eq "https")) {
                New-WebBinding -Name $siteName -Protocol "https" -HostHeader $hostHeader -Port 443 -SslFlags 0
                $binding = Get-WebBinding -Name $siteName -Protocol "https" -HostHeader $hostHeader
                $binding.AddSslCertificate($cert.Thumbprint, "My")
            }
        } -ArgumentList $WebSiteName, $Protocol, $DomainName
        Write-Host 'Disconnected from server' -ForegroundColor Yellow
        Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Write-Host 'Domain Bindding Completed' -ForegroundColor Green
}