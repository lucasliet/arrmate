---
name: instances
description: Adicionar/editar/remover instância Radarr/Sonarr/qBittorrent, API key, test connection, slow mode, multi-instância
---

# Instâncias

## Adicionar instância Radarr Sonarr ou qBittorrent

**Onde fica:** Configurações → seção "Instances" → "Add Instance".

**Passo a passo:**
1. Abrir a aba Configurações na barra inferior.
2. Na seção "Instances", tocar em "Add Instance" (último item da lista).
3. No seletor segmentado no topo, escolher o tipo: Radarr, Sonarr ou qBittorrent.
4. Preencher "Name" com um rótulo livre (ex: "Servidor Casa", "VPS").
5. Preencher "URL" completo, incluindo http(s):// e porta (ex: `http://192.168.1.10:7878`).
6. Para Radarr/Sonarr: colar a "API Key" em "API Key".
7. Para qBittorrent: preencher "Username" e "Password" da WebUI.
8. Tocar "Test Connection" para validar. Se OK, aparece versão e contagem de tags em verde.
9. Tocar "Save" para salvar.

**Observações:** Os metadados da instância (perfis de qualidade, root folders, tags) são cacheados localmente. Múltiplas instâncias do mesmo tipo são suportadas simultaneamente.

## Onde encontrar a API key do Radarr ou Sonarr

A API Key é gerada pelo próprio servidor Radarr ou Sonarr.

**Como obter:**
1. Abrir a interface web do Radarr ou Sonarr no navegador.
2. Ir em Settings → General.
3. Copiar o valor do campo "API Key".

Depois colar essa chave no campo "API Key" ao adicionar a instância no Arrmate.

## Testar conexão e validar instância

**Onde fica:** Tela de adicionar/editar instância → botão "Test Connection".

**Passo a passo:**
1. Preencher URL e credenciais da instância.
2. Tocar "Test Connection".
3. Aguardar o indicador de loading.
4. Se sucesso: aparece "Connection successful!" com versão, nome e contagem de tags.
5. Se falha: aparece mensagem de erro em vermelho com o motivo.

**Observações:** Sempre teste antes de salvar. Se falhar, verifique URL, porta, API key e conectividade de rede.

## Editar ou remover instância existente

**Onde fica:** Configurações → seção "Instances" → tocar na instância.

**Passo a passo para editar:**
1. Abrir Configurações → seção "Instances".
2. Tocar na instância desejada na lista.
3. Alterar os campos necessários (URL, API key, nome, etc).
4. Tocar "Test Connection" para validar.
5. Tocar "Save".

**Passo a passo para remover:**
1. Tocar na instância na lista.
2. Tocar no ícone de lixeira no canto superior direito.
3. Confirmar a exclusão no diálogo.

**Observações:** Remover uma instância limpa todo o cache local associado (filmes, séries, perfis, etc).

## Modo lento (slow mode) e cabeçalhos HTTP customizados

**Onde fica:** Tela de adicionar/editar instância → seção "Advanced Options".

**Slow Mode:**
- Toggle "Slow Mode" no formulário da instância.
- Quando ativado, o timeout de requisições sobe de 30s para 90s.
- Recomendado para servidores remotos, via VPN, ou com hardware limitado.

**Custom Headers:**
- Seção expansível "Custom Headers" no formulário da instância.
- Permite adicionar cabeçalhos HTTP customizados (nome:valor).
- Útil para reverse proxies com autenticação extra ou headers específicos.

## Suporte a múltiplas instâncias simultâneas

O Arrmate suporta várias instâncias do mesmo tipo ao mesmo tempo.

- É possível ter múltiplos Radarr, múltiplos Sonarr e múltiplos qBittorrent configurados.
- Cada instância é independente: nome, URL, credenciais e configurações próprias.
- Filmes e séries de todas as instâncias Radarr/Sonarr aparecem agregados nas respectivas abas.
- As instâncias são listadas na seção "Instances" em Configurações com ícone do tipo (filme, TV, download).
