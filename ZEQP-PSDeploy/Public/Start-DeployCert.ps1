function Start-DeployCert {
    param (
        [string]$ComputerName = "localhost",
        [int]$ComputerPort = 5985,
        [PSCredential]$Credential = "Administrator",
        [string]$Subject,
        [string]$RemotePath = "D:\Publish\"
    )
    $cert = Get-PACertificate $Subject
    if ($null -eq $cert) {
        Write-Host "Can't find certificate $Subject" -ForegroundColor Red
        exit
    }
    Write-Host 'Deploy Starting' -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Port $ComputerPort -Credential $Credential
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green

        Write-Host "Start copy certificate to the server:$RemotePath" -ForegroundColor Yellow
        Copy-Item $cert.PfxFullChain -Destination $RemotePath -ToSession $Session
        #部署系统
        Invoke-Command -Session $Session -ScriptBlock {
            Param($path, $pfxPass)
            $remotePath = (Resolve-Path $path).Path
            $filePath = "$remotePath\fullchain.pfx"
            Import-PfxCertificate -FilePath $filePath -CertStoreLocation Cert:\LocalMachine\My -Password $pfxPass
            Remove-Item -Path $filePath
        } -ArgumentList $RemotePath, $cert.PfxPass

        Write-Host 'Disconnected from server' -ForegroundColor Yellow
        Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Write-Host 'Deploy Completed' -ForegroundColor Green
}