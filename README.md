# PowerShell Deploy

自动部署

## 安装

把此代码下载或通过git clone到本地
然后在目录下面以管理员方式运行Install.ps1

```powershell
git clone https://github.com/ZEQP/ZEQP-PSDeploy.git
cd .\ZEQP-PSDeploy
.\Install.ps1
```

## 自动编译然后发布到指定服务器IIS站点

```powershell
#前端
Start-Deploy -ComputerName 127.0.0.1 -WebSiteName DefaultWebSite -WebSitePort 8051 -ScriptBlock { npm run build:live } -OutputPath .\dist\

#后端 dotnet core
#开发环境
Start-Deploy -ComputerName 127.0.0.1 -WebSiteName DefaultWebSite -WebSitePort 8053 -ScriptBlock { 
    param($o) dotnet publish -o $o -c "Debug" --no-self-contained -v m --nologo /p:EnvironmentName=Development 
} -OutputPath .\bin\publish\
#生产环境
Start-Deploy -ComputerName 127.0.0.1 -WebSiteName DefaultWebSite -WebSitePort 8053 -ScriptBlock { 
    param($o) dotnet publish -o $o -c "Release" --no-self-contained -v m --nologo /p:EnvironmentName=Production 
} -OutputPath .\bin\publish\

#后端 dotnet framework
Start-Deploy -ComputerName 127.0.0.1 -WebSiteName DefaultWebSite -WebSitePort 8053 -ScriptBlock {
    $MSBuildExe="${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    &$MSBuildExe -p:Configuration=Release
} -OutputPath .\bin\Release\
```

## 自动编译然后发布为服务

```powershell
#后端 dotnet core
#开发环境
Start-DeploySvc -ComputerName 127.0.0.1 -ServiceName DefaultService -BinaryPathName "DefaultService.exe --environment Development" -ServicePort 8053 -ScriptBlock { 
    param($o) dotnet publish -o $o -c "Debug" --no-self-contained -v m --nologo /p:EnvironmentName=Development
} -OutputPath .\bin\publish\

#生产环境
Start-DeploySvc -ComputerName 127.0.0.1 -ServiceName DefaultService -BinaryPathName "DefaultService.exe --environment Production" -ServicePort 8053 -ScriptBlock { 
    param($o) dotnet publish -o $o -c "Release" --no-self-contained -v m --nologo /p:EnvironmentName=Production
} -OutputPath .\bin\publish\

#后端 dotnet framework
Start-DeploySvc -ComputerName 127.0.0.1 -ServiceName DefaultService -BinaryPathName DefaultService.exe -ServicePort 8054 -ScriptBlock {
    $MSBuildExe="${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    &$MSBuildExe -p:Configuration=Release
} -OutputPath .\bin\Release\
```

## 只更新文件

```powershell
#把本地OutputPath目录的所有文件
#打包为ProjectNameyyyyMMddHHmmss.zip
#复制到目标服务器RemotePath
#然后解压到目标服务器RemotePath\ProjectName目录下面
Start-DeployFile -ComputerName 127.0.0.1 -Credential Administrator -OutputPath .\bin\Release\ -RemotePath D:\Publish\ -ProjectName AppName
```

## 备份文件

```powershell
#把本地D:\DataBackup\*.nb3文件备份到服务器D:\Backup\目录
Start-Backup -ComputerName 10.76.1.100 -Path "D:\DataBackup\*.nb3" -RemotePath "D:\Backup\"

#因为我们一般是通过计划任务自动运行的,所以我们一般会把帐号密码一起放到任务里面就可以向下面这样写
$password = ConvertTo-SecureString "MyPlainTextPassword" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ("username", $password)
Start-Backup -ComputerName 10.76.1.100 -$Credential $Cred -Path "D:\DataBackup\*.nb3" -RemotePath "D:\Backup\"
```

## 其它部署命令

```powershell
#部署通过Posh-ACME申请的证书至服务器
#https://github.com/rmbolger/Posh-ACME
Start-DeployCert -ComputerName 182.43.196.20 -Subject *.giantliu.cn
```

## 前置条件

连接到指定的服务器，是运用了PowerShell的运程管理功能

此功能是需要在对应服务器开启PowerShell运程管理功能
(Win服务里面有个WinRM的服务 显示名称：Windows Remote Management (WS-Management))

服务器打开防火墙入站规则“WinRM远程管理”,TCP端口为5985

```powershell
#在远程服务器运行此命令（用PowerShell以管理员方式运行）
Enable-PSRemoting
#信任指定host。*为所有  （本机和服务器都运行）
Set-Item wsman:localhost\Client\TrustedHosts -value *
```

## 参考文档

[介绍如何对 PowerShell 中的远程操作进行故障排除](https://docs.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting?view=powershell-7.2)
