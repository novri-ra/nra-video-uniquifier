import 'package:flutter/material.dart';

/// Central color tokens for dark and light themes.
class AppColors {
  // Editorial Architecture Tokens (Sprint 89)
  static const Color forestDeep = Color(0xFF0E5535);      // Deep Forest Emerald (Hero Light, Accent Kontras Tinggi)
  static const Color mintSage = Color(0xFFA3EFD5);        // Soft Mint Sage (Status Active / Glow Halus Dark)
  static const Color skyPastel = Color(0xFF7DDCF0);       // Sky Cyan Pastel (Secondary Data)
  static const Color butterYellow = Color(0xFFFFE98C);    // Cream Butter Yellow (Warm Highlight)
  static const Color persimmonOrange = Color(0xFFFF8E3E); // Warm Persimmon (CTA Secondary)
  static const Color obsidianBase = Color(0xFF111817);    // Dark Obsidian Deep Canvas
  static const Color obsidianDark = Color(0xFF1A2523);    // Dark Obsidian Surface Card
  static const Color mustardOchre = Color(0xFFC2A500);    // Vintage Mustard Ochre (Storage / Warning)
  static const Color electricIce = Color(0xFF7BD6F3);     // Electric Ice Blue (CFR 60 Engine)
  static const Color peachCream = Color(0xFFFEC7A0);      // Soft Peach (Pipeline Queue Container)
  static const Color vividCoral = Color(0xFFFF4431);      // Vivid Coral (High-Impact Action)

  // Dark Palette (Obsidian Editorial & Container terangkat)
  static const Color surface = Color(0xFF1A2523);
  static const Color surfaceContainerLowest = Color(0xFF111817);
  static const Color surfaceContainerLow = Color(0xFF1A2523);
  static const Color surfaceContainer = Color(0xFF22302D);
  static const Color surfaceContainerHigh = Color(0xFF2D3E3A);
  static const Color surfaceContainerHighest = Color(0xFF3B4E4A);

  // Mint / Emerald Accents
  static const Color primary = Color(0xFFA3EFD5);
  static const Color onPrimary = Color(0xFF003824);
  static const Color primaryContainer = Color(0xFF0E5535);
  static const Color onPrimaryContainer = Color(0xFFA3EFD5);
  static const Color secondary = Color(0xFF4DFFB2);
  static const Color onSecondary = Color(0xFF003822);

  // Dark Text & Outlines
  static const Color onSurface = Color(0xFFF2F6F4);
  static const Color onSurfaceVariant = Color(0xFFB9CBBF);
  static const Color outline = Color(0xFF84958A);
  static const Color outlineVariant = Color(0x1FA3EFD5);

  // Controlled Neutrals (Official)
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhiteCanvas = Color(0xFFF4F7F5);
  static const Color hairlineBorder = Color(0xFFE2ECE7);
  static const Color textDark = Color(0xFF121E1B);
  static const Color textLight = Color(0xFFF2F6F4);

  // Status & Error
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Light Palette Tokens (High Contrast Editorial Sage & Ivory)
  static const Color lightScaffoldBackground = offWhiteCanvas;
  static const Color lightSurface = white;
  static const Color lightSurfaceContainerLowest = white;
  static const Color lightSurfaceContainerLow = offWhiteCanvas;
  static const Color lightSurfaceContainer = Color(0xFFEAF0EC);
  static const Color lightSurfaceContainerHigh = Color(0xFFE2ECE7);
  static const Color lightSurfaceContainerHighest = Color(0xFFD6E3DD);

  static const Color lightPrimary = forestDeep;
  static const Color lightOnPrimary = white;
  static const Color lightPrimaryContainer = forestDeep;
  static const Color lightOnPrimaryContainer = white;
  static const Color lightSecondary = forestDeep;
  static const Color lightOnSecondary = white;

  static const Color lightOnSurface = textDark;
  static const Color lightOnSurfaceVariant = Color(0xFF4B5563);
  static const Color lightOutline = Color(0xFFD1D5DB);
  static const Color lightOutlineVariant = hairlineBorder;
}
