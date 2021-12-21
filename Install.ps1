#Requires -Version 5.1
# set the user module path based on edition and platform
if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop') {
    $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
} else {
    if ($IsWindows) {
        $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
    } else {
        $installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) '.local/share/powershell/Modules'
    }
}
# deal with execution policy on Windows
if (('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) -and (Get-ExecutionPolicy) -notin 'Unrestricted','RemoteSigned','Bypass')
{
    Write-Host "Setting user execution policy to RemoteSigned" -ForegroundColor Cyan
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}
# create user-specific modules folder if it doesn't exist
New-Item -ItemType Directory -Force -Path $installpath
Remove-Item "$installpath\ZEQP-PSDeploy" -Recurse -Force -EA Ignore
Copy-Item .\ZEQP-PSDeploy "$installpath\ZEQP-PSDeploy" -Recurse -Force -EA Continue
Import-Module -Name ZEQP-PSDeploy -Force
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module ZEQP-PSDeploy