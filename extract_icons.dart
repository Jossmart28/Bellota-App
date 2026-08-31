import 'dart:io';
import 'dart:convert';

void main() {
  final projectDir = Directory(r'c:\Users\USER\Downloads\bellotadevolpment\lib');
  final iconsData = <String, Map<String, dynamic>>{};

  final iconRegex = RegExp(r'Icons\.(\w+)');
  final iconWidgetRegex = RegExp(r'Icon\s*\(\s*Icons\.(\w+)([^)]*)\)');
  final bellotaIconRegex = RegExp(r'BellotaIcon\s*\(([^)]*)\)');
  final assetRegex = RegExp(r"(?:Image|SvgPicture|SvgPicture\.asset|Image\.asset)\s*\(\s*['\x22]([^'\x22]+)['\x22]([^)]*)\)");

  for (final file in projectDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      final relPath = file.path.replaceAll(r'c:\Users\USER\Downloads\bellotadevolpment\', '');

      // 1. Match Icon(Icons.xxx)
      for (final match in iconWidgetRegex.allMatches(content)) {
        final iconName = 'Icons.${match.group(1)}';
        final propsStr = match.group(2) ?? '';
        
        final sizeMatch = RegExp(r'size:\s*([\d.]+)').firstMatch(propsStr);
        final colorMatch = RegExp(r'color:\s*([a-zA-Z0-9_.]+)').firstMatch(propsStr);
        
        final size = sizeMatch != null ? sizeMatch.group(1)! : 'default';
        final color = colorMatch != null ? colorMatch.group(1)! : 'default';
        
        iconsData.putIfAbsent(iconName, () => {
          'name': iconName,
          'library': 'Material Icons',
          'locations': <String>{},
          'path_or_code': 'Material builtin',
          'properties': <String>{},
        });
        
        (iconsData[iconName]!['locations'] as Set<String>).add(relPath);
        final propStr = 'size: $size, color: $color';
        if (propStr != 'size: default, color: default') {
          (iconsData[iconName]!['properties'] as Set<String>).add(propStr);
        }
      }

      // Match standalone Icons.xxx
      for (final match in iconRegex.allMatches(content)) {
        final iconName = 'Icons.${match.group(1)}';
        iconsData.putIfAbsent(iconName, () => {
          'name': iconName,
          'library': 'Material Icons',
          'locations': <String>{},
          'path_or_code': 'Material builtin',
          'properties': <String>{},
        });
        (iconsData[iconName]!['locations'] as Set<String>).add(relPath);
      }

      // 2. Match BellotaIcon
      for (final match in bellotaIconRegex.allMatches(content)) {
        final propsStr = match.group(1) ?? '';
        final sizeMatch = RegExp(r'size:\s*([\d.]+)').firstMatch(propsStr);
        final colorMatch = RegExp(r'color:\s*([a-zA-Z0-9_.]+)').firstMatch(propsStr);
        
        final size = sizeMatch != null ? sizeMatch.group(1)! : 'default (24)';
        final color = colorMatch != null ? colorMatch.group(1)! : 'default';
        
        final iconName = 'BellotaIcon';
        iconsData.putIfAbsent(iconName, () => {
          'name': iconName,
          'library': 'Custom Widget',
          'locations': <String>{},
          'path_or_code': 'lib/widgets/bellota_icon.dart',
          'properties': <String>{},
        });
        
        (iconsData[iconName]!['locations'] as Set<String>).add(relPath);
        (iconsData[iconName]!['properties'] as Set<String>).add('size: $size, color: $color');
      }

      // 3. Match Assets
      for (final match in assetRegex.allMatches(content)) {
        final assetPath = match.group(1)!;
        final propsStr = match.group(2) ?? '';
        
        String library = 'Asset';
        if (assetPath.endsWith('.svg')) library = 'Custom SVG';
        if (assetPath.endsWith('.png') || assetPath.endsWith('.jpg')) library = 'Image Asset';

        final heightMatch = RegExp(r'height:\s*([\d.]+)').firstMatch(propsStr);
        final widthMatch = RegExp(r'width:\s*([\d.]+)').firstMatch(propsStr);
        final colorMatch = RegExp(r'color:\s*([a-zA-Z0-9_.]+)').firstMatch(propsStr);
        
        final props = <String>[];
        if (widthMatch != null) props.add('width: ${widthMatch.group(1)}');
        if (heightMatch != null) props.add('height: ${heightMatch.group(1)}');
        if (colorMatch != null) props.add('color: ${colorMatch.group(1)}');
        final propStr = props.isNotEmpty ? props.join(', ') : 'default';

        final iconName = assetPath.split('/').last;
        final key = assetPath;
        
        iconsData.putIfAbsent(key, () => {
          'name': iconName,
          'library': library,
          'locations': <String>{},
          'path_or_code': assetPath,
          'properties': <String>{},
        });
        
        (iconsData[key]!['locations'] as Set<String>).add(relPath);
        if (propStr != 'default') {
          (iconsData[key]!['properties'] as Set<String>).add(propStr);
        }
      }
    }
  }

  // Convert Sets to Lists
  final result = iconsData.values.map((data) {
    return {
      'name': data['name'],
      'library': data['library'],
      'locations': (data['locations'] as Set<String>).toList(),
      'path_or_code': data['path_or_code'],
      'properties': (data['properties'] as Set<String>).isEmpty ? ['default'] : (data['properties'] as Set<String>).toList(),
    };
  }).toList();

  final jsonFile = File(r'c:\Users\USER\Downloads\bellotadevolpment\icons_extracted.json');
  jsonFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(result));
  print('Extracted ${result.length} icons.');
}
