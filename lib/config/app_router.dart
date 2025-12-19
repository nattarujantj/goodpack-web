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
      // Main route with sidebar navigation - includes all pages
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ProductListScreen(),
          ),
          // Product detail route
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
          // Product form route
          GoRoute(
            path: '/product-form',
            builder: (context, state) {
              final productId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return ProductFormScreen(
                productId: productId,
                duplicateId: duplicateId,
              );
            },
          ),
          // Customer routes
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          // Customer detail route
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
          GoRoute(
            path: '/customer-form',
            builder: (context, state) {
              final customerId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return CustomerFormScreen(
                customerId: customerId,
                duplicateId: duplicateId,
              );
            },
          ),
          // Purchase routes
          GoRoute(
            path: '/purchases',
            builder: (context, state) {
              final vatParam = state.uri.queryParameters['vat'];
              String? vatFilter;
              if (vatParam == 'true') {
                vatFilter = 'VAT';
              } else if (vatParam == 'false') {
                vatFilter = 'Non-VAT';
              }
              return PurchaseListScreen(initialVatFilter: vatFilter);
            },
          ),
          // Purchase detail route
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
          GoRoute(
            path: '/purchase-form',
            builder: (context, state) {
              final purchaseId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return PurchaseFormScreen(
                purchaseId: purchaseId,
                duplicateId: duplicateId,
              );
            },
          ),
          // Sale routes
          GoRoute(
            path: '/sales',
            builder: (context, state) {
              final vatParam = state.uri.queryParameters['vat'];
              String? vatFilter;
              if (vatParam == 'true') {
                vatFilter = 'VAT';
              } else if (vatParam == 'false') {
                vatFilter = 'Non-VAT';
              }
              return SaleListScreen(initialVatFilter: vatFilter);
            },
          ),
          // Sale detail route
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
          GoRoute(
            path: '/sale-form',
            builder: (context, state) {
              final saleId = state.uri.queryParameters['id'];
              final quotationId = state.uri.queryParameters['quotationId'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return SaleFormScreen(
                saleId: saleId,
                quotationId: quotationId,
                duplicateId: duplicateId,
              );
            },
          ),
          // Quotation routes
          GoRoute(
            path: '/quotations',
            builder: (context, state) {
              final vatParam = state.uri.queryParameters['vat'];
              String? vatFilter;
              if (vatParam == 'true') {
                vatFilter = 'VAT';
              } else if (vatParam == 'false') {
                vatFilter = 'Non-VAT';
              }
              return QuotationListScreen(initialVatFilter: vatFilter);
            },
          ),
          // Quotation detail route
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
          GoRoute(
            path: '/quotation-form',
            builder: (context, state) {
              final quotationId = state.uri.queryParameters['id'];
              final duplicateId = state.uri.queryParameters['duplicateId'];
              return QuotationFormScreen(
                quotationId: quotationId,
                duplicateId: duplicateId,
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
