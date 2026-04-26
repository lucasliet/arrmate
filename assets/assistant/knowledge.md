# Arrmate — Base de conhecimento do Assistant

## Sobre o Arrmate — o que o app faz

Arrmate é um app mobile companion para gerenciar servidores **Radarr** (filmes), **Sonarr** (séries) e **qBittorrent** (downloads).

Funcionalidades principais:
- Biblioteca de filmes e séries: navegar, buscar, filtrar, ordenar, monitorar e deletar.
- Adicionar novos filmes e séries via busca online no Radarr/Sonarr.
- Busca manual de releases (grab interativo) com filtro e seleção.
- Calendário de próximos lançamentos e episódios.
- Monitoramento de fila de downloads e histórico de atividade.
- Cliente qBittorrent integrado: listar, pausar, retomar, remover, adicionar torrents.
- Notificações push via ntfy.sh com sincronização multi-dispositivo.
- Multi-instância: conectar vários servidores Radarr, Sonarr e qBittorrent ao mesmo tempo.
- Assistente de IA on-device para dúvidas sobre o próprio app.
- Atualização automática do app via GitHub Releases.

O app é feito em Flutter, roda totalmente no dispositivo e não envia dados pessoais para servidores externos.

## Navegação principal — abas Filmes Séries Calendário Atividade Configurações

O Arrmate usa uma barra de navegação inferior com 5 abas:

1. **Filmes** — Biblioteca de filmes do Radarr.
2. **Séries** — Biblioteca de séries do Sonarr.
3. **Calendário** — Próximos lançamentos e episódios organizados por data.
4. **Atividade** — Fila de downloads, histórico e torrents do qBittorrent.
5. **Configurações** — Instâncias, aparência, notificações, sistema e assistente.

A aba ativa é destacada com ícone preenchido e cor de destaque. Tocar em qualquer aba navega diretamente.

A maioria das telas possui ícone de sino no topo para acessar a central de notificações.

## Aba inicial — escolher qual abre ao iniciar o app

**Onde fica:** Configurações → seção "Appearance" → "Home Tab".

**Passo a passo:**
1. Abrir a aba Configurações.
2. Tocar em "Appearance".
3. Tocar em "Home Tab".
4. Selecionar qual aba abre ao iniciar: Filmes, Séries, Calendário ou Atividade.

**Observações:** O padrão é Filmes.

## Adicionar instância Radarr Sonarr ou qBittorrent

**Onde fica:** Configurações → seção "Instances" → "Add Instance".

**Passo a passo:**
1. Abrir a aba Configurações na barra inferior.
2. Na seção "Instances", tocar em "Add Instance" (último item da lista).
3. No seletor segmentado no topo, escolher o tipo: Radarr, Sonarr ou qBittorrent.
4. Preencher "Name" com um rótulo livre (ex: "Servidor Casa", "VPS").
5. Preencher "URL" completo, incluindo http(s):// e porta (ex: `http://192.168.1.10:7878`).
6. Para Radarr/Sonarr: colar a "API Key" em "API Key".
7. Para qBittorrent: preencher "Username" e "Password" da WebUI.
8. Tocar "Test Connection" para validar. Se OK, aparece versão e contagem de tags em verde.
9. Tocar "Save" para salvar.

**Observações:** Os metadados da instância (perfis de qualidade, root folders, tags) são cacheados localmente. Múltiplas instâncias do mesmo tipo são suportadas simultaneamente.

## Onde encontrar a API key do Radarr ou Sonarr

A API Key é gerada pelo próprio servidor Radarr ou Sonarr.

**Como obter:**
1. Abrir a interface web do Radarr ou Sonarr no navegador.
2. Ir em Settings → General.
3. Copiar o valor do campo "API Key".

Depois colar essa chave no campo "API Key" ao adicionar a instância no Arrmate.

## Testar conexão e validar instância

**Onde fica:** Tela de adicionar/editar instância → botão "Test Connection".

**Passo a passo:**
1. Preencher URL e credenciais da instância.
2. Tocar "Test Connection".
3. Aguardar o indicador de loading.
4. Se sucesso: aparece "Connection successful!" com versão, nome e contagem de tags.
5. Se falha: aparece mensagem de erro em vermelho com o motivo.

**Observações:** Sempre teste antes de salvar. Se falhar, verifique URL, porta, API key e conectividade de rede.

## Editar ou remover instância existente

**Onde fica:** Configurações → seção "Instances" → tocar na instância.

