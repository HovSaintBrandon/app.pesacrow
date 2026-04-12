import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNotifications {
  static OverlayEntry? _currentOverlay;
  static AnimationController? _currentController;
  static Timer? _timer;

  static void showSuccess(BuildContext context, String message) {
    _showOverlay(context, message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    _showOverlay(context, message, isError: true);
  }

  static void _showOverlay(BuildContext context, String message, {required bool isError}) {
    // If a notification is currently visible, destroy it immediately.
    final prevController = _currentController;
    final prevOverlay = _currentOverlay;
    
    if (prevController != null && prevOverlay != null) {
      try {
        if (!prevController.isDismissed) {
          prevController.reverse().then((_) {
            prevOverlay.remove();
          }).catchError((_) { /* Ignore errors if already disposed */ });
        } else {
          prevOverlay.remove();
        }
      } catch (e) {
        // Fallback catch if controller is already disposed
        try { prevOverlay.remove(); } catch (_) {}
      }
    }
    
    _currentController = null;
    _currentOverlay = null;
    _timer?.cancel();

    final overlayState = Overlay.of(context);
    
    // Use theme primary color for success (Green/Blue depending on role) or Red for error.
    final primaryColor = Theme.of(context).colorScheme.primary; 
    final bgColor = isError ? const Color(0xFFEF4444) : primaryColor;
    final iconData = isError ? Icons.error_outline : Icons.check_circle;

    late OverlayEntry overlayEntry;

    // Create a local AnimationController that we manage within the overlay builder.
    // To do this, we need a Stateful widget wrapper.
    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedToast(
        message: message,
        bgColor: bgColor,
        iconData: iconData,
        onInit: (controller) {
          _currentController = controller;
        },
        onDismiss: () {
          _timer?.cancel();
          _currentController?.reverse().then((_) {
            overlayEntry.remove();
            if (_currentOverlay == overlayEntry) {
              _currentOverlay = null;
              _currentController = null;
            }
          });
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlayState.insert(overlayEntry);

    // Auto-dismissal after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      _currentController?.reverse().then((_) {
        // Double check it hasn't already been removed
        if (_currentOverlay == overlayEntry) {
          overlayEntry.remove();
          _currentOverlay = null;
          _currentController = null;
        }
      });
    });
  }
}

class _AnimatedToast extends StatefulWidget {
  final String message;
  final Color bgColor;
  final IconData iconData;
  final Function(AnimationController) onInit;
  final VoidCallback onDismiss;

  const _AnimatedToast({
    required this.message,
    required this.bgColor,
    required this.iconData,
    required this.onInit,
    required this.onDismiss,
  });

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuint,
    ));

    widget.onInit(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 10;

    return Positioned(
      top: topPadding,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Icon(widget.iconData, color: Colors.white, size: 24),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       widget.message,
                       style: GoogleFonts.inter(
                         color: Colors.white,
                         fontSize: 14,
                         fontWeight: FontWeight.w700,
                       ),
                     ),
                   ),
                   GestureDetector(
                     onTap: widget.onDismiss,
                     child: const Icon(Icons.close, color: Colors.white70, size: 20),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
