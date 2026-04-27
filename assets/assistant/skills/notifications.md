---
name: notifications
description: Configurar ntfy.sh, tópico, auto-configurar webhooks, tipos de evento, central, battery saver
---

# Notificações

## Configurar notificações push via ntfy.sh

**Onde fica:** Configurações → seção "Notifications" → "Notification Settings".

**Passo a passo (primeira vez):**
1. Abrir Configurações (quinta aba da barra inferior).
2. Localizar seção **"Notifications"** (deve estar visível sem scroll ou após scroll).
3. Tocar em **"Notification Settings"** (com ícone de sino e descrição "Setup notifications").
4. Abre a tela **NotificationSettingsScreen** com:
   - Card informativo: "In-App Notifications — Notifications are received in real-time while the app is open..."
   - Se nenhum tópico configurado: botão **"Setup Notifications"** com texto "Tap to generate your unique topic".
5. Tocar **"Setup Notifications"**.
   - Um tópico único ntfy.sh é gerado **automaticamente** (ex: `arrmate_abc123def456`).
   - Mensagem confirma geração.

**Após tópico gerado:**
1. Toggle **"Enable Notifications"** aparece com toggle OFF por padrão.
2. Tocar toggle para ativar (ON).
   - Ícone ao lado muda para "Connected to ntfy.sh" com check verde (🟢).
   - Campo "Your Topic" mostra o tópico gerado.
3. Seção de **"Setup in Radarr/Sonarr"** aparece com:
   - Botão **"Auto-configure *arr instances"** (azul).
   - Instruções de setup manual abaixo (para referência).
4. Tocar **"Auto-Configure All Instances"** (recomendado).
   - Dialog de progresso aparece enquanto configura.
   - Ao finalizar: dialog com resultados ("X instances configured").
5. **Configurar triggers** (ver seção "Tipos de evento" abaixo).

**Observações:**
- ntfy.sh é um serviço **gratuito** de notificações push.
- Tópico é **único por dispositivo** — gerado localmente, não requer conta.
- Notificações são **in-app apenas** (não são push do SO).
- O tópico é armazenado localmente no app (Shared Preferences).

## Tópico ntfy — copiar compartilhar e assinar em outros dispositivos

**Onde fica:** Configurações → Notification Settings → campo "Your Topic".

**Passo a passo:**
1. Na tela de Notification Settings, localize o campo **"Your Topic"** (mostra texto como `arrmate_abc123`).
2. Tocar no **ícone de cópia** (clipboard) ao lado do tópico.
   - Snackbar confirma: "Topic copied to clipboard".
3. **Compartilhar em outro dispositivo:**
   - Cole o tópico em qualquer lugar ou abra `https://ntfy.sh/[seu-topico]` no navegador.
   - Qualquer dispositivo com acesso à URL receberá as notificações.

**Observações:**
- O tópico é **público** — qualquer um com a URL pode receber notificações.
- **Não compartilhe o tópico publicamente** (redes sociais, etc).
- Use para sincronizar notificações entre seus próprios dispositivos apenas.
- Se o tópico foi exposto, você pode regenerar tocando "Setup Notifications" novamente.

## Auto-configurar webhooks nas instâncias Radarr e Sonarr

**Onde fica:** Configurações → Notification Settings → botão "Auto-Configure All Instances".

**O que acontece:**
- O Arrmate **automaticamente** conecta ao Radarr/Sonarr configurado.
- Cria webhooks (conexões) para enviar eventos para o tópico ntfy.
- Cada instância é processada; resultados mostrados em dialog.

**Passo a passo:**
1. Na tela de Notification Settings, tocar **"Auto-Configure All Instances"** (botão azul).
2. Dialog de progresso com loading spinner aparece: "Auto-configuring notifications...".
3. Aguarde conclusão.
4. **Dialog de resultados** exibe:
   - ✓ (check verde) para cada instância configurada com sucesso.
   - ✗ (X vermelho) para instâncias que falharam, com mensagem de erro.
