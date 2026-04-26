---
name: library
description: Filtrar/ordenar filmes e séries, alternar grade/lista, busca local
---

# Biblioteca

## Filtrar e ordenar a lista de filmes

**Onde fica:** Aba Filmes → ícone de sort/filter na AppBar (canto superior direito).

**Ordenação disponível:**
- Title (A-Z), Added Date, Rating, Year, Release Date, File Size.
- Toggle ascendente/descendente.

**Filtros disponíveis:**
- All: todos os filmes.
- Downloaded: filmes monitorados com arquivo presente.
- Missing: filmes monitorados sem arquivo.
- Unmonitored: filmes não monitorados.

**Passo a passo:**
1. Tocar no ícone de sort/filter na AppBar.
2. No sheet que abre, selecionar opção de sort e/ou filtro.
3. A lista atualiza instantaneamente.
4. Pode combinar sort + filtro ao mesmo tempo.

## Filtrar e ordenar a lista de séries

**Onde fica:** Aba Séries → ícone de sort/filter na AppBar.

**Ordenação disponível:**
- Title (A-Z), Added Date, Rating, Year, Next Airing, Episodes.
- Toggle ascendente/descendente.

**Filtros disponíveis:**
- All: todas as séries.
- Downloaded: todos os episódios monitorados com arquivos.
- Missing: episódios monitorados sem arquivos.
- Unmonitored: séries não monitoradas.

Funciona igual ao filtro de filmes — abrir o sheet, selecionar combinação de sort + filtro.

## Alternar entre visualização em grade e lista

**Onde fica:** Aba Filmes ou Séries → ícone de toggle na AppBar.

- Tocar no ícone de grid/list na AppBar para alternar.
- **Grade (Grid):** posters em colunas com título e status por cima.
- **Lista (List):** tiles horizontais com poster pequeno, título e metadados.
- A escolha é salva localmente.

## Buscar filme ou série na biblioteca local

**Onde fica:** Aba Filmes ou Séries → ícone de lupa na AppBar.

**Passo a passo:**
1. Tocar no ícone de lupa na AppBar.
2. Campo de busca aparece com placeholder "Search movies..." ou "Search series...".
3. Digitar o título. A filtragem é instantânea em tempo real.
4. Resultados atualizam conforme digita.
5. Tocar no X para limpar a busca.

**Observações:** Busca apenas na biblioteca local já carregada. Não busca novos títulos no Radarr/Sonarr (para isso use o botão "+").
