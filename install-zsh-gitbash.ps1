<#
============================================================================
 install-zsh-gitbash.ps1
 Instala Zsh + Oh My Zsh + zsh-autosuggestions dentro do Git for Windows.
 Resultado: um Zsh de verdade rodando nativamente no Windows (sem WSL),
 usando o runtime MSYS2 que ja vem com o Git for Windows.

 COMO USAR:
   1. Abra o PowerShell COMO ADMINISTRADOR
   2. Se necessario libere a execucao do script na sessao atual:
        Set-ExecutionPolicy -Scope Process Bypass -Force
   3. Rode:
        .\install-zsh-gitbash.ps1

 O que ele faz (equivale aos passos 2, 3, 5, 6, 7 do seu roteiro):
   - Baixa o pacote zsh mais recente do MSYS2
   - Extrai e copia etc/ e usr/ para dentro do Git (sem sobrescrever nada seu)
   - Instala o Oh My Zsh
   - Clona o plugin oficial zsh-autosuggestions
   - Escreve um ~/.zshrc com o plugin ativado
   - Faz o Git Bash abrir direto no zsh (o "passo que resta" - via ~/.bashrc)
============================================================================
#>

$ErrorActionPreference = 'Stop'

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "OK  $m"  -ForegroundColor Green }
function Warn($m) { Write-Host "!!  $m"  -ForegroundColor Yellow }

# --- 0. Precisa de admin (vamos escrever em C:\Program Files\Git) ----------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    throw "Rode este script em um PowerShell ABERTO COMO ADMINISTRADOR."
}

# --- 1. Localiza a instalacao do Git for Windows ---------------------------
Info "Localizando o Git for Windows..."
$gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
$gitRoot = $null
if ($gitExe) {
    # .../Git/cmd/git.exe  ->  .../Git
    $gitRoot = Split-Path (Split-Path $gitExe -Parent) -Parent
}
foreach ($cand in @($gitRoot, "$env:ProgramFiles\Git", "${env:ProgramFiles(x86)}\Git", "$env:LOCALAPPDATA\Programs\Git")) {
    if ($cand -and (Test-Path (Join-Path $cand 'usr\bin\bash.exe'))) { $gitRoot = $cand; break }
}
if (-not $gitRoot -or -not (Test-Path (Join-Path $gitRoot 'usr\bin\bash.exe'))) {
    throw "Nao encontrei o Git for Windows. Instale em https://git-scm.com/download/win e rode de novo."
}
$bash = Join-Path $gitRoot 'usr\bin\bash.exe'
Ok "Git encontrado em: $gitRoot"

# --- 2. Descobre e baixa o pacote zsh mais recente do MSYS2 ----------------
Info "Procurando o pacote zsh mais recente no repositorio MSYS2..."
$repo = 'https://repo.msys2.org/msys/x86_64/'
$listing = (Invoke-WebRequest -Uri $repo -UseBasicParsing).Content
# pega zsh-<versao>-x86_64.pkg.tar.zst (ignora zsh-doc)
$pkgs = [regex]::Matches($listing, 'href="(zsh-\d[^"]*-x86_64\.pkg\.tar\.zst)"') |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -notlike 'zsh-doc*' } |
        Sort-Object -Descending
if (-not $pkgs) { throw "Nao consegui encontrar o pacote zsh em $repo" }
$pkgName = $pkgs[0]
$pkgUrl  = $repo + $pkgName
Ok "Pacote: $pkgName"

$work = Join-Path $env:TEMP 'zsh-gitbash-setup'
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null
$pkgFile = Join-Path $work $pkgName

Info "Baixando..."
Invoke-WebRequest -Uri $pkgUrl -OutFile $pkgFile -UseBasicParsing
Ok "Baixado em $pkgFile"

# --- 3. Extrai o .zst -------------------------------------------------------
Info "Extraindo o pacote (.tar.zst)..."
$extractDir = Join-Path $work 'extracted'
New-Item -ItemType Directory -Path $extractDir | Out-Null
# tar do Windows 10/11 (bsdtar) le zstd nativamente:
& tar.exe -xf $pkgFile -C $extractDir
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao extrair com tar. Extraia $pkgName manualmente (7-Zip/PeaZip) e copie etc\ e usr\ para $gitRoot"
}
Ok "Extraido"

