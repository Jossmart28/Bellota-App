import 'dart:io';

void main() {
  final dashFile = File('lib/presentation/screens/home/dashboard_screen.dart');
  if (dashFile.existsSync()) {
    String c = dashFile.readAsStringSync();
    
    // Fix imports
    c = c.replaceAll('package:bellotadevelopment/screens/', 'package:bellotadevelopment/presentation/screens/');
    c = c.replaceAll('package:bellotadevelopment/widgets/', 'package:bellotadevelopment/presentation/common/');
    c = c.replaceAll('package:bellotadevelopment/theme/', 'package:bellotadevelopment/presentation/theme/');
    
    c = c.replaceAll("import 'package:bellotadevelopment/database/database_helper.dart';", 
    "import 'package:bellotadevelopment/core/di/injection_container.dart';\nimport 'package:bellotadevelopment/domain/repositories/auth_repository.dart';\nimport 'package:bellotadevelopment/domain/repositories/profile_repository.dart';\nimport 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';\nimport 'dashboard_controller.dart';");

    // Replace state variables with controller instance
    c = c.replaceFirst(
      'class _DashboardScreenState extends State<DashboardScreen> {',
      'class _DashboardScreenState extends State<DashboardScreen> {\n  final DashboardController _controller = DashboardController();\n'
    );

    // Remove variables
    final regexVars = RegExp(r'  int _currentPhaseIndex = 0;.*?(?=  // \â”€\â”€ Definici\Ã³n de las 4 fases)', dotAll: true);
    c = c.replaceFirst(regexVars, '');

    // Replace didChangeDependencies and logic
    final regexLogic = RegExp(r'  bool _initialLoadDone = false;.*?(?=  @override\n  Widget build\(BuildContext context\))', dotAll: true);
    c = c.replaceFirst(regexLogic, '''
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _controller.loadUserAndDashboard().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

''');

    // Replace usages in build
    c = c.replaceAll('_currentPhaseIndex', '_controller.currentPhaseIndex');
    c = c.replaceAll('_userName', '_controller.userName');
    c = c.replaceAll('_profileImageExists', '_controller.profileImageExists');
    c = c.replaceAll('_profileImagePath', '_controller.profileImagePath');
    c = c.replaceAll('_todaySymptoms', '_controller.todaySymptoms');
    c = c.replaceAll('_todayMood', '_controller.todayMood');
    c = c.replaceAll('_nextPeriodDate', '_controller.nextPeriodDate');
    c = c.replaceAll('_cycleInfo', '_controller.cycleInfo');
    c = c.replaceAll('_predictedSymptoms', '_controller.predictedSymptoms');
    c = c.replaceAll('_activeAlerts', '_controller.activeAlerts');
    c = c.replaceAll('_periodoIniciado', '_controller.periodoIniciado');
    c = c.replaceAll('_userId', '_controller.userId');

    dashFile.writeAsStringSync(c);
  }

  // Fix Onboarding Screens imports
  final obFiles = [
    'lib/presentation/screens/onboarding/birth_year_screen.dart',
    'lib/presentation/screens/onboarding/language_selection_screen.dart',
    'lib/presentation/screens/profile/account_language_screen.dart'
  ];
  for (final path in obFiles) {
    final f = File(path);
    if (f.existsSync()) {
      String c = f.readAsStringSync();
      c = c.replaceAll('package:bellotadevelopment/screens/', 'package:bellotadevelopment/presentation/screens/');
      c = c.replaceAll('package:bellotadevelopment/widgets/', 'package:bellotadevelopment/presentation/common/');
      c = c.replaceAll('package:bellotadevelopment/theme/', 'package:bellotadevelopment/presentation/theme/');
      
      c = c.replaceAll("import 'package:bellotadevelopment/database/database_helper.dart';", 
      "import 'package:bellotadevelopment/core/di/injection_container.dart';\nimport 'package:bellotadevelopment/domain/repositories/user_repository.dart';");
      
      c = c.replaceAll('DatabaseProvider.instance.updateUserLanguage', 'sl<UserRepository>().updateUserLanguage');
      c = c.replaceAll('DatabaseHelper.instance.updateUserLanguage', 'sl<UserRepository>().updateUserLanguage');
      
      f.writeAsStringSync(c);
    }
  }

  print('Restored UI connected to controllers and DI.');
}
