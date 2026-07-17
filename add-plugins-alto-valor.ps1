<#
============================================================================
 add-plugins-alto-valor.ps1
 Instala os "Plugins de alto valor" no seu zsh (Git Bash / Windows):
   - fzf + fzf-tab   (busca fuzzy no histórico Ctrl+R e na tab-completion)
   - zoxide          (cd inteligente por frequência: `z parte-do-caminho`)
   - zsh-completions (completions extras)
   - zsh-history-substring-search (prefixo + seta pra cima filtra o histórico)
   - colored-man-pages, extract  (plugins nativos do Oh My Zsh)

 USO (PowerShell normal, NÃO precisa admin):
   Set-ExecutionPolicy -Scope Process Bypass -Force
   .\add-plugins-alto-valor.ps1

 Pré-requisito: já ter rodado install-zsh-gitbash.ps1 (zsh + Oh My Zsh + ~/.zshrc).
 Idempotente: pode rodar de novo sem duplicar nada.
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
Install-Win 'junegunn.fzf'     'fzf'
Install-Win 'ajeetdsouza.zoxide' 'zoxide'

# --- parte do zsh (clonar plugins + editar ~/.zshrc) via bash --------------
$payload = @'
#!/usr/bin/env bash
set -e
ZSHRC="$HOME/.zshrc"
ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -f "$ZSHRC" ] || { echo "ERRO: ~/.zshrc não encontrado. Rode install-zsh-gitbash.ps1 primeiro."; exit 1; }
mkdir -p "$ZC/plugins"

clone_or_update(){ local url="$1" dir="$2"
  if [ -d "$dir" ]; then git -C "$dir" pull --ff-only || true
  else git clone --depth=1 "$url" "$dir"; fi; }

echo "==> Clonando plugins customizados..."
clone_or_update https://github.com/zsh-users/zsh-completions.git              "$ZC/plugins/zsh-completions"
clone_or_update https://github.com/zsh-users/zsh-history-substring-search.git "$ZC/plugins/zsh-history-substring-search"
clone_or_update https://github.com/Aloxaf/fzf-tab.git                         "$ZC/plugins/fzf-tab"

add_plugins(){ cp "$ZSHRC" "$ZSHRC.bak.$(date +%s)"
  awk -v add="$*" '
    /^plugins=\(/ && !done {
      line=$0; sub(/^plugins=\(/,"",line); sub(/\).*/,"",line)
      n=split(line,a,/[ \t]+/); order_n=0
      for(i=1;i<=n;i++) if(a[i]!=""){ if(a[i]=="zsh-syntax-highlighting") shl=1; else if(!(a[i] in seen)){seen[a[i]]=1; order[++order_n]=a[i]} }
      na=split(add,b,/[ \t]+/)
      for(i=1;i<=na;i++) if(b[i]!=""){ if(b[i]=="zsh-syntax-highlighting") shl=1; else if(!(b[i] in seen)){seen[b[i]]=1; order[++order_n]=b[i]} }
      out="plugins=("; for(i=1;i<=order_n;i++) out=out (i>1?" ":"") order[i]
      if(shl) out=out (order_n>0?" ":"") "zsh-syntax-highlighting"
      print out ")"; done=1; next
    } {print}
  ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"; }

echo "==> Ativando plugins no ~/.zshrc (zsh-syntax-highlighting continua por último)..."
add_plugins fzf fzf-tab zsh-completions zsh-history-substring-search colored-man-pages extract

append_block(){ local marker="$1"
  grep -qF "# >>> $marker >>>" "$ZSHRC" 2>/dev/null && return 0
  { echo ""; echo "# >>> $marker >>>"; cat; echo "# <<< $marker <<<"; } >> "$ZSHRC"; }

echo "==> Escrevendo integrações (zoxide + history-substring-search)..."
append_block "alto-valor" <<'EOF'
# zoxide: cd inteligente por frequência  ->  use `z parte-do-caminho`
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init zsh)"; fi
# history-substring-search: digite um prefixo e use as setas pra filtrar o histórico
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
EOF

echo "OK: seção 'Plugins de alto valor' aplicada."
'@

$tmp = Join-Path $env:TEMP 'zsh-alto-valor.sh'
[IO.File]::WriteAllText($tmp, ($payload -replace "`r`n","`n"))
& $bash -lc "bash '$($tmp -replace '\\','/')'"

Write-Host ""
Ok "Pronto. Abra um novo Git Bash para carregar os plugins."
Write-Host "Teste: Ctrl+R (fzf), 'z <pasta>' (zoxide), prefixo + seta-cima (history-substring-search)." -ForegroundColor Green
