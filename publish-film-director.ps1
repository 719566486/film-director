$ErrorActionPreference = 'Continue'
$env:GH_HOST = 'github.com'
$env:GH_PAGER = 'cat'
Remove-Item Env:GH_PROMPT_DISABLED -ErrorAction SilentlyContinue

function Read-GitHub {
    param([string]$Endpoint, [string]$Filter, [int[]]$Missing = @())
    $result = & $gh api $Endpoint --jq $Filter 2>&1
    $exitCode = $LASTEXITCODE
    $message = ($result -join [Environment]::NewLine).Trim()
    if ($exitCode -eq 0) { return $message }
    foreach ($status in $Missing) {
        if ($message -match "\bHTTP $status\b") { return $null }
    }
    throw "GitHub query failed for $Endpoint. $message"
}

function Publish-FilmDirector {
    $gh = (Get-Command gh.exe -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1).Source
    if (-not $gh) {
        $installed = Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'
        if (Test-Path -LiteralPath $installed) { $gh = $installed }
    }
    if (-not $gh) { throw 'GitHub CLI was not found. Install GitHub.cli, then run this script again.' }

    $repo = $PSScriptRoot
    $skill = '.agents\skills\film-director\SKILL.md'
    if (-not (Test-Path -LiteralPath (Join-Path $repo $skill))) {
        $repo = Join-Path $PSScriptRoot 'film-director'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repo $skill))) {
        throw 'The local film-director repository could not be located.'
    }
    $localHead = & git -C $repo rev-parse --verify refs/heads/main
    if ($LASTEXITCODE -ne 0) { throw 'The local main branch could not be read.' }

    & $gh auth status --hostname github.com 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        & $gh auth login --hostname github.com --git-protocol https --web
        if ($LASTEXITCODE -ne 0) { throw 'GitHub authorization did not complete.' }
    }
    $owner = Read-GitHub 'user' '.login'
    if ($owner -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*$') { throw 'GitHub did not return a valid account name.' }
    $destination = "$owner/film-director"
    $url = "https://github.com/$destination"
    $endpoint = "repos/$destination"
    $marker = (& git -C $repo rev-parse --path-format=absolute --git-path "film-director-created-for-$owner")
    if ($LASTEXITCODE -ne 0) { throw 'The local publishing state could not be located.' }
    $createdHere = (Test-Path -LiteralPath $marker) -and
        ((Get-Content -Raw -LiteralPath $marker -ErrorAction Stop).Trim() -eq $destination)

    Write-Host "Checking $url"
    $visibility = Read-GitHub $endpoint '.visibility' @(404)
    if ($null -eq $visibility) {
        if ($createdHere) {
            throw "GitHub could not find the previously created repository at $url. Check that this account still has access."
        }
        & $gh repo create $destination --public --description 'AI film directing skill for cinematography, animation, sound, editing and Kling storyboards.'
        if ($LASTEXITCODE -ne 0) { throw "GitHub could not create $url." }
        Set-Content -LiteralPath $marker -Value $destination -Encoding Ascii -ErrorAction Stop
        $createdHere = $true
        $visibility = Read-GitHub $endpoint '.visibility'
    }
    if ($visibility -ne 'public') {
        throw "The existing repository at $url is not public. Review its visibility on GitHub before publishing."
    }

    $remoteHead = Read-GitHub "$endpoint/branches/main" '.commit.sha' @(404,409)
    if ($remoteHead -ne $localHead) {
        if (-not $createdHere) { throw "Review the existing repository at $url before pushing into it." }
        if (-not $remoteHead) {
            $branchCount = Read-GitHub "$endpoint/branches" 'length'
            if ($branchCount -ne '0') { throw "The existing repository at $url has branches but no main. Review it on GitHub first." }
        }
        Write-Host "Pushing main to $url"
        $ghShellPath = $gh.Replace('\', '/').Replace("'", "'\''")
        $credentialHelper = "credential.helper=!'$ghShellPath' auth git-credential"
        & git -C $repo -c 'credential.helper=' -c $credentialHelper push "$url.git" 'refs/heads/main:refs/heads/main'
        if ($LASTEXITCODE -ne 0) { throw 'The push did not complete. See the Git error above.' }
        $remoteHead = Read-GitHub "$endpoint/branches/main" '.commit.sha'
        $visibility = Read-GitHub $endpoint '.visibility'
    }
    if ($remoteHead -ne $localHead -or $visibility -ne 'public') {
        throw 'GitHub did not confirm the expected public main branch.'
    }

    Write-Host "VERIFIED PUBLIC REPOSITORY: $url"
    Write-Host "Commit: $localHead"
}

try {
    Publish-FilmDirector
    exit 0
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host 'Publication was not verified.'
    exit 1
}
