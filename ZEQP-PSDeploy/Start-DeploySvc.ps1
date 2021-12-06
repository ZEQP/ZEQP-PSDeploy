# Start-DeploySvc -ComputerName 139.9.69.110 -ServiceName WMSWCS -ServicePort 8054
function Start-DeploySvc {
    param (
        [string]$ComputerName = "localhost",
        [PSCredential]$Credential = "Administrator",
        [string]$ServiceName,
        [string]$RemotePath="D:\Publish\",
		[int]$ServicePort,
		[ScriptBlock]$ScriptBlock={ param($o) dotnet publish -o $o -c "Release" --no-self-contained -v m --nologo }
    )
    Write-Host 'Build Starting' -ForegroundColor Yellow
    $CurPath = (Resolve-Path .).Path
    $OutputPath = "$CurPath\bin\publish\"
    Remove-Item -Path $OutputPath -Force -Recurse
    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $OutputPath
    Write-Host 'Build Completed' -ForegroundColor Green
    
    Write-Host 'Compress Starting' -ForegroundColor Yellow
    $CurDateString = Get-Date -Format "yyyyMMddHHmmss"
    $ZIPFileName = "$ServiceName$CurDateString.zip"
    $ZIPFilePath = "$CurPath\$ZIPFileName"
    $CompressPath = "$OutputPath*"
    Compress-Archive -Path $CompressPath -DestinationPath $ZIPFilePath
    Write-Host "Compress Completed $ZIPFilePath" -ForegroundColor Green
    
    Write-Host 'Deploy Starting' -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green    
        Write-Host "Start copy files to the server $RemotePath" -ForegroundColor Yellow
        Copy-Item $ZIPFilePath -Destination $RemotePath -ToSession $Session
    
        $Service = Invoke-Command -Session $Session -ScriptBlock { param($name) Get-Service -Name $name } -ArgumentList $ServiceName
        if (!$Service) {
            #如果没有服务,就创建此服务
            Invoke-Command -Session $Session -ScriptBlock {
                Param($rootPath, $svcName, $port)
                $fullPath = "$rootPath$svcName"
                if (!(Test-Path -Path $fullPath)) {
                    Write-Host "1.创建目录$fullPath" -ForegroundColor Yellow
                    New-Item -Path $rootPath -Name $svcName -ItemType Directory
                }
                
                Write-Host "3.创建服务$svcName" -ForegroundColor Yellow
                New-Service -Name $svcName -BinaryPathName "$fullPath\Giant.WCS.exe" -Description $svcName -DisplayName $svcName -StartupType Automatic
    
                Write-Host "4.打开防火墙端口$port" -ForegroundColor Yellow
                New-NetFirewallRule -Name "$svcName$port" -DisplayName "$svcName$port" -Action Allow -Protocol TCP -LocalPort $port -Direction Inbound
    
            } -ArgumentList $RemotePath, $ServiceName, $ServicePort
        }
    
        $RemoteDestinationPath = "$RemotePath$ServiceName\"
        $RemoteZipPath = "$RemotePath$ZIPFileName"
    
        #部署服务
        Invoke-Command -Session $Session -ScriptBlock {
            Param($name, $file, $path)
            Write-Host "Stop the Service:$name" -ForegroundColor Yellow
            Stop-Service -Name $name
            while ((Get-Service -Name $name).Status -ne "Stopped") {
                Write-Host "Waiting Stop the Service:$name" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            Get-Service -Name $name
            Write-Host "Start Expand files on the server:$path" -ForegroundColor Yellow
            Remove-Item -Path $path -Recurse -Force
            Expand-Archive -Path $file -DestinationPath $path -Force
            Write-Host "Restart the Service:$name" -ForegroundColor Yellow
            Start-Service -Name $name
    
        } -ArgumentList $ServiceName, $RemoteZipPath, $RemoteDestinationPath
    
        Write-Host 'Disconnected from server' -ForegroundColor Yellow
        Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Remove-Item -Path $ZIPFilePath
    Write-Host 'Deploy Completed' -ForegroundColor Green    
}