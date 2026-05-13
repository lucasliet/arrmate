---
name: series
description: Adicionar/detalhes/episódios/editar/deletar série, deletar arquivo de episódio, deletar todos os arquivos da série ou de uma temporada inteira
---

# Séries

## Adicionar série — buscar e cadastrar no Sonarr

**Onde fica:** Aba Séries → botão "+" (floating action button no canto inferior direito).

**Passo a passo:**
1. Abrir a aba **Séries** (segunda aba da barra inferior).
2. Tocar no botão **"+"** no canto inferior direito (FAB redondo).
3. Um sheet (painel deslizável) abre com título "Add Series".
4. Na barra de busca, digite o título da série (ex: "Breaking Bad", "Game of Thrones").
5. Tocar "Search" ou pressionar Enter no teclado.
6. **Resultados aparecem com:**
   - Poster thumbnail no lado esquerdo.
   - Título em bold.
   - Ano de lançamento.
   - Nota (ex: 9.5/10).
   - Se a série já estiver na sua biblioteca: badge **"In Library"**.
7. Tocar no resultado desejado.
8. O sheet transforma-se na **tela de configuração** (segunda etapa) com:
   - **Monitored:** toggle (padrão ON) — se ON, o Sonarr busca episódios automaticamente.
   - **Series Type:** dropdown com opções:
     - **Standard** (padrão): episódios numerados por temporada e número (S01E01, S01E02).
     - **Anime**: usa numbering absoluto (1, 2, 3...) e geralmente com nomes customizados.
     - **Daily**: episódios numerados por data de exibição (AAAA-MM-DD).
   - **Quality Profile:** dropdown listando perfis do Sonarr.
   - **Root Folder:** dropdown com pastas destino.
   - **Season Folder:** toggle (padrão ON) — se ON, cria pastas por temporada (Season 01, Season 02, etc).
9. Tocar **"Add Series"** (botão no rodapé).
10. Snackbar confirma "Series added successfully" e a lista atualiza.

**Observações:**
- Série é adicionada ao Sonarr imediatamente.
- O tipo de série afeta como o Sonarr renomeia e busca episódios.
- "Season Folder" ON recomendado para organização clara no disco.

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

**3. Files & Metadata:**
- Semelhante a Filmes: lista de arquivos baixados com codec, resolução, tamanho, áudio.
- Ícone de lixeira para deletar arquivos individuais.
- Se houver "extra files" (legendas, etc), listados também.

**4. History:**
- Lista de eventos específicos da série (grab, import, falhas, etc).
- Timestamp relativo para cada evento.
- Tipos coloridos (Grabbed, Imported, Failed, Deleted).

**Botões de ação (AppBar — 4 ícones no canto superior direito):**
1. **Refresh & Scan** (ícone `manage_search`): dispara rescan de arquivos no Sonarr.
2. **Automatic Search** (ícone `travel_explore`): dispara busca automática de releases no Sonarr.
3. **Monitor Toggle** (ícone `bookmark`/`bookmark_border`): alterna monitoramento da série (ON ↔ OFF).
4. **Menu ⋮** (PopupMenuButton):
   - **"Edit"**: abre SeriesEditScreen.
   - **"Delete files"**: apaga todos os arquivos da série em disco (série continua no Sonarr). Desabilitado quando não há arquivos.
   - **"Delete"**: remove a série da biblioteca (diálogo de confirmação com opção de apagar arquivos do disco).

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
- **Botão "Delete season files"** (ícone `delete_sweep` no canto superior direito): apaga todos os arquivos dessa temporada em disco. **Desabilitado** (acinzentado) quando a temporada não tem nenhum episódio com arquivo baixado.

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

5. **Opções por episódio:**
   - Tocar no toggle para monitorar/desmonitorar episódio individual.
   - Tocar no ícone de busca (lupa) para abrir sheet de releases (mesmo padrão de busca do Radarr).
   - Tocar em qualquer lugar do tile para ver **detalhes completos do episódio** (nome, sinopse, elenco, etc).

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
   - Botões: "Cancel" e "Delete" (botão vermelho).
5. Marcar a checkbox **se também quiser apagar os arquivos** em disco.
6. Tocar **"Delete"** para confirmar.
7. Snackbar confirma:
   - "Series deleted" (se checkbox desmarcado), ou
   - "Series and files deleted" (se checkbox marcado).
8. Volta automaticamente à lista de séries.

**Observações:**
- A série é removida do Sonarr imediatamente.
- Arquivos em disco só são apagados se a checkbox estiver marcada.
- Não pode ser desfeito via app (re-adicionar manualmente se necessário).

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
6. Um **indicador de progresso** (spinner circular) aparece centralizado enquanto o app apaga os arquivos um por um — não feche o app durante essa operação.
7. Snackbar confirma:
   - `Deleted N file(s)` (com a contagem real de arquivos apagados), ou
   - `No files to delete` (se não havia arquivos).

**Observações:**
- A série **permanece** cadastrada no Sonarr — apenas os arquivos físicos são removidos.
- Todos os episódios passam para status "Missing" (vermelho).
- Se a série estiver monitorada, o Sonarr voltará a buscar releases automaticamente.
- A operação pode demorar alguns segundos em séries com muitos episódios (cada arquivo é apagado em sequência).

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
