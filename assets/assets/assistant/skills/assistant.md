---
name: assistant
description: Modelos disponíveis, OpenCode Zen, Apple Intelligence, LiteRT, download, import, switch, delete, how it works, tool-calling
---

# Assistente de IA

## Sobre o Assistant — modelos disponíveis baixar importar trocar deletar

**Location:** **Settings** in bottom navigation or the sidebar → "System" → "Assistant".

O **Assistant** é uma funcionalidade de IA para responder dúvidas sobre o Arrmate. Por padrão ele usa o modelo online gratuito do **OpenCode Zen** sem API key. A IA local (on-device) depende da plataforma:

| Plataforma | IA em nuvem | IA local |
|---|---|---|
| Android | OpenCode Zen | Modelos LiteRT-LM (Gemma) baixados ou importados |
| iPhone, iPad e Mac | OpenCode Zen | **Apple Intelligence** (modelo do sistema, iOS 26 / macOS 26 ou mais recente) |
| Windows, Linux e Web | OpenCode Zen | Não disponível |

**Tela de Assistant:**

- **Model Selector (ListTile único no topo):**
  - **Ícone:** `cloud_outlined` no modo online, `apple` no modo Apple Intelligence, `smart_toy` se há modelo LiteRT carregado, ou `smart_toy_outlined` se nenhum modelo local está selecionado.
  - **Título:** `OpenCode Zen` no modo online, `Apple Intelligence`, nome do modelo LiteRT ativo (ex: "Gemma 4 E2B"), ou "No local model selected".
  - **Subtítulo:** id do modelo online ativo, "On-device model" (Apple Intelligence pronto) ou o motivo da indisponibilidade, ou tamanho do modelo LiteRT formatado (ex: "2.1 GB").
  - **Menu ⋮ (PopupMenuButton)** ao lado direito, com as opções:
    - **OpenCode Zen** (ícone `cloud_outlined`) — usa o modo online gratuito sem API key. Todas as plataformas.
    - **Online Models** (ícone `cloud_queue`) — permite escolher um modelo `-free` do OpenCode Zen. Todas as plataformas.
    - **Apple Intelligence** (ícone `apple`) — **apenas iPhone, iPad e Mac**; usa o modelo on-device do sistema. Quando indisponível, o item mostra o motivo logo abaixo do nome.
    - **Download** (ícone `download`) — **apenas Android**; abre sheet do catálogo de modelos LiteRT disponíveis.
    - **Import** (ícone `upload_file`) — **apenas Android**; abre file picker para selecionar arquivo `.litertlm` do dispositivo.
    - **Local Models** (ícone `swap_horiz`) — **apenas Android** e **apenas se há modelos instalados**; abre sheet de seleção de modelo LiteRT ativo.

**Ações disponíveis:**

1. **Usar OpenCode Zen online:**
   - O modo online é o padrão do Assistant.
   - Ele busca os modelos em `https://opencode.ai/zen/v1/models`, usa apenas modelos terminados em `-free` e não exige API key.
   - O modelo padrão é `mimo-v2.6-flash-free`.
   - Se o modelo ativo falhar, o app tenta automaticamente o próximo modelo free da lista e mantém o primeiro que funcionar.

2. **Usar Apple Intelligence (iPhone, iPad e Mac):**
   - Tocar no **ícone ⋮** do model selector → tocar **"Apple Intelligence"**.
   - Requisitos: **iOS 26 / iPadOS 26 / macOS 26** ou mais recente, aparelho compatível com Apple Intelligence e Apple Intelligence **ativado** nos Ajustes do sistema.
   - Não há download nem import: o modelo é do próprio sistema.
   - Se algum requisito faltar, o app mostra o motivo (ex: "Turn on Apple Intelligence in the system settings.") e continua no modo atual.
   - Ao tocar na opção, o app verifica a disponibilidade de novo — útil depois de ativar a Apple Intelligence ou quando o modelo termina de baixar.

3. **Download um modelo local novo (Android):**
   - Tocar no **ícone ⋮** do model selector → tocar **"Download"**.
   - Um sheet abre exibindo o **catálogo de modelos** disponíveis:
     - Cada modelo mostra nome e descrição.
     - Se já instalado: badge **"Installed"** + ícone `check_circle`.
   - Tocar no modelo desejado para iniciar o download.
   - Progresso aparece no model selector enquanto baixa.
   - Pode levar **2-10 minutos** dependendo da conexão e tamanho.

