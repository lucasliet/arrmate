---
name: support
description: Funcionalidades suportadas/não suportadas, FAQs, onde reportar bugs, feedback
---

# Suporte & Comunidade

## O que o Arrmate suporta — funcionalidades atuais

### ✅ SUPORTADO

**Gerenciamento de Biblioteca:**
- Navegar e gerenciar filmes (Radarr) e séries (Sonarr).
- Busca local de filmes/séries com filtros avançados (título, ano, rating, tamanho, etc).
- Ordenação (por título, ano, adicionado, rating, tamanho, duração).
- Visualização em grid ou lista.
- Ver detalhes completos (Overview, Files & Metadata, History).

**Adicionar Conteúdo:**
- Adicionar novo filme/série via busca online (integrado com Radarr/Sonarr).
- Selecionar quality profile, root folder e outras opções na adição.
- Editar filme/série (monitoramento, qualidade, pasta, tipo de série, etc).
- Deletar filme/série da biblioteca (com confirmação).
- Deletar arquivo de mídia individual (arquivo de filme ou episódio).

**Busca & Download:**
- Busca manual de releases (interactive search / manual grab).
- Seleção de release desejada antes de enviar para download.
- Import manual de arquivos da fila (manual import dialog).
- Import de torrents completos diretamente para biblioteca (torrent import com seleção de alvo).

**Calendário & Monitoramento:**
- Calendário de lançamentos futuros (filmes e episódios).
- Agrupar por data.
- Ver status de monitoramento e episódios faltando.

**Atividade & Downloads:**
- Fila de downloads ativa (Queue) com progresso, velocidade, ETA.
- Histórico de eventos (Grabbed, Imported, Failed, Deleted).
- Cliente qBittorrent completo:
  - Listar torrents com filtros (All, Downloading, Seeding, Paused, Error).
  - Adicionar torrent (magnet link, HTTP URL, arquivo .torrent).
  - Pausa, retoma, rechecks, remove torrent.
  - Ver arquivos de cada torrent.
  - Mover torrent entre pastas.
  - Import torrent completo para Radarr/Sonarr.

**Notificações:**
- Push notifications via ntfy.sh.
- Sincronização multi-dispositivo (mesma instância em vários devices recebe notificações).
- Tipos de evento: Grab, Import, Failure, Media Added/Deleted, File Deleted, Instance Update, Manual Interaction, Health Issues.
- Central de notificações (visualizar, marcar como lida, limpar).

**Configuração & Sistema:**
- Multi-instância (múltiplos Radarr, Sonarr, qBittorrent simultâneos).
- Perfis de qualidade (visualizar disponíveis em cada instância).
- Logs (ARR logs do servidor + APP logs internos) com filtros.
- Health checks (diagnóstico de problemas do servidor).
- Tema (Light/Dark/System).
- Cor de destaque (customização de color scheme).
- Aba inicial (escolher qual aba abre ao iniciar).
- Advanced: Slow Mode, Custom Headers para instâncias.

**Atualização:**
- Verificação automática de atualizações (via GitHub Releases).
- Download e instalação OTA (Over-The-Air) de novas versões.

**Assistente de IA:**
- LLM on-device (Gemma 4 E2B ou E4B).
- Tool-calling para respostas baseadas na documentação.
- Sem envio de dados para nuvem.
- Suporta follow-up questions.

---

### ❌ NÃO SUPORTADO

**Reprodução/Streaming:**
- Reprodução ou streaming de arquivos de mídia (Arrmate não é um player).
- Integração com Plex, Jellyfin, Emby (apenas Radarr/Sonarr/qBittorrent).

**Gerenciamento Avançado (requer web):**
- Adicionar/remover/editar indexadores (faça via interface web do Radarr/Sonarr).
- Configurar download clients (Deluge, Transmission, Sabnzbd, etc) — faça via web do Radarr/Sonarr.
- Backup/restauração de configuração do Arrmate.
- Sincronização de configuração entre dispositivos.

**Recursos de Segurança:**
- Autenticação/biometria para abrir o app (qualquer um com acesso ao dispositivo pode acessar).
- Criptografia de credenciais (armazenadas em text plano no device).

**Widgets & Integração:**
- Widget de homescreen.
- Atalhos rápidos (shortcuts).
- Notificação de sistema (push notifications da OS; apenas in-app + ntfy.sh).

**Funcionalidades Futuras (não implementadas):**
- Edição em massa de filmes/séries.
- Importação de lista (Trakt, IMDb, etc).
- Recomendações baseadas em histórico.
- Modo offline (app precisa de internet para conectar ao servidor).

---

## FAQs — Perguntas frequentes

**P: Preciso de acesso à internet para usar o Arrmate?**
R: Sim e não. O Arrmate precisa de internet para **conectar ao seu servidor Radarr/Sonarr/qBittorrent remoto**. Porém, o **Assistant roda offline** (on-device) sem precisar de internet. Se servidores estão na LAN local (mesma rede Wi-Fi), o app funciona sem VPN/internet externa.

