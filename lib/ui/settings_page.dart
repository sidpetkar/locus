import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/calendar_state.dart';
import 'widgets/locus_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _timeAwareness = false;
  String? _birthday;
  final TextEditingController _birthdayController = TextEditingController();

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

  void _showBirthdayOverlay() {
    _birthdayController.clear();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.white.withOpacity(0.1),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black87, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Center(
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
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Used for Momento Mori",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 40),
                            TextField(
                              controller: _birthdayController,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 28,
                                letterSpacing: -0.5,
                              ),
                              keyboardType: TextInputType.datetime,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d/\-\.]')),
                              ],
                              decoration: InputDecoration(
                                hintText: "DD/MM/YYYY",
                                hintStyle: GoogleFonts.spaceGrotesk(
                                  color: Colors.grey.shade400,
                                  fontSize: 28,
                                ),
                                border: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black87),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black87, width: 2),
                                ),
                              ),
                              autofocus: true,
                            ),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  final text = _birthdayController.text.trim();
                                  if (text.isNotEmpty) {
                                    setState(() => _birthday = text);
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarStateProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LocusHeader(
              leftIcon: const Icon(Icons.arrow_back, size: 28, color: Colors.black87),
              onLeftTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Settings" in same style as month header
                    Text(
                      "Settings",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Profile row
                    if (user != null)
                      _buildRow(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(Icons.person, size: 20, color: Colors.grey)
                              : null,
                        ),
                        title: user.displayName ?? "User",
                        subtitle: user.email ?? "",
                      ),
                    const SizedBox(height: 12),

                    // Birthday row
                    _buildRow(
                      leading: const Icon(Icons.calendar_today_outlined, size: 22, color: Colors.black87),
                      title: "Birthday",
                      subtitle: _birthday ?? "Not set",
                      onTap: _showBirthdayOverlay,
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
                    ),
                    const SizedBox(height: 12),

                    // Time Awareness row
                    _buildRow(
                      leading: const Icon(Icons.hourglass_bottom_rounded, size: 22, color: Colors.black87),
                      title: "Time Awareness",
                      subtitle: "Momento Mori reminders",
                      trailing: SizedBox(
                        width: 44,
                        height: 28,
                        child: Switch(
                          value: _timeAwareness,
                          onChanged: (val) => setState(() => _timeAwareness = val),
                          activeColor: Colors.white,
                          activeTrackColor: Colors.black87,
                          inactiveThumbColor: Colors.black54,
                          inactiveTrackColor: Colors.transparent,
                          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                            return Colors.black87;
                          }),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Sign out stuck at bottom
                    if (user != null)
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
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: Colors.black54,
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
