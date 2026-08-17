---
name: movies
description: Adicionar/detalhes/editar/deletar filme, discover busca por título ID URL TMDB IMDb, deletar arquivo, purge (remover filme + arquivos + torrents no qBittorrent), import exclusion, buscar release
---

# Filmes

## Adicionar filme — buscar e cadastrar no Radarr

**Onde fica:** Aba Filmes → botão "+" (floating action button no canto inferior direito).

> **Atalho:** o "+" abre a tela **Discover** já em modo filme. Veja a seção "Adicionar via Discover" abaixo para busca por título, ID TMDB/IMDb ou URL.

**Passo a passo:**
1. Abrir a aba Filmes (primeira aba da barra inferior).
2. Tocar no botão **"+"** no canto inferior direito (FAB redondo).
3. Abre a tela **Discover** com AppBar "Add Movie" e ícone **X** ("Close") à direita para sair.
4. No campo **"Search"**, digite o título do filme (ex: "Inception", "The Matrix").
5. A busca roda sozinha com debounce enquanto você digita; pressionar Enter dispara a busca imediatamente.
6. **Resultados aparecem com:**
   - Poster thumbnail no lado esquerdo.
   - Título do filme.
   - Subtítulo com ano e nota TMDB (ex: "2010 · 8.4"), ou "No rating" quando não há nota.
   - Filmes que **já estão na biblioteca** mostram um ✅ **check verde** no lugar do chevron; tocar neles **abre o filme na biblioteca** em vez de adicionar.
7. Tocar em um resultado ainda não adicionado.
8. Abre a etapa **"Movie Preview"** (AppBar com esse título e seta de voltar): poster grande, "Título (Ano)", linha com certificação · duração · gêneros, sinopse e botão **"Configure Addition"**.
9. Tocar em **"Configure Addition"** para abrir a etapa final (AppBar com o título do filme, seta de voltar e botão **"Add"** à direita):
   - **Monitor:** dropdown com "Movie", "Movie + Collection" ou "None" (escolher "None" adiciona o filme sem monitorar).
   - **Minimum Availability:** dropdown com opções:
     - Announced (filme anunciado mas ainda não lançado).
     - In Cinemas (lançado em cinemas).
     - Released (lançado em qualquer formato).
   - **Quality Profile:** dropdown listando perfis de qualidade do Radarr (ex: "1080p", "4K").
   - **Root Folder:** dropdown com pastas destino do Radarr (ex: "/movies", "/media/movies").
   - **Tags:** chips das tags da instância (aparece só quando o Radarr tem tags cadastradas).
10. Tocar **"Add"** no canto superior direito (vira spinner enquanto envia).
11. Snackbar confirma "Movie added successfully" e a lista volta a atualizar automaticamente.

**Observações:**
- O filme é adicionado ao Radarr imediatamente.
- A busca automática de releases no Radarr depende da configuração do Radarr (pode ser imediata ou agendada).
- Se faltar quality profile ou root folder, o app avisa "Please select a movie, quality profile, and root folder" e não envia.
- Use a **seta de voltar** de cada etapa para revisar a escolha anterior.

## Adicionar via Discover — busca por título ID ou URL

**Onde fica:** Aba Filmes → botão "+" (FAB) → abre a tela **Discover** em modo filme.

A tela **Discover** abre **direto no tipo de mídia da aba de origem** — o "+" da aba Filmes busca filmes, o "+" da aba Séries busca séries. Não há abas Movies/Series dentro da tela: para adicionar uma série, use o "+" da aba Séries. A busca aceita não só o título, mas também identificadores e links.

**Layout da tela:**
- **AppBar** com título "Add Movie" e ícone **X** ("Close").
- Campo **"Search"** com exemplos no hint (`Interstellar, tmdb:157336, imdb:tt0816692`).
- Dropdown **"Sort"** e chip **"Hide already added"** logo abaixo (empilhados em telas muito estreitas).

**Como buscar:**
- **Por título:** digite o nome (ex: "Dune") — a busca tem debounce e roda automaticamente enquanto você digita.
- **Por ID TMDB/IMDb:** cole o identificador (ex: `tt10366206`, o ID numérico do TMDB).
- **Por URL:** cole um link do IMDb ou TMDB — o app extrai o ID embutido na URL e faz o lookup.

