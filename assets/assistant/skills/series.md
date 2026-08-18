---
name: series
description: Adicionar/detalhes/episódios/editar/deletar série, discover busca por título ID URL TVDB IMDb, deletar arquivo de episódio, deletar todos os arquivos da série ou de uma temporada inteira, purge (remover série + arquivos + torrents no qBittorrent), import exclusion
---

# Séries

## Adicionar série — buscar e cadastrar no Sonarr

**Onde fica:** Aba Séries → botão "+" (floating action button no canto inferior direito).

> **Atalho:** o "+" abre a tela **Discover** já em modo série. Veja a seção "Adicionar via Discover" abaixo para busca por título, ID TVDB/IMDb ou URL.

**Passo a passo:**
1. Abrir a aba **Séries** (segunda aba da barra inferior).
2. Tocar no botão **"+"** no canto inferior direito (FAB redondo).
3. Abre a tela **Discover** com AppBar "Add Series" e ícone **X** ("Close") à direita para sair.
4. No campo **"Search"**, digite o título da série (ex: "Breaking Bad", "Game of Thrones").
5. A busca roda sozinha com debounce enquanto você digita; pressionar Enter dispara a busca imediatamente.
6. **Resultados aparecem com:**
   - Poster thumbnail no lado esquerdo.
   - Título da série.
   - Subtítulo com ano e nota (ex: "2008 · 9.5"), ou "No rating" quando não há nota.
   - Séries que **já estão na biblioteca** mostram um ✅ **check verde** no lugar do chevron; tocar nelas **abre a série na biblioteca** em vez de adicionar.
7. Tocar em um resultado ainda não adicionado.
8. Abre a etapa **"Series Preview"** (AppBar com esse título e seta de voltar): poster grande, "Título (Ano)", linha com certificação · emissora · gêneros, sinopse e botão **"Configure Addition"**.
9. Tocar em **"Configure Addition"** para abrir a etapa final (AppBar com o título da série, seta de voltar e botão **"Add"** à direita):
   - **Monitor:** dropdown com All Episodes, Future Episodes, Missing Episodes, Existing Episodes, Recent Episodes, Pilot Episode, etc.
   - **Monitor New Seasons:** switch — se ON, novas temporadas entram monitoradas.
   - **Series Type:** dropdown com opções:
     - **Standard** (padrão): episódios numerados por temporada e número (S01E01, S01E02).
     - **Anime**: usa numbering absoluto (1, 2, 3...) e geralmente com nomes customizados.
     - **Daily**: episódios numerados por data de exibição (AAAA-MM-DD).
   - **Season Folder:** switch (padrão ON) — se ON, cria pastas por temporada (Season 01, Season 02, etc).
   - **Quality Profile:** dropdown listando perfis do Sonarr.
   - **Root Folder:** dropdown com pastas destino.
   - **Tags:** chips das tags da instância (aparece só quando o Sonarr tem tags cadastradas).
10. Tocar **"Add"** no canto superior direito (vira spinner enquanto envia).
11. Snackbar confirma "Series added successfully" e a lista atualiza.

**Observações:**
- Série é adicionada ao Sonarr imediatamente.
- O tipo de série afeta como o Sonarr renomeia e busca episódios.
- "Season Folder" ON recomendado para organização clara no disco.
- Se faltar quality profile ou root folder, o app avisa "Please select a series, quality profile, and root folder" e não envia.

## Adicionar via Discover — busca por título ID ou URL

**Onde fica:** Aba Séries → botão "+" (FAB) → abre a tela **Discover** em modo série.

A tela **Discover** abre **direto no tipo de mídia da aba de origem** — o "+" da aba Séries busca séries, o "+" da aba Filmes busca filmes. Não há abas Movies/Series dentro da tela: para adicionar um filme, use o "+" da aba Filmes. A busca aceita não só o título, mas também identificadores e links.

