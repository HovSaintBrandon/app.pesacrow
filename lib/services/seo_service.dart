import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// A service to handle dynamic SEO metadata updates in Flutter Web.
/// This updates the browser's document title and meta tags.
class SeoService {
  static void updateSEO({
    required String title,
    required String description,
    String? imageUrl,
  }) {
    if (!kIsWeb) return;

    // Update Title
    js.context['document']['title'] = title;

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
  }

  static void _updateMetaTag(String name, String content) {
    if (!kIsWeb) return;

    // We can use direct JS manipulation for meta tags
    js.context.callMethod('eval', [
      '''
      (function() {
        var names = ['name', 'property'];
        var tag;
        for (var i = 0; i < names.length; i++) {
          tag = document.querySelector('meta[' + names[i] + '="$name"]');
          if (tag) break;
        }
        
        if (!tag) {
          tag = document.createElement('meta');
          tag.setAttribute('name', '$name');
          document.head.appendChild(tag);
        }
        tag.setAttribute('content', '$content');
      })()
      '''
    ]);
  }
}