5. Tocar "Close" para fechar dialog.

**Se falhar para uma instância:**
- Verifique que a URL e API Key estão corretos em Configurações → Instances.
- Tente manualmente em Settings do Radarr/Sonarr (Settings → Connect → ntfy).
- Use a instrução manual exibida em "OR MANUAL SETUP" na tela de Notification Settings.

**Observações:**
- **Novas instâncias** adicionadas depois são auto-configuradas **se notificações já estiverem ativas**.
- Os webhooks informam o Radarr/Sonarr para enviar eventos para o tópico ntfy quando eventos ocorrem.

## Tipos de evento de notificação — grab import falha mídia adicionada saúde

**Onde fica:** Configurações → Notification Settings → seção de toggles (aparece apenas se "Enable Notifications" está ON).

**Seções e toggles disponíveis:**

**Downloads:**
- ✓ **Notify on Grab:** alertar quando uma release é capturada e enviada ao cliente de download.
- ✓ **Notify on Import:** alertar quando um arquivo é importado com sucesso à biblioteca.
- ✓ **Notify on Failure:** alertar quando ocorre falha no download ou import.

**Media Updates:**
- ✓ **Movie/Series Added:** alertar quando novo filme ou série é adicionado à biblioteca.
- ✓ **Movie/Series Deleted:** alertar quando filme ou série é deletado.
- ✓ **File Deleted:** alertar quando um arquivo de mídia é deletado.

**System:**
- ✓ ***arr Instance Update:** alertar quando Radarr/Sonarr é atualizado.
- ✓ **Manual Interaction:** alertar quando manual intervention é necessário (ex: manual import).
- ✓ **Health Issues:** alertar sobre health check warnings/errors.
  - Sub-toggles (aparecem indentados se "Health Issues" está ON):
    - ✓ **Include Warnings:** também notifique sobre avisos (não apenas erros).
    - ✓ **Health Restored:** notifique quando um health issue é resolvido.

**Comportamento:**
- Cada toggle pode ser ativado/desativado **independentemente**.
- Mudança é salva **imediatamente** ao tocar.
- Você pode ter qualquer combinação ativa (ex: apenas Grab e Import, sem Failure).
- Se nenhum trigger estiver ON: notificações não serão enviadas mesmo se habilitadas.

**Observações:**
- Recomenda-se manter pelo menos **Notify on Grab** e **Notify on Failure** ativas.
- Health Issues útil para monitorar problemas no servidor.

## Central de notificações — visualizar marcar como lida limpar

**Onde fica:** Ícone de sino na AppBar de qualquer tela principal, **OU** Configurações → seção "Notifications" → "Notification Center".

**Estrutura visual:**
- **AppBar com ações:**
  - Título: "Notifications".
  - Botão **"Mark All as Read"** (aparece apenas se há notificações não lidas).
  - Botão **"Clear All"** (aparece se há notificações; mostra ícone de lixeira).

- **Lista de notificações:**
  - Cada card exibe:
    - **Badge colorido** indicando tipo (Grab, Import, Failure, etc).
    - **Título** da notificação.
    - **Timestamp relativo** (ex: "2 hours ago").
    - **Indicador de leitura:** notificações não lidas têm fundo destacado ou ponto visual.

- **Ações:**
  - **Tocar em uma notificação:** marca como lida (background volta ao normal).
  - **Swipe left/right:** descarta/remove notificação (snackbar permite "Undo").
  - **Botão "Mark All as Read":** marca todas como lidas (aparece apenas se há não lidas).
  - **Botão "Clear All":** remove todas as notificações com confirmação.

- **Pull-to-refresh:** recarrega lista de notificações.

**Estado vazio:**
- Ícone de sino tachado.
- "No notifications"
- Subtitle: "When you receive notifications from Radarr or Sonarr, they will appear here".

**Observações:**
- Notificações são **persistidas localmente** (entre sessões).
- Tocar em uma notificação não navega para conteúdo específico (ainda; pode ser futuro).
- Useful para auditar o que aconteceu no servidor.