**P: Os dados são sincronizados com a nuvem?**
R: Não. Tudo fica no dispositivo. Credenciais, configurações, cache de filmes — **nada sai do app**. O app apenas se conecta ao seu servidor pessoal.

**P: Posso usar o Arrmate com múltiplos Radarr/Sonarr?**
R: Sim. Configure todas as instâncias em Configurações → Instances. Filmes/séries aparecerão agregados na mesma aba.

**P: Como funciona o Assistant de IA?**
R: O Assistant roda **100% no dispositivo** usando um modelo LLM (Gemma 4). Usa tool-calling para buscar a documentação relevante antes de responder. Nenhuma pergunta é enviada para nuvem.

**P: Qual modelo de IA devo baixar?**
R: **Gemma 4 E2B** é recomendado para a maioria (2.1 GB, equilibrado). Use **E4B** apenas se seu dispositivo tem 6+ GB RAM e quer melhor qualidade.

**P: O app recebe notificações em tempo real?**
R: Notificações chegam via ntfy.sh (serviço gratuito remoto). O app recebe quando o servidor Radarr/Sonarr envia webhook. Se nenhuma notificação chega, verifique que webhooks foram auto-configurados (Notification Settings → "Auto-Configure All Instances").

**P: Posso editar categorias, indexadores ou download clients no app?**
R: Não. Essas configurações requerem interface web do Radarr/Sonarr. O Arrmate é apenas um **cliente mobile** (leitura + ações básicas como add/delete/edit).

**P: O app funciona em tablets?**
R: Sim. Interface é responsiva e funciona em qualquer Android 6+. Layout se adapta a telas maiores.

**P: Posso fazer backup das minhas configurações do Arrmate?**
R: Não há função de backup nativa. Instância configuradas são salvas localmente. Se reinstalar app, precisa reconfigurar. Sugestão: anote URLs e API keys em local seguro.

---

## Onde reportar bugs e dar feedback

### 📋 Reportar um bug ou problema

1. **Abrir repositório GitHub:**
   - Navegador → `https://github.com/lucasliet/arrmate`

2. **Ir para aba "Issues":**
   - Procurar se o bug já foi reportado (use search).
   - Se não existe, tocar "New issue" → "Bug report".

3. **Preencher informações:**
   - Título claro: ex: "App crashes when importing torrent".
   - Descrição: passos para reproduzir, versão do app, modelo do dispositivo.
   - Logs: se possível, incluir logs do app (Configurações → System Management → Logs → "Copy all").

4. **Enviar issue:**
   - Tocar "Submit new issue".
   - Mantidor responderá em breve.

### 💡 Sugerir feature/melhoria

1. **Abrir GitHub Issues** → "New issue" → "Feature request".
2. **Descrever:**
   - Qual feature você gostaria.
   - Por que seria útil.
   - Exemplos de como funcionaria.
3. **Enviar.**
   - Comunidade discute e mantidor avalia.

### 💬 Participar da comunidade

- **GitHub Discussions:** conversar sobre ideias, dúvidas técnicas, etc.
- **GitHub Issues:** bugs e features (mais formal).
- **Redes sociais:** se app está vinculado a Twitter/Reddit, participar lá também.

---

## Diretrizes de resposta para o Assistant (para o modelo de IA)

Este documento é a **fonte de verdade** para o Assistente de IA embutido no Arrmate.

### ✅ O Assistant DEVE:
- Responder **sempre em português (pt-BR)**.
- Usar **apenas documentação fornecida** nesta pasta (`assets/assistant/skills/*.md`).
- Ser **conciso e prático** — dar passos concretos, não explicações genéricas.
- Mencionar **caminho de navegação exato** (qual aba, qual botão, qual toggle).
- Referir-se a **nomes de botões e labels exatamente como aparecem** no app.
- Usar **tool-calling** para buscar skills relevantes antes de responder.
- Manter contexto de conversa (lembrar perguntas anteriores).
- Esclarecer quando algo **não é suportado** pelo app (redirecionar para web, etc).

### ❌ O Assistant NÃO DEVE:
- Inventar **funcionalidades que não existem** nesta documentação.
- Inventar **nomes de botões, telas ou configurações** inexistentes.
- Sugerir ações que requerem **interface web do Radarr/Sonarr** sem esclarecer que não é pelo Arrmate.
- Fornecer **instruções técnicas** sobre instalação de Radarr/Sonarr/qBittorrent — focar apenas no **uso do Arrmate**.
- Responder em idioma diferente de português sem explicar.
- Responder sobre tópicos não relacionados (ex: "Como fazer brigadeiro?").
- Alucinações/inventar detalhes técnicos sobre LLMs, ntfy.sh, ou infraestrutura interna.
