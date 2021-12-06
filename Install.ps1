$installpath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
New-Item -ItemType Directory -Force -Path $installpath
Remove-Item "$installpath\ZEQP-PSDeploy" -Recurse -Force -EA Ignore
Copy-Item .\ZEQP-PSDeploy "$installpath\ZEQP-PSDeploy" -Recurse -Force -EA Continue
Import-Module -Name ZEQP-PSDeploy -Force