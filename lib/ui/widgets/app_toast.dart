import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum ToastType { info, success, error }

class AppToast {
  static OverlayEntry? _currentEntry;

  static void dismiss() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    // Dismiss any existing toast first
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final IconData effectiveIcon = icon ??
        (switch (type) {
          ToastType.error => Icons.warning_amber_rounded,
          ToastType.success => Icons.check_circle_outline,
          ToastType.info => Icons.info_outline,
        });

    final Color accentColor = switch (type) {
      ToastType.error => AppTheme.rubyEmergency,
      ToastType.success => AppTheme.emeraldSuccess,
      ToastType.info => AppTheme.goldLight,
    };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlayWidget(
        message: message,
        icon: effectiveIcon,
        accentColor: accentColor,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            try {
              entry.remove();
            } catch (_) {}
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 3200)}) {
    show(context, message, type: ToastType.error, duration: duration);
  }

  static void success(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2800)}) {
    show(context, message, type: ToastType.success, duration: duration);
  }

  static void info(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2800)}) {
    show(context, message, type: ToastType.info, duration: duration);
  }
}

class _ToastOverlayWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accentColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlayWidget({
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<_ToastOverlayWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();

    _autoDismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _handleDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    _autoDismissTimer?.cancel();
    if (_animController.isAnimating) return;
    try {
      await _animController.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 12;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _handleDismiss,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                      _handleDismiss();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.accentColor.withOpacity(0.55),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.icon, color: widget.accentColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: AppTheme.crema,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
