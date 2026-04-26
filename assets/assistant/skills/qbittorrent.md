---
name: qbittorrent
description: Listar/pausar/retomar torrents, adicionar torrent, import torrent, filtros
---

# qBittorrent

## qBittorrent — listar pausar retomar e remover torrents

**Onde fica:** Aba Atividade → aba "Torrents" (aparece se um qBittorrent estiver configurado).

A aba Torrents mostra todos os torrents do qBittorrent:

- **Filtros por status (chips no topo):** All, Downloading, Seeding, Paused, Error.
- Cada torrent mostra: nome, progresso em %, status, velocidade ↓ upload ↑.
- **Ações por torrent:**
  - Tocar para ver detalhes (seeders, peers, tamanho, ETA).
  - Pausar/Retomar.
  - Remover (com ou sem deletar arquivos).
  - Recheck (verificar integridade dos dados).
- Pull-to-refresh disponível.

**Observações:** O qBittorrent precisa estar configurado como instância em Configurações → Instances para que esta aba apareça.

## Adicionar torrent — magnet URL ou arquivo .torrent

**Onde fica:** Aba Atividade → aba Torrents → botão "+" (FAB).

**Passo a passo:**
1. Abrir Atividade → Torrents.
2. Tocar no botão "+" no canto inferior direito.
3. No sheet que abre, escolher:
   - **URLs:** colar link magnet ou URL .torrent (múltiplas URLs, uma por linha).
   - **OU arquivo:** tocar em "Select .torrent File" e escolher arquivo do dispositivo.
   - (Selecionar arquivo limpa o campo de URL se preenchido.)
4. Configurar opcionalmente:
   - **Save Path:** pasta de destino customizada.
   - **Category:** categoria do qBittorrent (com autocomplete).
   - **Tags:** tags separadas por vírgula (com autocomplete).
   - **Start Paused:** toggle para iniciar pausado.
5. Tocar "Add Torrent".
6. Snackbar confirma sucesso.

**Observações:** Pelo menos uma fonte é obrigatória (URL ou arquivo). A validação impede envio sem conteúdo.

## Importar torrent completo para Radarr ou Sonarr — torrent import

**Onde fica:** Aba Atividade → Torrents → tocar em torrent completo → botão "Import to Media Library".

**Passo a passo:**
1. Abrir Atividade → Torrents.
2. Tocar em um torrent que esteja completo (100%).
3. No sheet de detalhes do torrent, tocar no botão "Import to Media Library".
4. Sheet "Select Target" abre com duas abas: Movies e Series.
5. Buscar ou selecionar o filme ou série de destino na lista.
6. Sheet "Import to Movie" ou "Import to Series" abre com a lista de arquivos do torrent.
7. Selecionar os arquivos desejados (checkbox). O mapeamento automático aparece (ex: S01E03).
8. Tocar "Import" no canto superior direito.
9. Snackbar confirma "X file(s) imported successfully".

**Observações:** O botão "Import to Media Library" só aparece quando o torrent está 100% completo. Os arquivos são escaneados na pasta do torrent (`savePath`) e apresentados com qualidade, tamanho e grupo de release detectados automaticamente.

## Filtrar torrents por status — baixando seedando pausado erro

**Onde fica:** Aba Atividade → Torrents → chips de filtro no topo da lista.

Chips disponíveis:
- **All:** todos os torrents.
- **Downloading:** torrents baixando ativamente.
- **Seeding:** torrents completos fazendo seed.
- **Paused:** torrents pausados.
- **Error:** torrents com erro.

Tocar em um chip filtra a lista instantaneamente. O chip ativo fica destacado.
