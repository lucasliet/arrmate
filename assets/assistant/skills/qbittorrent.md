---
name: qbittorrent
description: Listar/pausar/retomar torrents, adicionar torrent, import torrent, filtros, alternative URL failover local externa
---

# qBittorrent

> **URL local + externa:** assim como Radarr/Sonarr, o qBittorrent aceita uma **Alternative URL** (LAN + URL externa) com failover automático. Veja `instances.md` → seção "Alternative URL".

## qBittorrent — listar pausar retomar e remover torrents

**Onde fica:** Aba Atividade → aba "Torrents" (terceira aba; só aparece se um qBittorrent estiver configurado em Configurações → Instances — ou enquanto o tour inicial estiver rodando, para o tour poder explicar a aba).

A aba Torrents mostra **todos os torrents do qBittorrent** configurado:

**Estrutura visual:**

**Filtros (topo):**
- **Chips de filtro por status** (horizontalmente scrolláveis):
  - **All** — todos os torrents.
  - **Downloading** — torrents em download ativo.
  - **Seeding** — torrents 100% completos fazendo upload (seed).
  - **Paused** — torrents pausados (inclui downloads pausados e seeds pausadas).
  - **Error** — torrents com erro (falha de conexão, espaço insuficiente, etc).
- Toque em um chip para filtrar instantaneamente; o chip ativo muda de cor para destacar.
- **Chips de filtro por vínculo com a biblioteca** (após um divisor vertical, só aparecem se houver Radarr/Sonarr configurado):
  - **Orphan** — o torrent foi baixado pelo Radarr/Sonarr, mas o item já saiu do catálogo; só sobrou o torrent.
  - **File removed** — o item ainda está no catálogo, mas o arquivo de mídia foi apagado.
  - **In library** — o torrent sustenta um filme/episódio que continua na biblioteca.
  - **Not in library** — baixado por fora, sem relação com a biblioteca.
- Tocar novamente no chip de vínculo ativo remove o filtro.
- **Cross-seed:** cópias cross-seed do mesmo release têm infohash diferente, então o Radarr/Sonarr só conhece uma delas. As outras herdam o mesmo vínculo (aparecem em **In library** ou **File removed**, não mais como **Orphan**) por comparação do nome do release. O casamento é só pelo nome normalizado (minúsculas, sem espaços nas pontas): pasta de download, tamanho e tracker são ignorados.
- **Depois da importação:** o vínculo sobrevive à saída do item da fila. Ele é reconstruído pelo histórico do Radarr/Sonarr: pelo evento de *grab* e, quando não houve grab (torrent adicionado à mão no cliente e importado depois), pelo evento de importação — os dois carregam o mesmo infohash.

**Lista de torrents:**
- **Cada torrent (card/tile):**
  - **Ícone colorido** à esquerda (nuvem com download/upload indicando ação).
  - **Título/Nome** do torrent em bold.
  - **Barra de progresso linear** mostrando % de conclusão (ex: 45% completed).
  - **Status** em badge colorido (Downloading, Seeding, Paused, Error).
  - **Badge de vínculo com a biblioteca** (quando há Radarr/Sonarr configurado): mostra o título do filme/episódio vinculado (ex: "Severance · S01E05"), ou "File removed", "Orphan", "Not in library". Torrents **órfãos** ganham borda e fundo em vermelho para destacar que só o torrent sobrou.
  - **Badge "Cross-seed"** ao lado do badge de vínculo quando a relação foi herdada de um torrent irmão com o mesmo nome de release.
  - **Seed time** (⏱, quando o torrent já semeou): há quanto tempo está semeando (ex: "2d 5h").
  - **Velocidades** (se ativo):
    - ⬇️ Download speed (ex: "2.5 MB/s").
    - ⬆️ Upload speed (ex: "1.2 MB/s").
  - **Pull-to-refresh** (arrastar para baixo) para atualizar lista em tempo real.

**Estado vazio:**
- Se "All" filter: "No Torrents — Add a new torrent to start downloading" com botão "Add Torrent".
- Se outro filtro: "No torrents found with this filter".
- **Exceção durante o tour inicial:** se o tour estiver rodando sem qBittorrent configurado, a aba mostra **torrents de exemplo** sob o aviso "Sample content shown during the tour". Eles não abrem detalhes, não representam downloads reais e somem — junto com a própria aba — assim que o tour é concluído ou pulado.

