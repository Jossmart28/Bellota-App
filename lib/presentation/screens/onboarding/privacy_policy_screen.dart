import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/presentation/common/bellota_top_actions.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/presentation/screens/onboarding/birth_year_screen.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  Future<void> _continue() async {
    if (!_accepted) return;
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_policy_accepted', true);
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const BirthYearScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final loc = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: Theme.of(context).bellotaColors.chilero,
          body: SafeArea(
            child: Column(
              children: [
                // Top actions (Accessibility / Language)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      BellotaTopActions(
                        showSettings: false,
                        onLanguagePressed: () => languageNotifier.toggle(),
                      ),
                    ],
                  ),
                ),
                
                // Policy Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).bellotaColors.blanco,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header moved here
                                Center(
                                  child: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).bellotaColors.chilero, size: 48),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    loc.privacyPolicyTitle,
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).bellotaColors.chilero,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildParagraph(loc.privacyPolicyIntro),
                                _buildSectionTitle(loc.privacyPolicySec1),
                                _buildBulletItem(loc.privacyPolicyEmailTitle, loc.privacyPolicyEmailBody),
                                _buildBulletItem(loc.privacyPolicyLocationTitle, loc.privacyPolicyLocationBody),
                                _buildSubBulletItem(loc.privacyPolicyLocationUseTitle, loc.privacyPolicyLocationUseBody),
                                _buildSectionTitle(loc.privacyPolicySec2),
                                _buildParagraph(loc.privacyPolicyHealthBody),
                                _buildSectionTitle(loc.privacyPolicySec3),
                                _buildParagraph(loc.privacyPolicyThirdPartyBody),
                                _buildBulletItem(loc.privacyPolicyMapsTitle, loc.privacyPolicyMapsBody),
                                _buildSectionTitle(loc.privacyPolicySec4),
                                _buildParagraph(loc.privacyPolicySecurityBody),
                                _buildSectionTitle(loc.privacyPolicySec5),
                                _buildParagraph(loc.privacyPolicyRightsBody),
                                _buildBulletItem(loc.privacyPolicyDeleteTitle, loc.privacyPolicyDeleteBody),
                                _buildBulletItem(loc.privacyPolicyLocationPermTitle, loc.privacyPolicyLocationPermBody),
                                _buildSectionTitle(loc.privacyPolicySec6),
                                _buildParagraph(loc.privacyPolicyModBody),
                                _buildSectionTitle(loc.privacyPolicySec7),
                                _buildParagraph(loc.privacyPolicyContactBody),
                                _buildParagraph(loc.privacyPolicyEmail, isBold: true),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        
                        // Acceptance Area
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _accepted,
                                    activeColor: Theme.of(context).bellotaColors.chilero,
                                    onChanged: (val) {
                                      setState(() => _accepted = val ?? false);
                                    },
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _accepted = !_accepted);
                                      },
                                      child: Text(
                                        loc.privacyPolicyAcceptText,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _accepted && !_isLoading ? _continue : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).bellotaColors.chilero,
                                    foregroundColor: Theme.of(context).bellotaColors.blanco,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: _isLoading 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        loc.privacyPolicyContinue,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).bellotaColors.chilero,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '• $title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 24),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '◦ $title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }
}



