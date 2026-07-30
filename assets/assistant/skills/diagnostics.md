---
name: diagnostics
description: Diagnósticos de conexão, latência, traces de requisições, export de relatório, system overview storage disco, version history changelog, what's new, offline banner, problemas de rede status armazenamento versão
---

# Diagnósticos, Sistema e Versão

## Connection Diagnostics — testar endpoints e exportar relatório

**Onde fica:** Configurações (quinta aba da barra inferior) → seção "System Management" → "Diagnostics".

A tela de **Connection Diagnostics** testa a conectividade de cada instância configurada e ajuda a investigar problemas de rede.

**Topo da tela (AppBar):**
- **Título:** "Connection Diagnostics".
- **Botão refresh** (ícone `refresh`): reexecuta as checagens de endpoint.
- **Botão export** (ícone `ios_share`): compartilha um **relatório sanitizado** (via share sheet do sistema).

**Card "Connection troubleshooting":**
- Resumo explicativo: testa cada endpoint por reachability e latência, mostra traces de requisições recentes e exporta relatório.

**Resumo de rede:**
- Ícone `wifi_rounded` (verde) quando há interface de rede, ou `wifi_off_rounded` (vermelho) quando offline.
- Status dos endpoints: "Endpoints available", "Some endpoints unavailable" ou "Endpoints unavailable".
- Timestamp de geração (data/hora) e interfaces de rede detectadas (ex: "wifi", "vpn").

**Checagens por endpoint (Endpoint connectivity):**
- Cada instância configura um tile por endpoint testado:
  - **Ícone:** `check_circle` verde (OK) ou `error` vermelho (falha).
  - **Título:** `<Label da instância> · <endpoint>` (ex: "Casa · Primary endpoint · Active").
  - **Detalhe:** latência em milissegundos + versão do servidor (quando OK), ou mensagem de erro (quando falha).
- Se nenhuma instância estiver configurada: "No Radarr, Sonarr, or qBittorrent instances are configured."

**Traces de requisições recentes (Recent request traces):**
- Lista das últimas 20 requisições HTTP feitas pelo app:
  - Método + caminho (ex: "GET /api/v3/movie").
  - Fonte (instância/serviço), status code ou tipo de erro, e duração.
- Quando vazia: "No recent requests recorded."

**Export de relatório sanitizado:**
- O relatório **não expõe credenciais**: hosts são redacted, cabeçalhos sensíveis (`x-api-key`, `authorization`, `token`, etc.) são mascarados, instâncias aparecem como "Instance 1", "Instance 2".
- Inclui: versão do app, plataforma, interfaces de rede, checagens por instância e até 50 traces de requisições.
- Use para anexar a um bug report no GitHub.

**Observações:**
- As checagens testam cada endpoint configurado (URL principal e alternativa) chamando o endpoint autenticado de status do servidor.
- O relatório marca quando o cache de imagens foi limpo pela última vez.

## System Overview — armazenamento disco e tamanho da biblioteca

**Onde fica:** Configurações → seção "System Management" → "System Overview".

A tela de **System Overview** exibe informações de armazenamento e biblioteca para cada instância Radarr/Sonarr.

**Topo da tela (AppBar):**
- **Título:** "System Overview".
- **Botão refresh** (ícone `refresh`): recarrega os dados de storage.
- **Pull-to-refresh** também funciona.

**Card por instância:**
- **Cabeçalho:** ícone da instância (filme/TV), nome (label), tipo (Radarr/Sonarr) e badge de versão.
- **Resumo da biblioteca** (quando disponível):
  - **Radarr:** número de filmes + tamanho total da biblioteca (ex: "250 Movies", "1.2 TB Library").
  - **Sonarr:** número de séries, episódios + tamanho total (ex: "30 Series", "1.500 Episodes", "800 GB Library").
- **Disk Space (espaço em disco):**
  - Uma linha por local de armazenamento (root folder):
    - Nome do disco e caminho.
    - **`LinearProgressIndicator`** mostrando a fração usada.
    - "Used X (NN%)" e "Y free of Z" (ex: "Used 800 GB (80%)", "200 GB free of 1 TB").
  - Se nenhum disco reportado: "No storage locations reported."
- **Container de falhas** (quando algum disco falha ao consultar):
  - Fundo `errorContainer`, ícone `warning_amber_rounded`, lista de mensagens de erro.

**Estado vazio:**
- "No Arr instances configured" → "Add a Radarr or Sonarr instance to view system data."

**Observações:**
- Útil para antecipar falta de espaço em disco antes que downloads falhem.
- Combina com a tela de Health (avisos do servidor) para diagnóstico completo.

## Version History — histórico de versões e changelog

**Onde fica:** Configurações → seção "System Management" → "Version History".

A tela de **Version History** lista todas as releases publicadas no GitHub.

**Estrutura:**
- Lista de cards, um por release, em ordem cronológica decrescente.
- **Cada card exibe:**
  - Badge com a versão (ex: "v1.20.0").
  - Versão atualmente instalada destacada com badge `primaryContainer` + texto **"Installed"** (cor `primary`).
  - Data de publicação (formato local).
  - Changelog completo da release (notas de versão do GitHub).

**Ações:**
- **Pull-to-refresh:** recarrega a lista de releases.
- **Botão refresh** na AppBar.

**Estados:**
- Vazio: "No releases available" → "Release history could not be loaded."
- Erro: mensagem com botão de retry.

## What's New — changelog pós-atualização

**Onde aparece:** automaticamente após instalar uma atualização (uma vez por versão).

O diálogo **What's New** mostra as notas de versão da versão recém-instalada.

**Comportamento:**
- Aparece **uma única vez** por versão, após a primeira abertura pós-atualização.
- Não pode ser fechado tocando fora (`barrierDismissible: false`).

**Conteúdo:**
- Ícone `new_releases_rounded`.
- Título: "What's New in v<versão>".
- Corpo: o changelog da release (rolável quando longo).
- Se a release não tiver notas: "This release does not include release notes."

**Ações (botões):**
- **"Dismiss":** fecha o diálogo.
- **"View All Versions":** fecha e navega para Configurações → Version History.

## Offline — banner de status offline

**Onde aparece:** topo da tela (acima do conteúdo), em qualquer aba, quando o dispositivo está sem rede.

O **OfflineStatusBanner** indica explicitamente quando o app está offline.

**Aparência:**
- Cor de fundo `errorContainer`.
- Ícone `cloud_off_outlined` (cor `onErrorContainer`).
- Título **"Offline"** em bold.
- Subtítulo com:
  - **Last online** (timestamp relativo da última conexão), ou "No previous online connection recorded".
  - Aviso: imagens em cache podem ter até **N dias** (período de stale do cache).

**Comportamento:**
- Some automaticamente quando a rede volta.
- Não impede o uso do app — apenas sinaliza que dados podem estar desatualizados.
