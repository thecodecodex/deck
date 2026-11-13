# Instalador do Deck para Windows: baixa o executável da última release pública (sem Go, Node nem login),
# confere o SHA-256, coloca o Deck no menu Iniciar e abre o assistente `deck setup all`.
#
# Uso (PowerShell):
#   irm https://raw.githubusercontent.com/thecodecodex/deck/main/install.ps1 | iex
#
# Variáveis: DECK_INSTALL_DIR (padrão ~\.deck\bin), DECK_NO_SETUP=1 (não abre o assistente),
# DECK_NO_APP=1 (não cria o atalho no menu Iniciar), DECK_NO_OPEN=1 (não abre a página de instalação).
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$repo = "thecodecodex/deck"
$destDir = if ($env:DECK_INSTALL_DIR) { $env:DECK_INSTALL_DIR } else { Join-Path $HOME ".deck\bin" }
$asset = "deck-windows-amd64.exe"

# a release mais nova do canal estável (v<ANO.MES.BUILD>); sem nenhuma, a mais nova do canal dev (-dev)
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases?per_page=30" -Headers @{ Accept = "application/vnd.github+json" }
$tags = @($releases | Where-Object { -not $_.draft } | ForEach-Object { $_.tag_name })
$tag = $tags | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' } | Select-Object -First 1
if (-not $tag) { $tag = $tags | Where-Object { $_ -match '^v\d+\.\d+\.\d+-dev$' } | Select-Object -First 1 }
if (-not $tag) { throw "Nenhuma release do Deck encontrada em github.com/$repo." }

$base = "https://github.com/$repo/releases/download/$tag"
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("deck-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    Write-Host "Baixando $asset ($tag) de github.com/$repo..."
    Invoke-WebRequest -Uri "$base/$asset" -OutFile (Join-Path $tmp $asset)
    Invoke-WebRequest -Uri "$base/checksums.txt" -OutFile (Join-Path $tmp "checksums.txt")

    $linha = Get-Content (Join-Path $tmp "checksums.txt") | Where-Object { ($_ -split '\s+')[1] -eq $asset } | Select-Object -First 1
    $esperado = if ($linha) { ($linha -split '\s+')[0].ToLower() } else { "" }
    $obtido = (Get-FileHash -Algorithm SHA256 (Join-Path $tmp $asset)).Hash.ToLower()
    if (-not $esperado -or $esperado -ne $obtido) {
        throw "SHA-256 de $asset não confere com o checksums.txt da release: download corrompido ou adulterado."
    }

    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $exe = Join-Path $destDir "deck.exe"
    Move-Item -Force (Join-Path $tmp $asset) $exe
    Unblock-File $exe
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
Write-Host "deck instalado em $exe ($(& $exe --version))."

# o Deck no menu Iniciar (abre o painel)
if ($env:DECK_NO_APP -ne "1") {
    & $exe app instalar --yes
    if ($LASTEXITCODE -ne 0) { Write-Warning "Não foi possível instalar o programa do Deck (rode 'deck app instalar' depois)." }
    # página de fim da instalação, numa aba do navegador padrão (ou Chrome/Edge/Brave se o padrão não for Chromium) (onde aparece o "Instalar" da janela do Deck)
    if ($env:DECK_NO_OPEN -ne "1") {
        & $exe app abrir --pagina /instalar --aba *> $null
        if ($LASTEXITCODE -eq 0) { Write-Host "Abri o Deck no navegador: clique em ""Instalar"" na página para ele ganhar janela e ícone próprios." }
    }
}
$env:DECK_INSTALADOR = "1"
Write-Host ""

if ($env:DECK_NO_SETUP -eq "1") { return }
& $exe setup all @args
