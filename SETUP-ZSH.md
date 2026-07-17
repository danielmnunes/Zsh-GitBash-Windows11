# Zsh + Oh My Zsh no Git Bash (Windows, sem WSL)

Isto monta tudo do seu roteiro (Opção 2) e resolve **o passo que faltava**: fazer o
zsh de fato **iniciar**. O bloco do `etc/profile` que você tinha estava corrompido —
não precisa dele. Existem dois jeitos limpos de dar o start, ambos incluídos abaixo.

## Arquivos entregues

- `install-zsh-gitbash.ps1` — instalador automático (faz os passos 2, 3, 5, 6, 7 e o start).
- `zshrc.template` — referência do `~/.zshrc` (com `zsh-autosuggestions` e `zsh-syntax-highlighting` já no `plugins=(...)`).
- `SETUP-ZSH.md` — este guia (passo a passo manual + Windows Terminal + verificação).

---

## Caminho recomendado: rodar o instalador

1. Abra o **PowerShell como Administrador** (precisa disso só para escrever em `C:\Program Files\Git`).
2. Libere a execução na sessão atual:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass -Force
   ```
3. Rode:
   ```powershell
   cd "C:\Users\danie\dev\sandbox\git-windows"
   .\install-zsh-gitbash.ps1
   ```
4. Abra um **novo Git Bash**. Ele já entra no zsh, com Oh My Zsh e as sugestões em cinza.

O script baixa o pacote zsh mais recente do MSYS2, copia `etc\` e `usr\` para dentro do
Git (merge, sem sobrescrever nada seu), instala o Oh My Zsh, clona o
`zsh-autosuggestions`, escreve o `~/.zshrc` e configura o start.

---

## O passo que resta (o que faz de fato funcionar)

Depois que o zsh está instalado, ele ainda precisa ser **lançado**. Escolha um:

### Opção A — Git Bash abre direto no zsh (mais simples, sem admin, sem mexer em Program Files)

Adicione no fim de `~/.bashrc`:

```bash
# >>> launch zsh from git bash >>>
if [ -t 1 ] && command -v zsh >/dev/null 2>&1; then
  exec zsh
fi
# <<< launch zsh from git bash <<<
```

Todo Git Bash (e qualquer coisa que use `git-bash.exe`) passa a cair no zsh.
**O instalador já faz isso.** É o substituto correto do passo 3 (editar o `profile`),
sem precisar de administrador nem alterar arquivos de sistema do Git.

### Opção B — Profile dedicado no Windows Terminal

Se você prefere um perfil separado no Windows Terminal apontando direto para o zsh
(equivale ao passo 4 do roteiro), adicione em **Settings → Open JSON file**, dentro de
`profiles.list`:

```json
{
  "name": "Zsh (Git)",
  "commandline": "%PROGRAMFILES%/Git/usr/bin/zsh.exe -il",
  "icon": "%PROGRAMFILES%/Git/mingw64/share/git/git-for-windows.ico",
  "startingDirectory": "%USERPROFILE%",
  "colorScheme": "Campbell"
}
```

`-i` = interativo, `-l` = login (carrega os arquivos de init do zsh). Se o Git estiver
em outro lugar (ex.: `%LOCALAPPDATA%\Programs\Git`), ajuste o caminho.

> As opções A e B não conflitam. Com a A, qualquer terminal que abrir Git Bash já vira zsh.

---

## Passo a passo manual (se não quiser o script)

1. **Git for Windows** já instalado (`git --version`).
2. **Baixar o zsh do MSYS2**: pegue `zsh-<versão>-x86_64.pkg.tar.zst` em
   <https://repo.msys2.org/msys/x86_64/> (o mais recente, **não** o `zsh-doc`).
3. **Extrair** com 7-Zip/PeaZip (ou `tar -xf arquivo.pkg.tar.zst`). Vão aparecer as
   pastas `etc\` e `usr\`.
4. **Copiar** `etc\` e `usr\` para dentro de `C:\Program Files\Git`, mesclando quando
   perguntar. Nada seu é sobrescrito.
5. No Git Bash: `zsh --version` para confirmar. No primeiro `zsh`, o assistente pergunta
   sobre history/completion — pode escolher `2` (populate) e seguir, ou `0` para um
   `.zshrc` vazio (o Oh My Zsh vai reescrever de qualquer forma).
6. **Oh My Zsh**:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```
7. **Plugins oficiais** zsh-autosuggestions e zsh-syntax-highlighting:
   ```bash
   git clone https://github.com/zsh-users/zsh-autosuggestions.git \
     "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
     "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
   ```
8. No `~/.zshrc`, deixe: `plugins=(git zsh-autosuggestions zsh-syntax-highlighting)`
   (veja `zshrc.template`). O `zsh-syntax-highlighting` **precisa ser o último** da lista.
9. Faça o start pela **Opção A** ou **B** acima.

---

## Verificação

Abra um novo terminal e confira:

```bash
echo $ZSH_VERSION                 # deve imprimir a versão (ex.: 5.9)
echo $ZSH_CUSTOM                  # caminho dos plugins customizados
ls "$ZSH_CUSTOM/plugins/zsh-autosuggestions"       # arquivos do plugin
ls "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"   # arquivos do plugin
```

Digite um comando que você já usou antes — deve aparecer a sugestão em **cinza**
(`→` ou `End` aceita a sugestão inteira). E, enquanto você digita, um comando válido
fica **verde** e um inexistente fica **vermelho** — isso é o `zsh-syntax-highlighting`.

> **Já tinha rodado o instalador antes?** Rode de novo (ele é idempotente) **ou** só clone o
> plugin e ajuste o `plugins=(...)` para terminar em `zsh-syntax-highlighting`:
> ```bash
> git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
>   "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
> ```

---

## Observação honesta (custo x benefício)

Como você mesmo notou: só para ter a **sugestão de comandos anteriores em cinza**, o
`ble.sh` no próprio Bash resolve sem trocar de shell nem mexer em arquivos de sistema.
Vale ir por este caminho do Zsh quando você quer o **ecossistema** do Oh My Zsh
(temas como Powerlevel10k, dezenas de plugins, a experiência idêntica ao Mac/Linux),
não só a sugestão em cinza.
