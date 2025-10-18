import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConfig.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppConfig.tabletBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        
        if (constraints.maxWidth >= AppConfig.desktopBreakpoint) {
          crossAxisCount = 4; // Desktop: 4 columns
        } else if (constraints.maxWidth >= AppConfig.tabletBreakpoint) {
          crossAxisCount = 3; // Tablet: 3 columns
        } else if (constraints.maxWidth >= AppConfig.mobileBreakpoint) {
          crossAxisCount = 2; // Large mobile: 2 columns
        } else {
          crossAxisCount = 1; // Small mobile: 1 column
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        EdgeInsets padding;
        
        if (constraints.maxWidth >= AppConfig.desktopBreakpoint) {
          padding = desktopPadding ?? const EdgeInsets.all(24.0);
        } else if (constraints.maxWidth >= AppConfig.tabletBreakpoint) {
          padding = tabletPadding ?? const EdgeInsets.all(16.0);
        } else {
          padding = mobilePadding ?? const EdgeInsets.all(12.0);
        }

        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        TextStyle responsiveStyle = style ?? Theme.of(context).textTheme.bodyMedium!;
        
        if (constraints.maxWidth >= AppConfig.desktopBreakpoint) {
          responsiveStyle = responsiveStyle.copyWith(fontSize: (style?.fontSize ?? 14) + 2);
        } else if (constraints.maxWidth >= AppConfig.tabletBreakpoint) {
          responsiveStyle = responsiveStyle.copyWith(fontSize: (style?.fontSize ?? 14) + 1);
        }

        return Text(
          text,
          style: responsiveStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AppBar(
          title: ResponsiveText(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: actions,
          centerTitle: centerTitle,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: constraints.maxWidth >= AppConfig.tabletBreakpoint ? 4 : 2,
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
