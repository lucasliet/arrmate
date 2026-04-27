---
name: appearance
description: Tema claro/escuro/automático, cor de destaque, aba inicial
---

# Aparência

## Tema claro escuro automático

**Onde fica:** Configurações → seção "Appearance" → "Theme Mode".

**Passo a passo:**
1. Abrir Configurações (quinta aba da barra inferior).
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
