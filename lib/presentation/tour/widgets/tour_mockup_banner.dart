import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Key identifying the banner that introduces the guided tour mockups.
const Key tourMockupBannerKey = ValueKey('tour-mockup-banner');

/// Banner shown above the guided tour mockups, making it explicit that the
/// entries below are samples rather than real library data.
class TourMockupBanner extends StatelessWidget {
  /// Creates a banner describing the sample content shown by the tour.
  const TourMockupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: tourMockupBannerKey,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, paddingSm, 0, paddingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: paddingMd,
        vertical: paddingSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: iconSizeSm,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: paddingSm),
          Expanded(
            child: Text(
              'Sample content shown during the tour. It disappears once the '
              'tour ends.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps guided tour sample content so it stays purely visual.
///
/// The mockups mirror real cards, but tapping them must never open details for
/// media that does not exist, so pointer events are swallowed here.
class TourMockup extends StatelessWidget {
  /// The sample content to render.
  final Widget child;

  /// Creates an inert wrapper around [child].
  const TourMockup({super.key, required this.child});

  @override
  Widget build(BuildContext context) => IgnorePointer(child: child);
}
