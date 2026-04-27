---
name: series
description: Adicionar/detalhes/episódios/editar/deletar série, deletar arquivo de episódio
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
     - **"Delete"** → abre diálogo de confirmação com botões "Cancel" e "Delete" (vermelho).
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
   - **"Delete"**: remove a série da biblioteca (diálogo de confirmação).

**Observações:**
- Tocar em uma temporada abre a tela **SeasonDetailsScreen** (tela cheia) com a lista de episódios. Use a seta de voltar para retornar aos detalhes da série.
- Você pode monitorar/desmonitorar temporadas individuais sem deletá-las.

## Episódios e temporadas — monitorar e buscar release

**Onde fica:** Detalhes da série → seção "Seasons" → tocar em uma temporada.

**Passo a passo:**
1. Abrir detalhes da série (tocando na série na lista).
2. Scroll para a seção **"Seasons"**.
3. Tocar em uma temporada (ex: "Season 1").
4. A tela **SeasonDetailsScreen** abre em tela cheia exibindo lista de episódios (use a seta de voltar para retornar aos detalhes da série):

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
   - Mensagem: "Are you sure you want to delete this series?"
   - Botões: "Cancel" e "Delete" (em vermelho).
5. Tocar **"Delete"** para confirmar.
6. Snackbar confirma "Series deleted successfully" e volta à lista de séries.

**Observações:**
- A série é removida do Sonarr imediatamente.
- Os arquivos em disco **podem ou não ser removidos** dependendo da configuração do Sonarr.
- Não pode ser desfeito via app (re-adicionar manualmente se necessário).

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
