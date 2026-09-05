import os
import re

files = [
    'lib/screens/symptom_log_screen.dart',
    'lib/screens/symptoms_selection_screen.dart',
    'lib/screens/dolor_sintomatologia_screen.dart',
    'lib/screens/patron_sangrado_screen.dart',
    'lib/screens/flujo_vaginal_selection_screen.dart',
    'lib/screens/sexo_selection_screen.dart',
    'lib/screens/medical_report_preview_screen.dart'
]

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip if already has ValueListenableBuilder inside build
    if 'ValueListenableBuilder<String>' in content and 'valueListenable: languageNotifier' in content:
        continue
        
    # Ensure import
    if 'language_notifier.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../l10n/language_notifier.dart';")
        if 'language_notifier.dart' not in content:
            content = "import '../l10n/language_notifier.dart';\n" + content

    # Find the build method
    # It starts with "Widget build(BuildContext context) {"
    build_start = content.find('Widget build(BuildContext context) {')
    if build_start == -1:
        print(f'Build method not found in {file_path}')
        continue

    # We need to find the matching closing brace of the build method
    # Count braces starting from the '{'
    brace_start = content.find('{', build_start)
    count = 1
    i = brace_start + 1
    while count > 0 and i < len(content):
        if content[i] == '{': count += 1
        elif content[i] == '}': count -= 1
        i += 1
    
    build_end = i - 1
    
    build_body = content[brace_start+1:build_end]
    
    # Inside the build body, remove inal lang = languageNotifier.currentLang; if it exists
    # because our builder will provide lang.
    build_body = re.sub(r'final\s+lang\s*=\s*languageNotifier\.currentLang;\s*', '', build_body)
    
    # Replace other languageNotifier.currentLang calls inside the build body with lang
    build_body = build_body.replace('languageNotifier.currentLang', 'lang')
    
    new_build_body = f'''
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {{{build_body}}});
  '''
    
    content = content[:brace_start+1] + new_build_body + content[build_end:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f'Processed {file_path}')