4. **Switch (trocar) entre modelos locais instalados (Android):**
   - Tocar no **ícone ⋮** do model selector → tocar **"Switch"** (opção visível apenas se há modelos instalados).
   - Um sheet abre com lista dos modelos instalados:
     - **Radio button** (marcado/desmarcado) ao lado de cada modelo.
     - Nome e tamanho do modelo.
     - **Botão de lixeira** (vermelho) ao lado de cada modelo para deletar.
   - Tocar no radio button do modelo desejado.
   - Mudança é **instantânea** (modelo ativo muda).

5. **Delete (remover) um modelo local instalado (Android):**
   - Tocar no **ícone ⋮** do model selector → tocar **"Switch"**.
   - No sheet de seleção, tocar o **ícone de lixeira** (vermelho) ao lado do modelo.
   - Dialog de confirmação aparece.
   - Tocar **"Delete"** para confirmar ou **"Cancel"** para cancelar.
   - Após confirmar, modelo é removido (libera espaço em disco).

6. **Import modelo local de arquivo (Android):**
   - Tocar no **ícone ⋮** do model selector → tocar **"Import"**.
   - File picker abre; selecione um arquivo no formato **`.litertlm`**.
   - Modelo é importado e fica disponível para seleção.

**Observações:**
- O modo online envia a pergunta e a documentação relevante para o OpenCode Zen.
- O modo local LiteRT (Android) roda no dispositivo e usa **tool-calling** para carregar skills relevantes.
- O modo Apple Intelligence roda no dispositivo; o app envia apenas os trechos mais relevantes da documentação, porque o modelo da Apple tem contexto curto.
- Você pode ter **múltiplos modelos LiteRT instalados** simultaneamente, mas apenas um modelo local está ativo.
- Maior modelo local (E4B) oferece respostas mais precisas, mas consome mais bateria e memória.
- **Recomendação:** use OpenCode Zen para começar rapidamente; para respostas offline use Apple Intelligence no iPhone, iPad ou Mac, ou Gemma 4 E2B no Android em dispositivos com menos de 6GB de RAM.

## Como o Assistant funciona — online e local

O **Assistant** pode usar o OpenCode Zen online ou IA local no dispositivo: **LiteRT-LM** (engine de inferência otimizado para mobile) no Android, ou **Apple Intelligence** (modelo de linguagem do sistema) no iPhone, iPad e Mac.

**Características fundamentais:**
- ✅ **Online por padrão:** usa modelos gratuitos do OpenCode Zen sem API key.
- ✅ **Fallback automático:** se o modelo online ativo falhar, tenta o próximo modelo free da lista.
- ✅ **Modo local opcional:** modelos `.litertlm` baixados ou importados no Android; Apple Intelligence no iPhone, iPad e Mac.
- ✅ **Offline no modo local:** a IA local funciona mesmo em avião ou sem Wi-Fi.
- ❌ **Windows, Linux e Web:** apenas o OpenCode Zen online.
- ✅ **Baseado na documentação:** usa a documentação do Arrmate para respostas precisas.

**Fluxo de funcionamento:**

1. **Você faz uma pergunta:**
   - Toque no campo "Ask about Arrmate..." na tela do Assistant.
   - Digite sua pergunta em português (ex: "Como adicionar um filme?").
   - Toque no botão de **enviar** (ícone de seta ou papel de avião).

2. **Busca na documentação:**
   - No modo online, o app seleciona as skills mais relevantes localmente e envia esse contexto para o OpenCode Zen.
   - No modo local LiteRT, o modelo usa tool-calling para carregar skills relevantes.
   - No modo Apple Intelligence, o app escolhe as seções mais relevantes das skills e as envia junto com as últimas mensagens da conversa, cabendo no contexto do modelo.
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

O Assistant consulta automaticamente **15 skills temáticas**:
- `overview.md` — navegação global, abas.
- `library.md` — busca, filtros, sort.
- `calendar.md` — calendário, lançamentos, filtros.
- `movies.md` — adicionar, detalhes, editar filmes, discover.
- `series.md` — séries, temporadas, episódios, discover.
- `activity.md` — queue, history, importação manual.
- `qbittorrent.md` — cliente torrent, downloads.
- `instances.md` — configurar servidores, credenciais.
- `notifications.md` — ntfy.sh, notificações, central.
- `appearance.md` — tema, cor, aba inicial.
- `system.md` — logs, health, quality profiles.
- `diagnostics.md` — connection diagnostics, system overview storage, version history, what's new, offline banner.
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
- **Privacidade:** no modo online a pergunta é enviada ao OpenCode Zen; nos modos locais (LiteRT e Apple Intelligence) tudo fica no dispositivo.
