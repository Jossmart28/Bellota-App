import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bellota_colors.dart';
import 'map_screen.dart';

/// Pantalla de detalle de un centro de salud
/// Muestra toda la información del centro con diseño fiel al mockup
class HealthCenterDetailScreen extends StatelessWidget {
  final HealthCenter center;

  const HealthCenterDetailScreen({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE3),
      body: SafeArea(
        child: Column(
          children: [
            // ══════════════════════════════════════
            // BARRA SUPERIOR — Búsqueda + íconos
            // ══════════════════════════════════════
            _buildSearchBar(context),
            // ══════════════════════════════════════
            // CONTENIDO SCROLLABLE
            // ══════════════════════════════════════
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Título del centro
                      Text(
                        center.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: BellotaColors.textoDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Imagen placeholder del centro
                      _buildImagePlaceholder(),
                      const SizedBox(height: 20),
                      // Información detallada
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      // Especialidades
                      _buildSpecialtiesSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────
  // BARRA DE BÚSQUEDA
  // ────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF5EDE3),
      child: Row(
        children: [
          // Botón de regreso
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF3D2B27), size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: BellotaColors.textoMedio, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buscar...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: BellotaColors.textoMedio.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Botón de traducción
          _iconButton(
            child: Text(
              '文A',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BellotaColors.textoDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón de audio/accesibilidad
          _iconButton(
            child: Icon(Icons.volume_up_rounded, color: BellotaColors.textoDark, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required Widget child}) {
    return GestureDetector(
      onTap: () {}, // Sin función por ahora
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  // ────────────────────────────────────────
  // IMAGEN PLACEHOLDER DEL CENTRO
  // ────────────────────────────────────────
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFD35D53), Color(0xFFE8897A)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: BellotaColors.chilero.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Patrón decorativo
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            left: 30,
            bottom: 30,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Ícono central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital_rounded, color: Colors.white.withValues(alpha: 0.9), size: 48),
                const SizedBox(height: 8),
                Text(
                  'Centro de Salud',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────
  // INFORMACIÓN DETALLADA
  // ────────────────────────────────────────
  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Tipo:', center.type),
          const SizedBox(height: 10),
          _infoRow('Dirección:', center.address),
          const SizedBox(height: 10),
          _infoRow('Horario de atención:', center.schedule),
          const SizedBox(height: 10),
          _infoRow('Ciudad:', center.city),
          const SizedBox(height: 10),
          _infoRow('Departamento:', center.department),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3D2B27),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BellotaColors.textoDark,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: BellotaColors.textoMedio,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────
  // ESPECIALIDADES — Chips / Tags
  // ────────────────────────────────────────
  Widget _buildSpecialtiesSection() {
    return Column(
      children: [
        Text(
          'Especialidades',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BellotaColors.textoDark,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: center.specialties.map((specialty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: BellotaColors.nancite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: BellotaColors.textoMedio.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                specialty,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: BellotaColors.textoDark,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
