# Design Guidelines - Arrmate

Este documento contém os padrões de design e componentes UI do Arrmate para garantir consistência ao criar novos widgets.

## Índice

- [Design System](#design-system)
- [Theme System](#theme-system)
- [Cards](#cards)
- [Bottom Sheets](#bottom-sheets)
- [Widgets Comuns](#widgets-comuns)
- [Formatação](#formatação)
- [Context Extensions](#context-extensions)
- [Imagens](#imagens)
- [Ícones e Status](#ícones-e-status)
- [Boas Práticas](#boas-práticas)

---

## Design System

**Arquivo**: `lib/core/constants/app_constants.dart`

### Padding/Spacing

```dart
const double paddingXs = 4.0;      // Mínimo
const double paddingSm = 8.0;      // Pequeno
const double paddingMd = 16.0;     // Médio (mais usado)
const double paddingLg = 24.0;     // Grande
const double paddingXl = 32.0;     // Extra grande
```

### Border Radius

```dart
const double radiusSm = 8.0;       // Cards menores
const double radiusMd = 12.0;      // Padrão (cards, buttons)
const double radiusLg = 16.0;      // Diálogos
const double radiusXl = 24.0;      // Grandes superfícies
```

### Aspect Ratios

```dart
const double posterAspectRatio = 2 / 3;      // Posters (retrato)
const double fanartAspectRatio = 16 / 9;     // Fanart (panorâmico)
```

### Grid

```dart
const double gridSpacing = 12.0;
const int gridColumnsCompact = 3;    // Telas pequenas
const int gridColumnsLarge = 4;      // Telas grandes
```

### Ícones

```dart
const double iconSizeSm = 16.0;
const double iconSizeMd = 24.0;
const double iconSizeLg = 32.0;
```

---

## Theme System

**Arquivo**: `lib/presentation/theme/app_theme.dart`

### Color Schemes Disponíveis

```dart
enum AppColorScheme {
  blue, indigo, purple, pink, red, orange, amber, green, teal
}
```

### Padrão de Cards

```dart
cardTheme: CardThemeData(
  elevation: 0,
  color: isDark
      ? colorScheme.surfaceContainerHighest
      : colorScheme.surfaceContainerLow,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
```

### Padrão de Bottom Sheets

```dart
bottomSheetTheme: BottomSheetThemeData(
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  backgroundColor: colorScheme.surface,
),
```

---

## Cards

### Grid Card Pattern (MovieCard/SeriesCard)

**Uso**: Grids de filmes/séries

```dart
Card(
  clipBehavior: Clip.antiAlias,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusMd),
  ),
  child: InkWell(
    onTap: onTap,
    child: Stack(
      children: [
        // Background image
        Positioned.fill(child: _buildPoster()),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.5, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Status icons (top)
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: _buildStatusIcons(),
        ),

        // Title and subtitle (bottom)
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: _buildInfo(),
        ),
      ],
    ),
  ),
)
```

### List Tile Pattern (MovieListTile/SeriesListTile)

**Uso**: Listas de filmes/séries

```dart
Card(
  clipBehavior: Clip.antiAlias,
  margin: const EdgeInsets.only(bottom: 8),
  child: InkWell(
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster (80x120)
        SizedBox(
          width: 80,
          height: 120,
          child: _buildPoster(),
        ),

        // Info column
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusIcons(),
                const SizedBox(height: 4),
                _buildTitle(),
                const SizedBox(height: 4),
                _buildSubtitle(),
                const SizedBox(height: 4),
                _buildInfo(),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
)
```

### Card com Progress Bar (QueueListItem)

**Uso**: Items da fila de download

```dart
Card(
  margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
  elevation: 0,
  color: theme.colorScheme.surfaceContainer,
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo()),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceDim,
              valueColor: AlwaysStoppedAnimation(
                hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              minHeight: 4,
            ),
          ),

          // Error message (if any)
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    ),
  ),
)
```

---

## Bottom Sheets

### DraggableScrollableSheet Pattern

**Uso**: Bottom sheets com conteúdo scrollável

```dart
DraggableScrollableSheet(
  initialChildSize: 0.7,
  minChildSize: 0.5,
  maxChildSize: 0.9,
  expand: false,
  builder: (context, scrollController) {
    return Column(
      children: [
        // Drag handle indicator
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
        ),

        // Content
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            children: [...],
          ),
        ),
      ],
    );
  },
)
```

### Bottom Sheet com AppBar

**Uso**: Bottom sheets fullscreen com ações

```dart
DraggableScrollableSheet(
  initialChildSize: 0.9,
  minChildSize: 0.5,
  maxChildSize: 0.95,
  expand: false,
  builder: (context, scrollController) {
    return Column(
      children: [
        AppBar(
          title: Text(title),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [...],
          ),
        ),
      ],
    );
  },
)
```

### Status Badge Widget

**Uso**: Exibir status com cores

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    label.toUpperCase(),
    style: theme.textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### Custom Badge Widget

**Uso**: Tags, labels, formatos customizados

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: color.withValues(alpha: 0.5)),
  ),
  child: Text(
    label,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ).copyWith(color: color),
  ),
)
```

### Error Container

**Uso**: Mensagens de erro em destaque

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: theme.colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    ],
  ),
)
```

---

## Widgets Comuns

**Arquivo**: `lib/presentation/widgets/common_widgets.dart`

### LoadingIndicator

```dart
LoadingIndicator(message: 'Carregando arquivos...')
```

### ErrorDisplay

```dart
ErrorDisplay(
  message: 'Falha ao carregar arquivos',
  onRetry: () => ref.refresh(movieFilesProvider(movieId)),
)
```

### EmptyState

```dart
EmptyState(
  icon: Icons.movie_outlined,
  title: 'Nenhum arquivo encontrado',
  subtitle: 'Este filme ainda não tem arquivos de mídia',
  action: FilledButton(
    onPressed: onSearch,
    child: const Text('Buscar'),
  ),
)
```

---

## Formatação

**Arquivo**: `lib/core/utils/formatters.dart`

### Tamanho de Arquivo

```dart
formatBytes(8589934592)  // "8.0 GB"
formatBytes(1048576)     // "1.0 MB"
```

### Duração

```dart
formatRuntime(142)  // "2h 22m"
formatRuntime(90)   // "1h 30m"
formatRuntime(45)   // "45m"
```

### Episódio

```dart
formatEpisodeNumber(1, 5)              // "Season 1, Episode 5"
formatEpisodeNumber(1, 5, short: true) // "S01E05"
```

### Temporada

```dart
formatSeasonNumber(1)  // "Season 1"
formatSeasonNumber(0)  // "Specials"
```

### Percentual

```dart
formatPercentage(0.7532)  // "75%"
```

### Progresso

```dart
formatProgress(5, 10)  // "5 / 10"
```

### Custom Score

```dart
formatCustomScore(5)   // "+5"
formatCustomScore(-3)  // "-3"
```

### Lista com Separador

```dart
formatListWithSeparator(['Bluray-1080p', 'English', '8.5GB'])
// "Bluray-1080p · English · 8.5GB"
```

### Data

```dart
formatDate(DateTime(2024, 1, 15))  // "2024-01-15"
```

---

## Context Extensions

**Arquivo**: `lib/core/extensions/context_extensions.dart`

### Acesso ao Theme

```dart
context.theme
context.colorScheme
context.textTheme
context.isDarkMode
```

### MediaQuery

```dart
context.screenSize
context.screenWidth
context.screenHeight
context.padding
context.isLargeScreen      // > 600
context.isExtraLargeScreen // > 900
```

### SnackBars

```dart
context.showSnackBar('Arquivo deletado com sucesso')
context.showErrorSnackBar('Falha ao deletar arquivo')
```

### Bottom Sheets

```dart
context.showBottomSheet(
  MediaFileDetailsSheet(file: file),
)
```

---

## Imagens

### Pattern com Cache e Placeholder

```dart
Widget _buildPoster() {
  final posterUrl = movie.remotePoster;

  if (posterUrl == null) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.movie_outlined,
        size: 32,
        color: theme.colorScheme.outline,
      ),
    );
  }

  return CachedNetworkImage(
    imageUrl: posterUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Container(color: Colors.white),
    ),
    errorWidget: (context, url, error) => Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.movie_outlined,
        size: 32,
        color: theme.colorScheme.outline,
      ),
    ),
  );
}
```

### Tamanhos Padrão

- Poster em lista: `80x120`
- Poster em grid: `aspect ratio 2/3`
- Fanart: `aspect ratio 16/9`

---

## Ícones e Status

### Status Icons para Movies/Series

```dart
Widget _buildStatusIcons() {
  return Row(
    children: [
      // Monitored
      Icon(
        movie.monitored ? Icons.bookmark : Icons.bookmark_border,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 8),

      // Download status
      if (movie.hasFile == true)
        Icon(
          Icons.check_circle,
          size: 18,
          color: theme.colorScheme.primary,
        )
      else if (movie.monitored)
        Icon(
          Icons.access_time,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        )
      else
        Icon(
          Icons.cancel_outlined,
          size: 18,
          color: theme.colorScheme.error,
        ),
    ],
  );
}
```

### Queue Status Colors

```dart
Color getStatusColor(QueueStatus status) {
  switch (status) {
    case QueueStatus.downloading:
      return Colors.blue;
    case QueueStatus.completed:
      return Colors.green;
    case QueueStatus.failed:
    case QueueStatus.warning:
      return theme.colorScheme.error;
    case QueueStatus.paused:
      return Colors.orange;
    default:
      return theme.colorScheme.onSurfaceVariant;
  }
}
```

---

## Boas Práticas

### Spacing & Padding

- **Padrão**: `paddingMd (16)` para padding geral
- **Dentro de cards**: `paddingSm (8)` ou `12`
- **Margin de cards**: `EdgeInsets.only(bottom: 8)` ou `EdgeInsets.only(bottom: 12, left: 16, right: 16)`
- **SizedBox entre elementos**: `8` ou `12`

### Cards

- ✅ Sempre: `elevation: 0`
- ✅ Sempre: `clipBehavior: Clip.antiAlias`
- ✅ Border radius: `BorderRadius.circular(radiusMd)`
- ✅ Background: `theme.colorScheme.surfaceContainer` ou `surfaceContainerHighest`
- ✅ Wrap content com `InkWell` para tap effect

### Bottom Sheets

- ✅ Use `DraggableScrollableSheet` para flexibilidade
- ✅ Sempre inclua drag handle indicator no topo
- ✅ Default: `initialChildSize: 0.7`
- ✅ Use `ListView` com `scrollController` para conteúdo scrollável
- ✅ Padding no bottom do ListView: `EdgeInsets.only(bottom: 24)`

### Texts

- ✅ Use `theme.textTheme` para estilos
- ✅ Cores via `theme.colorScheme`
- ✅ Subtítulos: `onSurfaceVariant`
- ✅ Labels pequenos: `theme.textTheme.labelSmall`
- ✅ Títulos: `theme.textTheme.titleLarge` ou `titleMedium`

### Imagens

- ✅ Use `CachedNetworkImage` com placeholder shimmer
- ✅ Sempre tenha fallback com ícone
- ✅ `fit: BoxFit.cover` para manter aspect ratio

### Loading & Error States

- ✅ Loading: `LoadingIndicator()`
- ✅ Erro: `ErrorDisplay()` com `onRetry`
- ✅ Empty: `EmptyState()` com ícone e mensagem

### Riverpod Patterns

```dart
// FutureProvider com family
final itemProvider = FutureProvider.autoDispose.family<Item, int>((ref, id) async {
  final repository = ref.watch(repositoryProvider);
  if (repository == null) throw Exception('Repository not available');
  return repository.getItem(id);
});

// Consumir provider
ref.watch(itemProvider(id)).when(
  data: (item) => ItemWidget(item: item),
  loading: () => const LoadingIndicator(),
  error: (error, stack) => ErrorDisplay(
    message: error.toString(),
    onRetry: () => ref.refresh(itemProvider(id)),
  ),
);
```

---

## Exemplos de Referência

- **Grid Card**: `lib/presentation/screens/movies/widgets/movie_card.dart`
- **List Tile**: `lib/presentation/screens/movies/widgets/movie_list_tile.dart`
- **Progress Card**: `lib/presentation/screens/activity/widgets/queue_list_item.dart`
- **Bottom Sheet Simple**: `lib/presentation/widgets/sort_bottom_sheet.dart`
- **Bottom Sheet Complex**: `lib/presentation/shared/widgets/releases_sheet.dart`
- **Calendar Item**: `lib/presentation/screens/calendar/widgets/calendar_item.dart`
