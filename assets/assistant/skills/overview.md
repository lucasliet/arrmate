---
name: overview
description: Sobre o Arrmate, navegação principal (5 abas), aba inicial
---

# Visão geral do Arrmate

## Sobre o Arrmate — o que o app faz

Arrmate é um app mobile companion para gerenciar servidores **Radarr** (filmes), **Sonarr** (séries) e **qBittorrent** (downloads).

Funcionalidades principais:
- Biblioteca de filmes e séries: navegar, buscar, filtrar, ordenar, monitorar e deletar.
- Adicionar novos filmes e séries via busca online no Radarr/Sonarr.
- Busca manual de releases (grab interativo) com filtro e seleção.
- Calendário de próximos lançamentos e episódios.
- Monitoramento de fila de downloads e histórico de atividade.
- Cliente qBittorrent integrado: listar, pausar, retomar, remover, adicionar torrents.
- Notificações push via ntfy.sh com sincronização multi-dispositivo.
- Multi-instância: conectar vários servidores Radarr, Sonarr e qBittorrent ao mesmo tempo.
- Assistente de IA on-device para dúvidas sobre o próprio app.
- Atualização automática do app via GitHub Releases.

O app é feito em Flutter, roda totalmente no dispositivo e não envia dados pessoais para servidores externos.

## Navegação principal — abas Filmes Séries Calendário Atividade Configurações

O Arrmate usa uma barra de navegação inferior com 5 abas:

1. **Filmes** — Biblioteca de filmes do Radarr.
2. **Séries** — Biblioteca de séries do Sonarr.
3. **Calendário** — Próximos lançamentos e episódios organizados por data.
4. **Atividade** — Fila de downloads, histórico e torrents do qBittorrent.
5. **Configurações** — Instâncias, aparência, notificações, sistema e assistente.

A aba ativa é destacada com ícone preenchido e cor de destaque. Tocar em qualquer aba navega diretamente.

A maioria das telas possui ícone de sino no topo para acessar a central de notificações.

## Aba inicial — escolher qual abre ao iniciar o app

**Onde fica:** Configurações → seção "Appearance" → "Home Tab".

**Passo a passo:**
1. Abrir a aba Configurações.
2. Tocar em "Appearance".
3. Tocar em "Home Tab".
4. Selecionar qual aba abre ao iniciar: Filmes, Séries, Calendário ou Atividade.

**Observações:** O padrão é Filmes.
