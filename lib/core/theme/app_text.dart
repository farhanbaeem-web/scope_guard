import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized typography tokens.
/// Designed for premium SaaS UI across all platforms.
class AppText {
  // Display / Hero text (rare use)
  static TextStyle h1(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineLarge!
      .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4);

  // Main page titles
  static TextStyle h2(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineMedium!
      .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3);

  // Section headers
  static TextStyle h3(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700);

  // Card / row titles
  static TextStyle title(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600);

  // Subtitles / metadata
  static TextStyle subtitle(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(color: AppColors.subtext, fontWeight: FontWeight.w500);

  // Body text
  static TextStyle body(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium!.copyWith(color: AppColors.text, height: 1.4);

  static TextStyle bodyMuted(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium!.copyWith(color: AppColors.subtext, height: 1.4);

  // Small text (timestamps, hints)
  static TextStyle small(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall!
      .copyWith(color: AppColors.subtext, fontWeight: FontWeight.w500);

  // Labels / buttons
  static TextStyle label(BuildContext context) => Theme.of(context)
      .textTheme
      .labelLarge!
      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2);

  // Chips / badges
  static TextStyle chip(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6);
}
