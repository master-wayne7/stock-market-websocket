import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';

class SymbolImage extends StatelessWidget {
  final String symbol;
  final double size;
  final Color? backgroundColor;

  const SymbolImage({
    super.key,
    required this.symbol,
    this.size = 32.0,
    this.backgroundColor,
  });

  Widget _buildFallbackWidget() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          symbol.length > 2 ? symbol.substring(0, 2).toUpperCase() : symbol.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    // Try lowercase image in error widget
    return CachedNetworkImage(
      imageUrl: AppConstants.getSymbolImageUrl(symbol, lowercase: true),
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingWidget(),
      errorWidget: (context, url, error) => _buildFallbackWidget(),
      memCacheWidth: (size * 2).round(),
      memCacheHeight: (size * 2).round(),
      maxWidthDiskCache: (size * 3).round(),
      maxHeightDiskCache: (size * 3).round(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      cacheKey: 'symbol_${symbol.toLowerCase()}_${size.round()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CachedNetworkImage(
          imageUrl: AppConstants.getSymbolImageUrl(symbol), // Default uppercase
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingWidget(),
          errorWidget: (context, url, error) => _buildErrorWidget(), // Try lowercase on error
          memCacheWidth: (size * 2).round(),
          memCacheHeight: (size * 2).round(),
          maxWidthDiskCache: (size * 3).round(),
          maxHeightDiskCache: (size * 3).round(),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          cacheKey: 'symbol_${symbol.toUpperCase()}_${size.round()}',
        ),
      ),
    );
  }
}
