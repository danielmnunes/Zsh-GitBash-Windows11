# Adicionando `Co-authored-by` automaticamente em todos os commits (Git Bash / Windows)

Este tutorial configura um hook global do Git para adicionar automaticamente um trailer `Co-authored-by` em toda mensagem de commit, sem precisar digitar nada manualmente a cada commit.

## Como funciona

O `Co-authored-by` é um trailer (linha no formato `Chave: valor`) no fim da mensagem de commit. Não é um campo especial nos metadados internos do Git, é só texto na mensagem que plataformas como GitHub e GitLab sabem interpretar para atribuir o commit a mais de um autor.

A automação usa o hook `prepare-commit-msg`, que o Git executa depois de montar a mensagem de commit e antes de abrir o editor (ou de finalizar, se usado `-m`). O hook recebe dois argumentos:

1. o caminho do arquivo temporário com a mensagem de commit
2. a origem da mensagem (`message`, `template`, `merge`, `squash`, `commit`, ou vazio)

## Passo 1: Criar a pasta de hooks globais

No **Git Bash**, use sempre sintaxe Bash (`~`, `$HOME`), nunca sintaxe do PowerShell (`$env:`, `New-Item`) — mesmo que os dois terminais estejam abertos na mesma janela do Windows Terminal, misturar as sintaxes gera configs quebradas.

```bash
mkdir -p ~/.git-hooks
```

## Passo 2: Criar o script do hook

```bash
cat > ~/.git-hooks/prepare-commit-msg << 'EOF'
#!/bin/sh
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

case "$COMMIT_SOURCE" in
  merge|squash|commit)
    exit 0
    ;;
esac

echo "" >> "$COMMIT_MSG_FILE"
echo "Co-authored-by: Claude <noreply@anthropic.com>" >> "$COMMIT_MSG_FILE"
EOF

chmod +x ~/.git-hooks/prepare-commit-msg
```

**Por que o `case` em vez de checar se `COMMIT_SOURCE` está vazio:** `COMMIT_SOURCE` só vem vazio quando o commit é feito sem `-m` (abrindo o editor). No uso mais comum, `git commit -m "mensagem"`, o valor é `message` — uma checagem de "vazio" pula justamente esse caso. O `case` acima cobre `-m`, `template` e o caso vazio (editor), e só pula em `merge`, `squash` e `commit` (amend/cherry-pick), onde a mensagem já vem de outro lugar.

## Passo 3: Apontar o Git para a pasta de hooks globais

```bash
git config --global core.hooksPath ~/.git-hooks
```

Confirme que salvou certo:

```bash
git config --get core.hooksPath
```

Deve retornar algo como `/c/Users/seu-usuario/.git-hooks` (ou `C:/Users/seu-usuario/.git-hooks`). Se aparecer qualquer coisa com `$env:` ou `:USERPROFILE` no meio, a config foi salva com sintaxe errada — rode o comando do Passo 3 de novo, sempre dentro do Git Bash.

## Passo 4: Testar

```bash
cd algum-repositorio-de-teste
git commit --allow-empty -m "commit de teste"
git log -1
```

A mensagem do commit deve conter, no final:

```
Co-authored-by: Claude <noreply@anthropic.com>
```

## Diagnóstico (se não funcionar)

**Verificar se o hook está no lugar certo:**

```bash
ls -la ~/.git-hooks/
cat ~/.git-hooks/prepare-commit-msg
```

**Rodar o hook manualmente para isolar o problema:**

```bash
echo "teste de commit" > /tmp/msg.txt
sh ~/.git-hooks/prepare-commit-msg /tmp/msg.txt message
cat /tmp/msg.txt
```

Se o trailer aparecer aqui mas não em commits reais, o problema está na config do `core.hooksPath` (volte ao Passo 3). Se não aparecer nem aqui, o problema está no próprio script — verifique se o arquivo não tem final de linha CRLF (isso quebra o shebang `#!/bin/sh`).

## Observação

Como o `Co-authored-by` usa um e-mail (`noreply@anthropic.com`) que não corresponde a nenhuma conta real, plataformas como GitHub não vão linkar isso a um perfil — ele aparece só como texto no commit, que é o comportamento esperado nesse caso.
