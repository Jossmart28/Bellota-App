import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/navigation_service.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../l10n/language_notifier.dart';

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
    
    final nextScreen = NavigationService.resolveHomeScreen(prefs);
    NavigationService.goReplace(context, nextScreen);
  }

  @override
  Widget build(BuildContext context) {
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
                    onTalkBackPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: Theme.of(context).bellotaColors.blanco, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'PolÃ­tica de Privacidad',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).bellotaColors.blanco,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ãšltima actualizaciÃ³n: 4 de septiembre de 2026',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
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
                            _buildParagraph('En Bellota, nos tomamos muy en serio tu privacidad. Esta polÃ­tica explica de manera clara y directa cÃ³mo manejamos la informaciÃ³n que recopilamos cuando usas nuestra aplicaciÃ³n. Nos regimos bajo el principio de minimizaciÃ³n de datos: solo solicitamos la informaciÃ³n estrictamente necesaria para que la aplicaciÃ³n funcione y te brinde un servicio seguro y personalizado.'),
                            _buildSectionTitle('1. Datos que Recopilamos y Finalidad'),
                            _buildBulletItem('Correo ElectrÃ³nico', 'Solicitamos tu direcciÃ³n de correo exclusivamente para la creaciÃ³n y gestiÃ³n de tu cuenta, autenticaciÃ³n de seguridad y recuperaciÃ³n de acceso. No compartimos ni vendemos tu correo a terceros para fines publicitarios.'),
                            _buildBulletItem('Datos de UbicaciÃ³n Precisa (GPS)', 'Solicitamos acceso a la ubicaciÃ³n de tu dispositivo Ãºnicamente para identificar y mostrarte en un mapa interactivo las clÃ­nicas, farmacias y centros de salud mÃ¡s cercanos a ti.'),
                            _buildSubBulletItem('Uso de la ubicaciÃ³n', 'La ubicaciÃ³n se procesa Ãºnicamente mientras usas esta funciÃ³n especÃ­fica en la aplicaciÃ³n. No rastreamos tu ubicaciÃ³n en segundo plano ni guardamos un historial de tus desplazamientos.'),
                            _buildSectionTitle('2. Datos de Salud y Ciclo Menstrual'),
                            _buildParagraph('â€¢ Los datos sobre tu ciclo menstrual, sÃ­ntomas o fechas registradas en la aplicaciÃ³n se procesan exclusivamente para brindarte las estimaciones del calendario.\nâ€¢ Priorizamos la privacidad de tus datos de salud: la informaciÃ³n de tu ciclo se almacena localmente en tu dispositivo o de forma cifrada y segura, garantizando que nadie fuera de la aplicaciÃ³n (incluyendo terceros) pueda acceder a tus registros mÃ©dicos o personales.'),
                            _buildSectionTitle('3. ComparticiÃ³n de Datos con Terceros'),
                            _buildParagraph('No vendemos, alquilamos ni comercializamos tus datos personales. Solo compartimos informaciÃ³n en el siguiente caso puntual:'),
                            _buildBulletItem('Proveedores de Mapas', 'Para mostrarte los centros de salud cercanos, la aplicaciÃ³n utiliza servicios de mapas de terceros (como Google Maps o Apple Maps). Estos servicios reciben Ãºnicamente las coordenadas de tu ubicaciÃ³n actual de forma anÃ³nima, exclusivamente para devolver los resultados en el mapa.'),
                            _buildSectionTitle('4. Almacenamiento y Seguridad'),
                            _buildParagraph('Implementamos medidas de seguridad tÃ©cnicas y administrativas avanzadas (como cifrado de datos en trÃ¡nsito y en reposo) para proteger tu correo electrÃ³nico y tu informaciÃ³n registrada contra el acceso no autorizado, pÃ©rdida, alteraciÃ³n o divulgaciÃ³n.'),
                            _buildSectionTitle('5. Tus Derechos'),
                            _buildParagraph('En cualquier momento tienes derecho a:'),
                            _buildBulletItem('Acceder, Corregir o Eliminar', 'Puedes solicitar la eliminaciÃ³n completa de tu cuenta, tus datos de salud y tu correo electrÃ³nico en cualquier momento desde la configuraciÃ³n de la app o enviÃ¡ndonos un mensaje.'),
                            _buildBulletItem('Controlar los Permisos de UbicaciÃ³n', 'Puedes activar o desactivar el permiso de ubicaciÃ³n directamente desde la configuraciÃ³n de tu dispositivo mÃ³vil en cualquier momento (aunque esto impedirÃ¡ buscar clÃ­nicas cercanas automÃ¡ticamente).'),
                            _buildSectionTitle('6. Modificaciones a esta PolÃ­tica'),
                            _buildParagraph('Podemos actualizar esta polÃ­tica ocasionalmente para reflejar mejoras en la aplicaciÃ³n o cambios legales. Te notificaremos de manera destacada sobre cambios significativos antes de que entren en vigor.'),
                            _buildSectionTitle('7. Contacto'),
                            _buildParagraph('Si tienes dudas, comentarios o deseas ejercer tus derechos de privacidad, puedes contactarnos en:'),
                            _buildParagraph('Correo de soporte: usm.unshowmas@gmail.com', isBold: true),
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
                                    'He leÃ­do y acepto la PolÃ­tica de Privacidad de Bellota.',
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
                                    'Continuar',
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
              text: 'â€¢ $title: ',
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
              text: 'â—¦ $title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }
}


