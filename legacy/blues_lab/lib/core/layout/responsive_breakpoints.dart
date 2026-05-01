import 'package:flutter/widgets.dart';

/// Width breakpoints for web-first layout with usable mobile/tablet fallbacks.
abstract final class ResponsiveBreakpoints {
  /// Phone / narrow: modal [Drawer], stacked panels, tighter padding.
  static const double compactMax = 720;

  /// Tablet: still stacked or short side-by-side; drawer optional by product.
  static const double mediumMax = 1024;

  /// Max width for readable main content on ultra-wide monitors.
  static const double contentMaxWidth = 1320;

  static bool isCompact(double width) => width < compactMax;

  static bool isMedium(double width) =>
      width >= compactMax && width < mediumMax;

  static bool isExpanded(double width) => width >= mediumMax;

  /// Horizontal padding for page margins.
  static double pageHorizontalPadding(double width) {
    if (width < compactMax) return 12;
    if (width < mediumMax) return 16;
    return 24;
  }
}

extension ResponsiveBuildContext on BuildContext {
  double get responsiveWidth => MediaQuery.sizeOf(this).width;

  bool get isCompactLayout =>
      ResponsiveBreakpoints.isCompact(responsiveWidth);
}