**Passo a passo para editar:**
1. Abrir Configurações → seção "Instances".
2. Tocar na instância desejada na lista.
3. Alterar os campos necessários (URL, API key, nome, etc).
4. Tocar "Test Connection" para validar.
5. Tocar "Save".

**Passo a passo para remover:**
1. Tocar na instância na lista.
2. Tocar no ícone de lixeira no canto superior direito.
3. Confirmar a exclusão no diálogo.

**Observações:** Remover uma instância limpa todo o cache local associado (filmes, séries, perfis, etc).

## Modo lento (slow mode) e cabeçalhos HTTP customizados

**Onde fica:** Tela de adicionar/editar instância → seção "Advanced Options".

**Slow Mode:**
- Toggle "Slow Mode" no formulário da instância.
- Quando ativado, o timeout de requisições sobe de 30s para 90s.
- Recomendado para servidores remotos, via VPN, ou com hardware limitado.

**Custom Headers:**
- Seção expansível "Custom Headers" no formulário da instância.
- Permite adicionar cabeçalhos HTTP customizados (nome:valor).
- Útil para reverse proxies com autenticação extra ou headers específicos.

## Suporte a múltiplas instâncias simultâneas

O Arrmate suporta várias instâncias do mesmo tipo ao mesmo tempo.

- É possível ter múltiplos Radarr, múltiplos Sonarr e múltiplos qBittorrent configurados.
- Cada instância é independente: nome, URL, credenciais e configurações próprias.
- Filmes e séries de todas as instâncias Radarr/Sonarr aparecem agregados nas respectivas abas.
- As instâncias são listadas na seção "Instances" em Configurações com ícone do tipo (filme, TV, download).

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

## Calendário — próximos lançamentos de filmes e episódios

**Onde fica:** Aba Calendário (terceira aba da barra inferior).

O Calendário mostra próximos lançamentos organizados por data:

- **Cabeçalhos de data:** "TODAY" (em destaque), "TOMORROW", e datas subsequentes.
- **Itens:** cada lançamento mostra poster thumbnail, título, horário (se disponível) e ícone indicando se é filme ou episódio.
- Pull-to-refresh disponível.

**Estado vazio:** "No upcoming events" — "Check back later or add content to your libraries".

**Observações:** Os dados vêm dos Radarr e Sonarr configurados. Inclui filmes com data de lançamento futura e episódios que ainda vão ao ar.

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

## Configurar notificações push via ntfy.sh

**Onde fica:** Configurações → seção "Notifications" → "Notification Settings".

**Passo a passo (primeira vez):**
1. Abrir Configurações → seção "Notifications".
2. Tocar em "Notification Settings".
3. Ler card informativo sobre notificações via ntfy.sh.
4. Tocar em "Setup Push Notifications".
5. Um tópico único ntfy é gerado automaticamente (ex: `arrmate_abc123`).

**Após configurado:**
1. Toggle "Enable Notifications" ON.
2. Ícone mostra "Connected to ntfy.sh" com check verde.
3. Configurar triggers (ver seção "Tipos de evento").
4. Tocar "Auto-Configure All Instances" para configurar webhooks automaticamente.

**Observações:** O ntfy.sh é um serviço gratuito de notificações push. O tópico gerado é único por dispositivo. Não é necessário criar conta.

## Tópico ntfy — copiar compartilhar e assinar em outros dispositivos

**Onde fica:** Configurações → Notification Settings → campo "Your Topic".

- O tópico é exibido como texto (ex: `arrmate_abc123`).
- Tocar no ícone de copia para copiar para a área de transferência.
- Snackbar confirma "Topic copied to clipboard".
- Para assinar em outro dispositivo: abrir `https://ntfy.sh/[seu-topico]` no navegador.

**Observações:** Qualquer dispositivo com acesso à URL do tópico pode receber as notificações. Não compartilhe o tópico publicamente.

## Auto-configurar webhooks nas instâncias Radarr e Sonarr

**Onde fica:** Configurações → Notification Settings → botão "Auto-Configure All Instances".

**Passo a passo:**
1. Após gerar o tópico ntfy e ativar notificações.
2. Tocar em "Auto-Configure All Instances".
3. O Arrmate configura automaticamente webhooks em todos os Radarr e Sonarr conectados.
4. Mensagem confirma: "Configured X instances".

**Observações:** Novas instâncias adicionadas depois são auto-configuradas se as notificações já estiverem ativas. Os webhooks informam o Radarr/Sonarr para enviar eventos para o tópico ntfy.

## Tipos de evento de notificação — grab import falha mídia adicionada saúde

