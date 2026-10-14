---
name: instances
description: Adicionar/editar/remover instância Radarr/Sonarr/qBittorrent/Jellyfin, API key, test connection, slow mode, custom headers, multi-instância
---

# Instâncias

## Adicionar instância — Radarr Sonarr ou qBittorrent

**Location:** **Settings** in bottom navigation or the sidebar → "Instances" → "Add Instance".

A tela de **Add Instance** permite configurar um novo servidor Radarr, Sonarr ou qBittorrent.

**Estrutura da tela:**

1. **Seletor Segmentado no topo (tabs):**
   - **Radarr** (ícone 🎬): para servidor de filmes.
   - **Sonarr** (ícone 📺): para servidor de séries.
   - **qBittorrent** (ícone ⬇️): para cliente de downloads.
   - **Jellyfin** (ícone 🗄️): para servidor de mídia (streaming).
   - Toque para alternar tipo.

2. **Formulário de configuração:**
   - **Name** (obrigatório):
     - Label: "Instance Name".
     - Exemplo: "Casa", "VPS Remoto", "NAS Sala".
     - Campo de texto livre; qualquer nome descritivo.
   
   - **URL** (obrigatório):
     - Label: "URL".
     - Exemplo: `http://192.168.1.10:7878` (Radarr), `http://192.168.1.10:8989` (Sonarr), `http://192.168.1.10:8080` (qBittorrent), `http://192.168.1.10:8096` (Jellyfin).
     - **Importante:** incluir protocolo (http/https) e porta.
     - Campo de texto; suporta IPv4, IPv6, hostname ou domain.
   
   - **API Key**:
     - Label: "API Key".
     - **Radarr/Sonarr (obrigatório):** colar chave gerada no servidor (Settings → General → API Key no Radarr/Sonarr web).
     - **qBittorrent (opcional, v5.2.0+):** colar o Bearer token gerado em **qBittorrent WebUI → Tools → Options → Web UI → API Key**.
       - Se você usa **qBittorrent < v5.2.0** ou prefere autenticar com usuário/senha, deixe este campo **vazio** e use **Advanced Settings → "Add Basic Auth"** para informar as credenciais (veja seção própria abaixo).
       - O formulário aceita o campo vazio **apenas** se houver um header `Authorization` configurado nos Advanced Settings; caso contrário, exibe erro: "Provide an API key or add Basic Auth below".
     - **Jellyfin:** campo **API Key** aceita **somente a API key**, gerada em **Painel Jellyfin → Avançado → Chaves de API** (permite **apenas reprodução**, sem gravar estado de assistido). Para entrar com **login e senha** (o que habilita a **sincronização de progresso**), deixe o campo vazio e use **Advanced Settings → "Add Basic Auth"**. Ao salvar, o app faz login uma vez e guarda **apenas o token da sessão** — o header Basic é removido e a senha nunca fica no dispositivo; o campo volta vazio, com o texto "Signed in as <usuário>". Em uma instância já conectada, deixar o campo vazio mantém a sessão; digitar uma API key troca a sessão pela chave.
     - Campo de texto; pode usar botão de "visibility toggle" (olho) para ver/ocultar.

3. **Botão "Test Connection":**
   - Tocar para validar URL, API key/credenciais e conectividade (validação opcional).
   - Mostra spinner enquanto testa.
   - **Sucesso (verde):** "✓ Connection successful" + versão (ex: "Radarr v4.1.0") + metadados (ex: "15 tags").
   - **Falha (vermelho):** mensagem de erro (ex: "Connection refused", "Invalid API key", "Timeout").

4. **Botão "Save Instance":**
   - Sempre habilitado — não requer teste de conexão bem-sucedido para salvar.
   - Tocar para salvar instância imediatamente.
   - Retorna para tela "Instances" com nova instância na lista.

5. **Seção "Advanced Settings" (ExpansionTile expansível):**
   - Título: "Advanced Settings", subtítulo: "Custom Headers & Authentication".
   - Collapse/expand com chevron.
   - Contém toggles/campos adicionais:
     - **Slow Mode** (toggle): para servidores lentos/remotos.
     - **Botão "Add Header"**: abre diálogo com campos **Name** e **Value** para adicionar um cabeçalho HTTP customizado.
     - **Botão "Add Basic Auth"**: abre diálogo com campos **Username** e **Password**; codifica automaticamente em Base64 e adiciona como cabeçalho `Authorization` (Basic Auth).

