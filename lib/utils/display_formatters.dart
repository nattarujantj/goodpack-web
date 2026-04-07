import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/product.dart';

String formatCustomerDisplay(Customer customer) {
  final parts = <String>[];

  if (customer.companyName.isNotEmpty) {
    parts.add(customer.companyName);
  } else if (customer.contactName.isNotEmpty) {
    parts.add(customer.contactName);
  }

  if (customer.customerCode.isNotEmpty) {
    parts.add('[${customer.customerCode}]');
  }

  if (customer.companyName.isNotEmpty && customer.contactName.isNotEmpty) {
    parts.add('- ${customer.contactName}');
  }

  if (customer.phone.isNotEmpty) {
    parts.add('(${customer.phone})');
  }

  return parts.join(' ');
}

String formatSupplierDisplay(Supplier supplier) {
  final parts = <String>[];

  if (supplier.companyName.isNotEmpty) {
    parts.add(supplier.companyName);
  } else if (supplier.contactName.isNotEmpty) {
    parts.add(supplier.contactName);
  }

  if (supplier.supplierCode.isNotEmpty) {
    parts.add('[${supplier.supplierCode}]');
  }

  if (supplier.companyName.isNotEmpty && supplier.contactName.isNotEmpty) {
    parts.add('- ${supplier.contactName}');
  }

  if (supplier.phone.isNotEmpty) {
    parts.add('(${supplier.phone})');
  }

  return parts.join(' ');
}

String formatProductDisplay(Product product) {
  return '${product.skuId} | ${product.name} | ${product.description}';
}
