import 'package:flutter/material.dart';

import 'window_class.dart';

/// Opens transient content as a sheet on compact windows and a dialog elsewhere.
class AdaptiveSurface {
  const AdaptiveSurface._();

  /// Presents [builder] using the interaction appropriate to available width.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
  }) {
    final windowClass = WindowClass.fromWidth(MediaQuery.sizeOf(context).width);
    if (windowClass == WindowClass.compact) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        isDismissible: isDismissible,
        builder: builder,
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
          child: builder(context),
        ),
      ),
    );
  }
}