**Resultados:**
- Cada resultado mostra poster, título, ano e nota.
- Resultados que já estão na sua biblioteca aparecem marcados como existentes.
- Use o chip **"Hide already added"** para ocultar itens que você já tem.
- Use o **dropdown "Sort"** para reordenar por relevância, data ou avaliação.

**Adicionar:**
- Toque em um resultado para abrir o "Movie Preview" e depois "Configure Addition" (Monitor, Minimum Availability, Quality Profile, Root Folder, Tags) — mesmas etapas do fluxo padrão.
- Em seguida, toque em **"Add"** no canto superior direito.

**Observações:**
- O tipo de mídia do Discover vem do parâmetro `type` do deep link: `arrmate:///discover?type=movie` ou `arrmate:///search?q=<termo>&type=movie` (o padrão é `movie` quando o parâmetro é omitido).
- A extração de ID funciona para os formatos de URL mais comuns do IMDb e TMDB.

## Detalhes do filme — sinopse arquivos histórico ações

**Onde fica:** Aba Filmes → tocar em qualquer filme (no grid ou na lista).

Ao tocar em um filme, abre a tela **MovieDetailsScreen** com layout em scroll vertical:

**AppBar (topo expansível):**
- **Fanart** (imagem de fundo grande) que encolhe conforme você scroll para baixo.
- **Ícone de voltar** (seta) no canto superior esquerdo.
- **5 ícones de ação** no canto superior direito (da esquerda para direita):
  1. **Refresh & Scan** (ícone `manage_search`) — tooltip "Refresh & Scan" — dispara rescan do arquivo no Radarr.
  2. **Automatic Search** (ícone `travel_explore`) — tooltip "Automatic Search" — dispara busca automática de releases.
  3. **Interactive Search** (ícone `troubleshoot`) — tooltip "Interactive Search" — abre sheet de releases disponíveis para seleção manual.
  4. **Monitor Toggle** (ícone `bookmark` preenchido / `bookmark_border`) — tooltip "Monitor" ou "Unmonitor" — alterna monitoramento do filme.
  5. **Menu** (ícone ⋮ PopupMenuButton) — opções:
     - **"Edit"** → abre MovieEditScreen.
     - **"Delete files"** (ícone `delete_sweep`) → apaga todos os arquivos do filme em disco, mas mantém o filme cadastrado no Radarr. Fica **desabilitado** (acinzentado) quando o filme não tem nenhum arquivo baixado.
     - **"Delete"** → abre diálogo de confirmação com título "Delete Movie?", checkbox "Delete files from disk" (opcional), botões "Cancel" e "Delete" (vermelho).
     - **"Purge"** (ícone `delete_forever`, texto vermelho) → remove tudo (catálogo + arquivos + torrents fonte no qBittorrent, incluindo duplicatas cross-seed) para liberar o espaço em disco usado por dados com hardlink. Ver seção "Purge filme — remover tudo (Radarr + qBittorrent)".
- Título do filme fica visível no topo conforme scroll.

**Poster e informações principais:**
- **Poster** no lado esquerdo.
- **Título** em bold.
- **Ano** de lançamento.
- **Nota/Rating** (ex: 8.5/10 de fontes como IMDb ou TMDB).
- **Gêneros** (tags coloridas: "Action", "Sci-Fi", etc).
- **Badges de status** (coloridos e destacados):
  - "Downloaded" (verde) — arquivo completo presente.
  - "Missing" (vermelho) — monitorado mas sem arquivo.
  - "Unmonitored" (cinza) — não está em monitoramento.

**Seções abaixo (scroll):**

**1. Overview:**
- Sinopse/resumo do filme.
- Informações de produção: diretor, elenco principal (primeiros atores listados).
- Runtime (duração em minutos).
- Links externos (IMDb, TVDb, TheMovieDb) se disponíveis — toque para abrir no navegador.

**2. Files & Metadata:**
- Se houver arquivo baixado, lista exibe:
  - **Arquivo principal** com:
    - Codec de vídeo (ex: H.264, H.265/HEVC).
    - Resolução (ex: 1080p, 2160p/4K).
    - Tamanho em bytes (formatado, ex: 2.5 GB).
    - Áudio (codec e canais, ex: AAC Stereo, DTS 5.1).
  - **Arquivos extras** (legendas, trailers, making-of, etc) listados abaixo.
  - Ícone de **lixeira** ao lado de cada arquivo para deletar (requer confirmação).
