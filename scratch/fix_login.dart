import 'dart:io';

void main() {
  final file = File('lib/screens/login_screen.dart');
  String content = file.readAsStringSync();

  final target = '''  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(''';

  final replace = '''  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('show_aborted_registration_msg') == true) {
        if (mounted) {
          _showError("El proceso de registro fue interrumpido, por favor regístrate nuevamente.");
        }
        await prefs.remove('show_aborted_registration_msg');
      }
    });

    SystemChrome.setSystemUIOverlayStyle(''';

  content = content.replaceFirst(target, replace);
  file.writeAsStringSync(content);
}
