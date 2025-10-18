import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../screens/product_detail_screen.dart';
import '../config/env_config.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Initialize deep link handling
  void initialize(BuildContext context) {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri, context);
      },
      onError: (Object err) {
        print('Deep link error: $err');
      },
    );

    // Handle initial link (when app is opened from a link)
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri, context);
      }
    });
  }

  // Handle deep link
  void _handleDeepLink(Uri uri, BuildContext context) {
    print('Received deep link: $uri');
    
    // Check if it's a goodpack://product/{id} link (custom scheme)
    if (uri.scheme == 'goodpack' && uri.host == 'product') {
      final productId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      
      if (productId != null) {
        _navigateToProduct(context, productId);
      }
    }
    
    // Check if it's a web URL link
    if (uri.scheme == 'https' && uri.host == EnvConfig.qrDomain && uri.pathSegments.length >= 2) {
      if (uri.pathSegments[0] == 'product') {
        final productId = uri.pathSegments[1];
        _navigateToProduct(context, productId);
      }
    }
  }

  // Navigate to product detail screen
  void _navigateToProduct(BuildContext context, String productId) {
    // Wait for the current frame to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: productId),
          ),
        );
      }
    });
  }

  // Generate deep link URL
  String generateProductLink(String productId) {
    return '${EnvConfig.deepLinkUrl}/$productId';
  }

  // Dispose
  void dispose() {
    _linkSubscription?.cancel();
  }
}
