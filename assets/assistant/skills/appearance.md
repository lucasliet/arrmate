---
name: appearance
description: Tema claro/escuro/automático, cor de destaque, idioma, aba inicial
---

# Aparência

## Tema claro escuro automático

**Onde fica:** Configurações → seção "Appearance" → "Theme Mode".

**Passo a passo:**
1. Open **Settings** in bottom navigation or the sidebar.
2. Localizar seção **"Appearance"** (deve estar visível no topo).
3. Tocar em **"Theme Mode"** (mostra subtítulo com modo atual: Light, Dark, ou System).
4. Um **AlertDialog** (diálogo de seleção) aparece com opções:
   - **Light** (ícone de sol): tema claro. Fundo branco, texto escuro.
   - **Dark** (ícone de lua): tema escuro. Fundo preto, texto claro.
   - **System** (ícone de smartphone): segue configuração do SO/dispositivo (automático).
   - Cada opção tem um radio button; selecione tocando.
5. A mudança é **aplicada instantaneamente**.
6. Diálogo fecha automaticamente após seleção.

**Observações:**
- O tema usa **Material 3 Design System**.
- Todas as cores se adaptam automaticamente ao tema escolhido.
- **System** é recomendado para economizar bateria (tema escuro em modo noturno, claro durante dia).
- A escolha é salva localmente (persiste entre sessões).

## Cor de destaque (color scheme) do app

**Onde fica:** Configurações → seção "Appearance" → "Color Scheme".

**Passo a passo:**
1. Abrir Configurações.
2. Localizar seção **"Appearance"**.
3. Tocar em **"Color Scheme"** (mostra um **círculo colorido** indicando cor atual).
4. Um **AlertDialog com seletor de cores** aparece com múltiplos círculos coloridos:
   - **Cores disponíveis:** blue (padrão), indigo, purple, pink, red, orange, amber, green, teal.
   - Cada cor representa a cor de destaque (primary color) do app.
5. Tocar em um círculo de cor para aplicar.
   - A mudança é **instantânea** em toda a UI.
   - O círculo selecionado fica **destacado com borda** para confirmação.
6. Diálogo fecha automaticamente.

**Observações:**
- A cor de destaque é usada em:
  - Botões primários (FAB, "Add" buttons).
  - Icons na navegação ativa.
  - Highlights em campos focados.
  - Links e elementos interativos.
- A escolha é salva localmente e persiste entre sessões.

## Idioma do app (inglês, português, espanhol)

**Onde fica:** Configurações → seção "Appearance" (Aparência / Apariencia) → "Language" (Idioma).

**Primeira abertura:** numa instalação nova, o app pergunta o idioma antes do tour de boas-vindas. A opção do idioma do dispositivo já vem selecionada e a tela muda de idioma ao tocar em cada opção; tocar em **Continue** (Continuar) confirma.

**Passo a passo para trocar depois:**
1. Abrir Configurações.
2. Na seção **"Appearance"**, tocar em **"Language"** (o subtítulo mostra o idioma atual).
3. Escolher uma opção no diálogo:
   - **Padrão do sistema**: segue o idioma do dispositivo (inglês quando o idioma do dispositivo não é suportado).
   - **English**, **Português (Brasil)** ou **Español**.
4. A interface muda **instantaneamente**, sem reiniciar o app.

**Observações:**
- O assistente passa a responder no idioma escolhido.
- Mensagens vindas dos servidores (Radarr, Sonarr, qBittorrent, Jellyfin) continuam no idioma do servidor.
- O idioma entra no backup e é limpo por "Reset app settings" (volta a seguir o sistema).
- No Android 13+, com a opção **Padrão do sistema**, o idioma também segue o que for escolhido em Configurações do sistema → Apps → Arrmate → Idioma.

## Aba inicial — escolher qual abre ao iniciar o app

**Onde fica:** Configurações → seção "Appearance" → "Home Tab".

**Passo a passo:**
1. Abrir Configurações.
2. Localizar seção **"Appearance"**.
3. Tocar em **"Home Tab"** (mostra subtítulo com aba atual: ex: "Movies").
4. Um **AlertDialog com seleção de abas** aparece com opções:
   - **Movies** (ícone de filme): abre na aba Filmes.
   - **Series** (ícone de TV): abre na aba Séries.
   - **Calendar** (ícone de calendário): abre na aba Calendário.
   - **Activity** (ícone de download): abre na aba Atividade.
   - **Settings** é **excluída** das opções (não faz sentido como home).
   - Cada opção tem um radio button; selecione tocando.
5. A mudança é **aplicada na próxima vez** que você abrir o app.
6. Diálogo fecha automaticamente.

**Observações:**
- **Padrão:** Movies (aba Filmes).
- Útil se você usa mais uma aba específica (ex: usuários de qBittorrent preferem Activity como home).
- A escolha é salva nas Preferences do app.
