# Start-DeploySvc -ComputerName 139.9.69.110 -ServiceName WMSWCS -ServicePort 8054
function Start-DeploySvc {
    param (
        [string]$ComputerName = "localhost",
        [int]$ComputerPort = 5985,
        [PSCredential]$Credential = "Administrator",
        [string]$ServiceName,
        [string]$BinaryPathName,
        [string]$RemotePath = "D:\Publish\",
        [int]$ServicePort = 0,
        [ScriptBlock]$ScriptBlock = { param($o) dotnet publish -o $o -c "Release" --no-self-contained -v m --nologo },
        [string]$OutputPath = ".\bin\publish\",
        [bool]$IsFull = $true
    )
    Write-Host 'Build Starting' -ForegroundColor Yellow
    $outPath = (Resolve-Path $OutputPath).Path
    Write-Host "OutputPath:$outPath" -ForegroundColor Yellow
    if (!(Test-Path -Path $outPath)) {
        Write-Host "1.创建目录$outPath" -ForegroundColor Yellow
        New-Item -Path $outPath -ItemType Directory
    }
    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $outPath
    Write-Host 'Build Completed' -ForegroundColor Green
    
    Write-Host 'Compress Starting' -ForegroundColor Yellow
    $CurDateString = Get-Date -Format "yyyyMMddHHmmss"
    $ZIPFileName = "$ServiceName$CurDateString.zip"
    $CurPath = (Resolve-Path .).Path
    $ZIPFilePath = "$CurPath\$ZIPFileName"
    if ($IsFull -eq $true) {
        Compress-Archive -Path "$outPath\*" -DestinationPath $ZIPFilePath
    }
    else {
        Get-ChildItem -Path "$outPath\*" | Where-Object { $_.LastWriteTime -ge (Get-Date -Format "yyyy-MM-dd") } | Compress-Archive -DestinationPath $ZIPFilePath
    }
    Write-Host "Compress Completed $ZIPFilePath" -ForegroundColor Green
    
    Write-Host 'Deploy Starting' -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Port $ComputerPort -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host 'Successfully connected to the server' -ForegroundColor Green    
        Write-Host "Start copy files to the server $RemotePath" -ForegroundColor Yellow
        Copy-Item $ZIPFilePath -Destination $RemotePath -ToSession $Session
    
        $Service = Invoke-Command -Session $Session -ScriptBlock { param($name) Get-Service -Name $name } -ArgumentList $ServiceName
        if (!$Service) {
            #如果没有服务,就创建此服务
            Invoke-Command -Session $Session -ScriptBlock {
                Param($rootPath, $svcName, $binPathName, $port)
                $fullPath = "$rootPath$svcName"
                if (!(Test-Path -Path $fullPath)) {
                    Write-Host "1.创建目录$fullPath" -ForegroundColor Yellow
                    New-Item -Path $rootPath -Name $svcName -ItemType Directory
                }
                
                Write-Host "3.创建服务$svcName" -ForegroundColor Yellow
                New-Service -Name $svcName -BinaryPathName "$fullPath\$binPathName" -Description $svcName -DisplayName $svcName -StartupType Automatic
                if ($port -ne 0) {
                    Write-Host "4.打开防火墙端口$port" -ForegroundColor Yellow
                    New-NetFirewallRule -Name "$svcName$port" -DisplayName "$svcName$port" -Action Allow -Protocol TCP -LocalPort $port -Direction Inbound
                }
            } -ArgumentList $RemotePath, $ServiceName, $BinaryPathName, $ServicePort
        }
    
        $RemoteDestinationPath = "$RemotePath$ServiceName\"
        $RemoteZipPath = "$RemotePath$ZIPFileName"
    
        #部署服务
        Invoke-Command -Session $Session -ScriptBlock {
            Param($name, $file, $path, $full)
            Write-Host "Stop the Service:$name" -ForegroundColor Yellow
            Stop-Service -Name $name
            while ((Get-Service -Name $name).Status -ne "Stopped") {
                Write-Host "Waiting Stop the Service:$name" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            Get-Service -Name $name
            Write-Host "Start Expand files on the server:$path" -ForegroundColor Yellow
            if ($full -eq $true) { Remove-Item -Path $path -Recurse -Force }
            Expand-Archive -Path $file -DestinationPath $path -Force
            Write-Host "Restart the Service:$name" -ForegroundColor Yellow
            Start-Service -Name $name
    
        } -ArgumentList $ServiceName, $RemoteZipPath, $RemoteDestinationPath, $IsFull
    
        Write-Host 'Disconnected from server' -ForegroundColor Yellow
        Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host 'Failed connected to the server' -ForegroundColor Red
    }
    Remove-Item -Path $ZIPFilePath
    Write-Host 'Deploy Completed' -ForegroundColor Green    
}