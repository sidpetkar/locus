import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../state/calendar_state.dart';
import '../login_page.dart';
import '../privacy_policy_page.dart';
import '../terms_of_service_page.dart';

class LocusSidebar extends StatelessWidget {
  const LocusSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final provider = Provider.of<CalendarStateProvider>(context);
    final user = provider.currentUser;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.75,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.white.withOpacity(0.8),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // App Branding
                  Text(
                    "Locus",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 60),

                  if (user == null) ...[
                    Text(
                      "Capture your life,\nstored forever.",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        height: 1.2,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    // Privacy & Terms links
                    _buildTappableSidebarItem(
                      Icons.shield_outlined,
                      "Privacy Policy",
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                        );
                      },
                    ),
                    _buildTappableSidebarItem(
                      Icons.description_outlined,
                      "Terms of Service",
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Sign in button - navigates to login page
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        icon: const Icon(Icons.login, size: 20),
                        label: Text(
                          "Sign in with Google",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ] else ...[
                    // User Profile
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: user.photoURL != null 
                              ? NetworkImage(user.photoURL!) 
                              : null,
                          child: user.photoURL == null 
                              ? const Icon(Icons.person, color: Colors.grey) 
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? "User",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (provider.username != null)
                                Text(
                                  'mylocus.life/${provider.username}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                user.email ?? "",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (provider.username != null)
                      _buildSidebarItem(Icons.link_outlined, provider.username!),
                    _buildSidebarItem(Icons.cloud_done_outlined, "Cloud Sync Active"),
                    _buildSidebarItem(Icons.storage_outlined, "Firebase Storage"),
                    const Spacer(),
                    // Privacy & Terms links
                    _buildTappableSidebarItem(
                      Icons.shield_outlined,
                      "Privacy Policy",
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                        );
                      },
                    ),
                    _buildTappableSidebarItem(
                      Icons.description_outlined,
                      "Terms of Service",
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Logout button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade200, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: () async {
                          await authService.signOut();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.logout, size: 20),
                        label: Text(
                          "Sign Out",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableSidebarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
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
