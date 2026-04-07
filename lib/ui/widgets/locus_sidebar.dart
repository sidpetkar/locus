import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/calendar_state.dart';
import '../../theme/app_theme.dart';
import '../login_page.dart';
import '../settings_page.dart';
import '../momento_mori_page.dart';

class LocusSidebar extends StatelessWidget {
  const LocusSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarStateProvider>(context);
    final user = provider.currentUser;
    final colors = context.appColors;

    return Drawer(
      backgroundColor: colors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // App branding
              Row(
                children: [
                  Image.asset('assets/locus-icon.png', width: 32, height: 32),
                  const SizedBox(width: 10),
                  Text(
                    "Locus",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                      color: colors.labelPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // App description
              Text(
                "A social experiment —\nyour life on a calendar.",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  height: 1.4,
                  color: colors.labelTertiary,
                ),
              ),

              if (user == null) ...[
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.labelPrimary,
                      foregroundColor: colors.background,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/google-g-logo.png', width: 20, height: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Sign in with Google",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
                _buildMenuItem(
                  colors: colors,
                  icon: Icons.cloud_download_outlined,
                  label: "Import from Google",
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                _buildMenuItem(
                  colors: colors,
                  icon: Icons.hourglass_bottom_rounded,
                  label: "Momento Mori",
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MomentoMoriPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  colors: colors,
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required AppColorTokens colors,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.labelPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.divider),
          ],
        ),
      ),
    );
  }
}
