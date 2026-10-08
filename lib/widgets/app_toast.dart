import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_navigator.dart';

class AppToast {
  static OverlayState? _overlay([BuildContext? context]) {
    return rootNavigatorKey.currentState?.overlay ??
        (context != null ? Overlay.maybeOf(context, rootOverlay: true) : null);
  }

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    IconData icon = Icons.check_circle_rounded,
    Color? color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = _overlay(context);
    if (overlay == null) return;

    final accent = color ??
        (context.mounted ? AppColors.primaryOf(context) : AppColors.primary);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        title: title,
        message: message,
        icon: icon,
        color: accent,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Future.delayed(Duration(seconds: onAction == null ? 3 : 5), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.title,
    this.message,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withValues(alpha: 0.35)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      if (widget.message != null)
                        Text(widget.message!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      widget.onDismiss();
                      widget.onAction!();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: widget.color,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(widget.actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
