---
name: system
description: Logs, health, perfis de qualidade, sobre o app
---

# Sistema

## Logs do app e logs do Radarr Sonarr

**Onde fica:** Configurações → seção "System Management" → "Logs".

A tela de Logs tem duas abas:

**Arr Logs:**
- Logs do sistema dos servidores Radarr/Sonarr conectados.
- Cada entrada: timestamp, nível (INFO, WARN, ERROR, DEBUG), mensagem.
- Filtro por nível: All, Info, Warn, Error, Debug.
- Botão "Copy all" para copiar logs visíveis para clipboard.
- Auto-carrega mais conforme scroll.

**App Logs:**
- Logs internos do próprio Arrmate.
- Mesmo formato e filtros que Arr Logs.
- Botão "Clear" no topo para limpar logs (com confirmação).

**Observações:** Os logs são úteis para diagnóstico de problemas. App logs mostram requisições API, erros internos e eventos do ciclo de vida.

## Saúde (health) — checagens e avisos do sistema

**Onde fica:** Configurações → seção "System Management" → "Health".

**Funcionalidades:**
- Exibe resultados das checagens de saúde dos servidores Radarr/Sonarr.
- Ícone de refresh no topo para executar checagens manualmente.
- Barra de progresso linear enquanto checa.

**Sem problemas:**
- Ícone de check verde grande.
- "No issues found".

**Com problemas:**
- Lista de avisos/erros com:
  - Ícone (X vermelho para erros, ! laranja para warnings).
  - Fonte (qual instância).
  - Mensagem descritiva do problema.
  - Link para wiki (abre no navegador).

**Observações:** Problemas comuns incluem: espaço em disco baixo, pasta não gravável, download client inacessível, indexers com falha.

## Perfis de qualidade disponíveis nas instâncias

**Onde fica:** Configurações → seção "System Management" → "Quality Profiles".

**Funcionalidades:**
- Lista todos os perfis de qualidade das instâncias conectadas.
- Duas seções: Radarr Profiles e Sonarr Profiles.
- Cada perfil mostra: ícone, nome do perfil e ID.

**Estado vazio:** "No profiles found or instance not connected".

**Observações:** Estes perfis são usados ao adicionar ou editar filmes e séries. São obtidos via cache das instâncias configuradas.

## Sobre o app — versão atualizações e código-fonte

**Onde fica:** Configurações → seção "About".

**Informações exibidas:**
- Versão atual do app.
- Status de atualização (check verde se atualizado, ícone de update se há nova versão).
- Tocar para verificar atualizações manualmente.
- Link "Source Code" para o repositório GitHub.

**Atualizações:**
- O app verifica automaticamente por novas versões via GitHub Releases.
- Quando disponível, é possível baixar e instalar a atualização diretamente pelo app (OTA).
