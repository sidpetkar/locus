import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../state/calendar_state.dart';
import '../login_page.dart';
import '../settings_page.dart';

class LocusSidebar extends StatelessWidget {
  const LocusSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final provider = Provider.of<CalendarStateProvider>(context);
    final user = provider.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
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
                      color: Colors.black87,
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
                  color: Colors.black38,
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
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
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
                // Menu items at bottom above sign out
                _buildMenuItem(
                  icon: Icons.cloud_download_outlined,
                  label: "Import from Google",
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.hourglass_bottom_rounded,
                  label: "Momento Mori",
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Sign out
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.logout, size: 18, color: Colors.black54),
                    label: Text(
                      "Sign Out",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                  ),
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
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
