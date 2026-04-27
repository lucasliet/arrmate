---
name: library
description: Filtrar/ordenar filmes e séries, alternar grade/lista, busca local
---

# Biblioteca

## Filtrar e ordenar a lista de filmes

**Onde fica:** Aba Filmes → AppBar no topo.

**Passo a passo:**
1. Abrir a aba Filmes (primeira aba na barra inferior).
2. No topo da tela, localize a AppBar com três ícones no canto direito:
   - Ícone de lupa (busca)
   - Ícone de ordenação/filtro (funzinho)
   - Ícone de grid/list (alternância de visualização)
3. Tocar no **ícone de ordenação/filtro** (segundo ícone da direita).
4. Um sheet (painel deslizável) abre com três seções:

**Seção "SORT BY":**
- Opções: Title, Year, Added, Rating, Size, Runtime.
- Selecione uma tocando no radio button ao lado.
- A lista atualiza imediatamente e o sheet fecha.

**Seção "ORDER":**
- Opções: Ascending (A→Z) ou Descending (Z→A).
- Selecione tocando no radio button.
- A lista reflete a mudança instantaneamente.

**Seção "FILTER":**
- Chips (pequenos botões) com opções:
  - **All Movies:** mostra todos os filmes.
  - **Monitored:** apenas filmes com monitoramento ativo.
  - **Unmonitored:** apenas filmes sem monitoramento.
  - **Missing:** filmes monitorados mas sem arquivo baixado.
  - **Downloaded:** filmes com arquivo completamente baixado.
- Toque em um chip para aplicar filtro; o chip muda de cor para indicar seleção.
- A lista atualiza instantaneamente.

**Observações:**
- Você pode combinar sort + filter (ex: ordenar por Rating descendente + mostrar apenas Downloaded).
- Pull-to-refresh (arrastar para baixo) limpa a busca e recarrega.

## Filtrar e ordenar a lista de séries

**Onde fica:** Aba Séries → AppBar no topo.

**Passo a passo:**
Funciona exatamente como Filmes:

1. Abrir a aba Séries (segunda aba na barra inferior).
2. Tocar no **ícone de ordenação/filtro**.
3. O sheet exibe as mesmas três seções:

**Seção "SORT BY":**
- Opções: Title, Year, Added, Rating, Size.
- **Nota:** Séries não têm opção "Runtime"; têm "Size" em vez disso.

**Seção "ORDER":**
- Ascending ou Descending (igual a Filmes).

**Seção "FILTER":**
- Chips com opções:
  - **All Series:** todos os títulos.
  - **Monitored:** apenas monitoradas.
  - **Unmonitored:** apenas sem monitoramento.
  - **Ended:** séries finalizadas (status ended).
  - **Continuing:** séries em produção (status continuing).
- **Nota:** Séries usam status de série (Ended/Continuing) em vez de arquivos individuais.

**Observações:** O filtro de séries é pensado em termos de séries inteiras, não episódios individuais.

## Alternar entre visualização em grade e lista

**Onde fica:** Aba Filmes ou Séries → AppBar no topo (terceiro ícone da direita).

**Passo a passo:**
1. Na AppBar, identifique os três ícones do lado direito.
2. Tocar no **terceiro ícone da direita** (grid/list toggle):
   - Se estiver em **grade (grid):** ícone mostra um grid. Ao tocar, muda para mode lista.
   - Se estiver em **lista (list):** ícone mostra linhas. Ao tocar, muda para grid.

**Modo Grade (Grid):**
- Exibe posters em colunas (geralmente 2-3 por linha, dependendo do tamanho da tela).
- Cada poster mostra título e badges de status (ex: "Downloaded", "Missing", "Unmonitored") por cima.
- Toque no poster para abrir detalhes.

**Modo Lista (List):**
- Exibe linhas/tiles horizontais.
- Cada tile mostra:
  - Poster pequeno no lado esquerdo (thumbnail).
  - Título em bold no topo.
  - Metadados abaixo (ano, status, contagem de arquivos, etc).
- Toque no tile para abrir detalhes.

**Observações:** A escolha é salva localmente entre sessões. Você volta a encontrar a mesma visualização na próxima vez que abrir o app.

## Buscar filme ou série na biblioteca local

**Onde fica:** Aba Filmes ou Séries → AppBar no topo (primeiro ícone da direita).

**Passo a passo:**
1. Na AppBar, toque no **primeiro ícone da direita** (lupa/busca).
2. A AppBar transforma-se em um campo de texto com placeholder:
   - Filmes: "Search movies..."
   - Séries: "Search series..."
3. Comece a digitar o título, ator, gênero ou qualquer texto relevante.
4. **Filtragem em tempo real:** conforme você digita, a lista abaixo atualiza instantaneamente, mostrando apenas títulos que correspondem ao texto.
5. Para limpar a busca:
   - Toque no **ícone X** que aparece no lado direito do campo de busca.
   - Ou toque no **ícone de voltar** (seta) no lado esquerdo para sair do modo busca.

**Comportamento:**
- Busca procura em nome do título, ano, gêneros, nomes de atores (se disponíveis localmente).
- A busca é **case-insensitive** (maiúsculas/minúsculas não importam).
- A busca funciona apenas na **biblioteca local já carregada na memória do app**.

**Observações:**
- **Busca local vs. adição:** Busca aqui busca filmes/séries que já estão na sua biblioteca. Para adicionar um novo filme/série que não está na lista, use o botão **"+"** (FAB) na aba Filmes ou Séries.
- **Sem conexão:** Se o app não consegue conectar ao Radarr/Sonarr, a busca continua funcionando nos dados já carregados.
- **Combinação com filtros:** Você pode buscar e depois aplicar filtros/ordenação no mesmo sheet de sort/filter.
