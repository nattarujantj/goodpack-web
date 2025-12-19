import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/customer_list_screen.dart';
import '../screens/customer_detail_screen.dart';
import '../screens/customer_form_screen.dart';
import '../screens/purchase_list_screen.dart';
import '../screens/purchase_form_screen.dart';
import '../screens/purchase_detail_screen.dart';
import '../screens/sale_list_screen.dart';
import '../screens/sale_form_screen.dart';
import '../screens/sale_detail_screen.dart';
import '../screens/quotation_list_screen.dart';
import '../screens/quotation_detail_screen.dart';
import '../screens/quotation_form_screen.dart';

class AppRouter {
  // Helper function to build page with no animation
  static Page<void> _noAnimationPage(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static final GoRouter _router = GoRouter(
    routes: [
      // Main route with sidebar navigation - includes all pages
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _noAnimationPage(
              const ProductListScreen(),
              state,
            ),
          ),
          // Product detail route
          GoRoute(
            path: '/product/:id',
            pageBuilder: (context, state) {
              final productId = state.pathParameters['id']!;
              return _noAnimationPage(
                Scaffold(
                  appBar: AppBar(
                    title: const Text('รายละเอียดสินค้า'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/'),
                    ),
                  ),
                  body: ProductDetailScreen(productId: productId),
                ),
                state,
              );
            },
          ),
          // Product form route
          GoRoute(
            path: '/product-form',
            pageBuilder: (context, state) {
              final productId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return _noAnimationPage(
                ProductFormScreen(
                  productId: productId,
                  duplicateId: duplicateId,
                ),
                state,
              );
            },
          ),
          // Customer routes
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => _noAnimationPage(
              const CustomerListScreen(),
              state,
            ),
          ),
          // Customer detail route
          GoRoute(
            path: '/customer/:id',
            pageBuilder: (context, state) {
              final customerId = state.pathParameters['id']!;
              return _noAnimationPage(
                Scaffold(
                  appBar: AppBar(
                    title: const Text('รายละเอียดลูกค้า'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/customers'),
                    ),
                  ),
                  body: CustomerDetailScreen(customerId: customerId),
                ),
                state,
              );
            },
          ),
          GoRoute(
            path: '/customer-form',
            pageBuilder: (context, state) {
              final customerId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return _noAnimationPage(
                CustomerFormScreen(
                  customerId: customerId,
                  duplicateId: duplicateId,
                ),
                state,
              );
            },
          ),
          // Purchase routes
          GoRoute(
            path: '/purchases',
            pageBuilder: (context, state) {
              final vatParam = state.uri.queryParameters['vat'];
              String? vatFilter;
              if (vatParam == 'true') {
                vatFilter = 'VAT';
              } else if (vatParam == 'false') {
                vatFilter = 'Non-VAT';
              }
              return _noAnimationPage(
                PurchaseListScreen(initialVatFilter: vatFilter),
                state,
              );
            },
          ),
          // Purchase detail route
          GoRoute(
            path: '/purchase/:id',
            pageBuilder: (context, state) {
              final purchaseId = state.pathParameters['id']!;
              return _noAnimationPage(
                Scaffold(
                  appBar: AppBar(
                    title: const Text('รายละเอียดการซื้อ'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/purchases'),
                    ),
                  ),
                  body: PurchaseDetailScreen(purchaseId: purchaseId),
                ),
                state,
              );
            },
          ),
          GoRoute(
            path: '/purchase-form',
            pageBuilder: (context, state) {
              final purchaseId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return _noAnimationPage(
                PurchaseFormScreen(
                  purchaseId: purchaseId,
                  duplicateId: duplicateId,
                ),
                state,
              );
            },
          ),
          // Sale routes
          GoRoute(
            path: '/sales',
            pageBuilder: (context, state) {
              final vatParam = state.uri.queryParameters['vat'];
              String? vatFilter;
              if (vatParam == 'true') {
                vatFilter = 'VAT';
              } else if (vatParam == 'false') {
                vatFilter = 'Non-VAT';
              }
              return _noAnimationPage(
                SaleListScreen(initialVatFilter: vatFilter),
                state,
              );
            },
          ),
          // Sale detail route
          GoRoute(
            path: '/sale/:id',
            pageBuilder: (context, state) {
              final saleId = state.pathParameters['id']!;
              return _noAnimationPage(
                Scaffold(
                  appBar: AppBar(
                    title: const Text('รายละเอียดการขาย'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/sales'),
                    ),
                  ),
                  body: SaleDetailScreen(saleId: saleId),
                ),
                state,
              );
            },
          ),
          GoRoute(
            path: '/sale-form',
            pageBuilder: (context, state) {
              final saleId = state.uri.queryParameters['id'];
              final quotationId = state.uri.queryParameters['quotationId'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return _noAnimationPage(
                SaleFormScreen(
                  saleId: saleId,
                  quotationId: quotationId,
                  duplicateId: duplicateId,
                ),
                state,
              );
            },
          ),
          // Quotation routes
          GoRoute(
            path: '/quotations',
            pageBuilder: (context, state) {
              final vatParam = state.uri.queryParameters['vat'];
              String? vatFilter;
              if (vatParam == 'true') {
                vatFilter = 'VAT';
              } else if (vatParam == 'false') {
                vatFilter = 'Non-VAT';
              }
              return _noAnimationPage(
                QuotationListScreen(initialVatFilter: vatFilter),
                state,
              );
            },
          ),
          // Quotation detail route
          GoRoute(
            path: '/quotation/:id',
            pageBuilder: (context, state) {
              final quotationId = state.pathParameters['id']!;
              return _noAnimationPage(
                Scaffold(
                  appBar: AppBar(
                    title: const Text('รายละเอียดเสนอราคา'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/quotations'),
                    ),
                  ),
                  body: QuotationDetailScreen(quotationId: quotationId),
                ),
                state,
              );
            },
          ),
          GoRoute(
            path: '/quotation-form',
            pageBuilder: (context, state) {
              final quotationId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return _noAnimationPage(
                QuotationFormScreen(
                  quotationId: quotationId,
                  duplicateId: duplicateId,
                ),
                state,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;
}
