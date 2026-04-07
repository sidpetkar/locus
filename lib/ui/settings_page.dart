import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/calendar_state.dart';
import '../theme/app_theme.dart';
import 'widgets/locus_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _timeAwareness = false;
  final TextEditingController _birthdayController = TextEditingController();

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

  void _showBirthdayOverlay() {
    _birthdayController.clear();
    final colors = context.appColors;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: colors.barrier,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        final c = context.appColors;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: c.inputSurface,
              child: SafeArea(
                child: Column(
                  children: [
                    LocusHeader(
                      leftIcon: const Icon(Icons.close, size: 28),
                      onLeftTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "When were\nyou born?",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  letterSpacing: -2,
                                  color: c.labelPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Used for Momento Mori",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  color: c.labelSecondary,
                                ),
                              ),
                              const SizedBox(height: 40),
                              TextField(
                                controller: _birthdayController,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28,
                                  letterSpacing: -0.5,
                                  color: c.labelPrimary,
                                ),
                                keyboardType: TextInputType.datetime,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[\d/\-\.]')),
                                ],
                                decoration: InputDecoration(
                                  hintText: "DD/MM/YYYY",
                                  hintStyle: GoogleFonts.spaceGrotesk(
                                    color: c.labelTertiary,
                                    fontSize: 28,
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: c.labelPrimary),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: c.labelPrimary, width: 2),
                                  ),
                                ),
                                autofocus: true,
                              ),
                              const SizedBox(height: 28),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.labelPrimary,
                                    foregroundColor: c.background,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    final text = _birthdayController.text.trim();
                                    final parsed = _parseBirthday(text);
                                    if (parsed != null) {
                                      final provider = Provider.of<CalendarStateProvider>(context, listen: false);
                                      provider.setBirthday(parsed);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Text(
                                    "Save",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  void _showAppearanceOverlay() {
    final colors = context.appColors;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: colors.barrier,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        final c = context.appColors;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: c.inputSurface,
              child: SafeArea(
                child: Column(
                  children: [
                    LocusHeader(
                      leftIcon: const Icon(Icons.close, size: 28),
                      onLeftTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Appearance",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                  letterSpacing: -2,
                                  color: c.labelPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Choose your preferred look",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  color: c.labelSecondary,
                                ),
                              ),
                              const SizedBox(height: 40),
                              Consumer<CalendarStateProvider>(
                                builder: (ctx, provider, _) {
                                  final cc = ctx.appColors;
                                  return Column(
                                    children: [
                                      _AppearanceOption(
                                        label: "System Default",
                                        isSelected: provider.themeMode == ThemeMode.system,
                                        colors: cc,
                                        onTap: () {
                                          provider.setThemeMode(ThemeMode.system);
                                          Navigator.of(ctx).pop();
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _AppearanceOption(
                                        label: "Light",
                                        isSelected: provider.themeMode == ThemeMode.light,
                                        colors: cc,
                                        onTap: () {
                                          provider.setThemeMode(ThemeMode.light);
                                          Navigator.of(ctx).pop();
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _AppearanceOption(
                                        label: "Dark",
                                        isSelected: provider.themeMode == ThemeMode.dark,
                                        colors: cc,
                                        onTap: () {
                                          provider.setThemeMode(ThemeMode.dark);
                                          Navigator.of(ctx).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Parses common date formats: DD/MM/YYYY, DD-MM-YYYY, D/M/YY, D/M/YYYY
  DateTime? _parseBirthday(String text) {
    if (text.isEmpty) return null;
    final separators = RegExp(r'[/\-\.]');
    final parts = text.split(separators);
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    int? year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 1900;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  String _formatBirthday(DateTime date) {
    return "${date.day}-${date.month}-${date.year % 100}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarStateProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = provider.currentUser;
    final colors = context.appColors;

    String appearanceLabel;
    switch (provider.themeMode) {
      case ThemeMode.light:
        appearanceLabel = 'Light';
        break;
      case ThemeMode.dark:
        appearanceLabel = 'Dark';
        break;
      default:
        appearanceLabel = 'System';
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LocusHeader(
              leftIcon: const Icon(Icons.arrow_back, size: 28),
              onLeftTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Settings",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colors.labelPrimary,
                        height: 1.1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Profile row
                    if (user != null)
                      _buildRow(
                        colors: colors,
                        leading: CircleAvatar(
                          radius: 11,
                          backgroundColor: colors.surfaceVariant,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? Icon(Icons.person, size: 14, color: colors.labelSecondary)
                              : null,
                        ),
                        title: user.displayName ?? "User",
                        subtitle: user.email ?? "",
                      ),
                    const SizedBox(height: 12),

                    // Appearance row
                    _buildRow(
                      colors: colors,
                      leading: Icon(Icons.brightness_6_outlined, size: 22, color: colors.icon),
                      title: "Appearance",
                      subtitle: appearanceLabel,
                      onTap: _showAppearanceOverlay,
                      trailing: Icon(Icons.chevron_right, size: 20, color: colors.divider.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 12),

                    // Birthday row
                    _buildRow(
                      colors: colors,
                      leading: Icon(Icons.calendar_today_outlined, size: 22, color: colors.icon),
                      title: "Birthday",
                      subtitle: provider.birthday != null ? _formatBirthday(provider.birthday!) : "Not set",
                      onTap: _showBirthdayOverlay,
                      trailing: Icon(Icons.chevron_right, size: 20, color: colors.divider.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 12),

                    // Time Awareness row
                    _buildRow(
                      colors: colors,
                      leading: Icon(Icons.hourglass_bottom_rounded, size: 22, color: colors.icon),
                      title: "Time Awareness",
                      subtitle: "Momento Mori reminders",
                      trailing: SizedBox(
                        width: 44,
                        height: 28,
                        child: Switch(
                          value: _timeAwareness,
                          onChanged: (val) => setState(() => _timeAwareness = val),
                          activeColor: colors.background,
                          activeTrackColor: colors.labelPrimary,
                          inactiveThumbColor: colors.labelSecondary,
                          inactiveTrackColor: Colors.transparent,
                          trackOutlineColor: WidgetStateProperty.all(colors.labelPrimary),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Sign out stuck at bottom
                    if (user != null)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: Text(
                            "Sign Out",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300, width: 1.5),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required AppColorTokens colors,
    required Widget leading,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.labelPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: colors.labelSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: content,
      );
    }
    return content;
  }
}

// ---------------------------------------------------------------------------
// Appearance option tile
// ---------------------------------------------------------------------------
class _AppearanceOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AppColorTokens colors;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colors.labelPrimary : colors.labelSecondary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 22, color: colors.labelPrimary),
          ],
        ),
      ),
    );
  }
}
