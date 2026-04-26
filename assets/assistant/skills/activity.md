---
name: activity
description: Fila de downloads (queue), import manual, histórico de atividade
---

# Atividade

## Fila de downloads (queue) — monitorar progresso

**Onde fica:** Aba Atividade → aba "Queue".

A aba Queue mostra itens atualmente sendo baixados no Radarr/Sonarr:

- Cada item mostra: título, barra de progresso, velocidade de download, status e ETA.
- Status possíveis: grabbing, downloading, importing, etc.
- Pull-to-refresh para atualizar.
- Tocar em item para ver detalhes completos.
- Itens que requerem intervenção manual mostram seção "Manual Import Required".

**Estado vazio:** "Queue is empty — No active downloads at the moment".

**Observações:** A fila reflete o estado dos download clients configurados no Radarr/Sonarr, não o qBittorrent diretamente. Para torrents do qBittorrent, use a aba "Torrents".

## Import manual de arquivos da fila — manual import

**Onde fica:** Aba Atividade → Queue → tocar em item que requer intervenção → botão "Manual Import".

**Passo a passo:**
1. Abrir Atividade → Queue.
2. Tocar no item que mostra status de intervenção necessária.
3. No sheet de detalhes, a seção "Manual Import Required" aparece com o botão "Manual Import".
4. Tocar "Manual Import".
5. Sheet de seleção de arquivos abre mostrando arquivos importáveis:
   - Contagem de arquivos válidos (verde) e com problemas (laranja).
   - Cada arquivo mostra nome, qualidade, tamanho e grupo de release.
6. Selecionar os arquivos desejados (checkbox).
7. Tocar "Import" no canto superior direito.
8. Snackbar confirma "X file(s) imported successfully".

**Observações:** O manual import aparece quando o Radarr/Sonarr não consegue importar automaticamente (ex: nome de arquivo não reconhecido, qualidade ambígua). Apenas itens com `downloadId` disponível mostram essa opção.

## Histórico de atividade — grab import falha

**Onde fica:** Aba Atividade → aba "History".

O histórico mostra eventos recentes em ordem cronológica:

- **Tipos de evento (badges coloridos):**
  - Grab (amarelo) — release capturada.
  - Import (verde) — arquivo importado com sucesso.
  - Failed (vermelho) — falha no download ou import.
  - Deleted — item deletado.
- Cada card mostra: tipo, título, nome da release, timestamp relativo (ex: "2 hours ago").
- Tocar no card mostra detalhes completos (release info, qualidade, tamanho, mensagem de erro se failed).
- Botão "Load More" no final para carregar mais eventos.
- Pull-to-refresh disponível.

**Observações:** É possível filtrar eventos por tipo. O histórico inclui tanto filmes quanto séries.
