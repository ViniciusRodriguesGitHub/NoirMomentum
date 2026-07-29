#Requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$projectRoot = $PSScriptRoot
$repositoryName = 'ViniciusRodriguesGitHub/NoirMomentum'
$repositoryUrl = 'https://github.com/ViniciusRodriguesGitHub/NoirMomentum.git'
$privateEmail = '83930628+ViniciusRodriguesGitHub@users.noreply.github.com'
$versionTag = 'v0.2.0'


function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}


function Require-Command {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$InstallHint
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "$Name nao foi encontrado. $InstallHint"
    }
    return $command
}


function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)

    & git -C $projectRoot @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "O comando Git falhou: git $($Arguments -join ' ')"
    }
}


if (-not (Test-Path (Join-Path $projectRoot 'project.godot'))) {
    throw 'Execute este arquivo dentro da pasta NoirMomentum.'
}

Write-Step 'Verificando Git e GitHub'
Require-Command -Name 'git' -InstallHint 'Instale o Git antes de continuar.' |
    Out-Null
Require-Command -Name 'gh' -InstallHint (
    'Execute: winget install --id GitHub.cli --exact'
) | Out-Null

& gh auth status
if ($LASTEXITCODE -ne 0) {
    throw 'O GitHub CLI nao esta autenticado. Execute: gh auth login'
}

Write-Step 'Preparando o VS Code'
$codeCommand = Get-Command code -ErrorAction SilentlyContinue

if (-not $codeCommand) {
    $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCommand) {
        throw (
            'VS Code e WinGet nao foram encontrados. ' +
            'Instale o VS Code e execute este configurador novamente.'
        )
    }

    & $wingetCommand.Source install `
        --id Microsoft.VisualStudioCode `
        --exact `
        --source winget `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        throw 'Nao foi possivel instalar o VS Code automaticamente.'
    }

    $codeCandidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    )

    $codePath = $codeCandidates |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1

    if (-not $codePath) {
        throw 'VS Code foi instalado, mas o comando code nao foi localizado.'
    }
} else {
    $codePath = $codeCommand.Source
}

& $codePath --install-extension geequlim.godot-tools --force
if ($LASTEXITCODE -ne 0) {
    throw 'Nao foi possivel instalar a extensao Godot Tools.'
}

Write-Step 'Inicializando o repositorio local'
if (-not (Test-Path (Join-Path $projectRoot '.git'))) {
    & git -C $projectRoot init -b main
    if ($LASTEXITCODE -ne 0) {
        & git -C $projectRoot init
        Invoke-Git -Arguments @('branch', '-M', 'main')
    }
}

Invoke-Git -Arguments @('config', 'user.name', 'Vinicius Rodrigues')
Invoke-Git -Arguments @('config', 'user.email', $privateEmail)

$currentBranch = (& git -C $projectRoot branch --show-current).Trim()
if ($currentBranch -ne 'main') {
    Invoke-Git -Arguments @('branch', '-M', 'main')
}

Write-Step 'Executando o teste do projeto'
$godotConsole = Join-Path $env:LOCALAPPDATA (
    'Programs\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
)

if (Test-Path $godotConsole) {
    & $godotConsole `
        --headless `
        --path $projectRoot `
        --script 'res://tests/smoke_test.gd'

    if ($LASTEXITCODE -ne 0) {
        throw 'O teste do jogo falhou. A publicacao foi interrompida.'
    }
} else {
    throw 'Godot Console nao foi encontrado para validar o projeto.'
}

Write-Step 'Registrando a versao atual'
Invoke-Git -Arguments @('add', '--all')

$pendingChanges = & git -C $projectRoot status --porcelain
$hasCommit = $true
& git -C $projectRoot rev-parse --verify HEAD *> $null
if ($LASTEXITCODE -ne 0) {
    $hasCommit = $false
}

if ($pendingChanges -or -not $hasCommit) {
    Invoke-Git -Arguments @(
        'commit',
        '-m',
        'Prototipo jogavel do Noir Momentum'
    )
} else {
    Write-Host 'Nenhuma alteracao nova para registrar.' -ForegroundColor Yellow
}

Write-Step 'Criando e publicando o repositorio privado'
$originUrl = & git -C $projectRoot remote get-url origin 2>$null

if ($LASTEXITCODE -eq 0 -and $originUrl) {
    if ($originUrl.Trim() -ne $repositoryUrl) {
        throw (
            "A origem atual e '$($originUrl.Trim())'. " +
            "Esperado: '$repositoryUrl'."
        )
    }

    Invoke-Git -Arguments @('push', '-u', 'origin', 'main')
} else {
    & gh repo view $repositoryName *> $null
    if ($LASTEXITCODE -eq 0) {
        Invoke-Git -Arguments @('remote', 'add', 'origin', $repositoryUrl)
        Invoke-Git -Arguments @('push', '-u', 'origin', 'main')
    } else {
        & gh repo create $repositoryName `
            --private `
            --description 'Jogo de plataforma 2D noir desenvolvido em Godot 4.' `
            --source $projectRoot `
            --remote origin `
            --push

        if ($LASTEXITCODE -ne 0) {
            throw 'Nao foi possivel criar e publicar o repositorio.'
        }
    }
}

$existingTag = & git -C $projectRoot tag --list $versionTag
if (-not $existingTag) {
    Invoke-Git -Arguments @(
        'tag',
        '-a',
        $versionTag,
        '-m',
        'Movimentacao, corrida, derrapagem, pulo e deslizada.'
    )
}
Invoke-Git -Arguments @('push', 'origin', $versionTag)

Write-Step 'Abrindo o projeto no VS Code'
& $codePath (Join-Path $projectRoot 'NoirMomentum.code-workspace')

Write-Host "`nCONFIGURACAO CONCLUIDA" -ForegroundColor Green
Write-Host 'Repositorio: https://github.com/ViniciusRodriguesGitHub/NoirMomentum'
Write-Host "Pasta local: $projectRoot"
Write-Host "Versao: $versionTag"
Write-Host 'Atualizacoes futuras: git pull'
