import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// A service to handle dynamic SEO metadata updates in Flutter Web.
/// This updates the browser's document title and meta tags safely.
class SeoService {
  static void updateSEO({
    required String title,
    required String description,
    String? imageUrl,
  }) {
    if (!kIsWeb) return;

    try {
      // Safely update Title via JS eval to avoid NoSuchMethodError in production
      js.context.callMethod('eval', ['document.title = ${_jsString(title)}']);

      // Update Meta Tags
      _updateMetaTag('description', description);
      _updateMetaTag('og:title', title);
      _updateMetaTag('og:description', description);
      _updateMetaTag('twitter:title', title);
      _updateMetaTag('twitter:description', description);

      if (imageUrl != null) {
        _updateMetaTag('og:image', imageUrl);
        _updateMetaTag('twitter:image', imageUrl);
      }
    } catch (e) {
      if (kDebugMode) print('SEO Error: \$e');
    }
  }

  static void _updateMetaTag(String name, String content) {
    if (!kIsWeb) return;

    try {
      // Use direct JS manipulation for meta tags
      js.context.callMethod('eval', [
        '''
        (function() {
          var names = ['name', 'property'];
          var tag;
          for (var i = 0; i < names.length; i++) {
            tag = document.querySelector('meta[' + names[i] + '="${_escape(name)}"]');
            if (tag) break;
          }
          
          if (!tag) {
            tag = document.createElement('meta');
            tag.setAttribute('name', "${_escape(name)}");
            document.head.appendChild(tag);
          }
          tag.setAttribute('content', ${_jsString(content)});
        })()
        '''
      ]);
    } catch (e) {
      if (kDebugMode) print('Meta Tag Error (\$name): \$e');
    }
  }

  static String _jsString(String s) => '"${_escape(s)}"';

  static String _escape(String s) => s.replaceAll('"', '\\"').replaceAll('\\n', ' ');
}
