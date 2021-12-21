function Start-Deploy {
    param (
        [string]$ComputerName = "localhost",
        [PSCredential]$Credential = "Administrator",
        [string]$WebSiteName,
        [string]$RemotePath = "D:\Publish\",
        [int]$WebSitePort,
        [ScriptBlock]$ScriptBlock = { npm run build:live },
        [string]$OutputPath = ".\dist\"
    )
    Write-Host "Build Starting" -ForegroundColor Yellow
    $outPath = (Resolve-Path $OutputPath).Path
    Write-Host "OutputPath:$outPath" -ForegroundColor Yellow
    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $outPath
    Write-Host "Build Completed" -ForegroundColor Green

    Write-Host "Compress Starting" -ForegroundColor Yellow
    $CurDateString = Get-Date -Format "yyyyMMddHHmmss"
    $ZIPFileName = "$WebSiteName$CurDateString.zip"
    $CurPath = (Resolve-Path .).Path
    $ZIPFilePath = "$CurPath\$ZIPFileName"
    Compress-Archive -Path "$outPath\*" -DestinationPath $ZIPFilePath
    Write-Host "Compress Completed $ZIPFilePath" -ForegroundColor Green

    Write-Host "Deploy Starting" -ForegroundColor Yellow
    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    $Session
    if ($Session.State -eq "Opened") {
        Write-Host "Successfully connected to the server" -ForegroundColor Green

        Write-Host "Start copy files to the server:$RemotePath" -ForegroundColor Yellow
        Copy-Item $ZIPFilePath -Destination $RemotePath -ToSession $Session

        $WebSite = Invoke-Command -Session $Session -ScriptBlock { param($name) Get-Website -Name $name } -ArgumentList $WebSiteName
        if (!$WebSite) {
            #如果没有站点,就创建此站点
            Invoke-Command -Session $Session -ScriptBlock {
                Param($rootPath, $siteName, $port)
                $fullPath = "$rootPath$siteName"
                if (!(Test-Path -Path $fullPath)) {
                    Write-Host "1.创建目录$fullPath" -ForegroundColor Yellow
                    New-Item -Path $rootPath -Name $siteName -ItemType Directory
                }
                Write-Host "2.创建程序池$siteName" -ForegroundColor Yellow
                New-WebAppPool -Name $siteName
                Write-Host "设置程序池参数" -ForegroundColor Yellow
                #设置程序池.Net CLR版本 "":无托管代码,v4.0:.Net CLR版本为4.0
                Set-ItemProperty -Path "IIS:\AppPools\$siteName" -Name managedRuntimeVersion -Value ""
                #程序池启动模式 OnDemand:按需启动 AlwaysRunning:始终运行 (默认OnDemand)
                #Set-ItemProperty -Path "IIS:\AppPools\$siteName" -Name startMode -Value AlwaysRunning
                #程序池启动模式闲置超时时间(默认00:20:00)
                #Set-ItemProperty -Path "IIS:\AppPools\$siteName" -Name processModel.idleTimeout -Value 00:00:00

                Write-Host "3.创建站点$siteName" -ForegroundColor Yellow
                New-Website -Name $siteName -Port $port -PhysicalPath $fullPath -ApplicationPool $siteName
                #设置站点预加载是否启用(默认False)
                #Set-ItemProperty "IIS:\Sites\$siteName" -Name applicationDefaults.preloadEnabled -Value True
                Start-Website -Name $siteName

                Write-Host "4.打开防火墙端口$port" -ForegroundColor Yellow
                New-NetFirewallRule -Name "$siteName$port" -DisplayName "$siteName$port" -Action Allow -Protocol TCP -LocalPort $port -Direction Inbound

            } -ArgumentList $RemotePath, $WebSiteName, $WebSitePort
        }

        $RemoteDestinationPath = "$RemotePath$WebSiteName\"
        $ApplicationPool = $WebSiteName # $WebSite.ApplicationPool
        $RemoteZipPath = "$RemotePath$ZIPFileName"

        #部署系统
        Invoke-Command -Session $Session -ScriptBlock {
            Param($pool, $file, $path)
            Write-Host "Stop the AppPool:$pool" -ForegroundColor Yellow
            Stop-WebAppPool -Name $pool
            while ((Get-WebAppPoolState -Name $pool).Value -ne "Stopped") {
                Write-Host "Waiting Stop the AppPool:$pool" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            Get-WebAppPoolState -Name $pool
            Write-Host "Start Expand files on the server:$path" -ForegroundColor Yellow
            Remove-Item -Path $path -Recurse -Force
            Expand-Archive -Path $file -DestinationPath $path -Force
            Write-Host "Restart the AppPool:$pool" -ForegroundColor Yellow
            Start-WebAppPool -Name $pool
        } -ArgumentList $ApplicationPool, $RemoteZipPath, $RemoteDestinationPath

        Write-Host "Disconnected from server" -ForegroundColor Yellow
        Disconnect-PSSession -Session $Session
    }
    else {
        Write-Host "Failed connected to the server" -ForegroundColor Red
    }
    Remove-Item -Path $ZIPFilePath
    Write-Host "Deploy Completed" -ForegroundColor Green
}