---
name: series
description: Adicionar/detalhes/episódios/editar/deletar série, deletar arquivo de episódio
---

# Séries

## Adicionar série — buscar e cadastrar no Sonarr

**Onde fica:** Aba Séries → botão "+" (floating action button no canto inferior direito).

**Passo a passo:**
1. Abrir a aba Séries.
2. Tocar no botão "+" no canto inferior direito.
3. Digitar o título da série na barra de busca.
4. Tocar "Search" ou Enter.
5. Resultados aparecem com poster, título, ano e nota.
6. Tocar no resultado desejado.
7. Configurar:
   - **Monitored:** toggle ON (padrão).
   - **Series Type:** Standard (padrão), Anime ou Daily.
   - **Quality Profile:** selecionar perfil do Sonarr.
   - **Root Folder:** selecionar pasta de destino.
   - **Season Folder:** toggle ON (padrão) = organizar episódios em pastas por temporada.
8. Tocar "Add Series".
9. Snackbar confirma sucesso e lista atualiza.

## Detalhes da série — temporadas episódios histórico

**Onde fica:** Aba Séries → tocar em qualquer série.

Ao tocar em uma série, abre a tela de detalhes com:

- **AppBar expansível** com fanart de fundo.
- **Poster e informações:** título, ano, nota, gêneros, status, network, próxima exibição.
- **Seções:**
  - Overview: sinopse, contagem de episódios, status.
  - Seasons: lista de todas as temporadas com contagem de episódios e status.
  - Files & Metadata: codecs, tamanhos, arquivos extras.
  - History: eventos específicos da série (grab, import, falhas).
- **Ações:**
  - Edit: editar configurações da série.
  - Search Now: disparar busca automática.
  - Delete: deletar a série da biblioteca (menu ⋮).

**Observações:** Tocar em uma temporada abre a lista de episódios com número, título, data de exibição e status (baixado, faltando, não monitorado, próximo).

## Episódios e temporadas — monitorar e buscar release

**Onde fica:** Detalhes da série → seção "Seasons" → tocar na temporada.

**Passo a passo:**
1. Abrir detalhes da série.
2. Na seção "Seasons", tocar na temporada desejada.
3. Lista de episódios aparece, cada um com:
   - Número e título do episódio.
   - Data de exibição.
   - Ícone de status (verde = baixado, vermelho = faltando, cinza = não monitorado, azul = próximo).
4. Tocar no ícone de busca ao lado do episódio para buscar release manualmente.
5. No sheet de releases, selecionar e confirmar o download.

**Observações:** A busca de release por episódio funciona igual à busca por filme — mostra releases dos indexadores com score, seeders, tamanho.

## Editar série — tipo monitoramento qualidade pasta raiz pasta de temporada

**Onde fica:** Tela de detalhes da série → botão "Edit".

**Passo a passo:**
1. Abrir detalhes da série.
2. Tocar em "Edit".
3. Alterar campos:
   - **Monitored:** toggle ON/OFF para todos os episódios.
   - **Series Type:** Standard, Anime ou Daily (afeta renomeação e numbering).
   - **Quality Profile:** trocar perfil de qualidade.
   - **Root Folder:** trocar pasta de destino.
   - **Season Folder:** toggle ON/OFF para organizar por pastas de temporada.
4. Se a pasta raiz foi alterada e há episódios baixados: diálogo "Move Files?".
5. Tocar "Save".

**Observações:** O tipo de série (Standard/Anime/Daily) afeta como o Sonarr renomeia e numera os episódios. Anime usa absolute numbering. Daily usa formato de data.

## Deletar série da biblioteca — remover do Sonarr

**Onde fica:** Tela de detalhes da série → menu ⋮ (três pontos) → "Delete".

**Passo a passo:**
1. Abrir detalhes da série.
2. Tocar no menu ⋮ (três pontos) no canto superior direito.
3. Selecionar "Delete" (em vermelho).
4. Confirmar no diálogo "Are you sure you want to delete this series?".
5. Tocar "Delete" para confirmar.
6. Snackbar confirma "Series deleted" e volta para a lista de séries.

**Observações:** A série é removida do Sonarr. Os arquivos em disco podem ou não ser removidos dependendo da configuração do Sonarr.

## Deletar arquivo de mídia de episódio — remover arquivo individual

**Onde fica:** Detalhes da série → temporada → episódio → ícone de lixeira ao lado do arquivo.

**Passo a passo:**
1. Abrir detalhes da série.
2. Tocar na temporada desejada.
3. Tocar no episódio que possui arquivo.
4. No sheet de detalhes do episódio, localizar o arquivo.
5. Tocar no ícone de lixeira ao lado do arquivo.
6. Confirmar a exclusão no diálogo.
7. Snackbar confirma sucesso.

**Observações:** Remove apenas o arquivo selecionado do disco. O episódio permanece na biblioteca como "Missing".
