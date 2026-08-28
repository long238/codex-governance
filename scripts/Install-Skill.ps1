#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationRoot,

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$skillName = 'bootstrap-project-governance'

function Get-NormalizedFullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
    $fullPath = [System.IO.Path]::GetFullPath($expandedPath)
    $pathRoot = [System.IO.Path]::GetPathRoot($fullPath)

    if ([string]::Equals($fullPath, $pathRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $pathRoot
    }

    return $fullPath.TrimEnd([char[]]@('\', '/'))
}

function Assert-ExpectedSkillTarget {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillsRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedName
    )

    $normalizedRoot = Get-NormalizedFullPath -Path $SkillsRoot
    $normalizedTarget = Get-NormalizedFullPath -Path $TargetPath
    $targetParent = [System.IO.Path]::GetDirectoryName($normalizedTarget)
    $targetLeaf = [System.IO.Path]::GetFileName($normalizedTarget)

    if (-not [string]::Equals($targetParent, $normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to operate outside the intended skills root: $normalizedTarget"
    }

    if (-not [string]::Equals($targetLeaf, $ExpectedName, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to operate on an unexpected skill directory: $normalizedTarget"
    }
}

function Assert-ExpectedBackupTarget {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SkillsRoot,

        [Parameter(Mandatory = $true)]
        [string]$BackupPath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedPrefix
    )

    $normalizedRoot = Get-NormalizedFullPath -Path $SkillsRoot
    $normalizedBackup = Get-NormalizedFullPath -Path $BackupPath
    $backupParent = [System.IO.Path]::GetDirectoryName($normalizedBackup)
    $backupLeaf = [System.IO.Path]::GetFileName($normalizedBackup)

    if (-not [string]::Equals($backupParent, $normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to create a backup outside the intended skills root: $normalizedBackup"
    }

    if (-not $backupLeaf.StartsWith($ExpectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to use an unexpected backup directory: $normalizedBackup"
    }
}

function Get-DirectoryManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalizedRoot = Get-NormalizedFullPath -Path $Path
    $pathPrefix = $normalizedRoot + [System.IO.Path]::DirectorySeparatorChar
    $files = @(Get-ChildItem -LiteralPath $normalizedRoot -File -Recurse | Sort-Object -Property FullName)

    foreach ($file in $files) {
        if (-not $file.FullName.StartsWith($pathPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Found a file outside the manifest root: $($file.FullName)"
        }

        $relativePath = $file.FullName.Substring($pathPrefix.Length).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        "{0}`t{1}" -f $relativePath, $hash
    }
}

function Test-DirectoryContentEqual {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LeftPath,

        [Parameter(Mandatory = $true)]
        [string]$RightPath
    )

    $leftManifest = @(Get-DirectoryManifest -Path $LeftPath)
    $rightManifest = @(Get-DirectoryManifest -Path $RightPath)

    if ($leftManifest.Count -ne $rightManifest.Count) {
        return $false
    }

    for ($index = 0; $index -lt $leftManifest.Count; $index++) {
        if (-not [string]::Equals($leftManifest[$index], $rightManifest[$index], [StringComparison]::Ordinal)) {
            return $false
        }
    }

    return $true
}

$scriptFile = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptFile)) {
    throw 'Unable to resolve the installer script path.'
}

$scriptDirectory = Split-Path -Parent $scriptFile
$repositoryRoot = Get-NormalizedFullPath -Path (Join-Path $scriptDirectory '..')
$sourceSkill = Get-NormalizedFullPath -Path (Join-Path (Join-Path $repositoryRoot 'skills') $skillName)

if (-not (Test-Path -LiteralPath $sourceSkill -PathType Container)) {
    throw "Skill source directory does not exist: $sourceSkill"
}

$requiredSourceFiles = @(
    'SKILL.md',
    'agents\openai.yaml',
    'references\governance-model.md',
    'assets\project-governance\AGENTS.md',
    'assets\project-governance\docs\README.md',
    'assets\project-governance\docs\architecture.md',
    'assets\project-governance\docs\testing.md',
    'assets\project-governance\docs\plans\README.md',
    'assets\project-governance\docs\decisions\README.md',
    'assets\project-governance\docs\playbook\README.md'
)

foreach ($relativeSourceFile in $requiredSourceFiles) {
    $requiredPath = Join-Path $sourceSkill $relativeSourceFile
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Skill source is incomplete. Missing: $requiredPath"
    }
}

