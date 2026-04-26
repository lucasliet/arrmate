import 'package:flutter/services.dart';

class AssistantSkill {
  const AssistantSkill({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String description;
  final String assetPath;
}

class AssistantKnowledgeService {
  static const _skills = [
    AssistantSkill(
      id: 'overview',
      title: 'Visão Geral',
      description: 'Sobre o Arrmate, navegação principal (5 abas), aba inicial',
      assetPath: 'assets/assistant/skills/overview.md',
    ),
    AssistantSkill(
      id: 'instances',
      title: 'Instâncias',
      description:
          'Adicionar/editar/remover instância Radarr/Sonarr/qBittorrent, API key, test connection, slow mode, multi-instância',
      assetPath: 'assets/assistant/skills/instances.md',
    ),
    AssistantSkill(
      id: 'movies',
      title: 'Filmes',
      description:
          'Adicionar/detalhes/editar/deletar filme, deletar arquivo, buscar release',
      assetPath: 'assets/assistant/skills/movies.md',
    ),
    AssistantSkill(
      id: 'series',
      title: 'Séries',
      description:
          'Adicionar/detalhes/episódios/editar/deletar série, deletar arquivo',
      assetPath: 'assets/assistant/skills/series.md',
    ),
    AssistantSkill(
      id: 'library',
      title: 'Biblioteca',
      description:
          'Filtrar/ordenar filmes e séries, alternar grade/lista, busca local',
      assetPath: 'assets/assistant/skills/library.md',
    ),
    AssistantSkill(
      id: 'calendar',
      title: 'Calendário',
      description: 'Calendário de próximos lançamentos e episódios',
      assetPath: 'assets/assistant/skills/calendar.md',
    ),
    AssistantSkill(
      id: 'activity',
      title: 'Atividade',
      description: 'Fila de downloads (queue), import manual, histórico',
      assetPath: 'assets/assistant/skills/activity.md',
    ),
    AssistantSkill(
      id: 'qbittorrent',
      title: 'qBittorrent',
      description:
          'Listar/pausar/retomar torrents, adicionar torrent, import torrent, filtros',
      assetPath: 'assets/assistant/skills/qbittorrent.md',
    ),
    AssistantSkill(
      id: 'notifications',
      title: 'Notificações',
      description:
          'Configurar ntfy.sh, tópico, auto-configurar webhooks, tipos de evento, central, battery saver',
      assetPath: 'assets/assistant/skills/notifications.md',
    ),
    AssistantSkill(
      id: 'appearance',
      title: 'Aparência',
      description: 'Tema claro/escuro/automático, cor de destaque',
      assetPath: 'assets/assistant/skills/appearance.md',
    ),
    AssistantSkill(
      id: 'system',
      title: 'Sistema',
      description: 'Logs, health, perfis de qualidade, sobre o app',
      assetPath: 'assets/assistant/skills/system.md',
    ),
    AssistantSkill(
      id: 'assistant',
      title: 'Assistant',
      description: 'Sobre o assistente, modelos disponíveis, como funciona',
      assetPath: 'assets/assistant/skills/assistant.md',
    ),
    AssistantSkill(
      id: 'troubleshooting',
      title: 'Solução de Problemas',
      description:
          'Erros de conexão, autenticação, notificações, app desatualizado, modelo não carrega',
      assetPath: 'assets/assistant/skills/troubleshooting.md',
    ),
    AssistantSkill(
      id: 'support',
      title: 'Suporte',
      description: 'Funcionalidades suportadas/não suportadas, diretrizes',
      assetPath: 'assets/assistant/skills/support.md',
    ),
  ];

  List<AssistantSkill> get skills => _skills;

  String getSkillDescriptions() {
    return _skills.map((s) => '- ${s.id}: ${s.description}').join('\n');
  }

  Future<String> loadSkill(String name) async {
    final skill = _skills.where((s) => s.id == name.trim()).firstOrNull;
    if (skill == null) {
      return 'Skill not found.';
    }

    final content = await rootBundle.loadString(skill.assetPath);
    return content.trim();
  }
}
