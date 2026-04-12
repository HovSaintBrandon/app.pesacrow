import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On wide web screens (>= 800px), wraps content in a max-width centered layout.
/// On mobile or narrow web, passes through transparently.
class WebFrame extends StatelessWidget {
  final Widget child;

  const WebFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // On mobile app, always passthrough
    if (!kIsWeb) return child;

    // On web, just return child — MainScaffold handles its own responsive layout.
    // We keep WebFrame in the tree so it can be extended later (e.g. for non-scaffold pages).
    return child;
  }
}
