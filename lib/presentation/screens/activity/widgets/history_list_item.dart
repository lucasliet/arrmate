import 'package:flutter/material.dart';

// Placeholder for HistoryListItem
// Will implement simple tile for now since History model is not fully ready
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