- Se não houver arquivo: exibe "No files" ou similar.

**3. History:**
- Lista de eventos específicos do filme (filtro por tipo, se houver):
  - **Grabbed** (amarelo): release foi capturada e enviada ao cliente de download.
  - **Imported** (verde): arquivo foi importado com sucesso à biblioteca.
  - **Failed** (vermelho): falha no download ou import.
  - **Deleted** (cinza): arquivo foi deletado.
- Cada evento mostra timestamp relativo (ex: "2 hours ago").
- Toque em um evento para ver detalhes completos.

**Botões de ação (AppBar — 5 ícones no canto superior direito):**
1. **Refresh & Scan** (ícone `manage_search`): dispara rescan do arquivo no Radarr.
2. **Automatic Search** (ícone `travel_explore`): dispara busca automática de releases no Radarr.
3. **Interactive Search** (ícone `troubleshoot`): abre sheet de releases disponíveis para seleção manual (grab).
4. **Monitor Toggle** (ícone `bookmark`/`bookmark_border`): alterna monitoramento do filme (ON ↔ OFF).
5. **Menu ⋮** (PopupMenuButton):
   - **"Edit"**: abre MovieEditScreen para editar qualidade, pasta, monitoramento, etc.
   - **"Delete files"**: apaga todos os arquivos do filme em disco (filme continua no Radarr). Desabilitado quando não há arquivos.
   - **"Delete"**: abre diálogo "Delete Movie?" com checkbox "Delete files from disk" (opcional), botões "Cancel" e "Delete" (vermelho).
   - **"Purge"** (vermelho): remove catálogo + arquivos + torrents fonte no qBittorrent (incl. cross-seed). Libera espaço de dados com hardlink.

**Observações:**
- A seção Files mostra todos os arquivos associados; é possível deletar arquivos individuais sem deletar o filme.
- O histórico permite rastrear como o filme foi adquirido e importado.
- Se não houver ações possíveis (ex: filme já baixado e monitorado), alguns botões podem estar desabilitados.

## Editar filme — monitoramento qualidade pasta raiz disponibilidade

**Onde fica:** Tela de detalhes do filme → botão "Edit" ou menu ⋮ → "Edit".

**Passo a passo:**
1. Abrir detalhes do filme (tocando no filme na lista).
2. Tocar em **"Edit"** (ícone de lápis) ou acessar via menu ⋮.
3. Abre a tela **MovieEditScreen** com campos editáveis:

**Campos disponíveis:**
   - **Monitored:** toggle ON/OFF.
     - ON (padrão): o Radarr busca ativamente releases.
     - OFF: o Radarr ignora o filme até reativar.
   - **Minimum Availability:** dropdown com opções (Announced, In Cinemas, Released).
     - Define a partir de qual estágio o Radarr baixa releases.
   - **Quality Profile:** dropdown com perfis do Radarr (ex: "1080p", "4K").
     - Altera preferência de qualidade para futuras buscas.
   - **Root Folder:** dropdown com pastas destino (ex: "/movies", "/external/media/movies").
     - Pasta onde os arquivos serão armazenados (ou movidos, se configurado abaixo).

4. Se você **alterou a pasta raiz (Root Folder)** e o filme tem arquivos já baixados:
   - Um **diálogo de confirmação** aparece: "Move Files?"
   - **"Yes":** Move os arquivos fisicamente para a nova pasta no servidor.
   - **"No":** Apenas atualiza o banco de dados; arquivos permanecem no local antigo.

5. Tocar **"Save"** (ícone de checkmark ou botão no rodapé).
   - Snackbar confirma "Movie updated successfully".

**Observações:**
- Alterações são aplicadas imediatamente ao Radarr.
- Se houver erro ao salvar, um snackbar exibe a mensagem de erro.
- Você pode voltar sem salvar tocando no ícone de voltar.

## Deletar filme da biblioteca — remover do Radarr

**Onde fica:** Tela de detalhes do filme → menu ⋮ (três pontos) → "Delete".