if ($PSBoundParameters.ContainsKey('DestinationRoot')) {
    $destinationCandidate = $DestinationRoot
}
else {
    $destinationCandidate = [Environment]::GetEnvironmentVariable('CODEX_HOME')
    if ([string]::IsNullOrWhiteSpace($destinationCandidate)) {
        $userProfilePath = [Environment]::GetEnvironmentVariable('USERPROFILE')
        if ([string]::IsNullOrWhiteSpace($userProfilePath)) {
            throw 'Neither CODEX_HOME nor USERPROFILE is available.'
        }

        $destinationCandidate = Join-Path $userProfilePath '.codex'
    }
}

$resolvedDestinationRoot = Get-NormalizedFullPath -Path $destinationCandidate
$skillsRoot = Get-NormalizedFullPath -Path (Join-Path $resolvedDestinationRoot 'skills')
$targetSkill = Get-NormalizedFullPath -Path (Join-Path $skillsRoot $skillName)
Assert-ExpectedSkillTarget -SkillsRoot $skillsRoot -TargetPath $targetSkill -ExpectedName $skillName

if (Test-Path -LiteralPath $targetSkill) {
    if (-not (Test-Path -LiteralPath $targetSkill -PathType Container)) {
        throw "The install target exists but is not a directory: $targetSkill"
    }

    if (Test-DirectoryContentEqual -LeftPath $sourceSkill -RightPath $targetSkill) {
        Write-Output "Skill is already installed with identical content: $targetSkill"
        return
    }

    if (-not $Force) {
        throw "The installed skill differs from the repository copy. Re-run with -Force after reviewing the target: $targetSkill"
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $backupName = "{0}.backup.{1}" -f $skillName, $timestamp
    $backupSkill = Get-NormalizedFullPath -Path (Join-Path $skillsRoot $backupName)
    Assert-ExpectedBackupTarget -SkillsRoot $skillsRoot -BackupPath $backupSkill -ExpectedPrefix ($skillName + '.backup.')

    if (Test-Path -LiteralPath $backupSkill) {
        throw "Backup target already exists: $backupSkill"
    }

    $replaceAction = "Back up to '$backupSkill' and replace with '$sourceSkill'"
    if (-not $PSCmdlet.ShouldProcess($targetSkill, $replaceAction)) {
        return
    }

    New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
    Move-Item -LiteralPath $targetSkill -Destination $backupSkill

    try {
        Copy-Item -LiteralPath $sourceSkill -Destination $targetSkill -Recurse
    }
    catch {
        $installError = $_

        if (Test-Path -LiteralPath $targetSkill) {
            Assert-ExpectedSkillTarget -SkillsRoot $skillsRoot -TargetPath $targetSkill -ExpectedName $skillName
            Remove-Item -LiteralPath $targetSkill -Recurse -Force
        }

        if (Test-Path -LiteralPath $backupSkill) {
            Assert-ExpectedBackupTarget -SkillsRoot $skillsRoot -BackupPath $backupSkill -ExpectedPrefix ($skillName + '.backup.')
            Move-Item -LiteralPath $backupSkill -Destination $targetSkill
        }

        throw $installError
    }

    Write-Output "Backed up previous skill to: $backupSkill"
    Write-Output "Installed skill to: $targetSkill"
    return
}

$installAction = "Install from '$sourceSkill'"
if (-not $PSCmdlet.ShouldProcess($targetSkill, $installAction)) {
    return
}

New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
Copy-Item -LiteralPath $sourceSkill -Destination $targetSkill -Recurse
Write-Output "Installed skill to: $targetSkill"
