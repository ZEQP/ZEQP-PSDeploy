function Start-Backup {
	param (
		[string]$ComputerName = "localhost",
		[PSCredential]$Credential = "Administrator",
		[string]$Path = ".",
		[string]$RemotePath = "D:\Backup\"
	)
	Write-Host 'Backup Starting' -ForegroundColor Yellow
	$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
	$Session
	if ($Session.State -eq "Opened") {
		Write-Host 'Successfully connected to the server' -ForegroundColor Green
		Get-Item -Path $Path | ForEach-Object -Process {
			$fullPath = Join-Path -Path $RemotePath -ChildPath $_.Name
			$remoteFile = (Invoke-Command -Session $Session -ScriptBlock {
					Param($path)
					Get-Item -Path $path
				} -ArgumentList $fullPath)
			if ($null -eq $remoteFile || $remoteFile.LastWriteTime -ne $_.LastWriteTime) {
				Write-Host "Copy $_ To $fullPath" -ForegroundColor Green
				Copy-Item -Path $_.FullName -Destination $fullPath -ToSession $Session
			}
			else {
				Write-Host "File Exists $fullPath" -ForegroundColor Yellow
			}
		}
		Write-Host 'Disconnected from server' -ForegroundColor Yellow
		Disconnect-PSSession -Session $Session
	}
	else {
		Write-Host 'Failed connected to the server' -ForegroundColor Red
	}
	Write-Host 'Backup Completed' -ForegroundColor Green
}