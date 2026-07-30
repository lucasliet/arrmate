---
name: system
description: Logs, health, perfis de qualidade, sobre o app, diagnostics, system overview storage, version history, what's new, offline banner
---

# Sistema

> **Veja também:** a tela **System Management** também reúne **Connection Diagnostics**, **System Overview** e **Version History** — documentados em detalhe em `diagnostics.md`.

## Logs do app e logs do Radarr Sonarr

**Onde fica:** Configurações → seção "System Management" → "Logs".

A tela de Logs tem **duas abas** (TabBar no topo):

**AppBar da tela de Logs:**
- **Dropdown de filtro por nível** (na AppBar): opções All, Info, Warn, Error, Debug — selecione para filtrar instantaneamente.
- **Ícone "Clear All"** (visível apenas na aba "App Logs"): limpa todos os logs do app (com confirmação de diálogo).
- **Ícone "Copy All"**: copia todos os logs visíveis para o clipboard (útil para compartilhar com suporte).

**Aba "ARR LOGS":**
- Exibe logs remotos dos **servidores Radarr/Sonarr** conectados.
- Cada entrada mostra:
  - **Timestamp** (data/hora exata).
  - **Nível/Severity** (INFO, WARN, ERROR, DEBUG).
  - **Mensagem** do log.
- **Auto-load/Paginação**: conforme você scroll para baixo, mais logs carregam automaticamente.
- **Pull-to-refresh**: recarrega logs do servidor em tempo real.

**Aba "APP LOGS":**
- Exibe logs **internos do próprio Arrmate**.
- Mesmo formato que Arr Logs.
- Mostra requisições API, erros internos, eventos de ciclo de vida, etc.

**Detalhes de um log (ao tocar em uma entrada):**
- Abre como **DraggableScrollableSheet** (altura de 0.6 a 0.9).
- Seções exibidas:
  - **Time** — data/hora completa.
  - **Level** — nível de severidade.
  - **Logger** — componente que gerou o log.
  - **Message** — mensagem completa em caixa de código.
  - **Exception/Error** — caixa vermelha com stack trace (se presente).
- Cada seção é **copiável** individualmente.

**Observações:**
- Logs são **úteis para diagnóstico** de problemas de conexão, API, importação, etc.
- APP logs revelam erros internos e comportamento do app.
- ARR logs revelam comportamento do Radarr/Sonarr remoto.

## Saúde (health) — checagens e avisos do sistema

**Onde fica:** Configurações → seção "System Management" → "Health".

A tela de Health exibe **resultados de health checks** dos servidores Radarr/Sonarr:

**Sem problemas:**
- **Grande ícone de check verde** (✓) no centro.
- Mensagem: "No issues found".

**Com problemas:**
- **Lista de problemas/avisos:**
  - Cada item exibe:
    - **Ícone de severidade:**
      - 🔴 X vermelho = erro (grave).
      - 🟠 ! laranja = aviso (não crítico).
    - **Fonte** (qual instância detectou o problema).
    - **Mensagem descritiva** do problema (ex: "Disk space low", "Download client unreachable").
    - **Link wiki** (quando disponível): toque para abrir no navegador com mais informações.

**Ações:**
- **Ícone de refresh** no topo: toque para executar health checks manualmente.
- **Barra de progresso linear**: aparece enquanto checando.
- **Pull-to-refresh**: recarrega health status.

**Problemas comuns:**
- Espaço em disco baixo na pasta de mídia.
- Pasta não gravável (permissões).
- Download client (qBittorrent, etc) inacessível.
- Indexers falhando.
- Radarr/Sonarr desatualizado.
- Falha de DNS ou conectividade.

**Observações:**
- Health checks rodam automaticamente em background periodicamente.
- Você pode forçar check manual tocando no refresh.
- Alertas ajudam a identificar problemas antes que afetem downloads.

## Perfis de qualidade disponíveis nas instâncias

**Onde fica:** Configurações → seção "System Management" → "Quality Profiles".

A tela de Quality Profiles lista **todos os perfis de qualidade** configurados nas instâncias:

**Estrutura:**
- **Duas seções separadas:**
  - **Radarr Profiles** (para instâncias Radarr).
  - **Sonarr Profiles** (para instâncias Sonarr).
- Cada perfil mostra:
  - **Ícone** (opcional, indicando tipo).
  - **Nome do perfil** (ex: "1080p", "4K", "Any").
  - **ID** do perfil (número identificador).

**Estado vazio:**
- Se nenhuma instância conectada ou nenhum perfil encontrado:
  - Mensagem: "No profiles found or instance not connected".

**Observações:**
- Perfis são usados quando você **adiciona ou edita** filmes e séries.
- São **obtidos do cache local** do app (sincronizados quando você conecta à instância).
- Refletem a configuração do Radarr/Sonarr remoto.
- Útil para referência rápida de quais qualidades estão disponíveis.

## Sobre o app — versão atualizações e código-fonte

**Onde fica:** Configurações → seção "About".

A seção About exibe **informações sobre o Arrmate**:

**Informações exibidas:**
- **Versão atual** (ex: "v1.16.3").
- **Status de atualização:**
  - 🟢 Check verde: app está atualizado.
  - 📥 Ícone de download: nova versão disponível.
  - ⏳ Spinner: verificando atualizações.
- **Tocar na versão**: verifica manualmente se há atualizações (mostra spinner).
  - Se atualizado: snackbar "App is up to date".
  - Se nova versão: opção para baixar e instalar (OTA).
- **Link "Source Code"** (com ícone de GitHub):
  - Toque para abrir repositório GitHub no navegador (`https://github.com/lucasliet/arrmate`).

**Atualizações automáticas:**
- O app **verifica periodicamente** (a cada inicialização) por novas versões via GitHub Releases.
- Quando disponível, você pode **baixar e instalar diretamente** do app (OTA = Over-The-Air).
- Não requer ir à Play Store ou website.

**Observações:**
- Verificar atualizações manualmente útil se você suspeitar que há nova versão.
- App é open-source; você pode contribuir ou reportar issues no GitHub.

## Outras telas do System Management

A seção "System Management" das Configurações também reúne ferramentas de diagnóstico e sistema (documentadas em `diagnostics.md`):

- **Connection Diagnostics** (`/settings/diagnostics`): teste de reachability/latência de cada endpoint, traces de requisições recentes e export de relatório sanitizado (sem credenciais). Útil para investigar erros de conexão.
- **System Overview** (`/settings/system-overview`): armazenamento/disco por instância (com `LinearProgressIndicator`), tamanho da biblioteca (filmes/séries/episódios) e versão do servidor.
- **Version History** (`/settings/version-history`): lista de todas as releases do GitHub, com a versão instalada marcada como "Installed".
- **What's New**: popup automático com o changelog que aparece **uma vez** após cada atualização, com botão "View All Versions" para abrir o Version History.
- **Offline banner**: banner no topo do app (cor `errorContainer`, ícone `cloud_off_outlined`) que indica explicitamente quando o dispositivo está offline, mostrando o timestamp da última conexão e o caveat de imagens em cache.
