---
name: troubleshooting
description: Erros de conexão, autenticação API key, notificações, app desatualizado, modelo Assistant
---

# Solução de Problemas

## Erro de conexão com instância — diagnóstico e solução

**Sintomas:**
- App mostra "Connection failed", "Connection timeout", ou "Unable to connect" ao tentar carregar dados.
- Botão "Test Connection" mostra erro em vermelho.
- Filmes/séries/activity não carregam.

**Checklist de diagnóstico:**

| Passo | Verificar | Solução |
|---|---|---|
| **1. URL e porta** | Configurações → Instances → tocar instância. URL está correta? | Incluir protocolo (`http://` ou `https://`) + IP/hostname + porta. Exemplos: `http://192.168.1.10:7878` (Radarr), `http://192.168.1.10:8989` (Sonarr), `http://192.168.1.10:8080` (qBittorrent). |
| **2. Serviço rodando** | Acessar servidor via navegador no mesmo IP. | Se não abre, serviço Radarr/Sonarr/qBittorrent não está rodando. Reiniciar no servidor. |
| **3. Conectividade de rede** | Dispositivo está na mesma rede, VPN, etc? | Se remoto, VPN deve estar ativa. Ping do servidor (se possível) para confirmar alcance. |
| **4. Firewall/porta** | Porta está aberta no servidor? | Verificar firewall do servidor (Linux: `ufw`, Windows: Windows Defender, etc). Permitir porta. |
| **5. API Key (Radarr/Sonarr)** | Credenciais estão corretas? | Configurações → Instances → tocar instância. Verificar campo "API Key". Se vazio ou errado, atualizar. |
| **6. Timeout** | Servidor é lento ou remoto? | Ativar **Slow Mode** (Advanced Options → toggle "Slow Mode") para aumentar timeout de 30s → 90s. |
| **7. Teste novamente** | Todos verificados? | Tocar "Test Connection" na edição de instância. Deve mostrar "✓ Connection successful!" em verde. |

**Ações corretivas:**

1. **Atualizar credenciais:**
   - Configurações → Instances → tocar instância → corrigir campos.
   - Tocar "Test Connection" para validar.
   - Tocar "Save".

2. **Ativar Slow Mode (para servidores remotos/lentos):**
   - Configurações → Instances → tocar instância.
   - Scroll até "Advanced Options" → expansível.
   - Toggle **"Slow Mode"** para ON.
   - Tocar "Save".

3. **Resetar conexão:**
   - Fechar app completamente.
   - Aguardar 5 segundos.
   - Reabrir app.

## Erro de autenticação — API Key inválida, username/password incorreto

**Sintomas:**
- "Unauthorized", "Invalid API key", "401 Unauthorized", "Login failed".
- Erro ao tocar "Test Connection".

**Para Radarr/Sonarr (API Key):**

1. **Obter API Key correto:**
   - Abrir interface web do servidor no navegador (`http://[ip]:7878` para Radarr, `:8989` para Sonarr).
   - Ir em **Settings** (ícone ⚙️).
   - Abrir seção **"General"**.
   - Localizar campo **"API Key"** (string aleatória, ex: `a1b2c3d4e5f6`).
   - Copiar valor.

2. **Atualizar no Arrmate:**
   - Configurações → Instances → tocar instância.
   - Campo "API Key" → colar chave copiada.
   - Tocar "Test Connection" para validar.
   - Tocar "Save".

3. **Se error persiste:**
   - Regenerar API Key no servidor (Settings → General → regenerate/reset).
   - Copiar novo valor.
   - Atualizar Arrmate novamente.

**Para qBittorrent (Username/Password):**

1. **Verificar credenciais:**
   - WebUI do qBittorrent → Settings (ícone ⚙️).
   - Abrir seção **"WebUI"** ou **"Web UI"**.
   - Verificar **Username** e **Password** configurados.
   - Confirmar que **WebUI está habilitada** (checkbox "Enable Web User Interface").

2. **Atualizar no Arrmate:**
   - Configurações → Instances → tocar instância (tipo qBittorrent).
   - Campos **"Username"** e **"Password"** → inserir credenciais corretas.
   - Tocar "Test Connection" para validar.
   - Tocar "Save".

3. **Se error persiste:**
   - Resetar senha no qBittorrent (Settings → WebUI → "Reset to default").
   - Tentar novamente.

## Notificações não chegam — verificações e solução

**Sintomas:**
- Central de notificações vazia.
- Nenhum evento do Radarr/Sonarr é recebido.
- Sino (bell icon) não mostra badge de novas notificações.

**Checklist de diagnóstico (em ordem):**

