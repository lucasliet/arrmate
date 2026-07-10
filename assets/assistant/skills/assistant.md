---
name: assistant
description: Modelos disponíveis, download, import, switch, delete, how it works, tool-calling
---

# Assistente de IA

## Sobre o Assistant — modelos disponíveis baixar importar trocar deletar

**Onde fica:** Configurações (quinta aba da barra inferior) → seção "System Management" → "Assistant".

O **Assistant** é uma funcionalidade de IA para responder dúvidas sobre o Arrmate. Por padrão ele usa o modelo online gratuito do **OpenCode Zen** sem API key; também é possível usar modelos locais on-device com LiteRT-LM.

**Tela de Assistant:**

- **Model Selector (ListTile único no topo):**
  - **Ícone:** `cloud_outlined` no modo online, `smart_toy` se há modelo local carregado, ou `smart_toy_outlined` se nenhum modelo local está selecionado.
  - **Título:** `OpenCode Zen` no modo online, nome do modelo local ativo (ex: "Gemma 4 E2B"), ou "No local model selected".
  - **Subtítulo:** id do modelo online ativo ou tamanho do modelo local em bytes formatado (ex: "2.1 GB").
  - **Menu ⋮ (PopupMenuButton)** ao lado direito, com as opções:
    - **OpenCode Zen** (ícone `cloud_outlined`) — usa o modo online gratuito sem API key.
    - **Online Models** (ícone `cloud_queue`) — permite escolher um modelo `-free` do OpenCode Zen.
    - **Download** (ícone `download`) — abre sheet do catálogo de modelos locais disponíveis.
    - **Import** (ícone `upload_file`) — abre file picker para selecionar arquivo `.litertlm` do dispositivo.
    - **Local Models** (ícone `swap_horiz`) — aparece **apenas se há modelos instalados**; abre sheet de seleção de modelo local ativo.

**Ações disponíveis:**

1. **Usar OpenCode Zen online:**
   - O modo online é o padrão do Assistant.
   - Ele busca os modelos em `https://opencode.ai/zen/v1/models`, usa apenas modelos terminados em `-free` e não exige API key.
   - O modelo padrão é `deepseek-v4-flash-free`.
   - Se o modelo ativo falhar, o app tenta automaticamente o próximo modelo free da lista e mantém o primeiro que funcionar.

2. **Download um modelo local novo:**
   - Tocar no **ícone ⋮** do model selector → tocar **"Download"**.
   - Um sheet abre exibindo o **catálogo de modelos** disponíveis:
     - Cada modelo mostra nome e descrição.
     - Se já instalado: badge **"Installed"** + ícone `check_circle`.
   - Tocar no modelo desejado para iniciar o download.
   - Progresso aparece no model selector enquanto baixa.
   - Pode levar **2-10 minutos** dependendo da conexão e tamanho.

3. **Switch (trocar) entre modelos locais instalados:**
   - Tocar no **ícone ⋮** do model selector → tocar **"Switch"** (opção visível apenas se há modelos instalados).
   - Um sheet abre com lista dos modelos instalados:
     - **Radio button** (marcado/desmarcado) ao lado de cada modelo.
     - Nome e tamanho do modelo.
     - **Botão de lixeira** (vermelho) ao lado de cada modelo para deletar.
   - Tocar no radio button do modelo desejado.
   - Mudança é **instantânea** (modelo ativo muda).

4. **Delete (remover) um modelo local instalado:**
   - Tocar no **ícone ⋮** do model selector → tocar **"Switch"**.
   - No sheet de seleção, tocar o **ícone de lixeira** (vermelho) ao lado do modelo.
   - Dialog de confirmação aparece.
   - Tocar **"Delete"** para confirmar ou **"Cancel"** para cancelar.
   - Após confirmar, modelo é removido (libera espaço em disco).

5. **Import modelo local de arquivo:**
   - Tocar no **ícone ⋮** do model selector → tocar **"Import"**.
   - File picker abre; selecione um arquivo no formato **`.litertlm`**.
   - Modelo é importado e fica disponível para seleção.

