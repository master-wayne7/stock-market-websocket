import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wideDesktop = 1600;
}

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile && width < ResponsiveBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  }

  static bool isWideDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.wideDesktop;
  }

  static int getColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    if (isWideDesktop(context)) return 4;
    return 3; // Desktop
  }

  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 32.0;
    if (isWideDesktop(context)) return 64.0;
    return 48.0; // Desktop
  }

  static double getVerticalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0; // Desktop and above
  }

  static double getMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    if (isWideDesktop(context)) return 1400;
    return 1200; // Desktop
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: getVerticalPadding(context),
    );
  }

  static CrossAxisAlignment getCrossAxisAlignment(BuildContext context) {
    return isMobile(context) ? CrossAxisAlignment.stretch : CrossAxisAlignment.start;
  }

  static MainAxisAlignment getMainAxisAlignment(BuildContext context) {
    return isMobile(context) ? MainAxisAlignment.start : MainAxisAlignment.center;
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ResponsiveBreakpoints.mobile) {
          return mobile;
        } else if (constraints.maxWidth < ResponsiveBreakpoints.tablet) {
          return tablet ?? mobile;
        } else {
          return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: ResponsiveUtils.getMaxWidth(context),
      ),
      padding: ResponsiveUtils.getScreenPadding(context),
      child: centerContent ? Center(child: child) : child,
    );
  }
}
