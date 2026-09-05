import '../core/models/health_center_model.dart';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';

/// Pantalla de detalle de un centro de salud
class HealthCenterDetailScreen extends StatelessWidget {
  final HealthCenter center;

  const HealthCenterDetailScreen({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).bellotaColors.basilica,
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
                physics: ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        center.name,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          color: Theme.of(context).bellotaColors.textoDark,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildImagePlaceholder(context),
                      SizedBox(height: 20 ),
                      _buildInfoSection(context),
                      SizedBox(height: 24),
                      _buildSpecialtiesSection(context),
                      SizedBox(height: 30),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).bellotaColors.basilica,
      child: Row(
        children: [
          // Botón de regreso
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.blanco,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).bellotaColors.textoDark, size: 20),
            ),
          ),
          SizedBox(width: 10),
          
          // Campo de búsqueda
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.blanco,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(width: 14),
                  Icon(Icons.search, color: Theme.of(context).bellotaColors.textoMedio, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buscar...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          
          // === BOTONES GLOBALES ===
          BellotaTopActions(
            showSettings: false,
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
        gradient: LinearGradient(
          colors: [Theme.of(context).bellotaColors.chilero, Theme.of(context).bellotaColors.gradienteClaro],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.15),
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
                color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.1),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital_rounded, color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.9), size: 48),
                SizedBox(height: 8),
                Text(
                  'Centro de Salud',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.9),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).bellotaColors.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, 'Tipo:', center.type),
          SizedBox(height: 10),
          _infoRow(context, 'Dirección:', center.address),
          SizedBox(height: 10),
          _infoRow(context, 'Teléfono:', center.phone),
          SizedBox(height: 10),
          _infoRow(context, 'Municipio:', center.municipality),
          SizedBox(height: 10),
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
          padding: EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).bellotaColors.textoDark,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).bellotaColors.textoDark,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).bellotaColors.textoMedio,
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
  // SERVICIOS 
  // ────────────────
  Widget _buildSpecialtiesSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Servicios',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).bellotaColors.textoDark,
          ),
        ),
        SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: center.services.map((service) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.nancite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                service,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).bellotaColors.textoDark,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