**Observações:**
- Todos os campos são salvos **localmente** no dispositivo.
- Metadados da instância (perfis, pastas, tags) são **cacheados** na primeira conexão. Os formulários de adicionar e editar filme ou série relêem as tags do servidor ao abrir.
- Você pode ter **múltiplas instâncias** de cada tipo simultaneamente.

## Onde encontrar a API key do Radarr ou Sonarr

A **API Key** é uma chave de acesso gerada pelo próprio servidor Radarr ou Sonarr.

**Passo a passo para obter:**

1. **Abrir interface web** do Radarr ou Sonarr no navegador:
   - Radarr: `http://[seu-ip]:7878`
   - Sonarr: `http://[seu-ip]:8989`
   - Se não souber a porta, verifique em Settings do servidor.

2. **Navegar para Settings:**
   - Canto superior direito → ícone de engrenagem ⚙️ → "Settings".

3. **Abrir seção "General":**
   - Menu esquerdo → "General" (pode estar sob "General" ou "System").

4. **Localizar campo "API Key":**
   - Campo com rótulo "API Key" ou "API key".
   - Exibe string aleatória (ex: `a1b2c3d4e5f6g7h8i9j0`).

5. **Copiar a chave:**
   - Clique no campo ou ícone de cópia.
   - Snackbar confirma "Copied to clipboard".

6. **Colar no Arrmate:**
   - No app, ao adicionar instância Radarr/Sonarr, cole no campo "API Key".

**Observações:**
- Cada servidor Radarr/Sonarr tem sua própria chave.
- A chave é **sensível** — não compartilhe publicamente.
- Se suspeitar que foi exposta, regenere em Settings do servidor.

## Testar conexão e validar instância

**Onde fica:** Tela de adicionar/editar instância → botão "Test Connection".

**Passo a passo:**