**Layout da tela:**
- **AppBar** com título "Add Series" e ícone **X** ("Close").
- Campo **"Search"** com exemplos no hint (`Breaking Bad, tvdb:81189, imdb:tt0903747`).
- Dropdown **"Sort"** e chip **"Hide already added"** logo abaixo (empilhados em telas muito estreitas).

**Como buscar:**
- **Por título:** digite o nome (ex: "Severance") — a busca tem debounce e roda automaticamente enquanto você digita.
- **Por ID TVDB/IMDb:** cole o identificador (ex: `tt11280740`, o ID do TVDB).
- **Por URL:** cole um link do IMDb ou TVDB — o app extrai o ID embutido na URL e faz o lookup.

**Resultados:**
- Cada resultado mostra poster, título, ano e nota.
- Resultados que já estão na sua biblioteca aparecem marcados como existentes.
- Use o chip **"Hide already added"** para ocultar itens que você já tem.
- Use o **dropdown "Sort"** para reordenar por relevância, data ou avaliação.

**Adicionar:**
- Toque em um resultado para abrir o "Series Preview" e depois "Configure Addition" (Monitor, Monitor New Seasons, Series Type, Season Folder, Quality Profile, Root Folder, Tags) — mesmas etapas do fluxo padrão.
- Em seguida, toque em **"Add"** no canto superior direito.

**Observações:**
- O tipo de mídia do Discover vem do parâmetro `type` do deep link: `arrmate:///discover?type=series` ou `arrmate:///search?q=<termo>&type=series` (sem o parâmetro, o padrão é filme).
- A extração de ID funciona para os formatos de URL mais comuns do IMDb e TVDB.

## Detalhes da série — temporadas episódios histórico

**Onde fica:** Aba Séries → tocar em qualquer série (no grid ou na lista).

Ao tocar em uma série, abre a tela **SeriesDetailsScreen** com layout em scroll vertical:

**AppBar (topo expansível):**
- **Fanart** (imagem de fundo grande) que encolhe conforme scroll.
- **Ícone de voltar** (seta) no canto superior esquerdo.
- **4 ícones de ação** no canto superior direito (da esquerda para direita):
  1. **Refresh & Scan** (ícone `manage_search`) — tooltip "Refresh & Scan" — dispara rescan de arquivos no Sonarr.
  2. **Automatic Search** (ícone `travel_explore`) — tooltip "Automatic Search" — dispara busca automática de releases.
  3. **Monitor Toggle** (ícone `bookmark` preenchido / `bookmark_border`) — tooltip "Monitor" ou "Unmonitor" — alterna monitoramento da série.
  4. **Menu** (ícone ⋮ PopupMenuButton) — opções:
     - **"Edit"** → abre SeriesEditScreen.
     - **"Delete files"** (ícone `delete_sweep`) → apaga todos os arquivos da série em disco, mas mantém a série cadastrada no Sonarr. Fica **desabilitado** (acinzentado) quando a série não tem nenhum arquivo baixado.
     - **"Delete"** (texto vermelho) → abre diálogo de confirmação com checkbox **"Also delete files from disk"** (apagar também arquivos do disco) e botões "Cancel" e "Delete" (vermelho).
     - **"Purge"** (ícone `delete_forever`, texto vermelho) → remove tudo (catálogo + arquivos + torrents fonte no qBittorrent, incluindo duplicatas cross-seed) para liberar o espaço em disco usado por dados com hardlink. Ver seção "Purge série — remover tudo (Sonarr + qBittorrent)".
- Título da série fica visível no topo conforme scroll.

**Poster e informações principais:**
- **Poster** no lado esquerdo.
- **Título** em bold.
- **Ano** de início.
- **Nota/Rating** (ex: 9.5/10).
- **Gêneros** (tags coloridas: "Drama", "Crime", etc).
- **Status** (ex: "Continuing" ou "Ended").
- **Network** (canal: "AMC", "HBO", etc).
- **Próxima exibição** (se série está em produção: data e hora do próximo episódio).
- **Badges de status** (coloridos):
  - Indicadores de quantos episódios estão baixados vs. faltando.

**Seções abaixo (scroll):**

