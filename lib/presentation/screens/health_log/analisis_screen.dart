import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellotadevelopment/core/services/clinical_analysis_service.dart';
import 'package:bellotadevelopment/presentation/screens/hospitals/hospital_hub_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnalisisScreen extends StatefulWidget {
  final int cycleDuration;
  final int periodDuration;
  final List<ClinicalAlert>? activeAlerts;
  final int? userId;

  const AnalisisScreen({
    super.key,
    required this.cycleDuration,
    required this.periodDuration,
    this.activeAlerts,
    this.userId,
  });

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  int _loggedDays = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _animations = List.generate(
      4,
      (i) => CurvedAnimation(
        parent: _controller,
        curve: Interval(i * 0.15, 0.7 + i * 0.1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
    _checkLoggedDays();
  }

  Future<void> _checkLoggedDays() async {
    if (widget.userId != null) {
      final count = await sl<DailyLogRepository>().getDailyLogs(widget.userId!).then((v) => v.length);
      if (mounted) {
        setState(() {
          _loggedDays = count;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget? _buildHospitalIndicator() {
    if (widget.activeAlerts == null || widget.activeAlerts!.isEmpty || _loggedDays < 7) {
      return null;
    }
    
    // Sort to find the highest severity for color
    bool hasHigh = widget.activeAlerts!.any((a) => a.severity == 'high');
    bool hasMed = widget.activeAlerts!.any((a) => a.severity == 'medium');
    Color color = hasHigh ? const Color(0xFFD32F2F) : (hasMed ? const Color(0xFFF57C00) : const Color(0xFF388E3C));

    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HospitalHubScreen(activeAlerts: widget.activeAlerts)),
        );
      },
      backgroundColor: Colors.white,
      elevation: 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.local_hospital_rounded, color: color, size: 28),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 1.seconds).fade(begin: 1, end: 0, duration: 1.seconds),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05,1.05), duration: 1.seconds, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      floatingActionButton: _buildHospitalIndicator(),
      body: Stack(
        children: [
          // Gradient header background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 230,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFD4756A),
                    Color(0xFFE8998A),
                    Color(0xFFF2B5A0),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Análisis',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Perfil de ciclo',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Data cards row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: FadeTransition(
                          opacity: _animations[0],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(_animations[0]),
                            child: _DataCard(
                              icon: Icons.autorenew_rounded,
                              iconColor: const Color(0xFFD4756A),
                              label: 'Duración del ciclo',
                              value: '${widget.cycleDuration}',
                              unit: 'días',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FadeTransition(
                          opacity: _animations[1],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(_animations[1]),
                            child: _DataCard(
                              icon: Icons.water_drop_rounded,
                              iconColor: const Color(0xFFE8998A),
                              label: 'Duración del sangrado',
                              value: '${widget.periodDuration}',
                              unit: 'días',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      FadeTransition(
                        opacity: _animations[2],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_animations[2]),
                          child: _InfoCard(
                            title: 'Ciclo menstrual',
                            description:
                                'Un ciclo menstrual típico dura entre 21 y 35 días. El tuyo está registrado en ${widget.cycleDuration} días.',
                            icon: Icons.info_outline_rounded,
                            color: _cycleStatusColor(widget.cycleDuration),
                            statusLabel: _cycleStatusLabel(widget.cycleDuration),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeTransition(
                        opacity: _animations[3],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_animations[3]),
                          child: _InfoCard(
                            title: 'Duración del sangrado',
                            description:
                                'El sangrado menstrual normal dura entre 3 y 7 días. El tuyo está registrado en ${widget.periodDuration} días.',
                            icon: Icons.water_drop_outlined,
                            color: _bleedingStatusColor(widget.periodDuration),
                            statusLabel:
                                _bleedingStatusLabel(widget.periodDuration),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _cycleStatusColor(int days) {
    if (days >= 21 && days <= 35) return const Color(0xFF4CAF50);
    return const Color(0xFFFF7043);
  }

  String _cycleStatusLabel(int days) {
    if (days >= 21 && days <= 35) return 'Normal';
    return 'Irregular';
  }

  Color _bleedingStatusColor(int days) {
    if (days >= 3 && days <= 7) return const Color(0xFF4CAF50);
    return const Color(0xFFFF7043);
  }

  String _bleedingStatusLabel(int days) {
    if (days >= 3 && days <= 7) return 'Normal';
    if (days > 7) return 'Prolongado';
    return 'Corto';
  }
}

class _DataCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _DataCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3D2B1F),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E8B80),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF9E8B80),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String statusLabel;

  const _InfoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D2B1F),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF9E8B80),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
