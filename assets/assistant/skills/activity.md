---
name: activity
description: Fila de downloads (queue), import manual, histórico de atividade
---

# Atividade

## Fila de downloads (queue) — monitorar progresso

**Onde fica:** Aba Atividade → aba "Queue" (primeira aba no TabBar).

A aba Queue mostra itens **atualmente sendo baixados** no Radarr/Sonarr:

**Estrutura visual:**
- **Cada item (card):**
  - **Ícone colorido** à esquerda (identificando filme 🎬 ou série 📺).
  - **Título** do item em bold.
  - Se for episódio: **número da temporada e episódio** (ex: "S02E05") abaixo do título.
  - **Badge de status** (colorido):
    - 🔵 Azul = Downloading.
    - 🟢 Verde = Completed.
    - 🔴 Vermelho = Failed/Warning.
    - 🟠 Laranja = Paused.
  - **Barra de progresso linear** mostrando % de conclusão.
  - Se em download: **"X MB left"** e **"ETA: Xh Xm"** (tempo estimado).
  - Se houver aviso: **ícone de atenção** (⚠️) com indicação de "Manual Import Required".

- **Pull-to-refresh** (arrastar para baixo) para atualizar lista em tempo real.

**Ações:**
- **Tocar em um item:** abre um **sheet (QueueItemSheet)** com detalhes completos:
  - Status expandido, barra de progresso detalhada, ETA.
  - Se houver erro: mensagem de erro em container vermelho.
  - Se requer manual import: seção "Manual Import Required" com botão para iniciar importação.
  - **Opções de remoção:**
    - Toggle: "Remove from Download Client" (padrão ON).
    - Toggle: "Add to Blocklist" — automaticamente **desabilitado** quando "Search for Replacement" está ON (os dois são mutuamente exclusivos: não é possível bloquear e buscar substituto ao mesmo tempo).
    - Toggle: "Search for Replacement" — quando ativado, desabilita "Add to Blocklist" automaticamente.
    - Botão vermelho: "Remove from Queue".
  - **Informações adicionais:** protocolo (NZB/Torrent), cliente de download, caminho de saída.

**Estado vazio:**
- Ícone de check verde grande.
- "Queue is empty — No active downloads at the moment".

**Observações:**
- Reflete o estado dos clientes de download **configurados no Radarr/Sonarr** (não mostra downloads diretos do qBittorrent).
- Para torrents do qBittorrent, use a aba **"Torrents"**.
- A fila atualiza em tempo real conforme downloads progridem.

## Import manual de arquivos da fila — manual import

**Onde fica:** Aba Atividade → Queue → tocar em item que requer intervenção → botão "Manual Import".

**Quando aparece:**
- O item mostra badge de status indicando "Manual Import Required".
- Geralmente ocorre quando o Radarr/Sonarr não consegue importar automaticamente (nome de arquivo não reconhecido, qualidade ambígua, etc).

**Passo a passo:**
1. Abrir Atividade → aba **"Queue"**.
2. Tocar no item que mostra aviso de "Manual Import Required" (terá ícone ⚠️).
3. Um **sheet (QueueItemSheet)** abre com detalhes do item.
4. Scroll para localizar a seção **"Manual Import Required"** com botão azul "Manual Import".
5. Tocar **"Manual Import"**.
6. Um novo **sheet (ManualImportScreen)** abre com:
   - **Cabeçalho** mostrando título do item de download.
   - **Resumo:**
     - "X valid" (ícone verde ✓) — arquivos que podem ser importados.
     - "X with issues" (ícone laranja ⚠️) — arquivos com problemas de detecção.
   - **Lista de arquivos** com checkboxes:
     - Cada arquivo mostra: nome, qualidade detectada, tamanho, grupo de release.
     - Checkbox para selecionar arquivos a importar.
   - **Botão "Import"** (azul, no topo-direito) — habilitado apenas se há arquivos selecionados.

7. **Selecionar arquivos** tocando nos checkboxes (geralmente todos estão pré-selecionados).
8. Tocar **"Import"** para confirmar.
9. Snackbar confirma **"X file(s) imported successfully"**.
10. A tela volta à fila, e o item desaparece (já foi importado).

**Observações:**
- O manual import aparece quando o Radarr/Sonarr **não consegue detectar automaticamente** qual filme/série/episódio corresponde aos arquivos.
- Apenas itens com `downloadId` disponível mostram essa opção.
- A importação manual permite você selecionar especificamente quais arquivos importar se o download contiver múltiplos itens.

## Histórico de atividade — grab import falha

**Onde fica:** Aba Atividade → aba "History" (segunda aba no TabBar).

O histórico mostra **eventos passados em ordem cronológica reversa** (mais recentes primeiro):

**Estrutura visual:**
- **Cada evento (card):**
  - **Badge colorido** (ícone + label) indicando tipo:
    - 🔵 Azul "GRABBED" — release capturada e enviada ao cliente.
    - 🟢 Verde "IMPORTED" — arquivo importado com sucesso.
    - 🔴 Vermelho "FAILED" — falha no download ou import.
    - 🟠 Laranja "DELETED" — item ou arquivo deletado.
    - 🟣 Roxo "RENAMED" — arquivo renomeado.
    - ⚫ Cinza "IGNORED" — item ignorado.
  - **Título/Nome** do filme ou série.
  - **Nome da release** (ex: "Movie.Title.2023.1080p.WEB-DL-GROUP").
  - **Timestamp relativo** (ex: "2 hours ago", "Yesterday").
  - **Ícone de chevron** (>) indicando que há mais detalhes.

- **Pull-to-refresh** para recarregar histórico.
- **Botão "Load More"** no rodapé para carregar eventos mais antigos (paginação).

**Ações:**
- **Tocar em um evento:** abre um **sheet com detalhes completos:**
  - Tipo de evento expandido.
  - Título, release name, quality.
  - Tamanho, indexer (se disponível).
  - Mensagem de erro (se for FAILED).
  - Data/hora completa.

**Estado vazio:**
- "No history found" com ícone de histórico vazio.

**Observações:**
- O histórico inclui **tanto filmes quanto séries**.
- Eventos podem ser filtrados por tipo (abas ou chips, se implementado).
- Útil para auditar o que foi baixado, quando falhas ocorreram, etc.
- Dados persistem entre sessões do app.