**1. Overview:**
- Sinopse/resumo da série.
- Contagem de temporadas e episódios totais.
- Status (Continuing/Ended).
- Informações de produção: criadores, elenco.
- Links externos (IMDb, TVDb, TheMovieDb).

**2. Seasons:**
- **Botões no topo** (texto pequeno, não FAB):
  - **"All"**: monitora todas as temporadas de uma vez.
  - **"None"**: remove monitoramento de todas as temporadas de uma vez.
- Lista de **todas as temporadas** em cards/tiles:
  - Cada temporada mostra:
    - **Número** (ex: "Season 1", "Season 2").
    - **Contagem de episódios** (ex: "10 episodes").
    - **Indicador circular de progresso** mostrando quantos episódios estão baixados vs. total.
    - **Botão de ícone** (bookmark) ao lado — toque para monitorar/desmonitorar aquela temporada individualmente.
  - Toque em uma temporada para **abrir a tela completa SeasonDetailsScreen** (tela cheia com seta de voltar para retornar aos detalhes da série).

**3. Torrents:**
- Só aparece quando há uma instância qBittorrent configurada.
- Lista os torrents do cliente que sustentam a série, resolvidos pelo histórico da própria série (eventos **Grabbed** e **Imported**) casado com os infohashes do qBittorrent — season packs incluídos.
- Inclui as cópias **cross-seed** do mesmo release (mesmo nome, infohash diferente), marcadas com o badge "Cross-seed".
- Tocar em um card abre a ficha de detalhes do torrent (pausar, retomar, rechecar, arquivos, peers). O botão "Open in library" não aparece — você já está na tela da série.
- Se nada for encontrado: "No torrents in the download client".

**Arquivos e histórico:** diferente de Filmes, a tela da série **não** tem seções "Files & Metadata" nem "History" no nível da série. Os arquivos e o histórico ficam por episódio: Seasons → temporada → tocar no episódio abre a ficha com o arquivo, os torrents e o histórico daquele episódio.

**Botões de ação (AppBar — 4 ícones no canto superior direito):**
1. **Refresh & Scan** (ícone `manage_search`): dispara rescan de arquivos no Sonarr.
2. **Automatic Search** (ícone `travel_explore`): dispara busca automática de releases no Sonarr.
3. **Monitor Toggle** (ícone `bookmark`/`bookmark_border`): alterna monitoramento da série (ON ↔ OFF).
4. **Menu ⋮** (PopupMenuButton):
   - **"Edit"**: abre SeriesEditScreen.
   - **"Delete files"**: apaga todos os arquivos da série em disco (série continua no Sonarr). Desabilitado quando não há arquivos.
   - **"Delete"**: remove a série da biblioteca (diálogo de confirmação com opção de apagar arquivos do disco).
   - **"Purge"** (vermelho): remove catálogo + arquivos + torrents fonte no qBittorrent (incl. cross-seed). Libera espaço de dados com hardlink.

**Observações:**
- Tocar em uma temporada abre a tela **SeasonDetailsScreen** (tela cheia) com a lista de episódios. Use a seta de voltar para retornar aos detalhes da série.
- Você pode monitorar/desmonitorar temporadas individuais sem deletá-las.

## Episódios e temporadas — monitorar e buscar release

**Onde fica:** Detalhes da série → seção "Seasons" → tocar em uma temporada.

**Passo a passo:**
1. Abrir detalhes da série (tocando na série na lista).
2. Scroll para a seção **"Seasons"**.
3. Tocar em uma temporada (ex: "Season 1").
4. A tela **SeasonDetailsScreen** abre em tela cheia exibindo lista de episódios (use a seta de voltar para retornar aos detalhes da série).

