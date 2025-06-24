import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';

class CacheService {
  static final Logger _logger = Logger();

  /// Clear all cached images
  static Future<void> clearImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      _logger.i('Image cache cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear image cache: $e');
    }
  }

  /// Clear specific image from cache
  static Future<void> clearImageFromCache(String url) async {
    try {
      await DefaultCacheManager().removeFile(url);
      _logger.i('Removed image from cache: $url');
    } catch (e) {
      _logger.e('Failed to remove image from cache: $e');
    }
  }

  /// Get cache info
  static Future<String> getCacheInfo() async {
    try {
      final cacheManager = DefaultCacheManager();
      final store = cacheManager.store;

      // This is a simplified version - actual cache info would need more detailed implementation
      return 'Cache manager initialized';
    } catch (e) {
      _logger.e('Failed to get cache info: $e');
      return 'Cache info unavailable';
    }
  }

  /// Preload images for better performance
  static Future<void> preloadSymbolImages(List<String> symbols) async {
    try {
      _logger.i('Preloading ${symbols.length} symbol images');

      for (final symbol in symbols) {
        // Preload both uppercase and lowercase versions
        final uppercaseUrl = 'https://eodhd.com/img/logos/US/${symbol.toUpperCase()}.png';
        final lowercaseUrl = 'https://eodhd.com/img/logos/US/${symbol.toLowerCase()}.png';

        // Preload without waiting (fire and forget) - ignore errors silently
        DefaultCacheManager().downloadFile(uppercaseUrl).ignore();
        DefaultCacheManager().downloadFile(lowercaseUrl).ignore();
      }

      _logger.i('Started preloading symbol images');
    } catch (e) {
      _logger.e('Failed to preload symbol images: $e');
    }
  }
}
