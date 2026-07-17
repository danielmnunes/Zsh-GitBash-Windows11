<#
============================================================================
 add-cli-tools.ps1
 Ferramentas CLI que melhoram o dia a dia (instaladas via winget) + aliases:
   - bat        (cat com sintaxe colorida)   -> alias cat
   - eza        (ls moderno, ícones, git)    -> alias ls/ll/tree
   - ripgrep    (rg: grep rápido)
   - fd         (find amigável)
   - git-delta  (diff/blame bonito no git)   -> configurado no ~/.gitconfig

 USO (PowerShell normal; o winget pode pedir UAC pra alguns pacotes):
   Set-ExecutionPolicy -Scope Process Bypass -Force
   .\add-cli-tools.ps1

 Pré-requisito: install-zsh-gitbash.ps1 já rodado. Idempotente.
============================================================================
#>
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m){   Write-Host "OK  $m"  -ForegroundColor Green }
function Warn($m){ Write-Host "!!  $m"  -ForegroundColor Yellow }

# --- localizar Git Bash ----------------------------------------------------
$gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
$gitRoot = if ($gitExe) { Split-Path (Split-Path $gitExe -Parent) -Parent } else { $null }
foreach ($c in @($gitRoot,"$env:ProgramFiles\Git","${env:ProgramFiles(x86)}\Git","$env:LOCALAPPDATA\Programs\Git")) {
    if ($c -and (Test-Path (Join-Path $c 'usr\bin\bash.exe'))) { $gitRoot = $c; break }
}
if (-not $gitRoot -or -not (Test-Path (Join-Path $gitRoot 'usr\bin\bash.exe'))) {
    throw "Git for Windows não encontrado. Rode install-zsh-gitbash.ps1 antes."
}
$bash = Join-Path $gitRoot 'usr\bin\bash.exe'

# --- instalar binários via winget ------------------------------------------
function Install-Win($id,$name){
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Warn "winget indisponível — instale '$name' manualmente (id winget: $id)."; return
    }
    Info "Instalando $name (winget: $id)..."
    winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { Warn "$name pode já estar instalado (ou winget retornou $LASTEXITCODE) — seguindo." }
}
Install-Win 'sharkdp.bat'          'bat'
Install-Win 'eza-community.eza'    'eza'
Install-Win 'BurntSushi.ripgrep.MSVC' 'ripgrep'
Install-Win 'sharkdp.fd'           'fd'
Install-Win 'dandavison.delta'     'git-delta'

# --- aliases no zsh + configurar delta no git ------------------------------
$payload = @'
#!/usr/bin/env bash
set -e
ZSHRC="$HOME/.zshrc"
[ -f "$ZSHRC" ] || { echo "ERRO: ~/.zshrc não encontrado. Rode install-zsh-gitbash.ps1 primeiro."; exit 1; }

append_block(){ local marker="$1"
  grep -qF "# >>> $marker >>>" "$ZSHRC" 2>/dev/null && return 0
  { echo ""; echo "# >>> $marker >>>"; cat; echo "# <<< $marker <<<"; } >> "$ZSHRC"; }

echo "==> Adicionando aliases (bat/eza) no ~/.zshrc..."
append_block "cli-tools" <<'EOF'
# eza: ls moderno (só ativa se o binário existir)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias tree='eza --tree --level=2 --icons=auto'
fi
# bat: cat colorido
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --style=plain --paging=never'
  export BAT_THEME="ansi"
fi
EOF

# git-delta: pager de diff bonito (config global do git)
if command -v delta >/dev/null 2>&1; then
  echo "==> Configurando git-delta no ~/.gitconfig..."
  git config --global core.pager "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global merge.conflictStyle zdiff3
fi

echo "OK: seção 'Ferramentas CLI' aplicada."
'@

$tmp = Join-Path $env:TEMP 'zsh-cli-tools.sh'
[IO.File]::WriteAllText($tmp, ($payload -replace "`r`n","`n"))
& $bash -lc "bash '$($tmp -replace '\\','/')'"

Write-Host ""
Ok "Pronto. Abra um novo Git Bash (o PATH atualiza no terminal novo)."
Write-Host "Teste: ll, cat arquivo, rg termo, fd nome, git diff (delta)." -ForegroundColor Green