**AppBar da SeasonDetailsScreen:**
- **Título**: "[Nome da série] - Season [N]".
- **Botão "Automatic Search"** (ícone `travel_explore` no canto superior direito): dispara busca automática de releases para toda a temporada.
- **Botão "Interactive Search"** (ícone `troubleshoot` no canto superior direito): abre a busca manual de releases da temporada (lista de releases com ordenação e ação de download).
- **Botão "Delete season files"** (ícone `delete_sweep` no canto superior direito): apaga todos os arquivos dessa temporada em disco. **Desabilitado** (acinzentado) quando a temporada não tem nenhum episódio com arquivo baixado.
- **Botão "Purge season"** (ícone `delete_forever` no canto superior direito): remove episódios e arquivos da temporada no Sonarr e também remove torrents fonte no qBittorrent (com aprovação individual de cross-seed).

**Cada episódio exibe:**
   - **Número do episódio** (ex: "S01E01", "S01E02").
   - **Título** do episódio em bold.
   - **Data de exibição** (ex: "May 20, 2008").
   - **Ícone/Badge de status:**
     - 🟢 Verde = baixado/importado.
     - 🔴 Vermelho = monitorado mas faltando.
     - ⚫ Cinza = não monitorado.
     - 🔵 Azul = próximo a exibir.
   - **Toggle de monitoramento** (ao lado do episódio) — ON/OFF.
   - **Ícone de busca** (lupa) para buscar manualmente esse episódio.

5. **Opções da temporada e por episódio:**
   - Tocar em **Automatic Search** na AppBar para buscar releases da temporada inteira.
   - Tocar em **Interactive Search** na AppBar para abrir o sheet de releases da temporada com ordenação por score/seeders/idade/tamanho/indexador.
   - Tocar no toggle para monitorar/desmonitorar episódio individual.
   - Tocar no ícone de busca (lupa) para abrir sheet de releases de um episódio específico.
   - Tocar em qualquer lugar do tile para ver **detalhes completos do episódio** (nome, sinopse, elenco, etc). A ficha do episódio traz, entre o arquivo e o histórico, uma seção **Torrents** com os torrents do cliente que sustentam aquele episódio — um season pack aparece em todos os episódios que ele cobre, e cópias cross-seed vêm marcadas com o badge "Cross-seed". Tocar em um card abre a ficha do torrent.

6. Se tocou em uma release na busca:
   - Diálogo: "Are you sure you want to grab [título da release]?"
   - Tocar "Download" para confirmar.
   - A release é enviada ao cliente de download.
   - Monitore em Atividade → Queue.

**Observações:**
- A busca de release por episódio funciona **exatamente igual** à de Filmes.
- Você pode monitorar/desmonitorar episódios individuais ou em massa (via temporada).
- Status de episódio reflete o estado no Sonarr em tempo real.

## Editar série — tipo monitoramento qualidade pasta raiz pasta de temporada

**Onde fica:** Tela de detalhes da série → botão "Edit" ou menu ⋮ → "Edit".

**Passo a passo:**
1. Abrir detalhes da série.
2. Tocar em **"Edit"** (ícone de lápis) ou acessar via menu ⋮.
3. Abre a tela **SeriesEditScreen** com campos editáveis:

**Campos disponíveis:**
   - **Monitored:** toggle ON/OFF.
     - ON: o Sonarr busca episódios ativamente.
     - OFF: o Sonarr ignora a série.
   - **Series Type:** dropdown com opções (Standard, Anime, Daily).
     - Afeta renomeação e numbering de episódios no disco.
     - **Standard:** S##E## (ex: S01E05).
     - **Anime:** numbering absoluto + nomes customizados.
     - **Daily:** data de exibição (ex: 2008-05-20).
   - **Quality Profile:** dropdown com perfis do Sonarr.
     - Define qualidade para futuras buscas de episódios.
   - **Root Folder:** dropdown com pastas destino.
     - Pasta raiz onde a série será armazenada (ou movida).
   - **Season Folder:** toggle ON/OFF.
     - ON: cria pastas por temporada (Season 01, Season 02).
     - OFF: todos episódios na pasta raiz da série.

4. Se você **alterou Root Folder** e há episódios já baixados:
   - Um **diálogo de confirmação** aparece: "Move Files?"
   - **"Yes":** Move arquivos fisicamente.
   - **"No":** Apenas atualiza banco de dados.

