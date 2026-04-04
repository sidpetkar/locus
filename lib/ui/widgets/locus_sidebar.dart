import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'google_sign_in_button.dart';
import '../../services/auth_service.dart';
import '../../state/calendar_state.dart';

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
                    _buildGoogleButton(
                      context: context,
                      label: "Sign in with Google",
                      onPressed: () async {
                        await authService.signInWithGoogle();
                        Navigator.of(context).pop();
                      },
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
                    _buildSidebarItem(Icons.cloud_done_outlined, "Cloud Sync Active"),
                    _buildSidebarItem(Icons.storage_outlined, "Firebase Storage"),
                    const Spacer(),
                    _buildGoogleButton(
                      context: context,
                      label: "Sign out",
                      onPressed: () async {
                        await authService.signOut();
                        Navigator.of(context).pop();
                      },
                      isLogout: true,
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
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton({
    required BuildContext context, // Added context to handle pop
    required String label,
    required VoidCallback onPressed,
    bool isLogout = false,
  }) {
    // For Web, use the native Google Identity Services (GIS) button for "One Tap" experience
    if (kIsWeb && !isLogout) {
      return Center(
        child: SizedBox(
          height: 44, // Google's standard recommended button height
          child: buildGoogleSignInButtonWidget(),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isLogout ? Colors.transparent : Colors.black87,
          foregroundColor: isLogout ? Colors.redAccent : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isLogout ? BorderSide(color: Colors.redAccent.withOpacity(0.3)) : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
