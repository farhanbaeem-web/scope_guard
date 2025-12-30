import 'package:flutter/material.dart';

/// Shared navigation item used by drawers, sidebar, and adaptive layout.
class NavItem {
  final String label;
  final IconData icon;

  const NavItem({required this.label, required this.icon});
}