**Ações:**
- **Tocar em um torrent:** abre um **sheet (TorrentDetailsSheet)** com:
  - **Header:** nome do torrent, status badge, botão close.
  - **Progress section:**
    - Barra de progresso expandida com % e ETA.
    - "X% completed" e "ETA: Xd Xh Xm" (se em download).
  - **Stats grid (2 colunas):**
    - "Total Size", "Downloaded", "Uploaded", "Ratio".
    - Se ativo: "DL Speed", "UL Speed".
    - "Seeds", "Leechers" (peers conectados).
    - "Seed Time" (quando o torrent já semeou): tempo acumulado de seeding (ex: "3d 4h"), útil para conferir a regra de dias mínimos de seeding antes de remover.
  - **Information section:**
    - "Added On", "Category", "Save Path", "Tags", "Hash".
  - **Media Library section** (se o vínculo for conhecido):
    - Faixa colorida com o status do vínculo e a explicação (órfão aparece em vermelho).
    - Nota em itálico quando o vínculo veio de um cross-seed (mesmo nome de release, infohash diferente).
    - "Media" e "Instance" quando o item é conhecido.
    - Botão "Open in library" que troca para a instância de origem e abre o filme/episódio. O botão não aparece quando a ficha foi aberta a partir da própria tela da biblioteca.
  - **Actions section:**
    - Se paused: botão azul "Resume".
    - Se ativo: botão laranja "Pause".
    - Botão "Recheck" (ícone de sync) para verificar integridade.
    - Botão "Files" (ícone de pasta) para listar e gerenciar arquivos.
    - Botão "Move" (ícone de seta) para mudar localização no disco.
    - Se 100% completo: botão "Import to Media Library" (para importar para Radarr/Sonarr).
    - Botão "Remove Torrent" (texto em vermelho, destrutivo).

- **Confirmação de ações destrutivas:**
  - "Remove Torrent?" dialog com checkbox "Also delete files on disk".
  - Botões: "Cancel" e "Remove" (em vermelho).

**Observações:**
- O qBittorrent precisa estar configurado em Configurações → Instances para que essa aba apareça.
- A lista atualiza em tempo real conforme torrents progridem.
- Múltiplos torrents podem ser operados individualmente.

## Adicionar torrent — magnet URL ou arquivo .torrent

**Onde fica:** Aba Atividade → aba Torrents → botão "+" (FAB no canto inferior direito).

**Passo a passo:**
1. Abrir Atividade → aba **"Torrents"**.
2. Tocar no botão **"+"** (FAB redondo no canto inferior direito).
3. Um **sheet (AddTorrentSheet)** abre com título "Add Torrent".
4. **Seção "Source":**
   - **Opção 1 — URLs (magnet ou HTTP):**
     - Campo de texto com placeholder "Paste magnet links or HTTP URLs here\nOne per line".
     - Pode colar múltiplas URLs, uma por linha.
   - **Opção 2 — Arquivo .torrent:**
     - Botão "Select .torrent File".
     - Abre picker de arquivo; selecione um arquivo `.torrent` do dispositivo.
     - Ao selecionar, mostra card com nome e caminho do arquivo.
     - Toque no X para desselecionar e voltar para modo URLs.
   - **Nota:** Você deve fornecer **pelo menos uma fonte** (URL OU arquivo); não pode deixar vazio.

5. **Seção "Options":**
   - **Save Path** (opcional): campo de texto para caminho customizado.
     - Se deixado vazio, usa padrão do qBittorrent.
   - **Category** (opcional): campo com autocomplete.
     - Toque para sugerir categorias existentes no qBittorrent.
   - **Tags** (opcional): campo com autocomplete para adicionar múltiplas tags.
     - Separe tags com vírgula.
   - **Start Paused** (toggle, padrão OFF): se ON, torrent inicia pausado.