5. Tocar **"Save"** (ícone de checkmark ou botão no rodapé).
   - Snackbar confirma "Series updated successfully".

**Observações:**
- Tipo de série é importante: mudar de Standard para Anime afeta toda a estrutura de nomeação.
- Season Folder ON recomendado para organização clara.

## Deletar série da biblioteca — remover do Sonarr

**Onde fica:** Tela de detalhes da série → menu ⋮ (três pontos) → "Delete".

**Passo a passo:**
1. Abrir detalhes da série.
2. Tocar no **menu ⋮** (três pontos) no canto superior direito.
3. Selecionar **"Delete"** (texto em vermelho).
4. Um **diálogo de confirmação** aparece:
   - Mensagem: `Are you sure you want to delete "[Título da série]"?`
   - **Checkbox "Also delete files from disk"** (apagar também arquivos do disco) — desmarcado por padrão.
   - **Checkbox "Add import exclusion list"** (opcional) — se marcado, adiciona a série à lista de exclusão do Sonarr (`addImportListExclusion`), impedindo que ela seja re-importada automaticamente por listas/import lists no futuro.
   - Botões: "Cancel" e "Delete" (botão vermelho).
5. Marcar as checkboxes **se também quiser apagar os arquivos** em disco e/ou adicionar a exclusão.
6. Tocar **"Delete"** para confirmar.
7. Snackbar confirma:
   - "Series deleted" (se checkbox desmarcado), ou
   - "Series and files deleted" (se checkbox marcado).
8. Volta automaticamente à lista de séries.

**Observações:**
- A série é removida do Sonarr imediatamente.
- Arquivos em disco só são apagados se a checkbox estiver marcada.
- **Import exclusion** é útil quando você não quer que a série volte automaticamente via listas de importação — ela permanece na exclusion list do Sonarr até você removê-la de lá (pela web do Sonarr).
- Não pode ser desfeito via app (re-adicionar manualmente se necessário).

## Purge série — remover tudo (Sonarr + qBittorrent)

**Onde fica:** Tela de detalhes da série → menu ⋮ (três pontos) → "Purge".

Use o **Purge** quando quiser remover completamente uma série **e** liberar o espaço em disco ocupado pelos torrents fonte no qBittorrent. Diferente de "Delete" (que só remove a série do Sonarr, opcionalmente os arquivos importados), o Purge também deleta os **torrents originais** — inclusive **duplicatas cross-seed** — para que o espaço dos dados em hardlink seja efetivamente reclaimado.

**Passo a passo:**
1. Abrir detalhes da série.
2. Tocar no **menu ⋮** (três pontos) no canto superior direito.
3. Selecionar **"Purge"** (ícone `delete_forever`, texto vermelho).
4. Um **diálogo de confirmação** aparece:
   - Título: `Purge series`.
   - Mensagem: `This will permanently remove "[Título da série]" and all its episodes from Sonarr, delete its media files, and delete all source torrents (plus cross-seed duplicates) from qBittorrent. Frees disk space used by hardlinked data.`
   - Botões: "Cancel" e "Purge" (botão vermelho).
5. Tocar **"Purge"** para confirmar.
6. Se algum torrent tiver semeado **menos** que os "Minimum seeding days" configurados, aparece o diálogo **"Torrents still seeding"** listando esses torrents, com as opções "Cancel" (aborta tudo), "Keep seeding" (remove a série e os arquivos, mas mantém esses torrents) e "Delete all" (apaga tudo). Ver `system.md` → "Proteção de torrents".
7. Um **indicador de progresso** (spinner circular) aparece centralizado enquanto o fluxo completo roda — não feche o app durante a operação.
8. Snackbar confirma `Series purged.` seguido de um resumo multi-linha:
   - `Queue items: N` — itens removidos da fila do Sonarr.
   - `Media files: N` — arquivos de mídia que a série tinha (contados antes da remoção no Sonarr).
   - `Torrents: N (+M cross-seed)` — torrents deletados no qBittorrent (+ duplicatas cross-seed aprovadas).
   - Ou `qBittorrent skipped — configure a qBittorrent instance.` se nenhuma instância do qBittorrent estiver configurada (nesse caso só o lado Sonarr é afetado).
