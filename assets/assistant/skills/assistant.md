---
name: assistant
description: Modelos disponíveis, download, import, switch, delete, how it works, tool-calling
---

# Assistente de IA

## Sobre o Assistant — modelos disponíveis baixar importar trocar deletar

**Onde fica:** Configurações (quinta aba da barra inferior) → seção "System Management" → "Assistant".

O **Assistant** é uma funcionalidade de IA que roda **inteiramente no dispositivo** (on-device) para responder dúvidas sobre o Arrmate. Ele não requer internet e usa um sistema de **tool-calling** para consultar a documentação relevante antes de responder.

**Tela de Assistant:**
- **Seção "Available Models":**
  - Lista de **dois modelos** disponíveis no catálogo:
    - **Gemma 4 E2B** (recomendado):
      - Tamanho: ~2.1 GB.
      - Qualidade: balanceada.
      - Velocidade: mais rápido.
      - RAM necessária: ~4 GB.
      - Status: ✓ melhor para maioria dos dispositivos.
    - **Gemma 4 E4B**:
      - Tamanho: ~4.2 GB.
      - Qualidade: maior precisão nas respostas.
      - Velocidade: mais lento.
      - RAM necessária: ~6+ GB.
      - Status: para dispositivos high-end.
  - Ambos modelos suportam **tool-calling** (busca inteligente na documentação).

- **Seção "Downloaded Models" / "Active Model":**
  - Mostra qual modelo está **atualmente instalado e ativo**.
  - Ícone: ✓ check verde ao lado do modelo ativo.
  - Exemplo: "✓ Gemma 4 E2B (Active)".

**Ações disponíveis:**

1. **Download um modelo novo:**
   - Tocar no botão **"Download"** ao lado do modelo no catálogo.
   - Dialog com progresso de download aparece (barra linear + percentual).
   - Após 100%, modelo fica disponível em "Downloaded Models".
   - Pode levar **2-10 minutos** dependendo da conexão e tamanho.

2. **Switch (trocar) entre modelos instalados:**
   - Se você tem **múltiplos modelos baixados**, tocar **"Switch"** ou diretamente no modelo não-ativo.
   - Dialog com seleção aparece:
     - Lista de modelos instalados.
     - Radio button ao lado de cada.
     - Ícone de **lixeira** 🗑️ ao lado de cada modelo para deletar.
   - Tocar no radio button do modelo desejado.
   - Mudança é **instantânea** (modelo ativo muda).

3. **Delete (remover) um modelo instalado:**
   - Tocar **"Switch"** (mesmo se apenas um modelo está instalado).
   - No dialog de seleção, tocar **ícone de lixeira** 🗑️ ao lado do modelo.
   - Dialog de confirmação: "Delete [Model Name]? This will free up disk space."
   - Tocar **"Delete"** para confirmar ou **"Cancel"** para cancelar.
   - Após confirmar, modelo é removido (libera espaço em disco).

4. **Import modelo de arquivo:**
   - Se você tem arquivo `.litertlm` ou formato compatível do seu computador:
   - Tocar **"Import"** (botão adicional, se disponível).
   - File picker abre; selecione arquivo `.litertlm`.
   - Modelo é importado e fica disponível em "Downloaded Models".

**Observações:**
- Ambos os modelos usam **tool-calling**: antes de responder, o modelo busca automaticamente as skills (seções da documentação) relevantes à sua pergunta.
- Não há "nuvem" ou sincronização — tudo fica no dispositivo.
- Você pode ter **múltiplos modelos instalados** simultaneamente, mas apenas um está ativo.
- Maior modelo (E4B) oferece respostas mais precisas, mas consome mais bateria e memória.
- **Recomendação:** use Gemma 4 E2B em dispositivos com menos de 6GB de RAM.

## Como o Assistant funciona — on-device sem internet

O **Assistant roda 100% localmente** no dispositivo usando **LiteRT-LM** (engine de inferência otimizado para mobile).

**Características fundamentais:**
- ✅ **Sem internet:** não requer conexão com servidores externos.
- ✅ **Privacidade:** seus dados e perguntas **nunca saem do dispositivo**.
- ✅ **Offline:** funciona mesmo em avião ou sem Wi-Fi.
- ✅ **Rápido:** respostas em segundos (dependendo do modelo e dispositivo).
- ✅ **Tool-calling:** busca inteligente na documentação para respostas precisas.

**Fluxo de funcionamento:**

1. **Você faz uma pergunta:**
   - Toque no campo "Ask about Arrmate..." na tela do Assistant.
   - Digite sua pergunta em português (ex: "Como adicionar um filme?").
   - Toque no botão de **enviar** (ícone de seta ou papel de avião).

2. **Tool-calling — busca na documentação:**
   - O modelo **analisa sua pergunta** e identifica quais skills (tópicos) são relevantes.
   - Automaticamente, busca essas skills (ex: se você pergunta sobre filmes, busca `movies.md`).
   - Procura as **seções mais relevantes** dentro de cada skill.
   - Essas seções são **injetadas no contexto** do modelo como informação.

3. **O modelo gera a resposta:**
   - Com base na pergunta + skills relevantes, o modelo gera uma resposta em **português**.
   - Resposta é baseada **apenas** na documentação do Arrmate (não inventa features).
   - A resposta aparece na thread de chat.

4. **Você vê a resposta:**
   - Texto completo é exibido na tela.
   - Pode fazer **follow-up questions** (nova pergunta relacionada).
   - O modelo lembra do contexto anterior na conversa.

**Sistema de skills (documentação):**

O Assistant consult automaticamente **14 skills temáticas**:
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

| Você pergunta | Tool-calling busca | Resposta é baseada em |
|---|---|---|
| "Como adiciono um filme?" | `movies.md` → seção "Adicionar filme" | Passo a passo com screenshots mentais |
| "Qual é a diferença entre Radarr e Sonarr?" | `instances.md` → seção "Instâncias" | Explicação do papel de cada servidor |
| "O app funciona sem Wi-Fi?" | `assistant.md` → esta seção | Confirma funcionamento on-device |
| "Como recebo notificações?" | `notifications.md` + `instances.md` | Passo a passo de setup ntfy.sh |

**Observações finais:**
- **Respostas podem ser lentas:** dependendo do dispositivo e tamanho do modelo, pode levar **5-30 segundos**.
- **Contexto de conversa:** o Assistant mantém histórico da conversa; pode fazer follow-ups ("Mais detalhes", "Como assim?").
- **Tool-calling melhor qualidade:** modelos menores + tool-calling dão respostas melhores que tentar responder sem consultar documentação.
- **Nenhuma métrica é enviada:** nem mesmo qual pergunta você faz; tudo fica no dispositivo.
