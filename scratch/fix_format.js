const fs = require('fs');
let content = fs.readFileSync('lib/screens/resumen_diario_screen.dart', 'utf8');
content = content.replace('String format(DateTime d) => `${d.day} ${monthNames[d.month - 1]}`;', 'String format(DateTime d) => \'${d.day} ${monthNames[d.month - 1]}\';');
fs.writeFileSync('lib/screens/resumen_diario_screen.dart', content);