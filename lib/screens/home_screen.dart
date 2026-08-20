import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPhaseIndex = 0;
  int _selectedIndex = 0;
  String _userName = "Usuario";

  final List<Map<String, dynamic>> _phases = [
    {
      'name': 'Fase Menstrual',
      'color': BellotaColors.chilero,
      'symptoms': '• Dolor abdominal\n• Sangrado moderado\n• Dolores de cabeza',
    },
    {
      'name': 'Fase Folicular',
      'color': BellotaColors.chiltoma,
      'symptoms': '• Energía en aumento\n• Piel más clara\n• Buen humor',
    },
    {
      'name': 'Fase Ovulatoria',
      'color': BellotaColors.melon,
      'symptoms': '• Alta energía\n• Mayor deseo sexual\n• Ligero dolor pélvico',
    },
    {
      'name': 'Fase Lútea',
      'color': BellotaColors.asuncion,
      'symptoms': '• Cansancio\n• Cambios de humor\n• Antojos dulces',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Usuario';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentPhaseIndex];

    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: BellotaColors.nancite,
              child: Icon(Icons.person, color: BellotaColors.textoMedio),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: GoogleFonts.poppins(color: BellotaColors.textoDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: BellotaColors.chilero),
            onPressed: _logout, // Cierre de sesión temporal para pruebas
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de hoy
            Text('Resumen de hoy', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: BellotaColors.textoDark)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BellotaColors.nancite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPhaseIndex = (_currentPhaseIndex + 1) % _phases.length;
                      });
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentPhase['color'].withValues(alpha: 0.8),
                        border: Border.all(color: currentPhase['color'], width: 3),
                      ),
                      child: Center(
                        child: Text(
                          currentPhase['name'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Síntomas', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: BellotaColors.textoDark)),
                        const SizedBox(height: 8),
                        Text(currentPhase['symptoms'], style: GoogleFonts.poppins(fontSize: 12, color: BellotaColors.textoMedio)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Predicciones (Lorem Ipsum)
            Text('Predicciones', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: BellotaColors.textoDark)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BellotaColors.nancite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Tu próximo periodo será...', style: GoogleFonts.poppins(fontSize: 12, color: BellotaColors.textoMedio)),
                        Text('25/Feb.', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: BellotaColors.chilero)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 60, color: BellotaColors.textoMedio.withValues(alpha: 0.2)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                        style: GoogleFonts.poppins(fontSize: 11, color: BellotaColors.textoMedio),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: BellotaColors.chilero,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
