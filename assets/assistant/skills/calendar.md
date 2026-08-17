---
name: calendar
description: Calendário de próximos lançamentos e episódios, filtros por instância tipo monitorados estreias especiais
---

# Calendário

## Calendário — próximos lançamentos de filmes e episódios

**Onde fica:** Aba Calendário (terceira aba da barra inferior).

A aba Calendário mostra próximos lançamentos agrupados e ordenados por data:

**Estrutura visual:**
- **Cabeçalhos de data:** acima de cada grupo de itens, exibem:
  - "TODAY" (em destaque visual) se for hoje.
  - "TOMORROW" se for amanhã.
  - Data formatada (ex: "Wednesday, April 30") para demais datas.
- **Itens/Cards:** cada lançamento próximo exibe:
  - **Thumbnail do poster** no lado esquerdo (70×100 px aproximadamente).
  - **Título** do filme ou nome da série em bold.
  - **Timestamp** (hora de lançamento, se disponível, ex: "14:00").
  - **Badge colorido** indicando tipo:
    - Ícone de filme 🎬 (azul) para filmes.
    - Ícone de TV 📺 (roxo) para episódios de séries.
  - **Subtitle** com informações adicionais:
    - Para filmes: ano de lançamento, duração.
    - Para episódios: "S##E##" (número da temporada e episódio), ex: "Season 2, Episode 5".
  - **Faixa colorida vertical** no lado direito (cor varia por tipo).

**Ações:**
- **Toque em um item:** abre a tela de detalhes:
  - Se for filme: abre `MovieDetailsScreen` com all informações.
  - Se for episódio: abre os **detalhes do episódio exato** (`EpisodeDetailsSheet` sobre a `SeasonDetailsScreen`), permitindo ver a sinopse, buscar release e interagir diretamente com aquele episódio.
- **Pull-to-refresh** (arrastar para baixo): recarrega dados do Radarr/Sonarr.

## Filtros do calendário — instância tipo monitorados estreias especiais

**Onde fica:** Aba Calendário → barra horizontal de chips no topo (rolável horizontalmente).

A barra de filtros permite refinar quais eventos aparecem. Cada filtro é um chip; o chip **"Reset"** aparece apenas quando há algum filtro ativo e limpa todos de uma vez.

**Filtros disponíveis:**

| Filtro | Tipo | Como funciona |
|---|---|---|
| **Instance** (ícone `dns_outlined`) | PopupMenuButton | Filtra por uma instância específica (Radarr/Sonarr) ou "Any instance" (padrão). |
| **Tipo de mídia** (ícone `video_library_outlined`) | PopupMenuButton | Filtra por tipo: All, Movies, Series, etc. |
| **Monitored** (ícone `bookmark_outline`) | FilterChip | Quando ativo, mostra apenas itens monitorados. |
| **Premieres** (ícone `play_circle_outline`) | FilterChip | Quando ativo, mostra apenas estreias (season premieres). |
| **Hide specials** (ícone `star_outline`) | FilterChip | Quando ativo, oculta episódios especiais (temporada 0). |
| **Reset** (ícone `filter_alt_off_outlined`) | ActionChip | Só aparece com filtros ativos; limpa todos. |

**Observações:**
- Os filtros se combinam (ex: instância "Casa" + tipo "Series" + "Monitored").
- O calendário agrega eventos de **todas** as instâncias Radarr/Sonarr por padrão; use o filtro de instância para isolar uma.

**Estado vazio:** 
- Título: "No upcoming events"
- Subtitle: "Check back later or add content to your libraries"
- **Exceção durante o tour inicial:** se o tour estiver rodando e não houver nenhum Radarr/Sonarr configurado, no lugar do estado vazio aparecem **eventos de exemplo** sob o aviso "Sample content shown during the tour". Eles não abrem detalhes, não representam lançamentos reais e somem assim que o tour é concluído ou pulado.

**Observações:**
- Os dados vêm dos Radarr e Sonarr configurados em Configurações → Instances.
- Inclui filmes com data de lançamento futura e episódios agendados.
- A ordem é **sempre cronológica** (data mais próxima primeiro).
- Você pode scrollar para ver mais datas no futuro.
- Episódios mostram data/hora de exibição conforme configurado no Sonarr.