9. A central de notificações também recebe registros locais do tipo purge para cada torrent removido.
10. Volta automaticamente à lista de séries (que é recarregada).

**O que o Purge faz, por trás:**
1. Coleta os hashes dos torrents fonte a partir do histórico (eventos grabbed/imported) e da fila do Sonarr.
2. Conta os arquivos de mídia da série (valor apenas informativo, usado no resumo).
3. Remove a série do Sonarr com `deleteFiles: true` — é o próprio Sonarr que apaga os arquivos em disco.
4. **Só depois que essa remoção dá certo**, limpa os itens da fila do Sonarr (`removeFromClient: true`).
5. Lista os torrents no qBittorrent e deleta os que batem pelo hash, **mais** candidatos a duplicata cross-seed detectados por **nome normalizado**.
6. Para cada candidato cross-seed, o app abre um diálogo com detalhes (nome, hash, tamanho, save path e tags) e você escolhe **Delete** ou **Keep** individualmente.
7. Deleta os torrents aprovados com `deleteFiles: true`. Com hardlinks, o espaço só é liberado quando **todos** os hardlinks dos mesmos dados são removidos — por isso o Purge atua nos dois lados.

**Observações:**
- **Downloads preservados em caso de falha:** a fila e os torrents só são tocados depois que a série sai do catálogo do Sonarr. Se a remoção falhar, o download em andamento continua intacto.
- **Irreversível:** a série sai do Sonarr e os torrents saem do qBittorrent; re-adicionar exige busca manual.
- **Sem blocklist:** como a série é removida do catálogo, ela deixa de ser monitorada e não é re-grabbed automaticamente.
- **Aprovação manual por duplicata:** candidatos cross-seed só são deletados quando você aprova no diálogo; os não aprovados permanecem no qBittorrent.
- **Sem instância do qBittorrent:** o Purge só atua no lado Sonarr; um aviso é exibido no snackbar.
- Se você usa **múltiplas instâncias** de qBittorrent/Radarr/Sonarr, o Purge usa a primeira instância do qBittorrent configurada — pode não ser a correta.

## Deletar todos os arquivos da série — manter série no Sonarr

**Onde fica:** Tela de detalhes da série → menu ⋮ (três pontos) → "Delete files".

Use esta opção quando quiser **liberar espaço em disco** mas continuar acompanhando a série no Sonarr (ex.: para baixar novamente em qualidade diferente, ou aguardar nova temporada).

**Passo a passo:**
1. Abrir detalhes da série.
2. Tocar no **menu ⋮** (três pontos) no canto superior direito.
3. Selecionar **"Delete files"** (ícone `delete_sweep`).
   - Se a opção estiver **acinzentada/desabilitada**, é porque a série não tem nenhum arquivo baixado.
4. Um **diálogo de confirmação** aparece:
   - Mensagem: `Delete all files for "[Título da série]"? This removes every episode file from disk; the series stays in Sonarr.`
   - Botões: "Cancel" e "Delete" (botão vermelho).
5. Tocar **"Delete"** para confirmar.
6. Um **indicador de progresso** (spinner circular) aparece centralizado enquanto o app apaga os arquivos — não feche o app durante essa operação.
7. Snackbar confirma:
   - `Deleted N file(s)` (com a contagem real de arquivos apagados), ou
   - `No files to delete` (se não havia arquivos).

**Observações:**
- A série **permanece** cadastrada no Sonarr — apenas os arquivos físicos são removidos.
- Todos os episódios passam para status "Missing" (vermelho).
- Se a série estiver monitorada, o Sonarr voltará a buscar releases automaticamente.
- A remoção é feita em **uma única chamada em lote** ao Sonarr (endpoint bulk de episode files), então costuma ser rápida mesmo em séries grandes.

