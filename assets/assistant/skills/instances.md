---
name: instances
description: Adicionar/editar/remover instância Radarr/Sonarr/qBittorrent, API key, test connection, slow mode, custom headers, multi-instância
---

# Instâncias

## Adicionar instância — Radarr Sonarr ou qBittorrent

**Onde fica:** Configurações (quinta aba da barra inferior) → seção "Instances" → "Add Instance".

A tela de **Add Instance** permite configurar um novo servidor Radarr, Sonarr ou qBittorrent.

**Estrutura da tela:**

1. **Seletor Segmentado no topo (tabs):**
   - **Radarr** (ícone 🎬): para servidor de filmes.
   - **Sonarr** (ícone 📺): para servidor de séries.
   - **qBittorrent** (ícone ⬇️): para cliente de downloads.
   - Toque para alternar tipo.

2. **Formulário de configuração:**
   - **Name** (obrigatório):
     - Label: "Instance Name".
     - Exemplo: "Casa", "VPS Remoto", "NAS Sala".
     - Campo de texto livre; qualquer nome descritivo.
   
   - **URL** (obrigatório):
     - Label: "URL".
     - Exemplo: `http://192.168.1.10:7878` (Radarr), `http://192.168.1.10:8989` (Sonarr), `http://192.168.1.10:8080` (qBittorrent).
     - **Importante:** incluir protocolo (http/https) e porta.
     - Campo de texto; suporta IPv4, IPv6, hostname ou domain.
   
   - **API Key** (Radarr/Sonarr apenas):
     - Label: "API Key".
     - Colar chave gerada no servidor (Settings → General → API Key no Radarr/Sonarr web).
     - Campo de texto; pode usar botão de "visibility toggle" (olho) para ver/ocultar.
   
   - **Username & Password** (qBittorrent apenas):
     - Label: "Username" e "Password".
     - Credenciais da WebUI do qBittorrent.
     - Campos de texto; password tem visibility toggle.

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
- Metadados da instância (perfis, pastas, tags) são **cacheados** na primeira conexão.
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
   - API Key (Radarr/Sonarr) ou Username+Password (qBittorrent).

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
  - Útil para reverse proxies que exigem autenticação HTTP Basic.
- **Observações:**
  - Não adicione headers desnecessários; pode quebrar requisições.
  - Valores sensíveis (tokens, senhas) são armazenados **localmente no device** (não sincronizados).

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
