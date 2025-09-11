import 'package:flutter/material.dart';
import '../services/responsive_service.dart';

/// Adaptive card that adjusts its layout based on screen size
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool useFlexibleWidth;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.useFlexibleWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveService.getResponsivePadding(context);
    final responsiveMargin = margin ?? const EdgeInsets.all(8.0);
    final cardWidth = useFlexibleWidth ? ResponsiveService.getResponsiveCardWidth(context) : null;
    final minTapTarget = ResponsiveService.getMinTapTargetSize(context);

    Widget cardContent = Card(
      color: color,
      elevation: elevation ?? 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
        child: Container(
          width: cardWidth,
          constraints: BoxConstraints(
            minHeight: onTap != null ? minTapTarget : 0,
          ),
          padding: responsivePadding,
          child: child,
        ),
      ),
    );

    return Container(
      margin: responsiveMargin,
      child: cardContent,
    );
  }
}

/// Adaptive grid that adjusts column count based on screen size
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveService.getDeviceType(context);
    final responsivePadding = padding ?? ResponsiveService.getResponsivePadding(context);
    
    int crossAxisCount;
    switch (deviceType) {
      case DeviceType.mobile:
        crossAxisCount = 1;
        break;
      case DeviceType.tablet:
        crossAxisCount = 2;
        break;
      case DeviceType.desktop:
        crossAxisCount = 3;
        break;
    }

    return Padding(
      padding: responsivePadding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: ResponsiveService.isMobile(context) ? 3.0 : 1.5,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Adaptive dialog that shows full screen on mobile, modal on desktop
class AdaptiveDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool barrierDismissible;

  const AdaptiveDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.barrierDismissible = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AdaptiveDialog(
        title: title,
        actions: actions,
        barrierDismissible: barrierDismissible,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shouldUseFullScreen = ResponsiveService.shouldUseFullScreenDialog(context);
    final dialogWidth = ResponsiveService.getDialogWidth(context);

    if (shouldUseFullScreen) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: title != null
              ? AppBar(
                  title: Text(title!),
                  actions: actions,
                )
              : null,
          body: child,
        ),
      );
    } else {
      return Dialog(
        child: Container(
          width: dialogWidth,
          constraints: const BoxConstraints(
            maxHeight: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              Flexible(child: child),
              if (actions != null && actions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }
}

/// Adaptive data display that shows table on desktop, list on mobile
class AdaptiveDataDisplay<T> extends StatelessWidget {
  final List<T> data;
  final List<String> columnHeaders;
  final List<String Function(T)> cellBuilders;
  final Widget Function(T)? listTileBuilder;
  final VoidCallback? onRefresh;

  const AdaptiveDataDisplay({
    super.key,
    required this.data,
    required this.columnHeaders,
    required this.cellBuilders,
    this.listTileBuilder,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveService.isMobile(context);
    final shouldEnablePullToRefresh = ResponsiveService.shouldEnablePullToRefresh(context);

    Widget content;

    if (isMobile) {
      // Mobile: Show as list
      content = ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          
          if (listTileBuilder != null) {
            return listTileBuilder!(item);
          }
          
          // Default list tile
          return ListTile(
            title: Text(cellBuilders[0](item)),
            subtitle: cellBuilders.length > 1 ? Text(cellBuilders[1](item)) : null,
            trailing: cellBuilders.length > 2 
                ? Text(cellBuilders[2](item))
                : null,
          );
        },
      );
    } else {
      // Desktop/Tablet: Show as table
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columnHeaders.map((header) => DataColumn(
            label: Text(header),
          )).toList(),
          rows: data.map((item) => DataRow(
            cells: cellBuilders.map((builder) => DataCell(
              Text(builder(item)),
            )).toList(),
          )).toList(),
        ),
      );
    }

    // Wrap with pull-to-refresh if enabled and callback provided
    if (shouldEnablePullToRefresh && onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: () async {
          onRefresh!();
        },
        child: content,
      );
    }

    return content;
  }
}

/// Adaptive text that scales based on device type
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = ResponsiveService.getResponsiveTextScale(context);
    
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textScaler: TextScaler.linear(textScale),
    );
  }
}
