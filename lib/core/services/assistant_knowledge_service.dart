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
      description:
          'Sobre o Arrmate, navegação principal (5 abas), aba inicial, tour de onboarding',
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
          'Adicionar/detalhes/editar/deletar filme, deletar arquivo, buscar release, Discover',
      assetPath: 'assets/assistant/skills/movies.md',
    ),
    AssistantSkill(
      id: 'series',
      title: 'Séries',
      description:
          'Adicionar/detalhes/episódios/editar/deletar série, deletar arquivo, Discover',
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
      description:
          'Logs, health, perfis de qualidade, sobre o app, System Management, dias mínimos de seeding, limpar cache de imagens, resetar configurações',
      assetPath: 'assets/assistant/skills/system.md',
    ),
    AssistantSkill(
      id: 'diagnostics',
      title: 'Diagnósticos',
      description:
          'Connection diagnostics endpoints latência traces export relatório, system overview armazenamento disco biblioteca, version history changelog, what\'s new pós-atualização, banner offline rede',
      assetPath: 'assets/assistant/skills/diagnostics.md',
    ),
    AssistantSkill(
      id: 'assistant',
      title: 'Assistant',
      description:
          'Sobre o assistente, modelos disponíveis, IA local, Apple Intelligence, LiteRT, OpenCode Zen, como funciona',
      assetPath: 'assets/assistant/skills/assistant.md',
    ),
    AssistantSkill(
      id: 'troubleshooting',
      title: 'Solução de Problemas',
      description:
          'Erros de conexão, autenticação, notificações, app desatualizado, modelo não carrega, Apple Intelligence indisponível, itens de exemplo mostrados durante o tour inicial',
      assetPath: 'assets/assistant/skills/troubleshooting.md',
    ),
    AssistantSkill(
      id: 'support',
      title: 'Suporte',
      description: 'Funcionalidades suportadas/não suportadas, diretrizes',
      assetPath: 'assets/assistant/skills/support.md',
    ),
  ];

  static const _excerptSeparator = '\n\n---\n\n';

  static final _frontMatter = RegExp(r'^---\n[\s\S]*?\n---\n');

  static final _sectionStart = RegExp(r'^(?=##\s)', multiLine: true);

  static final _titleLine = RegExp(r'^#\s.*$', multiLine: true);

  /// Words too common in questions to tell sections apart.
  static const _stopWords = {
    'app',
    'arrmate',
    'com',
    'como',
    'das',
    'dos',
    'esse',
    'essa',
    'este',
    'esta',
    'fazer',
    'mais',
    'meu',
    'minha',
    'nao',
    'nas',
    'nos',
    'onde',
    'para',
    'pode',
    'por',
    'posso',
    'qual',
    'quais',
    'quando',
    'que',
    'sem',
    'sobre',
    'sua',
    'seu',
    'tem',
    'uma',
  };

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

  /// Loads the most relevant assistant skills for a question.
  Future<String> loadRelevantSkills(String question) async {
    final selectedSkills = _selectRelevantSkills(question);
    final contents = await Future.wait(
      selectedSkills.map((skill) async {
        final content = await rootBundle.loadString(skill.assetPath);
        return '# ${skill.id}\n\n${content.trim()}';
      }),
    );

    return contents.join('\n\n---\n\n');
  }

  List<AssistantSkill> _selectRelevantSkills(String question) {
    final normalizedQuestion = _normalize(question);
    final scoredSkills =
        _skills
            .map(
              (skill) =>
                  MapEntry(skill, _scoreSkill(skill, normalizedQuestion)),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final selectedSkills = scoredSkills
        .where((entry) => entry.value > 0)
        .take(4)
        .map((entry) => entry.key)
        .toList();

    if (selectedSkills.isEmpty) {
      return _skills
          .where(
            (skill) => ['overview', 'assistant', 'support'].contains(skill.id),
          )
          .toList();
    }

    if (!selectedSkills.any((skill) => skill.id == 'overview')) {
      selectedSkills.add(_skills.firstWhere((skill) => skill.id == 'overview'));
    }

    return selectedSkills;
  }

  int _scoreSkill(AssistantSkill skill, String normalizedQuestion) {
    final searchableText = _normalize(
      '${skill.id} ${skill.title} ${skill.description}',
    );

    return _searchTerms(
      normalizedQuestion,
    ).where(searchableText.contains).length;
  }

  /// Loads the documentation sections most relevant to [question].
  ///
  /// On-device models have small context windows, so instead of whole skill
  /// files this ranks the `##` sections of the relevant skills by how many
  /// question terms they mention, weighting their headings, and returns the
  /// best ones joined without exceeding [maxCharacters]. The top section is
  /// truncated when it alone does not fit. Returns an empty string when
  /// [maxCharacters] is not positive.
  Future<String> loadRelevantExcerpts(
    String question, {
    required int maxCharacters,
  }) async {
    if (maxCharacters <= 0) {
      return '';
    }

    final sections = <String>[];
    for (final skill in _selectRelevantSkills(question)) {
      final content = await rootBundle.loadString(skill.assetPath);
      sections.addAll(_splitSections(content));
    }

    final terms = _searchTerms(_normalize(question));
    final ranked =
        [
          for (final (index, section) in sections.indexed)
            (
              index: index,
              section: section,
              score: _scoreSection(section, terms),
            ),
        ]..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          return byScore != 0 ? byScore : a.index.compareTo(b.index);
        });

    final excerpts = <String>[];
    var remaining = maxCharacters;
    for (final candidate in ranked) {
      if (excerpts.isNotEmpty && candidate.score == 0) {
        break;
      }

      final cost =
          candidate.section.length +
          (excerpts.isEmpty ? 0 : _excerptSeparator.length);
      if (cost <= remaining) {
        excerpts.add(candidate.section);
        remaining -= cost;
      } else if (excerpts.isEmpty) {
        excerpts.add(_truncateAtLineBreak(candidate.section, remaining));
        break;
      }
    }

    return excerpts.join(_excerptSeparator);
  }

  List<String> _splitSections(String content) {
    return content
        .replaceFirst(_frontMatter, '')
        .split(_sectionStart)
        .map((section) => section.trim())
        .where(
          (section) => section.replaceAll(_titleLine, '').trim().isNotEmpty,
        )
        .toList();
  }

  /// Cuts [text] to [maxCharacters], preferring the last line break when it
  /// keeps at least half of the allowed length.
  String _truncateAtLineBreak(String text, int maxCharacters) {
    final cut = text.substring(0, maxCharacters);
    final lastBreak = cut.lastIndexOf('\n');
    return (lastBreak >= maxCharacters ~/ 2 ? cut.substring(0, lastBreak) : cut)
        .trimRight();
  }

  int _scoreSection(String section, Set<String> terms) {
    final normalized = _normalize(section);
    final heading = normalized.split('\n').first;

    return terms.fold(
      0,
      (score, term) =>
          score +
          (normalized.contains(term) ? 1 : 0) +
          (heading.contains(term) ? 2 : 0),
    );
  }

  Set<String> _searchTerms(String normalizedText) {
    return normalizedText
        .split(RegExp(r'[^a-z0-9]+'))
        .where((term) => term.length >= 3 && !_stopWords.contains(term))
        .toSet();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
