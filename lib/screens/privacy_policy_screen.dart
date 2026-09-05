import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/navigation_service.dart';
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
      backgroundColor: BellotaColors.chilero,
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
                  Icon(Icons.privacy_tip_outlined, color: BellotaColors.blanco, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Política de Privacidad',
                    style: GoogleFonts.poppins(
                      color: BellotaColors.blanco,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Última actualización: 4 de septiembre de 2026',
                    style: GoogleFonts.poppins(
                      color: BellotaColors.blanco.withValues(alpha: 0.8),
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
                  color: BellotaColors.blanco,
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
                            _buildParagraph('En Bellota, nos tomamos muy en serio tu privacidad. Esta política explica de manera clara y directa cómo manejamos la información que recopilamos cuando usas nuestra aplicación. Nos regimos bajo el principio de minimización de datos: solo solicitamos la información estrictamente necesaria para que la aplicación funcione y te brinde un servicio seguro y personalizado.'),
                            _buildSectionTitle('1. Datos que Recopilamos y Finalidad'),
                            _buildBulletItem('Correo Electrónico', 'Solicitamos tu dirección de correo exclusivamente para la creación y gestión de tu cuenta, autenticación de seguridad y recuperación de acceso. No compartimos ni vendemos tu correo a terceros para fines publicitarios.'),
                            _buildBulletItem('Datos de Ubicación Precisa (GPS)', 'Solicitamos acceso a la ubicación de tu dispositivo únicamente para identificar y mostrarte en un mapa interactivo las clínicas, farmacias y centros de salud más cercanos a ti.'),
                            _buildSubBulletItem('Uso de la ubicación', 'La ubicación se procesa únicamente mientras usas esta función específica en la aplicación. No rastreamos tu ubicación en segundo plano ni guardamos un historial de tus desplazamientos.'),
                            _buildSectionTitle('2. Datos de Salud y Ciclo Menstrual'),
                            _buildParagraph('• Los datos sobre tu ciclo menstrual, síntomas o fechas registradas en la aplicación se procesan exclusivamente para brindarte las estimaciones del calendario.\n• Priorizamos la privacidad de tus datos de salud: la información de tu ciclo se almacena localmente en tu dispositivo o de forma cifrada y segura, garantizando que nadie fuera de la aplicación (incluyendo terceros) pueda acceder a tus registros médicos o personales.'),
                            _buildSectionTitle('3. Compartición de Datos con Terceros'),
                            _buildParagraph('No vendemos, alquilamos ni comercializamos tus datos personales. Solo compartimos información en el siguiente caso puntual:'),
                            _buildBulletItem('Proveedores de Mapas', 'Para mostrarte los centros de salud cercanos, la aplicación utiliza servicios de mapas de terceros (como Google Maps o Apple Maps). Estos servicios reciben únicamente las coordenadas de tu ubicación actual de forma anónima, exclusivamente para devolver los resultados en el mapa.'),
                            _buildSectionTitle('4. Almacenamiento y Seguridad'),
                            _buildParagraph('Implementamos medidas de seguridad técnicas y administrativas avanzadas (como cifrado de datos en tránsito y en reposo) para proteger tu correo electrónico y tu información registrada contra el acceso no autorizado, pérdida, alteración o divulgación.'),
                            _buildSectionTitle('5. Tus Derechos'),
                            _buildParagraph('En cualquier momento tienes derecho a:'),
                            _buildBulletItem('Acceder, Corregir o Eliminar', 'Puedes solicitar la eliminación completa de tu cuenta, tus datos de salud y tu correo electrónico en cualquier momento desde la configuración de la app o enviándonos un mensaje.'),
                            _buildBulletItem('Controlar los Permisos de Ubicación', 'Puedes activar o desactivar el permiso de ubicación directamente desde la configuración de tu dispositivo móvil en cualquier momento (aunque esto impedirá buscar clínicas cercanas automáticamente).'),
                            _buildSectionTitle('6. Modificaciones a esta Política'),
                            _buildParagraph('Podemos actualizar esta política ocasionalmente para reflejar mejoras en la aplicación o cambios legales. Te notificaremos de manera destacada sobre cambios significativos antes de que entren en vigor.'),
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
                                activeColor: BellotaColors.chilero,
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
                                    'He leído y acepto la Política de Privacidad de Bellota.',
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
                                backgroundColor: BellotaColors.chilero,
                                foregroundColor: BellotaColors.blanco,
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
          color: BellotaColors.chilero,
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
