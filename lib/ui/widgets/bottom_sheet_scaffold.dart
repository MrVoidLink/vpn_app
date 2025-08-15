import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomSheetScaffoldV2 extends StatelessWidget {
  const BottomSheetScaffoldV2({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.footer,
    this.onRefresh,
    this.isLoading = false,
    this.errorText,
    this.empty = false,
    required this.childrenBuilder,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? footer;

  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final String? errorText;
  final bool empty;

  /// Content builder؛ چون بعضی صفحات ممکنه داده async داشته باشن
  final List<Widget> Function(BuildContext context) childrenBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = const Radius.circular(28);
    final borderRadius = BorderRadius.only(topLeft: radius, topRight: radius);

    final content = _buildStatefulBody(context, theme);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          elevation: 0,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _DragHandle(),
                const SizedBox(height: 8),
                _Header(
                  title: title,
                  subtitle: subtitle,
                  leading: leading,
                  actions: actions,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: onRefresh != null
                        ? RefreshIndicator.adaptive(
                      onRefresh: () async {
                        HapticFeedback.selectionClick();
                        await onRefresh!.call();
                      },
                      child: content,
                    )
                        : content,
                  ),
                ),
                if (footer != null) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: footer!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatefulBody(BuildContext context, ThemeData theme) {
    if (isLoading) {
      return const _LoadingView();
    }
    if (errorText != null && errorText!.trim().isNotEmpty) {
      return _ErrorView(
        message: errorText!,
        onRetry: onRefresh,
      );
    }
    if (empty) {
      return const _EmptyView();
    }

    final children = childrenBuilder(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: children,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 8),
      child: Row(
        children: [
          leading ?? const SizedBox(width: 0, height: 0),
          if (leading != null) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    // می‌تونی Skeleton هم اضافه کنی
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Icon(Icons.error_outline, size: 40,
            color: theme.colorScheme.error.withValues(alpha: 0.9)),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (onRetry != null)
          FilledButton.icon(
            onPressed: () => onRetry!.call(),
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
          ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Icon(Icons.inbox_outlined,
            size: 40, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(
          'موردی برای نمایش نیست',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}


/// Backward-compat adapter so existing code `BottomSheetScaffold(...)` still works.
class BottomSheetScaffold extends BottomSheetScaffoldV2 {
  const BottomSheetScaffold({
    super.key,
    required super.title,
    super.subtitle,
    super.leading,
    super.actions,
    super.footer,
    super.onRefresh,
    super.isLoading = false,
    super.errorText,
    super.empty = false,
    required super.childrenBuilder,
  });
}