**Onde fica:** Configurações → Notification Settings → seção de triggers.

Toggles disponíveis quando notificações estão ativas:

**Downloads:**
- Notify on Grab: alertar quando uma release é capturada.
- Notify on Import: alertar quando um arquivo é importado com sucesso.
- Notify on Failure: alertar quando ocorre falha no download ou import.

**Media Updates:**
- Movie/Series Added: alertar quando novo conteúdo é adicionado.
- Quality/Monitored Changed: alertar quando qualidade ou monitoramento são alterados.

**Health:**
- Health Warnings: alertar sobre avisos de saúde do sistema.

Cada toggle pode ser ativado/desativado independentemente. Salva imediatamente ao tocar.

## Central de notificações — visualizar marcar como lida limpar

**Onde fica:** Ícone de sino na AppBar de qualquer tela principal, ou Configurações → "Notification Center".

**Funcionalidades:**
- Lista todas as notificações recebidas do Radarr/Sonarr.
- Cada card mostra: tipo badge, título, timestamp relativo.
- Notificações não lidas têm indicador visual (destaque ou ponto).
- Tocar em uma notificação marca como lida.
- Swipe para descartar (com undo via snackbar).
- "Mark All as Read" no topo (aparece quando há não lidas).
- "Clear All" para limpar todas (com diálogo de confirmação).

**Estado vazio:** "No notifications" — "When you receive notifications from Radarr or Sonarr, they will appear here".

## Modo economia de bateria (battery saver) para notificações

**Onde fica:** Configurações → Notification Settings → toggle "Battery Saver".

- Quando ativado, reduz a frequência de polling em background.
- Útil para economizar bateria em dispositivos com restrição.
- Desativado por padrão.

**Observações:** Com battery saver OFF, o polling em background ocorre a cada 30 minutos. Com ON, a frequência é reduzida.

## Tema claro escuro automático

**Onde fica:** Configurações → seção "Appearance" → "Theme Mode".

**Passo a passo:**
1. Abrir Configurações.
2. Tocar em "Appearance".
3. Tocar em "Theme Mode".
4. Selecionar: Light, Dark ou System.
5. System segue a configuração do dispositivo automaticamente.

**Observações:** O tema usa Material 3 com suporte completo a dark mode. Todas as cores se adaptam ao tema escolhido.

## Cor de destaque (color scheme) do app

**Onde fica:** Configurações → seção "Appearance" → "Color Scheme".

**Passo a passo:**
1. Abrir Configurações → Appearance.
2. Tocar em "Color Scheme" (mostra círculo com cor atual).
3. Seletor de cores com círculos coloridos aparece.
4. Tocar na cor desejada para aplicar imediatamente.

**Cores disponíveis:** blue, indigo, purple, pink, red, orange, amber, green, teal.

## Logs do app e logs do Radarr Sonarr

**Onde fica:** Configurações → seção "System Management" → "Logs".

A tela de Logs tem duas abas:

**Arr Logs:**
- Logs do sistema dos servidores Radarr/Sonarr conectados.
- Cada entrada: timestamp, nível (INFO, WARN, ERROR, DEBUG), mensagem.
- Filtro por nível: All, Info, Warn, Error, Debug.
- Botão "Copy all" para copiar logs visíveis para clipboard.
- Auto-carrega mais conforme scroll.

**App Logs:**
- Logs internos do próprio Arrmate.
- Mesmo formato e filtros que Arr Logs.
- Botão "Clear" no topo para limpar logs (com confirmação).

**Observações:** Os logs são úteis para diagnóstico de problemas. App logs mostram requisições API, erros internos e eventos do ciclo de vida.

## Saúde (health) — checagens e avisos do sistema

**Onde fica:** Configurações → seção "System Management" → "Health".

**Funcionalidades:**
- Exibe resultados das checagens de saúde dos servidores Radarr/Sonarr.
- Ícone de refresh no topo para executar checagens manualmente.
- Barra de progresso linear enquanto checa.

**Sem problemas:**
- Ícone de check verde grande.
- "No issues found".

**Com problemas:**
- Lista de avisos/erros com:
  - Ícone (X vermelho para erros, ! laranja para warnings).
  - Fonte (qual instância).
  - Mensagem descritiva do problema.
  - Link para wiki (abre no navegador).

**Observações:** Problemas comuns incluem: espaço em disco baixo, pasta não gravável, download client inacessível, indexers com falha.

## Perfis de qualidade disponíveis nas instâncias

**Onde fica:** Configurações → seção "System Management" → "Quality Profiles".

