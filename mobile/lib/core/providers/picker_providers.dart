import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feature_providers.dart';
import '../../features/categories/models/category_model.dart';
import '../../features/payment_methods/models/payment_method_model.dart';

final activeCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  return ref.watch(categoryLocalRepositoryProvider).getAll();
});

final activePaymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethodModel>>((ref) {
  return ref.watch(paymentMethodLocalRepositoryProvider).getAll();
});