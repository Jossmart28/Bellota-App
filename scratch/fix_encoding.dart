import 'dart:io';

void main() {
  final file = File('lib/screens/dashboard_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll('Ã¡', 'á');
  content = content.replaceAll('Ã©', 'é');
  content = content.replaceAll('Ã­', 'í');
  content = content.replaceAll('Ã³', 'ó');
  content = content.replaceAll('Ãº', 'ú');
  content = content.replaceAll('Ã±', 'ñ');
  content = content.replaceAll('Ã\xAD', 'í');
  content = content.replaceAll('Â°', '°');
  content = content.replaceAll('ðŸ˜Œ', '😌');
  content = content.replaceAll('ðŸ˜•', '😕');
  content = content.replaceAll('ðŸ˜£', '😣');
  content = content.replaceAll('ðŸ˜–', '😖');
  content = content.replaceAll('ðŸ˜\xAD', '😭');
  content = content.replaceAll('ðŸ˜ ', '😁');
  content = content.replaceAll('ðŸ™\x82', '🙂');
  content = content.replaceAll('ðŸ˜\x94', '😔');
  content = content.replaceAll('ðŸ˜¢', '😢');
  content = content.replaceAll('â”€', '─');

  content = content.replaceAll('PrÃ³ximo perÃ­odo', 'Próximo período');
  content = content.replaceAll('sÃ­ntomas esperados', 'síntomas esperados');
  content = content.replaceAll('DÃ­a tranquilo', 'Día tranquilo');
  content = content.replaceAll('dÃ­as', 'días');
  content = content.replaceAll('dÃ­a', 'día');
  content = content.replaceAll('perÃ­odo', 'período');
  content = content.replaceAll('ovulaciÃ³n', 'ovulación');
  content = content.replaceAll('PosiciÃ³n', 'Posición');
  content = content.replaceAll('clÃ­nicas', 'clínicas');
  content = content.replaceAll('recomendaciÃ³n', 'recomendación');
  content = content.replaceAll('sÃ­ntoma', 'síntoma');
  content = content.replaceAll('SÃ­ntomas', 'Síntomas');
  content = content.replaceAll('SÃ­ntoma', 'Síntoma');
  content = content.replaceAll('mÃ¡s', 'más');
  content = content.replaceAll('cambiÃ³', 'cambió');
  content = content.replaceAll('estÃ©n', 'estén');
  content = content.replaceAll('estÃ¡n', 'están');

  file.writeAsStringSync(content);
  print('Fixed encoding for dashboard_screen.dart');
}
