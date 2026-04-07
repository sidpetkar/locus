import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Semantic color tokens — one value for light mode, one for dark mode.
// Access via: context.appColors.xxx
// ---------------------------------------------------------------------------
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.icon,
    required this.divider,
    required this.barrier,
    required this.inputSurface,
    required this.dotFilled,
    required this.dotEmpty,
    required this.carouselDotInactive,
    required this.accent,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;

  // Text hierarchy
  final Color labelPrimary;    // bold heading / primary content
  final Color labelSecondary;  // thin / muted secondary text (year, subtitles)
  final Color labelTertiary;   // dimmed hints, placeholders

  // Icons
  final Color icon;

  // Separators & borders
  final Color divider;

  // Modal scrim
  final Color barrier;

  // Blur-dialog background tint (semi-transparent)
  final Color inputSurface;

  // Memento Mori dots
  final Color dotFilled;
  final Color dotEmpty;

  // Carousel page indicator inactive dot
  final Color carouselDotInactive;

  // Accent (deepPurple for audio — unchanged in both modes)
  final Color accent;

  // ---- ThemeExtension boilerplate -----------------------------------------

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? labelPrimary,
    Color? labelSecondary,
    Color? labelTertiary,
    Color? icon,
    Color? divider,
    Color? barrier,
    Color? inputSurface,
    Color? dotFilled,
    Color? dotEmpty,
    Color? carouselDotInactive,
    Color? accent,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      labelPrimary: labelPrimary ?? this.labelPrimary,
      labelSecondary: labelSecondary ?? this.labelSecondary,
      labelTertiary: labelTertiary ?? this.labelTertiary,
      icon: icon ?? this.icon,
      divider: divider ?? this.divider,
      barrier: barrier ?? this.barrier,
      inputSurface: inputSurface ?? this.inputSurface,
      dotFilled: dotFilled ?? this.dotFilled,
      dotEmpty: dotEmpty ?? this.dotEmpty,
      carouselDotInactive: carouselDotInactive ?? this.carouselDotInactive,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppColorTokens lerp(AppColorTokens? other, double t) {
    if (other == null) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      labelPrimary: Color.lerp(labelPrimary, other.labelPrimary, t)!,
      labelSecondary: Color.lerp(labelSecondary, other.labelSecondary, t)!,
      labelTertiary: Color.lerp(labelTertiary, other.labelTertiary, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      barrier: Color.lerp(barrier, other.barrier, t)!,
      inputSurface: Color.lerp(inputSurface, other.inputSurface, t)!,
      dotFilled: Color.lerp(dotFilled, other.dotFilled, t)!,
      dotEmpty: Color.lerp(dotEmpty, other.dotEmpty, t)!,
      carouselDotInactive:
          Color.lerp(carouselDotInactive, other.carouselDotInactive, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// Token definitions
// ---------------------------------------------------------------------------
const _lightTokens = AppColorTokens(
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  surfaceVariant: Color(0xFFF3F3F3),       // grey.shade100 ≈
  labelPrimary: Color(0xDE000000),          // Colors.black87
  labelSecondary: Color(0x8A000000),        // Colors.black54
  labelTertiary: Color(0x61000000),         // Colors.black38
  icon: Color(0xDE000000),                  // Colors.black87
  divider: Color(0x1F000000),               // Colors.black12
  barrier: Color(0x26000000),               // black ~15%
  inputSurface: Color(0x1AFFFFFF),          // white ~10%
  dotFilled: Color(0xDE000000),             // Colors.black87
  dotEmpty: Color(0x1F000000),              // Colors.black12
  carouselDotInactive: Color(0xFFBDBDBD),  // grey.shade400-ish
  accent: Color(0xFF673AB7),               // Colors.deepPurple
);

const _darkTokens = AppColorTokens(
  background: Color(0xFF0D0D0D),
  surface: Color(0xFF1A1A1A),
  surfaceVariant: Color(0xFF262626),
  labelPrimary: Color(0xFFFFFFFF),          // white
  labelSecondary: Color(0x99FFFFFF),        // white ~60%
  labelTertiary: Color(0x61FFFFFF),         // white ~38%
  icon: Color(0xFFFFFFFF),                  // white
  divider: Color(0x1FFFFFFF),               // white ~12%
  barrier: Color(0x8C000000),               // black ~55%
  inputSurface: Color(0x0DFFFFFF),          // white ~5%
  dotFilled: Color(0xFFFFFFFF),             // white
  dotEmpty: Color(0x1FFFFFFF),              // white ~12%
  carouselDotInactive: Color(0x3DFFFFFF),  // white ~24%
  accent: Color(0xFFB39DDB),               // deepPurple.shade200 (softer on dark)
);

// ---------------------------------------------------------------------------
// AppTheme — builds full ThemeData for light and dark
// ---------------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        tokens: _lightTokens,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        tokens: _darkTokens,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppColorTokens tokens,
  }) {
    final base = brightness == Brightness.light
        ? ThemeData.light(useMaterial3: false)
        : ThemeData.dark(useMaterial3: false);

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: tokens.background,
      drawerTheme: DrawerThemeData(backgroundColor: tokens.surface),
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        surface: tokens.surface,
        onSurface: tokens.labelPrimary,
      ),
      iconTheme: IconThemeData(color: tokens.icon),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: tokens.labelPrimary,
        displayColor: tokens.labelPrimary,
      ),
      extensions: [tokens],
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience accessor
// ---------------------------------------------------------------------------
extension AppColorsX on BuildContext {
  AppColorTokens get appColors =>
      Theme.of(this).extension<AppColorTokens>()!;
}
