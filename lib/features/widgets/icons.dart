/// The original design names its icons (`cart`, `bread`, `leaf`, …).
/// This maps those names onto the rounded Material set.
library;

import 'package:flutter/material.dart';

const Map<String, IconData> _shopIcons = {
  'cart': Icons.shopping_cart_rounded,
  'bread': Icons.bakery_dining_rounded,
  'leaf': Icons.eco_rounded,
  'milk': Icons.local_drink_rounded,
  'meat': Icons.set_meal_rounded,
  'moon': Icons.nightlight_round,
  'bag': Icons.shopping_bag_rounded,
  'soap': Icons.soap_rounded,
  'store': Icons.storefront_rounded,
};

IconData shopIcon(String key) => _shopIcons[key] ?? Icons.storefront_rounded;

const Map<String, IconData> categoryIcons = {
  'sut': Icons.local_drink_rounded,
  'non': Icons.bakery_dining_rounded,
  'meva-sabzavot': Icons.eco_rounded,
  'gosht': Icons.set_meal_rounded,
  'ichimlik': Icons.local_cafe_rounded,
  'bakaleya': Icons.rice_bowl_rounded,
  'uy-rozgor': Icons.soap_rounded,
};

IconData categoryIcon(String id) =>
    categoryIcons[id] ?? Icons.grid_view_rounded;
