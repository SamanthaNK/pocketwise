import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

IconData iconForCategory(String? symbolName) {
  switch (symbolName) {
    case 'restaurant':
      return Symbols.restaurant_rounded;
    case 'directions_bus':
      return Symbols.directions_bus_rounded;
    case 'bolt':
      return Symbols.bolt_rounded;
    case 'home':
      return Symbols.home_rounded;
    case 'sim_card':
      return Symbols.sim_card_rounded;
    case 'medical_services':
      return Symbols.medical_services_rounded;
    case 'school':
      return Symbols.school_rounded;
    case 'shopping_bag':
      return Symbols.shopping_bag_rounded;
    case 'celebration':
      return Symbols.celebration_rounded;
    case 'savings':
      return Symbols.savings_rounded;
    case 'payments':
      return Symbols.payments_rounded;
    case 'storefront':
      return Symbols.storefront_rounded;
    case 'redeem':
      return Symbols.redeem_rounded;
    case 'account_balance_wallet':
      return Symbols.account_balance_wallet_rounded;
    default:
      return Symbols.category_rounded;
  }
}
