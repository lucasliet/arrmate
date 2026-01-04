import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/advanced_providers.dart';
import 'package:arrmate/domain/models/models.dart';
import 'dart:async';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _levelFilter = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(logsProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(logsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _levelFilter = value;
              });
            },
            itemBuilder: (context) => [
              'All', 'Info', 'Warn', 'Error', 'Debug'
            ].map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(logsProvider.future),
        child: logsAsync.when(
          data: (logPage) {
            final records = _levelFilter == 'All' 
                ? logPage.records 
                : logPage.records.where((e) => e.level.toLowerCase() == _levelFilter.toLowerCase()).toList();

            if (records.isEmpty) {
              return const Center(child: Text('No logs found matching filter'));
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: records.length + 1,
              itemBuilder: (context, index) {
                if (index == records.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final log = records[index];
                final isError = log.level.toLowerCase() == 'error';
                final isWarn = log.level.toLowerCase() == 'warn';

                return ListTile(
                  title: Text(
                    log.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: isError ? Colors.red : (isWarn ? Colors.orange : null),
                    ),
                  ),
                  subtitle: Text('${log.time.toLocal()} - ${log.logger}'),
                  onTap: () => _showLogDetail(context, log),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  void _showLogDetail(BuildContext context, LogEntry log) {
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
              Text('Log Detail', style: Theme.of(context).textTheme.headlineSmall),
              const Divider(),
              _buildDetailItem('Time', log.time.toLocal().toString()),
              _buildDetailItem('Level', log.level),
              _buildDetailItem('Logger', log.logger),
              const SizedBox(height: 16),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.withOpacity(0.1),
                child: Text(log.message, style: const TextStyle(fontFamily: 'monospace')),
              ),
              if (log.exception != null) ...[
                const SizedBox(height: 16),
                const Text('Exception:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.05),
                  child: Text(log.exception!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
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
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
