import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/main_screen.dart';
import '../screens/login_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/customer_list_screen.dart';
import '../screens/customer_detail_screen.dart';
import '../screens/customer_form_screen.dart';
import '../screens/supplier_list_screen.dart';
import '../screens/supplier_detail_screen.dart';
import '../screens/supplier_form_screen.dart';
import '../screens/purchase_list_screen.dart';
import '../screens/purchase_form_screen.dart';
import '../screens/purchase_detail_screen.dart';
import '../screens/sale_list_screen.dart';
import '../screens/sale_form_screen.dart';
import '../screens/sale_detail_screen.dart';
import '../screens/quotation_list_screen.dart';
import '../screens/quotation_detail_screen.dart';
import '../screens/quotation_form_screen.dart';
import '../screens/export_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/expense_list_screen.dart';
import '../screens/expense_form_screen.dart';
import '../screens/international_import_list_screen.dart';
import '../screens/international_import_detail_screen.dart';
import '../screens/international_import_form_screen.dart';
import '../screens/user_management_screen.dart';

class AppRouter {
  static Page<void> _noAnimationPage(Widget child, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isInitialized = authProvider.isInitialized;
        final isLoginPage = state.matchedLocation == '/login';

        if (!isInitialized) return null;
        if (!isLoggedIn && !isLoginPage) return '/login';
        if (isLoggedIn && isLoginPage) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => _noAnimationPage(
            const LoginScreen(),
            state,
          ),
        ),
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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                      ),
                    ),
                    body: ProductDetailScreen(productId: productId),
                  ),
                  state,
                );
              },
            ),
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
            GoRoute(
              path: '/customers',
              pageBuilder: (context, state) => _noAnimationPage(
                const CustomerListScreen(),
                state,
              ),
            ),
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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/customers');
                          }
                        },
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
            GoRoute(
              path: '/suppliers',
              pageBuilder: (context, state) => _noAnimationPage(
                const SupplierListScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/supplier/:id',
              pageBuilder: (context, state) {
                final supplierId = state.pathParameters['id']!;
                return _noAnimationPage(
                  Scaffold(
                    appBar: AppBar(
                      title: const Text('รายละเอียดซัพพลายเออร์'),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/suppliers');
                          }
                        },
                      ),
                    ),
                    body: SupplierDetailScreen(supplierId: supplierId),
                  ),
                  state,
                );
              },
            ),
            GoRoute(
              path: '/supplier-form',
              pageBuilder: (context, state) {
                final supplierId = state.uri.queryParameters['id'];
                final duplicateId = state.uri.queryParameters['duplicateId'];
                return _noAnimationPage(
                  SupplierFormScreen(
                    supplierId: supplierId,
                    duplicateId: duplicateId,
                  ),
                  state,
                );
              },
            ),
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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/purchases');
                          }
                        },
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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/sales');
                          }
                        },
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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/quotations');
                          }
                        },
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
            GoRoute(
              path: '/expenses',
              pageBuilder: (context, state) => _noAnimationPage(
                const ExpenseListScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/expense-form',
              pageBuilder: (context, state) {
                final expenseId = state.uri.queryParameters['id'];
                return _noAnimationPage(
                  ExpenseFormScreen(expenseId: expenseId),
                  state,
                );
              },
            ),
            GoRoute(
              path: '/export',
              pageBuilder: (context, state) => _noAnimationPage(
                const ExportScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => _noAnimationPage(
                const DashboardScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/internationals',
              pageBuilder: (context, state) => _noAnimationPage(
                const InternationalImportListScreen(),
                state,
              ),
            ),
            GoRoute(
              path: '/international/:id',
              pageBuilder: (context, state) {
                final importId = state.pathParameters['id']!;
                return _noAnimationPage(
                  InternationalImportDetailScreen(importId: importId),
                  state,
                );
              },
            ),
            GoRoute(
              path: '/international-form',
              pageBuilder: (context, state) {
                final importId = state.uri.queryParameters['id'];
                return _noAnimationPage(
                  InternationalImportFormScreen(importId: importId),
                  state,
                );
              },
            ),
            GoRoute(
              path: '/users',
              pageBuilder: (context, state) => _noAnimationPage(
                const UserManagementScreen(),
                state,
              ),
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
  }
}
