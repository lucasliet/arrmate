---
name: calendar
description: Calendário de próximos lançamentos e episódios
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
  - Se for episódio: abre `SeriesDetailsScreen` da série correspondente (não existe tela de episódio isolado).
- **Pull-to-refresh** (arrastar para baixo): recarrega dados do Radarr/Sonarr.

**Estado vazio:** 
- Título: "No upcoming events"
- Subtitle: "Check back later or add content to your libraries"

**Observações:**
- Os dados vêm dos Radarr e Sonarr configurados em Configurações → Instances.
- Inclui filmes com data de lançamento futura e episódios agendados.
- A ordem é **sempre cronológica** (data mais próxima primeiro).
- Você pode scrollar para ver mais datas no futuro.
- Episódios mostram data/hora de exibição conforme configurado no Sonarr.