**Funcionalidades:**
- Lista todos os perfis de qualidade das instâncias conectadas.
- Duas seções: Radarr Profiles e Sonarr Profiles.
- Cada perfil mostra: ícone, nome do perfil e ID.

**Estado vazio:** "No profiles found or instance not connected".

**Observações:** Estes perfis são usados ao adicionar ou editar filmes e séries. São obtidos via cache das instâncias configuradas.

## Sobre o app — versão atualizações e código-fonte

**Onde fica:** Configurações → seção "About".

**Informações exibidas:**
- Versão atual do app.
- Status de atualização (check verde se atualizado, ícone de update se há nova versão).
- Tocar para verificar atualizações manualmente.
- Link "Source Code" para o repositório GitHub.

**Atualizações:**
- O app verifica automaticamente por novas versões via GitHub Releases.
- Quando disponível, é possível baixar e instalar a atualização diretamente pelo app (OTA).

## Sobre o Assistant — modelos disponíveis baixar importar trocar

**Onde fica:** Configurações → seção "System Management" → "Assistant".

O Assistant é uma funcionalidade de IA que roda localmente no dispositivo para responder dúvidas sobre o Arrmate.

**Modelos disponíveis no catálogo:**
- Qwen 3 0.6B — pequeno e rápido (bom para respostas simples).
- Gemma 4 E2B — balanceado entre qualidade e tamanho (suporta tool-calling).
- Gemma 4 E4B — maior qualidade, mais memória (suporta tool-calling).

**Ações:**
- **Download:** tocar "Download" para baixar modelo do catálogo. Progresso aparece em diálogo.
- **Import:** tocar "Import" para importar arquivo `.litertlm` do dispositivo.
- **Switch:** tocar "Switch" para trocar entre modelos já instalados.
- **Delete:** no diálogo de switch, tocar ícone de lixeira ao lado do modelo (exceto o selecionado).

**Observações:** Modelos Gemma 4 usam tool-calling para buscar seções relevantes da documentação antes de responder. O Qwen recebe a documentação inteira no prompt. Modelos maiores consomem mais memória e podem ser mais lentos em dispositivos mais antigos.

## Como o Assistant funciona — on-device sem internet

O Assistant roda inteiramente no dispositivo usando LiteRT-LM (engine de inferência local).

**Características:**
- Não requer conexão com internet para funcionar.
- Dados ficam no dispositivo — nada é enviado para servidores externos.
- Usa a base de conhecimento do Arrmate como fonte de informação.
- Responde em português por padrão.
- Não inventa funcionalidades que não existem no app.

**Como usar:**
1. Configurações → Assistant.
2. Selecionar/baixar um modelo.
3. Digitar pergunta no campo "Ask about Arrmate...".
4. Tocar no botão de enviar.
5. Aguardar resposta (pode levar alguns segundos dependendo do modelo e dispositivo).

## Erro de conexão com instância — diagnóstico

Se o app não consegue se conectar a uma instância configurada, verificar:

1. **URL e porta:** confirmar que estão corretos em Configurações → Instances → tocar na instância. Incluir http:// ou https:// e a porta (ex: 7878 para Radarr, 8989 para Sonarr, 8080 para qBittorrent).
2. **API Key:** para Radarr/Sonarr, verificar que a chave está correta. Obter em Settings → General → API Key na interface web do servidor.
3. **Conectividade de rede:** confirmar que o dispositivo alcança o servidor (mesma rede, VPN ativa, etc).
4. **Serviço rodando:** verificar que Radarr/Sonarr/qBittorrent está em execução e acessível.
5. **Slow Mode:** se o servidor é remoto ou lento, ativar Slow Mode na instância para timeout de 90s.
6. **Custom Headers:** se usar reverse proxy com auth, configurar headers em Advanced Options.
7. **Testar:** tocar "Test Connection" na edição da instância para diagnóstico.

## Erro de autenticação API key inválida ou qBittorrent

**Para Radarr/Sonarr (API Key):**
- Mensagem típica: "Unauthorized" ou "Invalid API key".
- Solução: obter API Key correta na interface web do servidor (Settings → General → API Key) e atualizar no Arrmate.

**Para qBittorrent (Username/Password):**
- Mensagem típica: "Login failed" ou "Unauthorized".
- Solução: verificar username e senha da WebUI do qBittorrent. Certificar que a WebUI está habilitada nas configurações do qBittorrent.

**Passos:**
1. Configurações → Instances → tocar na instância.
2. Corrigir credenciais.
3. Tocar "Test Connection".
4. Se OK, tocar "Save".