**Observações:**
- O modo online envia a pergunta e a documentação relevante para o OpenCode Zen.
- O modo local roda no dispositivo e usa **tool-calling** para carregar skills relevantes.
- Você pode ter **múltiplos modelos locais instalados** simultaneamente, mas apenas um modelo local está ativo.
- Maior modelo local (E4B) oferece respostas mais precisas, mas consome mais bateria e memória.
- **Recomendação:** use OpenCode Zen para começar rapidamente, ou Gemma 4 E2B local em dispositivos com menos de 6GB de RAM.

## Como o Assistant funciona — online e local

O **Assistant** pode usar o OpenCode Zen online ou modelos locais no dispositivo usando **LiteRT-LM** (engine de inferência otimizado para mobile).

**Características fundamentais:**
- ✅ **Online por padrão:** usa modelos gratuitos do OpenCode Zen sem API key.
- ✅ **Fallback automático:** se o modelo online ativo falhar, tenta o próximo modelo free da lista.
- ✅ **Modo local opcional:** funciona com modelos `.litertlm` baixados ou importados.
- ✅ **Offline no modo local:** modelos locais funcionam mesmo em avião ou sem Wi-Fi.
- ✅ **Baseado na documentação:** usa a documentação do Arrmate para respostas precisas.

**Fluxo de funcionamento:**

1. **Você faz uma pergunta:**
   - Toque no campo "Ask about Arrmate..." na tela do Assistant.
   - Digite sua pergunta em português (ex: "Como adicionar um filme?").
   - Toque no botão de **enviar** (ícone de seta ou papel de avião).

2. **Busca na documentação:**
   - No modo online, o app seleciona as skills mais relevantes localmente e envia esse contexto para o OpenCode Zen.
   - No modo local, o modelo usa tool-calling para carregar skills relevantes.
   - As seções relevantes são injetadas no contexto do modelo como informação.

3. **O modelo gera a resposta:**
   - Com base na pergunta + skills relevantes, o modelo gera uma resposta em **português**.
   - Resposta é baseada **apenas** na documentação do Arrmate (não inventa features).
   - A resposta aparece na thread de chat.

4. **Você vê a resposta:**
   - Texto completo é exibido na tela.
   - Pode fazer **follow-up questions** (nova pergunta relacionada).
   - O modelo lembra do contexto anterior na conversa.

**Sistema de skills (documentação):**

O Assistant consulta automaticamente **14 skills temáticas**:
- `overview.md` — navegação global, abas.
- `library.md` — busca, filtros, sort.
- `calendar.md` — calendário, lançamentos.
- `movies.md` — adicionar, detalhes, editar filmes.
- `series.md` — séries, temporadas, episódios.
- `activity.md` — queue, history, importação manual.
- `qbittorrent.md` — cliente torrent, downloads.
- `instances.md` — configurar servidores, credenciais.
- `notifications.md` — ntfy.sh, notificações, central.
- `appearance.md` — tema, cor, aba inicial.
- `system.md` — logs, health, quality profiles.
- `assistant.md` — este arquivo, sobre o próprio Assistant.
- `troubleshooting.md` — erros comuns, soluções.
- `support.md` — feedback, bugs, comunidade.

**Exemplo prático:**

| Você pergunta | Documentação consultada | Resposta é baseada em |
|---|---|---|
| "Como adiciono um filme?" | `movies.md` → seção "Adicionar filme" | Passo a passo com screenshots mentais |
| "Qual é a diferença entre Radarr e Sonarr?" | `instances.md` → seção "Instâncias" | Explicação do papel de cada servidor |
| "O app funciona sem Wi-Fi?" | `assistant.md` → esta seção | Confirma funcionamento on-device |
| "Como recebo notificações?" | `notifications.md` + `instances.md` | Passo a passo de setup ntfy.sh |

**Observações finais:**
- **Respostas podem ser lentas:** dependendo da conexão, do modelo online ou do tamanho do modelo local, pode levar **5-30 segundos**.
- **Contexto de conversa:** o Assistant mantém histórico da conversa; pode fazer follow-ups ("Mais detalhes", "Como assim?").
- **Melhor qualidade:** respostas baseadas na documentação são melhores que tentar responder sem consultar o conteúdo do app.
- **Privacidade:** no modo online a pergunta é enviada ao OpenCode Zen; no modo local tudo fica no dispositivo.
