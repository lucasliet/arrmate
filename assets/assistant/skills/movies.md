---
name: movies
description: Adicionar/detalhes/editar/deletar filme, deletar arquivo, buscar release
---

# Filmes

## Adicionar filme — buscar e cadastrar no Radarr

**Onde fica:** Aba Filmes → botão "+" (floating action button no canto inferior direito).

**Passo a passo:**
1. Abrir a aba Filmes.
2. Tocar no botão "+" no canto inferior direito.
3. Na barra de busca, digitar o título do filme (ex: "Inception").
4. Tocar "Search" ou pressionar Enter.
5. Resultados aparecem com poster, título, ano e nota TMDB.
6. Se o filme já estiver na biblioteca, aparece badge "In Library".
7. Tocar no resultado desejado.
8. Configurar:
   - **Monitored:** toggle ON (padrão) = buscar ativamente releases.
   - **Minimum Availability:** Announced, In Cinemas ou Released.
   - **Quality Profile:** selecionar perfil de qualidade do Radarr.
   - **Root Folder:** selecionar pasta de destino.
9. Tocar "Add Movie".
10. Snackbar confirma "Movie added successfully" e a lista atualiza.

**Observações:** O filme é adicionado no Radarr. A busca automática de release depende da configuração do Radarr.

## Detalhes do filme — sinopse arquivos histórico ações

**Onde fica:** Aba Filmes → tocar em qualquer filme.

Ao tocar em um filme, abre a tela de detalhes com:

- **AppBar expansível** com fanart de fundo e botão de voltar.
- **Poster e informações:** título, ano, nota, gêneros, badges de status (Downloaded, Missing, Unmonitored).
- **Seções:**
  - Overview: sinopse, direção, elenco, runtime, links IMDb/TVDb.
  - Files & Metadata: codec de vídeo, resolução, tamanho, áudio, extra files (legendas).
  - History: eventos específicos do filme (grab, import, falhas).
- **Ações disponíveis:**
  - Edit: abrir formulário de edição do filme.
  - Search/Grab: abrir busca manual de releases.
  - Search Now: disparar busca automática no Radarr.
  - Delete: deletar o filme da biblioteca (menu ⋮).

**Observações:** A seção Files mostra todos os arquivos de mídia associados. É possível deletar arquivos individuais com confirmação.

## Editar filme — monitoramento qualidade pasta raiz disponibilidade

**Onde fica:** Tela de detalhes do filme → botão "Edit".

**Passo a passo:**
1. Abrir detalhes do filme.
2. Tocar em "Edit".
3. Alterar campos:
   - **Monitored:** toggle ON/OFF (OFF = não busca releases).
   - **Minimum Availability:** Announced, In Cinemas, Released.
   - **Quality Profile:** trocar perfil de qualidade.
   - **Root Folder:** trocar pasta de destino.
4. Se a pasta raiz foi alterada e o filme tem arquivos baixados: aparece diálogo "Move Files?".
   - "Yes" = mover arquivos fisicamente para a nova pasta.
   - "No" = apenas atualizar o banco de dados.
5. Tocar "Save".

## Deletar filme da biblioteca — remover do Radarr

**Onde fica:** Tela de detalhes do filme → menu ⋮ (três pontos) → "Delete".

**Passo a passo:**
1. Abrir detalhes do filme.
2. Tocar no menu ⋮ (três pontos) no canto superior direito.
3. Selecionar "Delete" (em vermelho).
4. Confirmar no diálogo "Are you sure you want to delete this movie?".
5. Tocar "Delete" para confirmar.
6. Snackbar confirma "Movie deleted" e volta para a lista de filmes.

**Observações:** O filme é removido do Radarr. Os arquivos em disco podem ou não ser removidos dependendo da configuração do Radarr.

## Deletar arquivo de mídia de um filme — remover arquivo individual

**Onde fica:** Tela de detalhes do filme → seção "Files & Metadata" → ícone de lixeira ao lado do arquivo.

**Passo a passo:**
1. Abrir detalhes do filme.
2. Na seção "Files & Metadata", localizar o arquivo desejado.
3. Tocar no ícone de lixeira ao lado do arquivo.
4. Confirmar a exclusão no diálogo.
5. Snackbar confirma sucesso.

**Observações:** Remove apenas o arquivo selecionado do disco. O filme permanece na biblioteca como "Missing".

## Buscar release manualmente (grab) de um filme

**Onde fica:** Tela de detalhes do filme → botão "Search" ou "Grab".

**Passo a passo:**
1. Abrir detalhes do filme.
2. Tocar no botão "Search" ou "Grab".
3. Sheet de releases aparece com lista de resultados dos indexadores.
4. Cada release mostra: título, indexer, score, seeders, idade, tamanho.
5. Ordenar por: Score (padrão), Seeders, Age, Size, Indexer (asc/desc).
6. Tocar na release desejada.
7. Confirmar no diálogo: "Are you sure you want to grab [título]?".
8. Tocar "Download" para confirmar.
9. A release é enviada ao cliente de download.
10. Monitorar progresso em Atividade → Queue.

**Observações:** A lista de releases vem dos indexadores configurados no Radarr. O score é calculado automaticamente pelo Radarr com base no perfil de qualidade.
