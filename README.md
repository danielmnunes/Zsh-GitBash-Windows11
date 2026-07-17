# Zsh + Oh My Zsh no Git Bash - Windows 11

Scripts para ter um **Zsh de verdade** — com Oh My Zsh, plugins e ferramentas
modernas de linha de comando — rodando **nativamente no Windows**, dentro do
Git Bash, sem precisar de WSL. Usa o runtime MSYS2 que já vem com o
[Git for Windows](https://git-scm.com/download/win).

Ideal pra quem já viu o setup de Zsh no Mac/Linux e quer o mesmo resultado no
Windows: sugestões de comando em cinza, sintaxe colorida, busca fuzzy no
histórico, `cd` inteligente e completions pro seu stack (Java / Gradle / GCP).

## Pré-requisitos

- Windows 10/11
- [Git for Windows](https://git-scm.com/download/win) instalado
- [winget](https://learn.microsoft.com/windows/package-manager/winget/) (já vem no Windows 11 e no 10 atualizado) — usado pelos scripts de ferramentas
- PowerShell

## Instalação rápida

Clone (ou baixe) este repositório e, no PowerShell, rode os scripts nesta ordem.
Só o **primeiro** precisa ser executado como **Administrador** (ele escreve em
`C:\Program Files\Git`); os demais rodam como usuário normal.

```powershell
# 1) base: instala o Zsh + Oh My Zsh + zsh-autosuggestions + zsh-syntax-highlighting
#    (PowerShell COMO ADMINISTRADOR)
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install-zsh-gitbash.ps1

# 2) extras (PowerShell normal) — rode os que quiser, em qualquer ordem:
.\add-plugins-alto-valor.ps1   # fzf, zoxide, completions, history-search...
.\add-plugins-stack.ps1        # gradle, mvn, gcloud, git-extras
.\add-cli-tools.ps1            # bat, eza, ripgrep, fd, git-delta
```

Depois, abra um **Git Bash novo** — ele já entra no Zsh com tudo configurado.

Todos os scripts são **idempotentes** (pode rodar de novo sem duplicar nada) e
fazem **backup do `~/.zshrc`** antes de qualquer alteração.

## O que tem nesta pasta

| Arquivo | O que faz |
|---|---|
| `install-zsh-gitbash.ps1` | Instalação base. Baixa o pacote `zsh` mais recente do MSYS2, copia para dentro do Git, instala o Oh My Zsh, clona `zsh-autosuggestions` e `zsh-syntax-highlighting`, escreve o `~/.zshrc` e faz o Git Bash abrir direto no Zsh. |
| `add-plugins-alto-valor.ps1` | fzf + fzf-tab (busca fuzzy, `Ctrl+R`), zoxide (`z pasta`), zsh-completions, zsh-history-substring-search, `colored-man-pages`, `extract`. |
| `add-plugins-stack.ps1` | Completions pro stack Java/Gradle/GCP: `gradle`, `gradle-completion`, `mvn`, `gcloud`, `git-extras`. |
| `add-cli-tools.ps1` | Ferramentas modernas via winget: `bat` (cat), `eza` (ls), `ripgrep`, `fd`, `git-delta`, com aliases e o delta já configurado no git. |
| `zshrc.template` | Referência do `~/.zshrc` gerado pela instalação base. |
| `SETUP-ZSH.md` | Guia detalhado: passo a passo manual, configuração do Windows Terminal, verificação e solução de problemas. |
| `README.md` | Este arquivo. |

## Detalhe importante: ordem dos plugins

O `zsh-syntax-highlighting` **precisa ser sempre o último** do array
`plugins=(...)` no `~/.zshrc`, porque ele envolve o editor de linha do Zsh e tem
que carregar depois de todos os outros. Os scripts já cuidam disso
automaticamente ao editar o array — se você mexer no `~/.zshrc` na mão, mantenha
essa regra.

## Dependências externas (não instaladas automaticamente)

- **gcloud** — o completion do GCP só ativa com o Google Cloud SDK instalado:
  `winget install --id Google.CloudSDK -e`
- **git-extras** — os completions ativam quando o binário existir:
  `scoop install git-extras`

## Verificação

Num Git Bash novo:

```bash
echo $ZSH_VERSION      # versão do zsh (ex.: 5.9)
```

- Comando já usado antes aparece sugerido em **cinza** (`→` / `End` aceita) — `zsh-autosuggestions`.
- Enquanto digita, comando válido fica **verde** e inexistente **vermelho** — `zsh-syntax-highlighting`.
- `Ctrl+R` abre a busca fuzzy no histórico — `fzf`.
- `z parte-do-caminho` pula pra pastas usadas com frequência — `zoxide`.


## Créditos

- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [zsh-users](https://github.com/zsh-users) (autosuggestions, syntax-highlighting, completions, history-substring-search)
- [fzf](https://github.com/junegunn/fzf) · [fzf-tab](https://github.com/Aloxaf/fzf-tab) · [zoxide](https://github.com/ajeetdsouza/zoxide)
- [bat](https://github.com/sharkdp/bat) · [eza](https://github.com/eza-community/eza) · [ripgrep](https://github.com/BurntSushi/ripgrep) · [fd](https://github.com/sharkdp/fd) · [delta](https://github.com/dandavison/delta)
- Método baseado no guia de [Dominik Rys](https://dominikrys.com/posts/zsh-in-git-bash-on-windows/)
