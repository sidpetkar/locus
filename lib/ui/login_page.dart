import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/calendar_state.dart';
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
      // Success - navigate back
      Navigator.of(context).pop();
    } else {
      // Show error
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon
                    Image.asset(
                      'assets/locus-icon.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 48),
                    
                    // Welcome text
                    Text(
                      "Welcome to",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        color: Colors.black54,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      "Locus",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 64),
                    
                    // Google Sign In button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: Text(
                                      'G',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF4285F4),
                                        height: 1.1,
                                      ),
                                    ),
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
                    
                    // Terms and Privacy
                    Text.rich(
                      TextSpan(
                        text: "By signing in, you agree to our\n",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: Colors.black87,
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
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: Colors.black87,
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
