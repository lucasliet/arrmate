import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/advanced_providers.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/core/services/logger_service.dart';
import 'dart:async';
import 'package:flutter/services.dart';

/// Displays both internal app logs and remote system logs from instances.
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String _levelFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_tabController.index == 0 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      ref.read(logsProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ARR Logs'),
            Tab(text: 'App Logs'),
          ],
        ),
        actions: [
          if (_tabController.index == 1) // Only show clear button for App Logs
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear App Logs',
              onPressed: () {
                logger.clearLogs();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App logs cleared')),
                  );
                }
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _levelFilter = value;
              });
            },
            itemBuilder: (context) => [
              'All',
              'Info',
              'Warn',
              'Error',
              'Debug',
            ].map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy all visible logs',
            onPressed: () => _copyAllLogs(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildArrLogs(), _buildAppLogs()],
      ),
    );
  }

  Widget _buildArrLogs() {
    final instances = ref.watch(arrLogInstancesProvider);
    final selectedInstance = ref.watch(selectedArrLogInstanceProvider);
    final logsAsync = ref.watch(logsProvider);

    return Column(
      children: [
        if (instances.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Log source',
                prefixIcon: Icon(Icons.dns_outlined),
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('arrLogsInstanceSelector'),
                  value: selectedInstance?.id,
                  isExpanded: true,
                  items: [
                    for (final instance in instances)
                      DropdownMenuItem(
                        value: instance.id,
                        child: Text(_instanceLabel(instance)),
                      ),
                  ],
                  onChanged: (instanceId) {
                    ref.read(selectedArrLogInstanceIdProvider.notifier).state =
                        instanceId;
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(logsProvider.future),
            child: logsAsync.when(
              data: (logPage) {
                final records = _levelFilter == 'All'
                    ? logPage.records
                    : logPage.records
                          .where(
                            (entry) =>
                                entry.level.toLowerCase() ==
                                _levelFilter.toLowerCase(),
                          )
                          .toList();

                if (instances.isEmpty) {
                  return ListView(
                    controller: _scrollController,
                    children: const [
                      SizedBox(height: 160),
                      Center(
                        child: Text('No Radarr or Sonarr instances configured'),
                      ),
                    ],
                  );
                }

                if (records.isEmpty) {
                  return ListView(
                    controller: _scrollController,
                    children: const [
                      SizedBox(height: 160),
                      Center(child: Text('No logs found matching filter')),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: records.length + 1,
                  itemBuilder: (context, index) {
                    if (index == records.length) {
                      if (logsAsync.isLoading && logsAsync.hasValue) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final log = records[index];
                    return _LogTile(
                      message: log.message,
                      level: log.level,
                      time: log.time,
                      logger: log.logger,
                      exception: log.exception,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ],
    );
  }

  String _instanceLabel(Instance instance) {
    final configuredLabel = instance.label.trim();
    final serverName = instance.name?.trim() ?? '';
    final name = configuredLabel.isNotEmpty
        ? configuredLabel
        : serverName.isNotEmpty
        ? serverName
        : instance.type.label;
    return name == instance.type.label
        ? name
        : '$name · ${instance.type.label}';
  }

  Widget _buildAppLogs() {
    final appLogsAsync = ref.watch(appLogsProvider);

    return appLogsAsync.when(
      data: (logs) {
        final filteredLogs = _levelFilter == 'All'
            ? logs
            : logs
                  .where(
                    (e) =>
                        e.level.name.toLowerCase() ==
                        _levelFilter.toLowerCase(),
                  )
                  .toList();

        if (filteredLogs.isEmpty) {
          return const Center(child: Text('No app logs found matching filter'));
        }

        return ListView.builder(
          itemCount: filteredLogs.length,
          itemBuilder: (context, index) {
            final log = filteredLogs[index];
            return _LogTile(
              message: log.message,
              level: log.level.name,
              time: log.time,
              logger: 'Internal',
              exception: log.error?.toString(),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Future<void> _copyAllLogs() async {
    final currentLogs = _tabController.index == 0
        ? ref.read(logsProvider)
        : ref.read(appLogsProvider);
    String text = '';

    currentLogs.whenData((logs) {
      if (_tabController.index == 0) {
        final records = (logs as LogPage).records;
        text = records
            .map(
              (e) => _formatLogForClipboard(
                time: e.time,
                level: e.level,
                logger: e.logger,
                message: e.message,
                exception: e.exception,
              ),
            )
            .join('\n\n');
      } else {
        final records = logs as List<AppLogEntry>;
        text = records
            .map(
              (e) => _formatLogForClipboard(
                time: e.time,
                level: e.level.name,
                logger: 'Internal',
                message: e.message,
                exception: e.error?.toString(),
              ),
            )
            .join('\n\n');
      }
    });

    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All logs copied to clipboard')),
        );
      }
    }
  }
}

class _LogTile extends StatelessWidget {
  final String message;
  final String level;
  final DateTime time;
  final String logger;
  final String? exception;

  const _LogTile({
    required this.message,
    required this.level,
    required this.time,
    required this.logger,
    this.exception,
  });

  @override
  Widget build(BuildContext context) {
    final isError = level.toLowerCase() == 'error';
    final isWarn =
        level.toLowerCase() == 'warn' || level.toLowerCase() == 'warning';

    return ListTile(
      title: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isError ? Colors.red : (isWarn ? Colors.orange : null),
        ),
      ),
      subtitle: Text('${time.toLocal()} - $logger'),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 20),
        onPressed: () async {
          await Clipboard.setData(
            ClipboardData(
              text: _formatLogForClipboard(
                time: time,
                level: level,
                logger: logger,
                message: message,
                exception: exception,
              ),
            ),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Log copied')));
          }
        },
      ),
      onTap: () => _showLogDetail(context),
    );
  }

  void _showLogDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Log Detail',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              _buildDetailItem('Time', time.toLocal().toString()),
              _buildDetailItem('Level', level),
              _buildDetailItem('Logger', logger),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.grey.withAlpha(26),
                child: Text(
                  message,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              if (exception != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Exception/Error:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withAlpha(13),
                  child: Text(
                    exception!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Renders a log entry the way the clipboard should carry it.
///
/// The exception is the half of an entry worth pasting into a bug report, so
/// it travels with the message instead of being left behind on the screen.
String _formatLogForClipboard({
  required DateTime time,
  required String level,
  required String logger,
  required String message,
  String? exception,
}) {
  final entry = StringBuffer('[${time.toLocal()}] $level ($logger): $message');
  if (exception != null && exception.isNotEmpty) {
    entry.write('\n$exception');
  }
  return entry.toString();
}
