<#
============================================================================
 add-plugins-stack.ps1
 Plugins relevantes pro seu stack (Java / Gradle / GCP) no zsh:
   - gradle              (plugin nativo do Oh My Zsh)
   - gradle-completion   (autocomplete das tasks do Gradle)
   - mvn                 (plugin nativo do Oh My Zsh, Maven)
   - gcloud              (plugin nativo: carrega o completion do Google Cloud SDK)
   - git-extras          (plugin nativo: completions dos comandos git-extras)

 USO (PowerShell normal, NÃO precisa admin):
   Set-ExecutionPolicy -Scope Process Bypass -Force
   .\add-plugins-stack.ps1

 Pré-requisito: install-zsh-gitbash.ps1 já rodado. Idempotente.

 Observações:
   * gcloud: o plugin só ativa o completion se o Google Cloud SDK estiver
     instalado (gcloud no PATH). Instale com: winget install Google.CloudSDK
   * git-extras: os completions ativam quando o git-extras estiver instalado
     (ex.: scoop install git-extras).
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

# --- parte do zsh ----------------------------------------------------------
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

echo "==> Clonando gradle-completion..."
clone_or_update https://github.com/gradle/gradle-completion.git "$ZC/plugins/gradle-completion"

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

echo "==> Ativando plugins no ~/.zshrc..."
add_plugins gradle gradle-completion mvn gcloud git-extras

echo "OK: seção 'Stack Java/Gradle/GCP' aplicada."
'@

$tmp = Join-Path $env:TEMP 'zsh-stack.sh'
[IO.File]::WriteAllText($tmp, ($payload -replace "`r`n","`n"))
& $bash -lc "bash '$($tmp -replace '\\','/')'"

# --- oferecer instalar o Google Cloud SDK se faltar ------------------------
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Warn "gcloud não está no PATH — o completion do GCP só ativa com o SDK instalado."
    Write-Host "    Para instalar:  winget install --id Google.CloudSDK -e" -ForegroundColor Yellow
}

Write-Host ""
Ok "Pronto. Abra um novo Git Bash. Teste: 'gradle <Tab>', 'gcloud <Tab>'."
