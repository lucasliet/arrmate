import 'package:flutter/material.dart';

// Placeholder for HistoryListItem
// Will implement simple tile for now since History model is not fully ready
/// A list tile widget for displaying a single history item.
class HistoryListItem extends StatelessWidget {
  const HistoryListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      title: Text('History Item'),
      subtitle: Text('Details...'),
    );
  }
}
