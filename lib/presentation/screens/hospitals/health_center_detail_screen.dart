import 'package:bellotadevelopment/core/models/health_center_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';

/// Pantalla de detalle de un centro de salud — Plantilla reutilizable con animaciones
class HealthCenterDetailScreen extends StatefulWidget {
  final HealthCenter center;

  const HealthCenterDetailScreen({super.key, required this.center});

  @override
  State<HealthCenterDetailScreen> createState() => _HealthCenterDetailScreenState();
}

class _HealthCenterDetailScreenState extends State<HealthCenterDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;

    return Scaffold(
      backgroundColor: colors.basilica,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero header fused with red gradient ──────────────────────
          _buildHeroHeader(context, colors),

          // ── Animated content ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Directions button ───────────────────────────
                      _buildDirectionsButton(colors),
                      const SizedBox(height: 24),

                      // ── Info cards ──────────────────────────────────
                      _buildInfoCard(context, colors),
                      const SizedBox(height: 20),

                      // ── Description ─────────────────────────────────
                      if (widget.center.description != null &&
                          widget.center.description!.isNotEmpty) ...[
                        _buildSectionTitle('Acerca del centro', colors),
                        const SizedBox(height: 12),
                        _buildDescriptionCard(colors),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO HEADER: image + red gradient overlay
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context, BellotaColors colors) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: colors.chilero,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Hospital image or gradient fill
            widget.center.imageAsset != null
                ? Image.asset(
                    widget.center.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientPlaceholder(colors),
                  )
                : _gradientPlaceholder(colors),

            // 2. Red gradient overlay from bottom (fuses header color with image)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      colors.chilero.withOpacity(0.55),
                      colors.chilero.withOpacity(0.92),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Top overlay: back button + emergency badge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      // Emergency badge only (no help button, no RPG text)
                      if (widget.center.emergencyAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.access_time_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Emergencias 24h',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Name + type at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.center.type,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Hospital name
                    Text(
                      widget.center.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (widget.center.municipality.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.center.municipality}, ${widget.center.department}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientPlaceholder(BellotaColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.chilero, colors.melon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital_rounded,
          size: 80,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DIRECTIONS BUTTON
  // ─────────────────────────────────────────────────────────────
  Widget _buildDirectionsButton(BellotaColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.chilero,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: colors.chilero.withOpacity(0.4),
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          // TODO: launch maps with center.location
        },
        icon: const Icon(Icons.near_me_rounded, size: 20),
        label: const Text(
          'Cómo llegar',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INFO CARD (tipo, dirección, municipio, departamento, teléfono)
  // ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, BellotaColors colors) {
    final rows = <_InfoItem>[
      if (widget.center.type.isNotEmpty)
        _InfoItem(icon: Icons.medical_services_rounded, label: 'Tipo', value: widget.center.type),
      if (widget.center.address.isNotEmpty)
        _InfoItem(icon: Icons.location_on_rounded, label: 'Dirección', value: widget.center.address),
      if (widget.center.municipality.isNotEmpty)
        _InfoItem(icon: Icons.location_city_rounded, label: 'Municipio', value: widget.center.municipality),
      if (widget.center.department.isNotEmpty)
        _InfoItem(icon: Icons.map_rounded, label: 'Departamento', value: widget.center.department),
      if (widget.center.phone.isNotEmpty && widget.center.phone != 'N/A')
        _InfoItem(icon: Icons.phone_rounded, label: 'Teléfono', value: widget.center.phone),
      if (widget.center.openHours.isNotEmpty)
        _InfoItem(icon: Icons.access_time_rounded, label: 'Horario', value: widget.center.openHours),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: colors.chilero.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.chilero.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: colors.chilero, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(fontSize: 11, color: colors.textoMedio, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: TextStyle(fontSize: 14, color: colors.textoDark, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (i < rows.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: colors.nancite),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DESCRIPTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildDescriptionCard(BellotaColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.textoMedio.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        widget.center.description!,
        style: TextStyle(fontSize: 14, color: colors.textoMedio, height: 1.6),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BellotaColors colors) {
    return Text(
      title,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textoDark),
    );
  }
}

// Helper data class for info rows
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  _InfoItem({required this.icon, required this.label, required this.value});
}
