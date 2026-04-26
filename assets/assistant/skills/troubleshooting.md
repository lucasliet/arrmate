---
name: troubleshooting
description: Erros de conexão, autenticação, notificações, app desatualizado, modelo não carrega
---

# Solução de problemas

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

1. **Modelo compatível:** usar modelos do catálogo oficial (Gemma 4 E2B, Gemma 4 E4B).
2. **Memória:** modelos maiores (Gemma 4 E4B) precisam de mais RAM. Fechar outros apps pode ajudar.
3. **Trocar modelo:** tentar modelo menor (Gemma 4 E2B) se o maior travar.
4. **Reimportar:** se o modelo foi importado manualmente, pode estar corrompido. Tentar baixar do catálogo.
5. **Dispositivo antigo:** em dispositivos com pouca RAM, usar o Gemma 4 E2B para melhor desempenho.
