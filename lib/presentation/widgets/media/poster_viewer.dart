import 'package:flutter/material.dart';

/// Displays a media poster in an interactive full-screen dialog.
class PosterViewer extends StatelessWidget {
  /// Title shown in the dialog app bar.
  final String title;

  /// Poster widget rendered inside the zoomable viewport.
  final Widget poster;

  const PosterViewer({super.key, required this.title, required this.poster});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(title),
          leading: IconButton(
            key: const Key('closePosterViewer'),
            tooltip: 'Close poster',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ),
        body: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          // A mouse wheel already zooms. A trackpad scroll otherwise pans, and
          // a poster that already fits the viewport cannot pan, so the gesture
          // looks like a no-op.
          trackpadScrollCausesScale: true,
          child: Center(
            child: AspectRatio(aspectRatio: 2 / 3, child: poster),
          ),
        ),
      ),
    );
  }
}

/// Opens a zoomable full-screen poster viewer.
Future<void> showPosterViewer({
  required BuildContext context,
  required String title,
  required Widget poster,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (context) => PosterViewer(title: title, poster: poster),
  );
}
