import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import 'map_screen.dart';

/// Pantalla de detalle de un centro de salud
class HealthCenterDetailScreen extends StatelessWidget {
  final HealthCenter center;

  const HealthCenterDetailScreen({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      body: SafeArea(
        child: Column(
          children: [
            // ════════════════════════════════════════════
            // BARRA SUPERIOR — Búsqueda + íconos globales
            // ════════════════════════════════════════════
            _buildSearchBar(context),
            
            // ══════════════════════
            // CONTENIDO SCROLLABLE
            // ══════════════════════
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        center.name,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          color: BellotaColors.textoDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildImagePlaceholder(context),
                      const SizedBox(height: 20),
                      _buildInfoSection(context),
                      const SizedBox(height: 24),
                      _buildSpecialtiesSection(context),
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
  // BARRA DE BÚSQUEDA Y BOTONES GLOBALES
  // ────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: BellotaColors.basilica,
      child: Row(
        children: [
          // Botón de regreso
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: BellotaColors.blanco,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: BellotaColors.textoDark, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: BellotaColors.blanco,
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
                  const Icon(Icons.search, color: BellotaColors.textoMedio, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buscar...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BellotaColors.textoMedio.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // === BOTONES GLOBALES ===
          BellotaTopActions(
            showSettings: false,
            onLanguagePressed: () {},
            onTalkBackPressed: () {},
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────
  // IMAGEN PLACEHOLDER DEL CENTRO
  // ───────────────────────────────
  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [BellotaColors.chilero, BellotaColors.gradienteClaro],
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
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BellotaColors.blanco.withValues(alpha: 0.15),
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
                color: BellotaColors.blanco.withValues(alpha: 0.1),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital_rounded, color: BellotaColors.blanco.withValues(alpha: 0.9), size: 48),
                const SizedBox(height: 8),
                Text(
                  'Centro de Salud',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: BellotaColors.blanco.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────
  // INFORMACIÓN DETALLADA
  // ───────────────────────
  Widget _buildInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BellotaColors.blanco,
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
          _infoRow(context, 'Tipo:', center.type),
          const SizedBox(height: 10),
          _infoRow(context, 'Dirección:', center.address),
          const SizedBox(height: 10),
          _infoRow(context, 'Horario de atención:', center.schedule),
          const SizedBox(height: 10),
          _infoRow(context, 'Ciudad:', center.city),
          const SizedBox(height: 10),
          _infoRow(context, 'Departamento:', center.department),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: BellotaColors.textoDark,
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
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: BellotaColors.textoDark,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: textTheme.bodyMedium?.copyWith(
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

  // ────────────────
  // ESPECIALIDADES 
  // ────────────────
  Widget _buildSpecialtiesSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Especialidades',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 12,
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