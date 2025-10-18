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
  static final GoRouter _router = GoRouter(
    routes: [
      // Product detail route (outside shell for direct access)
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('รายละเอียดสินค้า'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
            ),
            body: ProductDetailScreen(productId: productId),
          );
        },
      ),
      // Customer detail route (outside shell for direct access)
      GoRoute(
        path: '/customer/:id',
        builder: (context, state) {
          final customerId = state.pathParameters['id']!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('รายละเอียดลูกค้า'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/customers'),
              ),
            ),
            body: CustomerDetailScreen(customerId: customerId),
          );
        },
      ),
      // Purchase detail route (outside shell for direct access)
      GoRoute(
        path: '/purchase/:id',
        builder: (context, state) {
          final purchaseId = state.pathParameters['id']!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('รายละเอียดการซื้อ'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/purchases'),
              ),
            ),
            body: PurchaseDetailScreen(purchaseId: purchaseId),
          );
        },
      ),
      // Sale detail route (outside shell for direct access)
      GoRoute(
        path: '/sale/:id',
        builder: (context, state) {
          final saleId = state.pathParameters['id']!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('รายละเอียดการขาย'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/sales'),
              ),
            ),
            body: SaleDetailScreen(saleId: saleId),
          );
        },
      ),
      // Quotation detail route (outside shell for direct access)
      GoRoute(
        path: '/quotation/:id',
        builder: (context, state) {
          final quotationId = state.pathParameters['id']!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('รายละเอียดเสนอราคา'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/quotations'),
              ),
            ),
            body: QuotationDetailScreen(quotationId: quotationId),
          );
        },
      ),
      // Main route with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ProductListScreen(),
          ),
          // Product form route
          GoRoute(
            path: '/product-form',
            builder: (context, state) {
              final productId = state.uri.queryParameters['id'];
              return ProductFormScreen(
                productId: productId,
              );
            },
          ),
          // Customer routes
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/customer-form',
            builder: (context, state) {
              final customerId = state.uri.queryParameters['id'];
              return CustomerFormScreen(
                customerId: customerId,
              );
            },
          ),
          // Purchase routes
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const PurchaseListScreen(),
          ),
          GoRoute(
            path: '/purchase-form',
            builder: (context, state) {
              final purchaseId = state.uri.queryParameters['id'];
              return PurchaseFormScreen(
                purchaseId: purchaseId,
              );
            },
          ),
          // Sale routes
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SaleListScreen(),
          ),
          GoRoute(
            path: '/sale-form',
            builder: (context, state) {
              final saleId = state.uri.queryParameters['id'];
              final quotationId = state.uri.queryParameters['quotationId'];
              return SaleFormScreen(
                saleId: saleId,
                quotationId: quotationId,
              );
            },
          ),
          // Quotation routes
          GoRoute(
            path: '/quotations',
            builder: (context, state) => const QuotationListScreen(),
          ),
          GoRoute(
            path: '/quotation-form',
            builder: (context, state) {
              final quotationId = state.uri.queryParameters['id'];
              return QuotationFormScreen(
                quotationId: quotationId,
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
