import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final authService = AuthService();
    final result = await authService.signInWithGoogle();

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign in failed. Please try again.',
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: colors.icon, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/locus-icon.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      "Welcome to",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        color: colors.labelSecondary,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      "Locus",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: colors.labelPrimary,
                        height: 1.1,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Save your memories,\none day at a time",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        color: colors.labelSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 64),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.labelPrimary,
                          foregroundColor: colors.background,
                          disabledBackgroundColor: colors.surfaceVariant,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(colors.background),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/google-g-logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Sign in with Google",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text.rich(
                      TextSpan(
                        text: "By signing in, you agree to our\n",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: colors.labelSecondary,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: colors.labelPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TermsOfServicePage(),
                                  ),
                                );
                              },
                          ),
                          TextSpan(
                            text: " and ",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: colors.labelSecondary,
                            ),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: colors.labelPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
