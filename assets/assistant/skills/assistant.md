---
name: assistant
description: Sobre o assistente, modelos disponíveis, como funciona
---

# Assistente de IA

## Sobre o Assistant — modelos disponíveis baixar importar trocar

**Onde fica:** Configurações → seção "System Management" → "Assistant".

O Assistant é uma funcionalidade de IA que roda localmente no dispositivo para responder dúvidas sobre o Arrmate. Ele utiliza um sistema de skills baseado em tool-calling para buscar seções relevantes da documentação antes de responder.

**Modelos disponíveis no catálogo:**
- Gemma 4 E2B — balanceado entre qualidade e tamanho (suporta tool-calling).
- Gemma 4 E4B — maior qualidade, mais memória (suporta tool-calling).

**Ações:**
- **Download:** tocar "Download" para baixar modelo do catálogo. Progresso aparece em diálogo.
- **Import:** tocar "Import" para importar arquivo `.litertlm` do dispositivo.
- **Switch:** tocar "Switch" para trocar entre modelos já instalados.
- **Delete:** no diálogo de switch, tocar ícone de lixeira ao lado de qualquer modelo (incluindo o selecionado).

**Observações:** Ambos os modelos usam tool-calling para buscar seções relevantes da documentação antes de responder, através de um sistema de skills organizadas por domínio. Modelos maiores consomem mais memória e podem ser mais lentos em dispositivos mais antigos.

## Como o Assistant funciona — on-device sem internet

O Assistant roda inteiramente no dispositivo usando LiteRT-LM (engine de inferência local).

**Características:**
- Não requer conexão com internet para funcionar.
- Dados ficam no dispositivo — nada é enviado para servidores externos.
- Usa a base de conhecimento do Arrmate como fonte de informação, organizada em skills temáticas.
- Responde em português por padrão.
- Não inventa funcionalidades que não existem no app.

**Como usar:**
1. Configurações → Assistant.
2. Selecionar/baixar um modelo.
3. Digitar pergunta no campo "Ask about Arrmate...".
4. Tocar no botão de enviar.
5. Aguardar resposta (pode levar alguns segundos dependendo do modelo e dispositivo).

**Sistema de skills:**
O Assistant utiliza tool-calling para buscar seções relevantes da documentação. As skills são organizadas por domínio (filmes, séries, instâncias, notificações, etc.) e permitem respostas mais precisas e contextualizadas, pois o modelo consulta apenas a documentação relevante à pergunta antes de responder.
