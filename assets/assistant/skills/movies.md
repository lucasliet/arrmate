---
name: movies
description: Adicionar/detalhes/editar/deletar filme, deletar arquivo, buscar release
---

# Filmes

## Adicionar filme — buscar e cadastrar no Radarr

**Onde fica:** Aba Filmes → botão "+" (floating action button no canto inferior direito).

**Passo a passo:**
1. Abrir a aba Filmes (primeira aba da barra inferior).
2. Tocar no botão **"+"** no canto inferior direito (FAB redondo).
3. Um sheet (painel deslizável) abre com título "Add Movie".
4. Na barra de busca, digite o título do filme (ex: "Inception", "The Matrix").
5. Tocar "Search" ou pressionar Enter no teclado.
6. **Resultados aparecem com:**
   - Poster thumbnail no lado esquerdo.
   - Título em bold.
   - Ano de lançamento.
   - Nota TMDB (ex: 8.5/10).
   - Se o filme já estiver na sua biblioteca: badge **"In Library"** aparece no topo-direito do item.
7. Tocar no resultado desejado.
8. O sheet transforma-se na **tela de configuração** (segunda etapa) com:
   - **Monitored:** toggle (padrão ON) — se ON, o Radarr busca ativamente releases.
   - **Minimum Availability:** dropdown com opções:
     - Announced (filme anunciado mas ainda não lançado).
     - In Cinemas (lançado em cinemas).
     - Released (lançado em qualquer formato).
   - **Quality Profile:** dropdown listando perfis de qualidade do Radarr (ex: "1080p", "4K").
   - **Root Folder:** dropdown com pastas destino do Radarr (ex: "/movies", "/media/movies").
9. Tocar **"Add Movie"** (botão no rodapé).
10. Snackbar confirma "Movie added successfully" e a lista volta a atualizar automaticamente.

**Observações:**
- O filme é adicionado ao Radarr imediatamente. 
- A busca automática de releases no Radarr depende da configuração do Radarr (pode ser imediata ou agendada).
- Você pode voltar ao resultado anterior tocando no ícone de voltar/chevron (se houver).

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
     - **"Delete"** → abre diálogo de confirmação com título "Delete Movie?", checkbox "Delete files from disk" (opcional), botões "Cancel" e "Delete" (vermelho).
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
   - **"Delete"**: abre diálogo "Delete Movie?" com checkbox "Delete files from disk" (opcional), botões "Cancel" e "Delete" (vermelho).

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
   - Botões: "Cancel" e "Delete" (em vermelho).
5. Marcar ou deixar desmarcado o checkbox conforme desejado.
6. Tocar **"Delete"** para confirmar.
7. Snackbar confirma "Movie deleted successfully" e a tela volta à lista de filmes.

**Observações:**
- O filme é removido do Radarr imediatamente.
- Os arquivos em disco são removidos **somente se** o checkbox "Delete files from disk" estiver marcado.
- Esta ação é destrutiva e não pode ser desfeita via app (você pode re-adicionar o filme manualmente).

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