## Purge de temporada — remover temporada + arquivos + torrents fonte

**Onde fica:** SeasonDetailsScreen → botão "Purge season" (ícone `delete_forever` na AppBar).

Use esta opção quando quiser remover completamente uma temporada específica, incluindo episódios no Sonarr, arquivos em disco e torrents fonte no qBittorrent.

**Passo a passo:**
1. Abrir detalhes da série.
2. Scroll para **"Seasons"** e tocar na temporada desejada.
3. Na AppBar da SeasonDetailsScreen, tocar no ícone **"Purge season"** (`delete_forever`).
4. Um **diálogo de confirmação** aparece explicando que a operação remove episódios/arquivos da temporada e torrents fonte no qBittorrent.
5. Tocar **"Purge"** para confirmar.
6. Se algum torrent tiver semeado menos que os "Minimum seeding days", aparece o diálogo **"Torrents still seeding"** com as opções "Cancel", "Keep seeding" e "Delete all".
7. Se houver candidatos cross-seed, o app abre uma sequência de diálogos para aprovação individual (**Delete**/**Keep**) de cada duplicata.
8. **Indicador de progresso** (spinner) aparece durante a execução completa.
9. Snackbar confirma o purge com resumo da quantidade de arquivos e torrents removidos.

**Observações:**
- A operação atua apenas na temporada selecionada; o restante da série permanece no Sonarr.
- A central de notificações recebe registros locais do tipo purge para cada torrent removido.
- Se não houver instância qBittorrent configurada, somente o lado Sonarr é afetado e um aviso é exibido.

## Deletar arquivos de uma temporada inteira

**Onde fica:** SeasonDetailsScreen → botão "Delete season files" (ícone `delete_sweep` na AppBar).

Use esta opção quando quiser **apagar todos os arquivos de uma temporada específica** sem afetar as demais.

**Passo a passo:**
1. Abrir detalhes da série.
2. Scroll para **"Seasons"** e tocar na temporada desejada.
3. Na AppBar da SeasonDetailsScreen, tocar no ícone **"Delete season files"** (`delete_sweep`).
   - Se o ícone estiver **acinzentado/desabilitado**, é porque a temporada não tem nenhum episódio com arquivo.
4. Um **diálogo de confirmação** aparece:
   - Mensagem: `Delete all files for "[Título da série] - Season [N]"? This removes every episode file in this season from disk.`
   - Botões: "Cancel" e "Delete" (botão vermelho).
5. Tocar **"Delete"** para confirmar.
6. **Indicador de progresso** (spinner) aparece enquanto os arquivos são apagados.
7. Snackbar confirma `Deleted N file(s)`.

**Observações:**
- Apenas arquivos da temporada selecionada são afetados — outras temporadas permanecem intactas.
- Funciona corretamente com **arquivos multi-episódio** (um arquivo que cobre vários episódios é contado e apagado uma única vez).
- Episódios apagados ficam com status "Missing" e podem ser re-baixados normalmente.

## Deletar arquivo de mídia de episódio — remover arquivo individual

**Onde fica:** Detalhes da série → temporada → episódio → ícone de lixeira.

**Passo a passo:**
1. Abrir detalhes da série.
2. Scroll para **"Seasons"**.
3. Tocar em uma temporada.
4. Na lista de episódios, tocar no episódio que possui arquivo (status verde = "Downloaded").
5. Um **sheet de detalhes do episódio** abre mostrando:
   - Título, número, sinopse.
   - Arquivo(s) associado(s) com codec, resolução, tamanho.
6. Tocar no **ícone de lixeira** (🗑️) ao lado do arquivo.
7. Um **diálogo de confirmação** aparece.
8. Tocar **"Delete"** para confirmar.
9. Snackbar confirma "File deleted successfully".
10. O episódio agora mostra status **"Missing"** (vermelho).

**Observações:**
- Remove **apenas o arquivo selecionado**.
- O episódio permanece na biblioteca com status "Missing".
- Você pode re-buscar uma release tocando no ícone de busca (lupa) do episódio.
