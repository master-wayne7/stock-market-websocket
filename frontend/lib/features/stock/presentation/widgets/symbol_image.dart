import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';

class SymbolImage extends StatefulWidget {
  final String symbol;
  final double size;
  final Color? backgroundColor;

  const SymbolImage({
    super.key,
    required this.symbol,
    this.size = 32.0,
    this.backgroundColor,
  });

  @override
  State<SymbolImage> createState() => _SymbolImageState();
}

class _SymbolImageState extends State<SymbolImage> {
  // Static cache to remember which case works for each symbol across widget instances
  static final Map<String, bool> _symbolCaseCache = {};
  bool _isLoading = true;
  bool _hasError = false;
  String? _workingImageUrl;

  @override
  void initState() {
    super.initState();
    _determineWorkingUrl();
  }

  @override
  void didUpdateWidget(SymbolImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _determineWorkingUrl();
    }
  }

  Future<void> _determineWorkingUrl() async {
    // Check if we already know which case works for this symbol
    if (_symbolCaseCache.containsKey(widget.symbol)) {
      final useUppercase = _symbolCaseCache[widget.symbol]!;
      final imageUrl = AppConstants.getSymbolImageUrl(widget.symbol, lowercase: !useUppercase);
      if (mounted) {
        setState(() {
          _workingImageUrl = imageUrl;
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    // Try to determine which case works by checking the cache of CachedNetworkImage
    // If no cache exists, we'll default to uppercase and learn from the result
    final uppercaseUrl = AppConstants.getSymbolImageUrl(widget.symbol, lowercase: false);
    if (mounted) {
      setState(() {
        _workingImageUrl = uppercaseUrl;
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  void _onImageLoadSuccess(bool wasUppercase) {
    // Remember this choice for future instances
    _symbolCaseCache[widget.symbol] = wasUppercase;
  }

  void _onImageLoadError(bool wasUppercase) {
    // Try the opposite case
    final useUppercase = !wasUppercase;
    final imageUrl = AppConstants.getSymbolImageUrl(widget.symbol, lowercase: !useUppercase);

    if (mounted) {
      setState(() {
        _workingImageUrl = imageUrl;
        _hasError = false;
      });
    }
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          widget.symbol.length > 2 ? widget.symbol.substring(0, 2).toUpperCase() : widget.symbol.toUpperCase(),
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.5,
          height: widget.size * 0.5,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _isLoading
            ? _buildLoadingWidget()
            : _SmartCachedImage(
                imageUrl: _workingImageUrl!,
                symbol: widget.symbol,
                size: widget.size,
                onSuccess: _onImageLoadSuccess,
                onError: _onImageLoadError,
                fallbackWidget: _buildFallbackWidget(),
              ),
      ),
    );
  }
}

class _SmartCachedImage extends StatefulWidget {
  final String imageUrl;
  final String symbol;
  final double size;
  final Function(bool wasUppercase) onSuccess;
  final Function(bool wasUppercase) onError;
  final Widget fallbackWidget;

  const _SmartCachedImage({
    required this.imageUrl,
    required this.symbol,
    required this.size,
    required this.onSuccess,
    required this.onError,
    required this.fallbackWidget,
  });

  @override
  State<_SmartCachedImage> createState() => _SmartCachedImageState();
}

class _SmartCachedImageState extends State<_SmartCachedImage> {
  bool _hasTriedBothCases = false;

  bool _isUppercaseUrl(String url) {
    return url.contains('${widget.symbol.toUpperCase()}.png');
  }

  @override
  Widget build(BuildContext context) {
    final isUppercase = _isUppercaseUrl(widget.imageUrl);
    final cacheKey = 'symbol_${isUppercase ? widget.symbol.toUpperCase() : widget.symbol.toLowerCase()}_${widget.size.round()}';

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        if (!_hasTriedBothCases) {
          _hasTriedBothCases = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onError(isUppercase);
          });
          // Return a temporary placeholder while switching URLs
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        } else {
          // Both cases failed, show fallback
          return widget.fallbackWidget;
        }
      },
      memCacheWidth: (widget.size * 2).round(),
      memCacheHeight: (widget.size * 2).round(),
      maxWidthDiskCache: (widget.size * 3).round(),
      maxHeightDiskCache: (widget.size * 3).round(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      cacheKey: cacheKey,
      imageBuilder: (context, imageProvider) {
        // Image loaded successfully, remember this choice
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSuccess(isUppercase);
        });
        return Image(
          image: imageProvider,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