## Notificações não chegam — verificações

Se as notificações não estão chegando:

1. **Notificações ativas:** Configurações → Notification Settings → confirmar que "Enable Notifications" está ON.
2. **Tópico configurado:** verificar que o tópico ntfy aparece em "Your Topic".
3. **Status de conexão:** ícone deve mostrar "Connected to ntfy.sh" com check verde.
4. **Webhooks configurados:** tocar "Auto-Configure All Instances" para garantir que os webhooks estão ativos no Radarr/Sonarr.
5. **Triggers ativos:** verificar que pelo menos um tipo de evento está com toggle ON (Grab, Import, etc).
6. **Teste manual:** acessar `https://ntfy.sh/[seu-topico]` no navegador para verificar se o tópico está recebendo mensagens.
7. **Battery saver:** se ativado, o polling é menos frequente. Tentar desativar para teste.
8. **Rede:** confirmar que o dispositivo tem acesso à internet.

## App parece desatualizado após alterar configuração

Se a UI parece não refletir uma mudança recente:

1. **Pull-to-refresh:** arrastar para baixo na tela afetada para forçar atualização.
2. **Reabrir a tela:** navegar para outra aba e voltar.
3. **Reiniciar o app:** fechar completamente e abrir novamente.
4. **Cache:** o app cacheia dados localmente. Mudanças no servidor podem levar alguns segundos para aparecer.

## Modelo do Assistant não carrega ou trava

Se o Assistant não responde ou trava:

1. **Modelo compatível:** usar modelos do catálogo oficial (Qwen 3 0.6B, Gemma 4 E2B, Gemma 4 E4B).
2. **Memória:** modelos maiores (Gemma 4 E4B) precisam de mais RAM. Fechar outros apps pode ajudar.
3. **Trocar modelo:** tentar modelo menor (Qwen 3 0.6B) se o maior travar.
4. **Reimportar:** se o modelo foi importado manualmente, pode estar corrompido. Tentar baixar do catálogo.
5. **Dispositivo antigo:** em dispositivos com pouca RAM, usar apenas o Qwen 3 0.6B.

## O que o Arrmate suporta hoje (e o que não suporta)

**Suportado:**
- Navegação e gerenciamento de biblioteca de filmes (Radarr) e séries (Sonarr).
- Adicionar novos filmes e séries com busca online.
- Busca manual de releases (interactive search / grab).
- Edição de filmes e séries (monitoramento, qualidade, pasta, tipo).
- Deletar filmes e séries da biblioteca.
- Deletar arquivos de mídia individuais (filmes e episódios).
- Import manual de arquivos da fila (manual import).
- Import de torrents completos para a biblioteca Radarr/Sonarr (torrent import).
- Calendário de lançamentos futuros.
- Fila de downloads e histórico de atividade.
- Cliente qBittorrent completo (listar, adicionar, pausar, retomar, remover, recheck).
- Notificações push via ntfy.sh com multi-dispositivo.
- Multi-instância (vários Radarr, Sonarr, qBittorrent).
- Perfis de qualidade, logs e health checks.
- Atualização automática do app.
- Assistente de IA on-device.

**Não suportado atualmente:**
- Reprodução/streaming de mídia (o app não é um player).
- Gerenciamento de indexadores (adicionar/remover indexers — faça pela interface web do Radarr/Sonarr).
- Gerenciamento de download clients no Radarr/Sonarr (configurar Deluge/Transmission/etc — faça pela interface web).
- Backup/restauração de configuração do Arrmate.
- Autenticação/biometria para abrir o app.
- Widget de homescreen ou atalhos rápidos.

## Diretrizes de resposta para o Assistant

Este é o documento fonte de verdade para o Assistente de IA embutido no Arrmate.

O Assistant deve:
- Responder em português (pt-BR).
- Usar apenas a documentação fornecida e o comportamento conhecido do app.
- Ser conciso e prático — dar passos concretos, não explicações genéricas.
- Mencionar o caminho de navegação exato (qual aba, qual botão).
- Referir-se aos nomes de botões e labels exatamente como aparecem no app.

O Assistant NÃO deve:
- Inventar funcionalidades que não estão descritas nesta documentação.
- Inventar nomes de botões, telas ou configurações que não existem.
- Sugerir ações que requerem interface web do Radarr/Sonarr sem esclarecer que não é feito pelo Arrmate.
- Fornecer instruções técnicas sobre instalação do Radarr/Sonarr/qBittorrent — focar apenas no uso do Arrmate.