**Passo a passo:**
1. Abrir detalhes do filme.
2. Tocar no **menu ⋮** (três pontos) no canto superior direito.
3. Selecionar **"Delete"** (texto em vermelho para indicar ação destrutiva).
4. Um **diálogo de confirmação** aparece:
   - Título: "Delete Movie?"
   - **Checkbox** "Delete files from disk" (opcional) — se marcado, também remove os arquivos físicos do servidor.
   - **Checkbox "Add import exclusion list"** (opcional) — se marcado, adiciona o filme à lista de exclusão do Radarr, impedindo que ele seja re-importado automaticamente por listas/import lists no futuro.
   - Botões: "Cancel" e "Delete" (em vermelho).
5. Marcar ou deixar desmarcado os checkboxes conforme desejado.
6. Tocar **"Delete"** para confirmar.
7. Snackbar confirma "Movie deleted successfully" e a tela volta à lista de filmes.

**Observações:**
- O filme é removido do Radarr imediatamente.
- Os arquivos em disco são removidos **somente se** o checkbox "Delete files from disk" estiver marcado.
- **Import exclusion** é útil quando você não quer que o filme volte automaticamente via listas de importação — ele permanece na exclusion list do Radarr até você removê-lo de lá (pela web do Radarr).
- Esta ação é destrutiva e não pode ser desfeita via app (você pode re-adicionar o filme manualmente).

## Purge filme — remover tudo (Radarr + qBittorrent)

**Onde fica:** Tela de detalhes do filme → menu ⋮ (três pontos) → "Purge".

Use o **Purge** quando quiser remover completamente um filme **e** liberar o espaço em disco ocupado pelos torrents fonte no qBittorrent. Diferente de "Delete" (que só remove o filme do Radarr, opcionalmente os arquivos importados), o Purge também deleta os **torrents originais** — inclusive **duplicatas cross-seed** — para que o espaço dos dados em hardlink seja efetivamente reclaimado.

**Passo a passo:**
1. Abrir detalhes do filme.
2. Tocar no **menu ⋮** (três pontos) no canto superior direito.
3. Selecionar **"Purge"** (ícone `delete_forever`, texto vermelho).
4. Um **diálogo de confirmação** aparece:
   - Título: `Purge movie`.
   - Mensagem: `This will permanently remove "[Título do filme]" from Radarr, delete its media files, and delete all source torrents (plus cross-seed duplicates) from qBittorrent. Frees disk space used by hardlinked data.`
   - Botões: "Cancel" e "Purge" (botão vermelho).
5. Tocar **"Purge"** para confirmar.
6. Se algum torrent tiver semeado **menos** que os "Minimum seeding days" configurados, aparece o diálogo **"Torrents still seeding"** listando esses torrents, com as opções "Cancel" (aborta tudo), "Keep seeding" (remove o filme e os arquivos, mas mantém esses torrents) e "Delete all" (apaga tudo). Ver `system.md` → "Proteção de torrents".
7. Um **indicador de progresso** (spinner circular) aparece centralizado enquanto o fluxo completo roda — não feche o app durante a operação.
8. Snackbar confirma `Movie purged.` seguido de um resumo multi-linha:
   - `Queue items: N` — itens removidos da fila do Radarr.
   - `Media files: N` — arquivos de mídia que o filme tinha (contados antes da remoção no Radarr).
   - `Torrents: N (+M cross-seed)` — torrents deletados no qBittorrent (+ duplicatas cross-seed aprovadas).
   - Ou `qBittorrent skipped — configure a qBittorrent instance.` se nenhuma instância do qBittorrent estiver configurada (nesse caso só o lado Radarr é afetado).
9. A central de notificações também recebe registros locais do tipo purge para cada torrent removido.
10. Volta automaticamente à lista de filmes (que é recarregada).

**O que o Purge faz, por trás:**
1. Coleta os hashes dos torrents fonte a partir do histórico (eventos grabbed/imported) e da fila do Radarr.
2. Conta os arquivos de mídia do filme (valor apenas informativo, usado no resumo).
3. Remove o filme do Radarr com `deleteFiles: true` — é o próprio Radarr que apaga os arquivos em disco.
4. **Só depois que essa remoção dá certo**, limpa os itens da fila do Radarr (`removeFromClient: true`).
5. Lista os torrents no qBittorrent e deleta os que batem pelo hash, **mais** candidatos a duplicata cross-seed detectados por **nome normalizado**.
6. Para cada candidato cross-seed, o app abre um diálogo com detalhes (nome, hash, tamanho, save path e tags) e você escolhe **Delete** ou **Keep** individualmente.
7. Deleta os torrents aprovados com `deleteFiles: true`. Com hardlinks, o espaço só é liberado quando **todos** os hardlinks dos mesmos dados são removidos — por isso o Purge atua nos dois lados.