# --- 4. Copia etc/ e usr/ para dentro do Git (merge, sem sobrescrever) ------
Info "Copiando etc\ e usr\ para $gitRoot (merge)..."
foreach ($sub in @('etc', 'usr')) {
    $src = Join-Path $extractDir $sub
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $gitRoot -Recurse -Force
    }
}
if (-not (Test-Path (Join-Path $gitRoot 'usr\bin\zsh.exe'))) {
    throw "zsh.exe nao apareceu em $gitRoot\usr\bin. Verifique a extracao."
}
Ok "zsh.exe instalado em $gitRoot\usr\bin"

# --- 5. Confere versao do zsh ----------------------------------------------
Info "Verificando o zsh..."
$ver = & $bash -lc 'zsh --version'
Ok "$ver"

# --- 6. Instala Oh My Zsh (nao interativo) ---------------------------------
$homeCheck = & $bash -lc 'test -d "$HOME/.oh-my-zsh" && echo yes || echo no'
if ($homeCheck.Trim() -eq 'yes') {
    Warn "Oh My Zsh ja existe em ~/.oh-my-zsh, pulando instalacao."
} else {
    Info "Instalando Oh My Zsh..."
    # --unattended: nao troca o shell padrao nem abre zsh no fim
    & $bash -lc 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    Ok "Oh My Zsh instalado"
}

# --- 7. Clona os plugins oficiais (autosuggestions + syntax-highlighting) ---
Info "Instalando os plugins zsh-autosuggestions e zsh-syntax-highlighting..."
& $bash -lc '
  ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone_or_update() {
    local url="$1" dir="$2"
    if [ -d "$dir" ]; then
      git -C "$dir" pull --ff-only
    else
      git clone "$url" "$dir"
    fi
  }
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git      "$ZC/plugins/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git  "$ZC/plugins/zsh-syntax-highlighting"
'
Ok "zsh-autosuggestions e zsh-syntax-highlighting prontos"

# --- 8. Escreve ~/.zshrc (com o plugin ativado) ----------------------------
# Escrito DENTRO do bash com heredoc entre aspas -> garante quebras de linha
# LF (nada de \r do Windows, que quebraria o zsh). Faz backup se ja existir.
Info "Escrevendo ~/.zshrc..."
& $bash -lc '
  [ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak.$(date +%s)
  cat > ~/.zshrc <<"EOF"
# ~/.zshrc  -- gerado por install-zsh-gitbash.ps1

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# zsh-autosuggestions   -> sugere comandos anteriores em cinza (Tab/-> aceita)
# zsh-syntax-highlighting -> colore o comando enquanto voce digita
# IMPORTANTE: zsh-syntax-highlighting precisa ser SEMPRE o ultimo da lista.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source "$ZSH/oh-my-zsh.sh"

# Corrige encoding UTF-8 no Windows (acentos, emojis, box-drawing)
chcp.com 65001 > /dev/null 2>&1

# Suas customizacoes daqui pra baixo:
# alias gs="git status"
EOF
'
Ok "~/.zshrc escrito"

# --- 9. PASSO QUE RESTA: fazer o Git Bash abrir direto no zsh ---------------
Info "Configurando o Git Bash para iniciar no zsh (~/.bashrc)..."
& $bash -lc '
  MARK="# >>> launch zsh from git bash >>>"
  if ! grep -qF "$MARK" ~/.bashrc 2>/dev/null; then
    {
      echo ""
      echo "$MARK"
      echo "if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then"
      echo "  exec zsh"
      echo "fi"
      echo "# <<< launch zsh from git bash <<<"
    } >> ~/.bashrc
  fi
'
Ok "Git Bash agora abre no zsh automaticamente"

Write-Host ""
Ok "TUDO PRONTO."
Write-Host ""
Write-Host "Abra um novo Git Bash: ele ja entra no zsh com Oh My Zsh e autosuggestions." -ForegroundColor Green
Write-Host "Opcional (Windows Terminal): veja o profile em SETUP-ZSH.md." -ForegroundColor Green
