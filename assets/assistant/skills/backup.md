---
name: backup
description: Backup e restauração no Google Drive, backup de configurações e instâncias com API keys, backup automático, restore, appDataFolder, sign in Google, sessão expirada, backup not available
---

# Backup & Restore (Google Drive)

> **Onde tudo fica:** o backup fica em uma tela própria, a **Backup & Restore** (Configurações → seção "System" → "Backup & Restore", rota `/settings/backup`). Ele guarda as configurações do app e as instâncias configuradas na **pasta privada do app no Google Drive** do próprio usuário.

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

## Fazer login com a conta Google — sign in

**Onde fica:** Configurações → seção "System" → "Backup & Restore".

**Passo a passo:**
1. Abrir Configurações → seção **"System"** → **"Backup & Restore"**.
2. Tocar em **"Sign in with Google"**.
3. O **browser abre** para autorizar o Arrmate com a conta Google (permissões `drive.appdata` + e-mail/perfil).
4. Autorize na página do Google.
5. O app detecta o retorno do browser e você volta logado à tela de backup.

**Comportamento:**
- **No nativo** (Android/iOS/desktop): o app escuta o redirect em `http://localhost:<porta>` enquanto a autorização acontece no browser.
- **Na web**: após autorizar, o Google redireciona de volta para a própria página do app.

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

- **"Backup not available"**: build sem os dart-defines do Google (ex.: debug local sem as flags) — a função não foi compilada neste build.
- **Sessão expirada**: o app pede para fazer **"Sign in again"** — basta entrar de novo com a conta Google.
- **"No backup found"**: a conta Google logada nunca fez backup nesta tela — faça o primeiro "Back up now".

**Ações da tela (resumo):**
- **"Back up now"** — upload imediato; atualiza a data do último backup.
- **"Restore backup…"** — baixa e restaura com confirmação.
- **"Sign out"** — desconecta a conta Google (o backup automático para).
