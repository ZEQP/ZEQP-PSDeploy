#$password = ConvertTo-SecureString "MyPlainTextPassword" -AsPlainText -Force
#$Cred = New-Object System.Management.Automation.PSCredential ("username", $password)
#Start-Backup -ComputerName 10.76.1.100 -$Credential $Cred -Path "D:\DataBackup\*.nb3" -RemotePath "D:\Backup\"
function Start-Backup {
	param (
		[string]$ComputerName = "localhost",
		[int]$ComputerPort = 5985,
		[PSCredential]$Credential = "Administrator",
		[string]$Path = ".",
		[string]$RemotePath = "D:\Backup\"
	)
	Write-Host 'Backup Starting' -ForegroundColor Yellow
	$Session = New-PSSession -ComputerName $ComputerName -Port $ComputerPort -Credential $Credential
	$Session
	if ($Session.State -eq "Opened") {
		Write-Host 'Successfully connected to the server' -ForegroundColor Green
		Get-Item -Path $Path | ForEach-Object -Process {
			$fullPath = Join-Path -Path $RemotePath -ChildPath $_.Name
			$remoteFile = (Invoke-Command -Session $Session -ScriptBlock {
					Param($path)
					Get-Item -Path $path
				} -ArgumentList $fullPath)
			if (($null -eq $remoteFile) -or ($remoteFile.Length -ne $_.Length)) {
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