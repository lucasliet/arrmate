# Repository Guidelines

## Project Context & Business Goals

**Arrmate** is a mobile companion application designed for users of self-hosted
media servers, specifically **Radarr** (for movies) and **Sonarr** (for TV
series).

- **Objective**: Provide a seamless, efficient, and beautiful mobile interface
  for managing media libraries remotely.
- **Core Features**:
  - **Library Management**: Browse, search, filter, sort, monitor, and delete
    media.
  - **Releases Calendar**: View upcoming movie releases and series episodes.
  - **Activity Monitoring**: Check download queues and history status.
  - **Multi-Instance**: Support for managing multiple server instances within
    the same app.
  - **Search & Sort**: Client-side filtering and sorting for instant library
    navigation.
  - **Add Content**: Search and add new Movies/Series via API lookup, including
    Quality Profile and Root Folder configuration.
  - **Automatic Search**: Trigger automatic search for movie releases.
  - **Interactive Search**: Manual release search (torrents/nzbs) with filtering
    and download selection.
  - **Activity History**: View historical events (grabbed, imported, failed,
    deleted) with filtering by event type.
  - **Queue Management**: View active downloads with detailed status, remove
    tasks with blocklist option.
  - **Notifications**: Real-time push notifications via ntfy.sh integration.
  - **Advanced Management**: View Quality Profiles, System Logs, and Health
    Checks.
  - **Manual Import**: Match and import files manually from the queue.
  - **Movie & Series Files**: View detailed file metadata (quality, size,
    codecs) and extra files for both movies and series.
  - **Media History**: View movie-specific and series-specific historical
    events.
  - **Metadata Management**: Delete individual media files with confirmation
    dialogs and error handling.
  - **Edit Media**: Update monitoring, quality profile, root folder, and series
    type settings for movies and series.
  - **Move Files**: Option to physically move files when changing root folder
    during media edit.
  - **Slow Instance Mode**: Configurable extended timeout (90s) for slow or
    remote server connections.
  - **System Status**: Enhanced instance status and version checks.
  - **Auto-Updater**: Automatic and manual in-app updates via GitHub Releases.
- **Target Audience**: Home lab enthusiasts and media server maintainers who
  value a native mobile experience.

## Project Structure & Module Organization

- `lib/core`: Shared logic, constants, extensions, and utilities, including
  background services (`/services`).
- `lib/data`: Data layer including API clients (`/api`) and repository
  implementations (`/repositories`).
- `lib/domain`: Domain layer including models (`/models`) and repository
  interfaces (`/repositories`).
- `lib/presentation`: UI layer organized by feature (screens, widgets) and
  router configuration.
- `lib/providers`: State management using Riverpod.
- `assets/images`: Static image assets and icons.

## Build, Test, and Development Commands

- `flutter pub get`: Install dependencies.
- `flutter run`: Launch the application on a connected device or emulator.
- `flutter test`: Run unit and widget tests.
- `flutter build apk --split-per-abi`: Build release APKs for Android.
- `dart run build_runner build --delete-conflicting-outputs`: Generate code (if
  required by future dependencies).
- `dart run flutter_launcher_icons`: Generate app icons (configured for
  Android).

## Coding Style & Naming Conventions

- **Language**: Dart (Latest SDK).
- **Style**: Follow standard [Effective Dart](https://dart.dev/effective-dart)
  guidelines.
- **Formatting**: Use `dart format .` to ensure consistent formatting.
- **Naming**:
  - Classes: `PascalCase` (e.g., `MovieRepository`).
  - Variables/functions: `camelCase` (e.g., `getMovies`).
  - Files: `snake_case` (e.g., `movie_repository.dart`).
- **Lints**: Adhere to rules defined in `analysis_options.yaml` (based on
  `flutter_lints`).

## Logging Guidelines

All logging must be meaningful, useful, and secure. We use `LoggerService`
(accessed via global `logger`).

### DO NOT

- Use `print`, `debugPrint` or `stderr`.
- Log sensitive information (API Keys, tokens, passwords). **Mask these values**
  if logging headers or config objects.
- Log generic messages like "Error" without context or stack trace.

### DO

- Use the `[Component]` prefix in all log messages.
  - Good: `[MovieRepository] Fetching movies for instance: 1`
  - Bad: `Fetching movies`
- Use appropriate log levels:
  - `logger.debug`: detailed flow information, API request/response details
    (sanitized), state changes.
  - `logger.info`: high-level events (app started, user logged in, movie added).
  - `logger.warning`: unexpected but handled situations (retries, timeouts).
  - `logger.error`: exceptions that might impact user experience. Always pass
    `error` and `stackTrace`.
- Be consistent with the pattern: `[ServiceName] Action/State: Details` (e.g.,
  `[NtfyService] Connecting to topic: ...`).

## Documentation Guidelines

- **Language**: English (US) for all code comments and documentation.
- **DartDoc**: All public classes, methods, and fields must have DartDoc
  comments (`///`).
  - **Classes**: Describe the purpose of the class.
  - **Methods**: Describe what the method does, its parameters, and return
    value.
  - **Fields**: Describe what the field represents.
- **Comments**: Use `//` for implementation details inside methods if necessary,
  but prefer clean code that explains itself.
- **Formatting**: Keep comments concise and clear. Use referencing (e.g.,
  `[MyClass]`) when referring to other code elements.

## Testing Guidelines

- **Framework**: `flutter_test`.
- **Location**: Mirror the `lib/` structure inside the `test/` directory.
- **Conventions**: Test files should end with `_test.dart`.
- **Running**: Use `flutter test` to execute the suite.

## Commit & Pull Request Guidelines

- **Commits**: Use Conventional Commits format (e.g., `feat: add movie details`,
  `fix: resolve connection timeout`).
- **Pull Requests**:
  - Provide a clear description of changes.
  - Link related issues (if any).
  - Include screenshots or recordings for UI changes.

## Architecture Overview

The app follows a Clean Architecture-inspired layered approach:

1. **Data Layer**: Handles API communication (Dio) and data serialization.
2. **Domain/Providers**: Riverpod providers bridge data to UI and handle state.
3. **Presentation**: Screens and Widgets consume providers; minimal business
   logic in UI code.
4. **Services**: Background tasks for notifications and sync.

## Design Guidelines

**See**: @DESIGN_GUIDELINE.md

This file contains comprehensive UI/UX patterns, component templates, and design
system constants for maintaining consistency across the app. Always consult it
before creating new widgets or screens:

- **Design System**: Padding, spacing, border radius, colors
- **Card Patterns**: Grid cards, list tiles, progress cards
- **Bottom Sheets**: Draggable sheets, status badges, error containers
- **Common Widgets**: LoadingIndicator, ErrorDisplay, EmptyState
- **Formatters**: Bytes, durations, dates, custom scores
- **Images**: Cache patterns, placeholders, fallbacks
- **Best Practices**: Spacing rules, theme usage, Riverpod patterns

## Reference Implementation

The `rudarr/` directory contains the Ruddarr iOS app source code for reference.
It implements similar features in SwiftUI and can be used as a guide for API
integration and UI patterns.

## Quality Assurance

To ensure project stability, every code change or addition MUST be followed by
(use dart-mcp-server instead of direct commands if available):

1. **Format**: Run `dart format .` to maintain consistent style.
2. **Analyze**: Run `dart analyze` to catch potential errors and lint warnings.
3. **Test**: Run `flutter test` to ensure no regressions were introduced.