6. Tocar **"Add Torrent"** (botão azul no rodapé).
7. Snackbar confirma **"Torrent added successfully"**.
8. Sheet fecha e você volta à lista de torrents.

**Validação:**
- Se deixar Source vazio: snackbar "Please provide URLs or select a .torrent file".
- Se arquivo for inválido: snackbar "Failed to add torrent: [erro]".

**Observações:**
- Magnet link: `magnet:?xt=urn:btih:...` (copie direto de sites de torrents).
- HTTP URL: link direto para arquivo `.torrent` (ex: `http://example.com/file.torrent`).
- Arquivo local: arquivo `.torrent` no dispositivo ou nuvem sincronizada.

## Importar torrent completo para Radarr ou Sonarr — torrent import

**Onde fica:** Aba Atividade → Torrents → tocar em torrent 100% completo → botão "Import to Media Library".

**Passo a passo:**
1. Abrir Atividade → aba **"Torrents"**.
2. Tocar em um torrent que esteja **100% completo** (status "Seeding" ou barra de progresso em 100%).
3. Um **sheet (TorrentDetailsSheet)** abre.
4. Scroll para localizar o botão **"Import to Media Library"** (azul, tonalizado).
5. Tocar **"Import to Media Library"**.
6. Um novo **sheet (TorrentImportTargetSheet)** abre com título "Select Target":
   - **Duas abas:**
     - **Movies:** lista de filmes no Radarr (searchable).
     - **Series:** lista de séries no Sonarr (searchable).
   - **Campo de busca:** toque para buscar pelo nome do filme/série.
   - Selecione o filme ou série de destino tocando nele.

7. Um terceiro **sheet (TorrentImportFilesSheet)** abre com título "Import to [Movie/Series]":
   - **Cabeçalho:** nome do filme/série selecionado.
   - **Lista de arquivos** do torrent:
     - Cada arquivo mostra: nome, qualidade detectada, tamanho.
     - Checkboxes para selecionar quais arquivos importar (geralmente todos pré-selecionados).
     - **Mapeamento automático** aparece (ex: "Season 2, Episode 5" para séries).
   - **Botão "Import"** (azul, topo-direito): importa arquivos selecionados.

8. Tocar **"Import"** para confirmar.
9. Snackbar confirma **"X file(s) imported successfully"**.
10. Sheets fecham e você volta à lista de torrents.

**Observações:**
- O botão "Import to Media Library" **só aparece quando o torrent está 100% completo**.
- Os arquivos são escaneados automaticamente na pasta do torrent (savePath).
- Qualidade, tamanho e grupo de release são detectados automaticamente.
- Você pode selecionar apenas alguns arquivos se o torrent contiver múltiplos itens.
- Após import, o torrent permanece no qBittorrent; você pode deletá-lo manualmente depois.
- A importação **copia** os arquivos (hardlink, quando o Radarr/Sonarr estão configurados para isso e a pasta de download está no mesmo filesystem da biblioteca) — nunca move. O torrent continua semeando os mesmos arquivos.
- O infohash do torrent vai como download id, então o item importado continua vinculado ao torrent na lista (badge **In library**) depois da importação.

## Filtrar torrents por status — baixando seedando pausado erro

**Onde fica:** Aba Atividade → Torrents → chips de filtro no topo da lista.

**Chips disponíveis:**
- **All** — todos os torrents (sem filtro).
- **Downloading** — torrents em download ativo (status "Downloading").
- **Seeding** — torrents 100% completos fazendo upload ("Uploading" ou "Seeding").
- **Paused** — torrents pausados (inclui downloads pausados e seeds pausadas).
- **Error** — torrents com erro ("Error", "Stalled", etc).

**Comportamento:**
- Toque em um chip para ativar filtro.
- O chip ativo fica **destacado visualmente** (cor mais intensa, checkmark, etc).
- A lista refiltra **instantaneamente**.
- Você pode voltar ao "All" tocando nele ou em outro chip.

**Observações:**
- Cada chip mostra apenas torrents daquele status.
- Se nenhum torrent corresponde ao filtro: "No torrents found with this filter".
- O filtro "Downloading" útil para monitorar downloads em andamento.
- O filtro "Error" útil para diagnosticar problemas.