**Observações:**
- **Downloads preservados em caso de falha:** a fila e os torrents só são tocados depois que o filme sai do catálogo do Radarr. Se a remoção falhar, o download em andamento continua intacto.
- **Irreversível:** o filme sai do Radarr e os torrents saem do qBittorrent; re-adicionar exige busca manual.
- **Sem blocklist:** como o filme é removido do catálogo, ele deixa de ser monitorado e não é re-grabbed automaticamente.
- **Aprovação manual por duplicata:** candidatos cross-seed só são deletados quando você aprova no diálogo; os não aprovados permanecem no qBittorrent.
- **Sem instância do qBittorrent:** o Purge só atua no lado Radarr; um aviso é exibido no snackbar.
- Se você usa **múltiplas instâncias** de qBittorrent/Radarr/Sonarr, o Purge usa a primeira instância do qBittorrent configurada — pode não ser a correta.

## Deletar arquivo de mídia de um filme — remover arquivo individual

**Onde fica:** Tela de detalhes do filme → seção "Files & Metadata" → ícone de lixeira ao lado do arquivo.

**Passo a passo:**
1. Abrir detalhes do filme.
2. Scroll para a seção **"Files & Metadata"**.
3. Localizar o arquivo desejado (geralmente há um arquivo principal + extras).
4. Tocar no **ícone de lixeira** (🗑️) ao lado do arquivo.
5. Um **diálogo de confirmação** aparece:
   - Mensagem: "Are you sure you want to delete this file?"
   - Botões: "Cancel" e "Delete".
6. Tocar **"Delete"** para confirmar.
7. Snackbar confirma "File deleted successfully".
8. A tela atualiza e o arquivo desaparece da lista.

**Observações:**
- Remove **apenas o arquivo selecionado** do disco do servidor.
- O filme permanece na biblioteca com status **"Missing"** (em vermelho).
- Você pode re-buscar uma nova release tocando em "Search" na tela de detalhes.

## Buscar release manualmente (interactive search/grab) de um filme

**Onde fica:** Tela de detalhes do filme → botão "Search" ou "Manual Search" (ou "Grab").

**Passo a passo:**
1. Abrir detalhes do filme.
2. Localizar e tocar no botão **"Search"** ou **"Interactive Search"** (geralmente no topo da tela ou como botão flutuante).
3. Um **sheet (ReleasesSheet)** abre com lista de releases disponíveis dos indexadores do Radarr:

**Cada release exibe:**
   - **Título/Nome** da release.
   - **Indexer** (qual site: The Pirate Bay, 1337x, etc).
   - **Score** numérico (calculado automaticamente pelo Radarr baseado no perfil de qualidade; maior = melhor).
   - **Seeders** (quantos peers estão fazendo seed da release).
   - **Idade** (quando foi publicada; ex: "2 days ago").
   - **Tamanho** do arquivo (ex: 2.5 GB).

4. **Opções de ordenação** no topo do sheet:
   - Dropdowns para mudar ordem de exibição (Score, Seeders, Age, Size, Indexer).
   - Botão de toggle para Ascending/Descending.
   - A lista reordena instantaneamente.

5. Tocar na **release desejada**.
6. Um **diálogo de confirmação** aparece:
   - Mensagem: "Are you sure you want to grab [título da release]?"
   - Botões: "Cancel" e "Download".
7. Tocar **"Download"** para confirmar.
   - A release é **enviada ao cliente de download** (configurado no Radarr: qBittorrent, Transmission, etc).
   - Snackbar confirma sucesso.
8. Você pode monitorar o progresso indo para **Atividade → Queue**.

**Observações:**
- A lista de releases vem **em tempo real** dos indexadores configurados no Radarr.
- O score é calculado pelo Radarr com base no seu perfil de qualidade; nem sempre a release com maior score é a melhor (considere seeders e tamanho também).
- Uma vez "grabbed", a release entra na fila de download e geralmente é importada automaticamente quando concluída.
- Se a importação falhar automaticamente, você pode usar **Manual Import** em Atividade → Queue.
