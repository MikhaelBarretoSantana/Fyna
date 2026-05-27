import 'package:flutter/material.dart';

/// Inferência de ícone + tom de badge a partir do nome da categoria.
///
/// Centraliza a heurística que estava duplicada em 4 telas (home tile,
/// transações, classificação IA, picker de categorias). Quando `categoryEntity`
/// tiver `icon` e `color` próprios no futuro, dá pra estendê-los aqui.
({IconData icon, String tone}) iconAndToneForCategory(String? name) {
  final n = (name ?? '').toLowerCase();

  // Despesas frequentes
  if (n.contains('delivery') || n.contains('ifood')) {
    return (icon: Icons.delivery_dining_rounded, tone: 'food');
  }
  if (n.contains('mercado') || n.contains('supermerc')) {
    return (icon: Icons.shopping_cart_rounded, tone: 'shopping');
  }
  if (n.contains('aliment') || n.contains('restaur') || n.contains('comida')) {
    return (icon: Icons.restaurant_rounded, tone: 'food');
  }
  if (n.contains('transp') || n.contains('uber') || n.contains('99')) {
    return (icon: Icons.directions_car_rounded, tone: 'transport');
  }
  if (n.contains('combust') || n.contains('gasolina') || n.contains('posto')) {
    return (icon: Icons.local_gas_station_rounded, tone: 'transport');
  }
  if (n.contains('lazer') || n.contains('entret') || n.contains('streaming')) {
    return (icon: Icons.sports_esports_rounded, tone: 'entertainment');
  }
  if (n.contains('saúde') || n.contains('saude') || n.contains('médic') ||
      n.contains('farmacia') || n.contains('farmácia')) {
    return (icon: Icons.medical_services_rounded, tone: 'health');
  }
  if (n.contains('contas') || n.contains('luz') || n.contains('água') ||
      n.contains('agua') || n.contains('internet')) {
    return (icon: Icons.receipt_long_rounded, tone: 'bills');
  }
  if (n.contains('aluguel') || n.contains('moradia') || n.contains('casa') ||
      n.contains('condomín')) {
    return (icon: Icons.home_rounded, tone: 'bills');
  }
  if (n.contains('educa') || n.contains('curso') || n.contains('escola')) {
    return (icon: Icons.school_rounded, tone: 'info');
  }
  if (n.contains('viagem') || n.contains('viagens') || n.contains('hotel')) {
    return (icon: Icons.flight_rounded, tone: 'transport');
  }
  if (n.contains('compras') || n.contains('shopping')) {
    return (icon: Icons.shopping_bag_rounded, tone: 'shopping');
  }
  if (n.contains('pet') || n.contains('animal')) {
    return (icon: Icons.pets_rounded, tone: 'food');
  }
  if (n.contains('beleza') || n.contains('cabelo') || n.contains('estética')) {
    return (icon: Icons.spa_rounded, tone: 'entertainment');
  }
  if (n.contains('presente') || n.contains('gift')) {
    return (icon: Icons.card_giftcard_rounded, tone: 'entertainment');
  }
  if (n.contains('imposto') || n.contains('taxas') || n.contains('multa')) {
    return (icon: Icons.gavel_rounded, tone: 'warning');
  }

  // Receitas frequentes
  if (n.contains('salár') || n.contains('salario') || n.contains('salary')) {
    return (icon: Icons.flash_on_rounded, tone: 'salary');
  }
  if (n.contains('freelance') || n.contains('autônom')) {
    return (icon: Icons.work_outline_rounded, tone: 'success');
  }
  if (n.contains('investi') || n.contains('rendim') || n.contains('dividendo')) {
    return (icon: Icons.trending_up_rounded, tone: 'success');
  }
  if (n.contains('venda') || n.contains('reemb')) {
    return (icon: Icons.attach_money_rounded, tone: 'success');
  }
  if (n.contains('aluguel recebido')) {
    return (icon: Icons.apartment_rounded, tone: 'success');
  }

  // Transferência
  if (n.contains('transfer')) {
    return (icon: Icons.swap_horiz_rounded, tone: 'transfer');
  }

  // Fallback
  return (icon: Icons.label_rounded, tone: 'neutral');
}

/// Converte hex (#RRGGBB) → Color, com fallback seguro.
Color? colorFromCategoryHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}
