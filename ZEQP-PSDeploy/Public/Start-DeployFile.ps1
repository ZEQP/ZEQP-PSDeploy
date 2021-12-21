# Start-DeployFile -ComputerName 127.0.0.1 -Credential Administrator -OutputPath .\bin\Release\ -RemotePath D:\Publish\ -ProjectName AppName
function Start-DeployFile {
	param (
		[string]$ComputerName = "localhost",
		[PSCredential]$Credential = "Administrator",
		[string]$OutputPath = ".\bin\Release\",
		[string]$RemotePath = "D:\Publish\",
		[string]$ProjectName = "DeployFile"
	)
	$outPath = (Resolve-Path $OutputPath).Path
	Write-Host "OutputPath:$outPath" -ForegroundColor Yellow

	Write-Host 'Compress Starting' -ForegroundColor Yellow
	$CurDateString = Get-Date -Format "yyyyMMddHHmmss"
	$ZIPFileName = "$ProjectName$CurDateString.zip"
	$CurPath = (Resolve-Path .).Path
	$ZIPFilePath = "$CurPath\$ZIPFileName"
	Compress-Archive -Path "$outPath\*" -DestinationPath $ZIPFilePath
	Write-Host "Compress Completed $ZIPFilePath" -ForegroundColor Green

	Write-Host 'Deploy Starting' -ForegroundColor Yellow
	$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
	$Session
	if ($Session.State -eq "Opened") {
		Write-Host 'Successfully connected to the server' -ForegroundColor Green

		Write-Host "Start copy files to the server:$RemotePath" -ForegroundColor Yellow
		Copy-Item $ZIPFilePath -Destination $RemotePath -ToSession $Session
		#部署系统
		Invoke-Command -Session $Session -ScriptBlock {
			Param($name, $path, $file)
			$remotePath = (Resolve-Path $path).Path
			$filePath="$remotePath\$file"
			$projectPath="$remotePath\$name\"
			Write-Host "Start Expand files on the server:$projectPath" -ForegroundColor Yellow
			Remove-Item -Path $projectPath -Recurse -Force
			Expand-Archive -Path $filePath -DestinationPath $projectPath -Force

		} -ArgumentList $ProjectName, $RemotePath, $ZIPFileName

		Write-Host 'Disconnected from server' -ForegroundColor Yellow
		Disconnect-PSSession -Session $Session
	}
	else {
		Write-Host 'Failed connected to the server' -ForegroundColor Red
	}
	Remove-Item -Path $ZIPFilePath
	Write-Host 'Deploy Completed' -ForegroundColor Green
}