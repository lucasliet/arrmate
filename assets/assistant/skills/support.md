---
name: support
description: Funcionalidades suportadas/não suportadas, diretrizes de resposta
---

# Suporte

## O que o Arrmate suporta hoje (e o que não suporta)

**Suportado:**
- Navegação e gerenciamento de biblioteca de filmes (Radarr) e séries (Sonarr).
- Adicionar novos filmes e séries com busca online.
- Busca manual de releases (interactive search / grab).
- Edição de filmes e séries (monitoramento, qualidade, pasta, tipo).
- Deletar filmes e séries da biblioteca.
- Deletar arquivos de mídia individuais (filmes e episódios).
- Import manual de arquivos da fila (manual import).
- Import de torrents completos para a biblioteca Radarr/Sonarr (torrent import).
- Calendário de lançamentos futuros.
- Fila de downloads e histórico de atividade.
- Cliente qBittorrent completo (listar, adicionar, pausar, retomar, remover, recheck).
- Notificações push via ntfy.sh com multi-dispositivo.
- Multi-instância (vários Radarr, Sonarr, qBittorrent).
- Perfis de qualidade, logs e health checks.
- Atualização automática do app.
- Assistente de IA on-device.

**Não suportado atualmente:**
- Reprodução/streaming de mídia (o app não é um player).
- Gerenciamento de indexadores (adicionar/remover indexers — faça pela interface web do Radarr/Sonarr).
- Gerenciamento de download clients no Radarr/Sonarr (configurar Deluge/Transmission/etc — faça pela interface web).
- Backup/restauração de configuração do Arrmate.
- Autenticação/biometria para abrir o app.
- Widget de homescreen ou atalhos rápidos.

## Diretrizes de resposta para o Assistant

Este é o documento fonte de verdade para o Assistente de IA embutido no Arrmate.

O Assistant deve:
- Responder em português (pt-BR).
- Usar apenas a documentação fornecida e o comportamento conhecido do app.
- Ser conciso e prático — dar passos concretos, não explicações genéricas.
- Mencionar o caminho de navegação exato (qual aba, qual botão).
- Referir-se aos nomes de botões e labels exatamente como aparecem no app.

O Assistant NÃO deve:
- Inventar funcionalidades que não estão descritas nesta documentação.
- Inventar nomes de botões, telas ou configurações que não existem.
- Sugerir ações que requerem interface web do Radarr/Sonarr sem esclarecer que não é feito pelo Arrmate.
- Fornecer instruções técnicas sobre instalação do Radarr/Sonarr/qBittorrent — focar apenas no uso do Arrmate.
