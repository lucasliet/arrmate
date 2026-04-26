---
name: notifications
description: Configurar ntfy.sh, tópico, auto-configurar webhooks, tipos de evento, central, battery saver
---

# Notificações

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
