---
name: backup
description: Backup e restauração no Google Drive nos apps nativos e via arquivo local JSON. Na web só existe importar e exportar arquivo local, sem login Google. Backup de configurações e instâncias com API keys, backup automático, restore, exportar arquivo, importar arquivo, appDataFolder, sign in Google, sessão expirada, backup not available
---

# Backup & Restore (Google Drive e arquivo local)

> **Onde tudo fica:** o backup fica em uma tela própria, a **Backup & Restore** (Configurações → seção "System" → "Backup & Restore", rota `/settings/backup`). Nos apps nativos (Android, iOS, macOS, Windows e Linux) ele guarda as configurações e as instâncias de duas formas: na **pasta privada do app no Google Drive** do próprio usuário (com login Google) ou em um **arquivo JSON local**. Na **versão web** só existe o arquivo local — não há login Google, backup no Drive nem backup automático.

## O que entra no backup — configurações e instâncias

**Onde fica:** Configurações → seção "System" → "Backup & Restore".

O backup inclui **todas as configurações e preferências** do app:

- Tema e aparência.
- Home tab (aba inicial).
- Ordenação e filtros memorizados.
- Settings de notificação.
- Mínimo de dias de seeding.
- Defaults de add (perfil de qualidade, root folder, etc.).

E também as **instâncias configuradas** — Radarr, Sonarr e qBittorrent — **incluindo as API keys** de cada uma.

**Onde é armazenado:**
- Pasta **privada do app no Google Drive** (`appDataFolder`): invisível para outros apps e não aparece em "Meu Drive" do usuário.
- O arquivo de backup se chama `arrmate-backup.json`.
- Alternativamente, **um arquivo JSON local** exportado pela própria tela — ver seção abaixo.

## Backup em arquivo local — "Export backup to file" e "Restore from file…"

**Onde fica:** Configurações → seção "System" → "Backup & Restore", cartão na parte de baixo da tela.

**Exportar:**
1. Tocar em **"Export backup to file"**.
2. O app abre o **dialog de salvamento** do sistema (no web, baixa o arquivo direto).
3. O arquivo sugerido se chama `arrmate-backup-AAAA-MM-DD.json` (com a data do dia).
4. Uma confirmação verde aparece com o nome do arquivo salvo.

**Restaurar:**
1. Tocar em **"Restore from file…"**.
2. Escolher um arquivo de backup `.json` no seletor de arquivos.
3. Abre a **mesma confirmação** do restore do Drive (data, versão, plataforma, número de instâncias e aviso de substituição).
4. Confirmar para restaurar.

**Comportamento:**
- **Não precisa de login Google** — funciona até em builds sem a configuração do Google (quando o Drive aparece como "Google Drive backup not available").
- O arquivo local tem o **mesmo formato** do backup do Drive: um backup exportado pode ser restaurado no Drive e vice-versa.
- O restore **substitui** as configurações e instâncias atuais, igual ao restore do Drive.
- Exportar para arquivo **não altera** a data de "Last backup" nem o controle de sincronização do Drive.
- **Atenção**: o arquivo é **texto puro com as API keys das instâncias** — guarde em local seguro.

## Fazer login com a conta Google — sign in

**Onde fica:** Configurações → seção "System" → "Backup & Restore".

**Passo a passo:**
1. Abrir Configurações → seção **"System"** → **"Backup & Restore"**.
2. Tocar em **"Sign in with Google"**.
3. O **browser abre** para autorizar o Arrmate com a conta Google (permissões `drive.appdata` + e-mail/perfil).
4. Autorize na página do Google.
5. O app detecta o retorno do browser e você volta logado à tela de backup.
6. Se o Google Drive já tiver um backup que este aparelho ainda não restaurou (por exemplo, feito em outro aparelho), a tela mostra o cartão **"Backup found in your Google Drive"** com o botão **"Restore"** e a data do backup em "Last backup". Enquanto esse backup não for restaurado, os backups automáticos ficam pausados para não sobrescrevê-lo; **"Back up now"** continua disponível.

**Comportamento:**
- **No Android e no iOS**: a autorização abre em uma janela de login do sistema por cima do app (Chrome Custom Tab / sessão de autenticação do Safari). Ao concluir, a janela fecha sozinha e você volta ao Arrmate já logado, mesmo em navegadores que não seguem o redirecionamento; fechar a janela antes cancela o login.
- **No desktop**: o app escuta o redirect em `http://localhost:<porta>` enquanto a autorização acontece no browser, e a página final, no tema do app, avisa que o login terminou e que você pode voltar ao app.
- **Na web**: não há **"Sign in with Google"**, cartão de conta, **"Back up now"** nem texto de backup automático. A tela mostra apenas **"Export backup to file"** e **"Restore from file…"**.

## Fazer backup agora — "Back up now"

**Onde fica:** Configurações → seção "System" → "Backup & Restore".

**Passo a passo:**
1. Estar logado com a conta Google (ver seção anterior).
2. Tocar em **"Back up now"**.
3. O app faz o **upload** do `arrmate-backup.json` para a pasta privada no Drive.
4. A data do **último backup** é atualizada na tela.

## Restaurar backup — "Restore backup…"

**Onde fica:** Configurações → seção "System" → "Backup & Restore".

**Passo a passo:**
1. Estar logado com a conta Google.
2. Tocar em **"Restore backup…"**.
3. O app **baixa** o backup do Drive.
4. Abre uma **confirmação** mostrando **data, versão, plataforma e número de instâncias** do backup.
5. A confirmação **avisa que os dados locais serão substituídos**.
6. Confirmar para restaurar.

**Comportamento:**
- O restore **substitui (replace)** tudo que é do app no dispositivo: configurações, preferências e instâncias.
- A **home tab** restaurada só é aplicada **após reiniciar o app**.

## Backup automático — debounce de ~30s

**Comportamento:**
- Quando logado, o app faz backup **automaticamente ~30 segundos após mudanças** em instâncias ou settings.
- **Falhas são silenciosas** (apenas logadas) — nada aparece para o usuário.

## Privacidade e segurança

**Observações:**
- O backup contém as **API keys das instâncias em texto claro**, dentro da pasta privada do app no Drive do próprio usuário — só a conta Google autorizada consegue acessá-la.
- O Arrmate não tem acesso ao resto do Drive: o escopo é restrito à pasta do app (`drive.appdata`) + e-mail/perfil.

## Estados e problemas comuns

- **"Google Drive backup not available"**: build sem os dart-defines do Google (ex.: debug local sem as flags) — o backup por **Drive** não foi compilado neste build; o **arquivo local continua disponível** no cartão de baixo.
- **Sessão expirada**: o app pede para fazer **"Sign in again"** — basta entrar de novo com a conta Google.
- **"No backup found"**: a conta Google logada nunca fez backup nesta tela — faça o primeiro "Back up now".
- **"The backup file is corrupted or from an unsupported version"**: o arquivo escolhido em "Restore from file…" não é um backup válido do Arrmate ou foi gerado por versão incompatível.

**Ações da tela (resumo):**
- **"Back up now"** — upload imediato para o Drive; atualiza a data do último backup.
- **"Restore backup…"** — baixa do Drive e restaura com confirmação.
- **"Export backup to file"** — salva um `.json` local (funciona sem login).
- **"Restore from file…"** — restaura a partir de um `.json` local, com confirmação.
- **"Sign out"** — desconecta a conta Google (o backup automático para).
