function Start-PushGit {
    param (
        [string]$FromRemote = "origin",
        [string]$ToRemote = "gitea"
    )
    Write-Host "Start Push Code To $ToRemote" -ForegroundColor Yellow
    $branchs = git branch -l
    $branchs
    $curBranch = "main"
    $branchs | ForEach-Object -Process {
        $branchName = $_.Replace("*", "").Trim()
        if ($_.StartsWith("*")) {
            $curBranch = $branchName
        }
        Write-Host "Start Push $branchName To $ToRemote" -ForegroundColor Yellow
        git checkout $branchName
        git branch -u "$FromRemote/$branchName"
        git pull
        git push -u $ToRemote $branchName
        git push -u $FromRemote $branchName
        Write-Host "Completed Push $branchName To $ToRemote" -ForegroundColor Green
    }
    git checkout $curBranch
    Write-Host "Completed Push Code To $ToRemote" -ForegroundColor Green
}