1. **Preencher campos obrigatórios:**
   - Name: qualquer rótulo.
   - URL: endereço completo (http://... + porta).
   - **Radarr/Sonarr:** API Key obrigatória.
   - **qBittorrent:** API Key (v5.2.0+) **ou** Basic Auth configurado em Advanced Settings — pelo menos um dos dois.
   - **Jellyfin:** API Key **ou** Basic Auth (login e senha em Advanced Settings) — pelo menos um dos dois.

2. **Tocar "Test Connection":**
   - Botão mostra spinner/loading.
   - Teste leva **2-10 segundos** dependendo de latência.

3. **Resultado bem-sucedido (verde):**
   - Ícone de check ✓.
   - Texto: "Connection successful!".
   - Metadados exibidos:
     - Versão (ex: "Radarr v4.1.0").
     - Contagem de tags/perfis (ex: "15 tags").
     - Nome da instância (ex: "My Instance").

4. **Resultado com falha (vermelho):**
   - Ícone de erro ✗ ou ⚠️.
   - Mensagem descritiva (ex: "Connection refused", "Invalid API key", "Request timeout").
   - Dica: Verifique URL, credenciais, conectividade de rede, firewall.
   - O botão **"Save Instance"** continua habilitado — você pode salvar mesmo após falha no teste.

**Observações:**
- O teste de conexão é **opcional** mas recomendado para evitar configuração inválida.
- Se o teste falha:
  - ✓ URL está correto (protocolo + IP/hostname + porta)?
  - ✓ Serviço Radarr/Sonarr/qBittorrent está rodando?
  - ✓ Firewall permite acesso à porta?
  - ✓ Se remoto (VPN/internet): conexão está ativa?
  - ✓ API key está correta (Radarr/Sonarr)?

## Jellyfin — streaming e atualização automática da biblioteca

**Onde fica:** Adicionar/editar instância → tipo **Jellyfin**.

O Arrmate reproduz filmes e episódios direto do Jellyfin com um **player de vídeo integrado** (botão de play nos detalhes do filme/série/episódio). O player oferece seleção de **trilhas de áudio e legenda**, alternância de **qualidade** (quando disponível) e **abrir em player externo**.

**Como configurar a instância Jellyfin:**

1. Adicionar instância com tipo **Jellyfin** e a URL do servidor (ex: `http://192.168.1.10:8096`).
2. No campo **API Key**, escolher um dos formatos:
   - **Basic Auth** (Advanced Settings → "Add Basic Auth" com o usuário e a senha do Jellyfin): além de reproduzir, sincroniza o progresso — o item aparece no **"Continue Watching"** do Jellyfin.
   - **API key** no campo API Key (Painel Jellyfin → Avançado → Chaves de API): permite reprodução, mas **nunca grava estado de assistido** (a chave de admin não representa um usuário). O campo API Key não aceita `usuario:senha`.
3. **Test Connection** mostra versão e nome do servidor (ServerName). A credencial é validada de verdade: API key ou senha erradas mostram "Invalid Jellyfin credentials..." e servidor fora do ar mostra "Jellyfin server is unreachable...". O login feito só para o teste é encerrado em seguida.
4. **Save Instance** troca o Basic Auth por um token de sessão e salva só o token (a senha nunca fica no dispositivo; o header Basic é descartado). Instâncias antigas salvas com senha são migradas automaticamente na próxima abertura do app.
5. Se o Jellyfin invalidar a sessão (logout pelo painel, troca de senha, sessão que outro aparelho encerrou), ao tentar assistir o app avisa "Your Jellyfin session has expired. Sign in again." com o botão **Sign in**, e a instância aparece em Settings como "Session expired · tap to sign in" (o app também confere as sessões Jellyfin ao abrir Settings; um servidor fora do ar não marca a sessão como expirada). Na tela da instância, um aviso pede o login: use **Advanced Settings → "Add Basic Auth"** com usuário e senha de novo e salve (o campo API Key continua aceitando apenas a API key). O novo login cria uma sessão própria deste aparelho e descarta a antiga só localmente (sem `/Sessions/Logout`), então a sessão de outro aparelho não é derrubada. Os conectores do Radarr/Sonarr usam a chave de servidor e não são afetados.

**Como funciona o pareamento (library pairing):**
- O app localiza o arquivo do filme/episódio no Jellyfin automaticamente:
  1. **Caminho de arquivo** — compara o path do arquivo no Radarr/Sonarr com os paths da biblioteca Jellyfin.
  2. **Provider IDs** (TMDB/IMDb/TVDB) — fallback quando os paths não coincidem (ex: montagens diferentes).
  3. **Scan sob demanda** — se o Jellyfin ainda não indexou o arquivo, o app dispara uma varredura da biblioteca (`POST /Library/Media/Updated`) e aguarda a indexação antes de reproduzir.

**Atualização automática da biblioteca (conector Radarr/Sonarr):**
- Tela de **edição** de uma instância Jellyfin já salva → botão **"Set Up Library Auto-Update"**. O pareamento **só roda por essa ação explícita** — nunca automaticamente ao salvar.
- Cria/atualiza um conector chamado **"Arrmate Jellyfin (<id do aparelho>)"** (implementação MediaBrowser/Emby) em **todos os Radarr/Sonarr configurados**, um por aparelho — cada aparelho gerencia só o seu, para o Jellyfin atualizar a biblioteca sempre que mídia for importada, substituída, renomeada ou deletada.
- Resultado aparece em um diálogo com uma linha por instância; sucesso ✓ verde, falha ✗ vermelha.
- Sem Radarr/Sonarr configurados: mensagem "No Radarr or Sonarr instances configured".
- Com **API key**, o conector usa essa chave. Com login de **administrador**, o app cria (ou reutiliza, sem duplicar) a chave de API **deste aparelho**, `Arrmate (<id do aparelho>)`, no Jellyfin e guarda essa chave na instância para revogá-la ao remover. Um aparelho nunca reaproveita a chave de outro. Se o usuário não for administrador, o conector precisa de uma API key de servidor; o diálogo explica o motivo.

**Observações:**
- Somente o **token da sessão** é salvo no dispositivo — nunca a senha.
- O conector é idempotente: rodar de novo atualiza o conector existente em vez de duplicar.
- **Remover a instância Jellyfin** desfaz o que o app configurou: apaga o conector "Arrmate Jellyfin (<id do aparelho>)" **deste aparelho** (que aponta para esse servidor) de cada Radarr/Sonarr, revoga **somente** a chave `Arrmate (<id do aparelho>)` deste aparelho (guardada na instância — chaves e conectores de outros aparelhos, ou uma chave configurada à mão, nunca são tocados; uma chave que veio de outro aparelho por restauração de backup também é mantida) e encerra a sessão (`/Sessions/Logout`) — só quando a instância usa login (Basic Auth) feito **neste aparelho** (uma sessão que veio de outro aparelho por restauração de backup é apenas descartada localmente, sem deslogar o outro aparelho); com API key pura não há logout, porque ele revogaria a própria chave. Se algum passo falhar, a instância é removida mesmo assim e um aviso lista o que não foi limpo.

## Editar ou remover instância existente

**Onde fica:** Configurações → seção "Instances" → lista de instâncias.

**Passo a passo para editar:**

1. **Abrir Configurações** (quinta aba).
2. **Localizar seção "Instances"** (topo ou meio da tela).
3. **Tocar na instância** que deseja editar.
   - Abre tela de edição (mesmo formulário que "Add Instance").
4. **Alterar campos desejados:**
   - Name, URL, API Key/credenciais, etc.
5. **Tocar "Test Connection"** para validar mudanças.
   - Deve mostrar "Connection successful" em verde.
6. **Tocar "Save"** para aplicar.
   - Retorna para lista de instâncias.

**Passo a passo para remover:**

1. **Tocar na instância** na lista de Instances.
2. **Tocar ícone de lixeira** 🗑️ na **AppBar** (canto superior direito da tela de edição).
3. **Dialog de confirmação** aparece:
   - Texto: "Delete instance [Name]? All cached data will be removed."
   - Botões: "Cancel" | "Delete".
4. **Tocar "Delete"** para confirmar.
   - Instância é removida.
   - Cache associado (filmes, séries, perfis) é apagado.
   - Retorna para lista de instâncias.

**Observações:**
- Editar instância **não apaga** filme/série dados; apenas atualiza credenciais.
- Remover instância **apaga** todo cache local associado (recarrega na próxima vez que conectar).
- Se você remover e re-adicionar a mesma instância, dados serão re-sincronizados.

## Modo lento (slow mode) e cabeçalhos HTTP customizados

**Onde fica:** Tela de adicionar/editar instância → seção **"Advanced Settings"** (ExpansionTile expansível no final do formulário, subtítulo "Custom Headers & Authentication").

**Slow Mode (toggle):**
- Label: "Slow Mode" ou "Enable Slow Mode".
- **Padrão:** OFF.
- **Quando ativar:**
  - Servidor remoto via internet (não LAN).
  - Conexão por VPN ou móvel (4G/5G com latência alta).
  - Hardware limitado (Raspberry Pi, NAS antigo).
  - Você observa timeouts frequentes nas requisições.
- **Efeito:** timeout sobe de **30 segundos para 90 segundos**.
  - Permite que requisições lentas completem sem abortar.
  - Reduz risco de erro "Request timeout".
- **Desvantagem:** se realmente falhar, leva mais tempo para exibir erro.

**Custom Headers & Authentication:**
- Permite adicionar cabeçalhos HTTP customizados para requisições.
- **Quando usar:**
  - Reverse proxy com autenticação extra (ex: autenticação de header).
  - API Gateway com custom headers necessários.
  - Proxy requer User-Agent customizado, Authorization adicional, etc.
- **Botão "Add Header":**
  - Abre diálogo com campos **Name** e **Value**.
  - Cada header adicionado aparece na lista com ícone de lixeira para remover.
  - Exemplo: Name: `X-Custom-Auth`, Value: `my-token-123`.
- **Botão "Add Basic Auth":**
  - Abre diálogo com campos **Username** e **Password**.
  - O app codifica automaticamente `Username:Password` em Base64 e adiciona como cabeçalho `Authorization: Basic <base64>`.
  - **Casos de uso:**
    - Reverse proxies que exigem autenticação HTTP Basic na frente do Radarr/Sonarr/qBittorrent.
    - **qBittorrent sem API Key** (versões anteriores à v5.2.0 ou quando o usuário prefere user/password): deixe o campo "API Key" vazio no topo do formulário e configure as credenciais aqui.
- **Observações:**
  - Não adicione headers desnecessários; pode quebrar requisições.
  - Valores sensíveis (tokens, senhas) são armazenados **localmente no device** (não sincronizados).

## Alternative URL — URL local e externa com failover

**Onde fica:** Tela de adicionar/editar instância → campo **"Alternative URL"** (abaixo do campo "URL", visível para Radarr, Sonarr e qBittorrent).

A **Alternative URL** é uma segunda URL para a mesma instância, usada quando a URL principal não está alcançável. É ideal para quem acessa o servidor pela **LAN em casa** e por uma **URL externa** (VPN/reverse proxy) fora de casa.

**Como funciona o failover:**
- O app escolhe a ordem das URLs de acordo com a rede ativa: em rede local (Wi-Fi/Ethernet/VPN) prefere a URL principal; em rede móvel prefere a alternativa.
- Antes de usar, o app confirma qual URL está alcançável com um probe:
  - **Radarr/Sonarr:** endpoint público `/ping` (responde `{"status": "OK"}`).
  - **qBittorrent:** endpoint `/api/v2/app/version` (qualquer resposta HTTP, incluindo 403, prova que o host está online).
- Além disso, **leituras (GET)** fazem failover por requisição: se a URL ativa falhar com erro de conexão/timeout, o app tenta a outra URL automaticamente.

**Quando usar:**
- URL principal = `http://192.168.1.10:7878` (LAN) + Alternative URL = `https://radarr.minhodominio.com` (externa).
- Servidor atrás de VPN/reverse proxy que só é alcançável fora de casa.

**Observações:**
- **Mutações (add/pause/delete) não fazem failover por requisição** — apenas as leituras. Isso evita, por exemplo, adicionar o mesmo torrent em dois servidores qBittorrent distintos.
- A Alternative URL precisa ser HTTP/HTTPS válida, com host, e diferente da URL principal.
- A tela **Connection Diagnostics** mostra o status de cada endpoint (principal e alternativo) separadamente.
- Funciona para todos os tipos de instância: **Radarr, Sonarr, qBittorrent e Jellyfin**.

## Suporte a múltiplas instâncias simultâneas — agregação de dados

O **Arrmate suporta múltiplas instâncias** de **cada tipo** simultaneamente.

**Exemplos de configurações possíveis:**
- 2 x Radarr + 1 x Sonarr + 1 x qBittorrent.
- 3 x Radarr (casa, VPS, NAS) + 2 x Sonarr.
- 1 x Radarr + 1 x Sonarr + 2 x qBittorrent (um para privado, outro para público).

**Como os dados são agregados:**

| Elemento | Comportamento |
|---|---|
| **Abas Movies/Series** | Filmes/séries de **todas as instâncias Radarr/Sonarr** aparecem na mesma aba (agregados). Você pode filtrar por instância se desejar. |
| **Abas Activity/qBittorrent** | Queue, history e torrents de **todas as instâncias** aparecem agregados. Ícone de instância identifica origem. |
| **Notificações** | Notificações de todas as instâncias chegam no mesmo tópico ntfy. Badge mostra qual instância enviou. |
| **Perfis de qualidade** | Listados separados por instância (ex: "Radarr (Casa)" vs "Radarr (VPS)"). |
| **Settings/Instances** | Lista completa de todas as instâncias com tipo/nome/status. |

**Observações:**
- Cada instância é **independente**: nome, URL, credenciais, metadados próprios.
- Dados de uma instância **não afetam** outra (deletar filme em uma não afeta a outra).
- **Preferência padrão:** primeira instância Radarr/Sonarr é usada ao adicionar novo filme/série, mas você pode mudar.
- **Ícones visuais:** cada instância tem ícone colorido na lista para fácil identificação.

## Validar conectividade e armazenamento por instância

Para confirmar que uma instância está acessível e com espaço em disco saudável, use as ferramentas do **System Management** (documentadas em `diagnostics.md`):

- **Connection Diagnostics** (`/settings/diagnostics`): testa cada endpoint (URL principal e alternativa) por reachability e latência, mostra qual está ativo e exibe traces das requisições recentes. É a forma mais rápida de isolar se o problema é de rede, autenticação ou endpoint.
- **System Overview** (`/settings/system-overview`): mostra o espaço livre em cada disco/root folder da instância, o tamanho da biblioteca e a versão do servidor — útil para antecipar falta de espaço antes que downloads falhem.
