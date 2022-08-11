#Set-HostFile -IP 127.0.0.1 -Domain localhost
function Set-HostFile {
    param (
        [String]$IP = "127.0.0.1",
        [String]$Domain = "localhost"
    )
    Write-Host 'Update Host Starting' -ForegroundColor Green
    $path = Join-Path -Path $env:SystemRoot -ChildPath "System32\drivers\etc\hosts"
    Write-Host $path -ForegroundColor Green
    #修改host文件只读属性为false
    Set-ItemProperty -Path $path -Name IsReadOnly -Value $false
    $index = 0
    $domainIndex = -1
    $content = Get-Content -Path $path
    [string[]]$separator=" ","`t"
    foreach ($line in $content) {
        if (!($line.Trim().StartsWith("#") -or [string]::IsNullOrEmpty($line.Trim()))) {
            $info = $line.Split($separator, [System.StringSplitOptions]::RemoveEmptyEntries)
            Write-Debug $line
            if ($info[1] -eq $Domain) {
                $domainIndex = $index
            }
        }
        $index = $index + 1
    }
    Write-Host "Has Domain $Domain : $domainIndex"  -ForegroundColor Yellow
    if ($domainIndex -eq -1) {
        $newline = [System.Environment]::NewLine
        Add-Content -Path $path -Value "$newline$IP $Domain"
    }else {
        $content[$domainIndex] = "$IP $Domain"
        Set-Content -Path $path -Value $content
    }
    Get-Content -Path $path
    #修改host文件只读属性为true
    Set-ItemProperty -Path $path -Name IsReadOnly -Value $true
    Write-Host 'Update Host Completed' -ForegroundColor Green
}