| Passo | Verificar | Solução |
|---|---|---|
| **1. Notificações ativas** | Configurações → Notification Settings → "Enable Notifications" está ON? | Se OFF, tocar toggle para ligar. |
| **2. Tópico gerado** | Campo "Your Topic" mostra um tópico (ex: `arrmate_abc123`)? | Se vazio, tocar "Setup Notifications" para gerar novo tópico. |
| **3. Conexão ntfy** | Ícone ao lado de "Enable Notifications" mostra "✓ Connected"? | Se não, tentar "Setup Notifications" novamente. |
| **4. Webhooks configurados** | Radarr/Sonarr têm webhooks para o tópico ntfy? | Tocar "Auto-Configure All Instances" para configurar automaticamente. |
| **5. Triggers ativos** | Pelo menos um toggle de evento está ON (Notify on Grab, Notify on Import, etc)? | Se todos OFF, nenhuma notificação será enviada. Ativar pelo menos um. |
| **6. Internet ativa** | Dispositivo tem acesso a `ntfy.sh` (via internet)? | Notificações requerem conexão com ntfy.sh remoto. Verificar conectividade. |
| **7. Teste manual** | Acessar `https://ntfy.sh/[seu-topico]` no navegador. | Se página abre, tópico existe. Se vazio, ainda não há notificações. |

**Ações corretivas:**

1. **Setup completo novamente:**
   - Configurações → Notification Settings.
   - Tocar "Setup Notifications" (gera novo tópico ou usa existente).
   - Toggle "Enable Notifications" para ON.
   - Tocar "Auto-Configure All Instances".
   - Dialog mostra progresso; confirmar sucesso para cada instância.

2. **Ativar triggers:**
   - Notification Settings → scroll até toggles de eventos.
   - Ativar pelo menos:
     - ✓ **Notify on Grab** (alertar captura).
     - ✓ **Notify on Import** (alertar importação).
     - ✓ **Notify on Failure** (alertar falhas).

3. **Testar fluxo completo:**
   - No Radarr/Sonarr, procurar filme/série.
   - Fazer busca/adicionar para gerar evento.
   - Voltar para Arrmate → sino (bell icon) deve mostrar notificação.
   - Se não aparecer em 30 segundos, problemas acima permanecem.

## App parece desatualizado ou UI não reflete mudanças

**Sintomas:**
- Dados na tela parecem antigos.
- Mudança feita no servidor não aparece imediatamente no app.
- Botões/menus não atualizam.

**Solução (em ordem de tentativa):**

1. **Pull-to-refresh (mais rápido):**
   - Abrir tela afetada.
   - Arrastar para baixo com dedo.
   - Spinner mostra recarregamento.
   - Liberar para recarregar dados.

2. **Reabrir tela:**
   - Navegar para outra aba (ex: Series se estava em Movies).
   - Voltar para aba original.
   - Dados são recarregados.

3. **Reiniciar app (mais completo):**
   - Fechar app completamente (sair).
   - Aguardar 3-5 segundos.
   - Reabrir app.
   - Cache local é limpo; dados são re-sincronizados.

4. **Limpar cache (último recurso):**
   - Configurações do dispositivo → Apps → Arrmate → "Storage & cache" → "Clear cache".
   - Reabre app; re-sincroniza dados (pode levar mais tempo na primeira vez).

**Observação:** O app cacheia dados localmente para performance. Mudanças no servidor podem levar **até 30 segundos** para aparecer sem ação manual.

## Modelo do Assistant não carrega, trava ou responde lentamente

**Sintomas:**
- Tela de Assistant mostra loading infinito.
- App trava ao tentar usar Assistant.
- Modelo não aparece em "Downloaded Models".
- Respostas levam mais de 1 minuto.

**Solução (em ordem):**

1. **Verificar modelo compatível:**
   - Configurações → System Management → Assistant.
   - Apenas **Gemma 4 E2B** e **Gemma 4 E4B** são suportados.
   - Se modelo diferente foi importado, **Delete** e **Download** um oficial.

2. **Liberar memória:**
   - Fechar outros apps abertos (especialmente navegador, YouTube, etc).
   - Restart dispositivo se muitos apps estão rodando.
   - Modelos maiores (E4B) precisam de **6+ GB RAM** livre.

3. **Trocar para modelo menor (se trava):**
   - Configurações → Assistant → "Switch".
   - Dialog → ícone lixeira ao lado do modelo travado → "Delete".
   - Download **Gemma 4 E2B** (menor, mais rápido).
   - "Switch" para E2B.

4. **Reimportar modelo (se corrompido):**
   - Delete modelo atual.
   - Download novamente do catálogo (não importar arquivo local).

5. **Verificar especificações do dispositivo:**
   - Modelos LLM precisam de RAM adequada.
   - Se dispositivo tem < 4GB RAM total, apenas E2B funciona.
   - Se trava constantemente, upgrade dispositivo não é viável; use Assistant em dispositivo mais potente.

**Dica:** Para melhor experiência, use **Gemma 4 E2B** em qualquer dispositivo (mais rápido, mesma qualidade razoável).
