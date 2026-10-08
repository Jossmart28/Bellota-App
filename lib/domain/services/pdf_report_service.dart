import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:bellotadevelopment/core/errors/app_logger.dart';

class PdfReportService {
  /// Genera un reporte médico en formato PDF
  Future<File?> generateReport({
    required String userName,
    required String userAge,
    required String userLocation,
    required String periodDuration,
    required String cycleDuration,
    required List<String> medications,
    required Map<String, dynamic> reportData,
    required String reportId,
    required String fechaHoy,
    required Map<String, String> localizedStrings, // Traducciones pasadas desde la UI
  }) async {
    try {
      final pdf = pw.Document();

      // Cargar fuentes
      final Uint8List fontData = (await rootBundle.load('assets/fonts/Poppins-Regular.ttf')).buffer.asUint8List();
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());
      final Uint8List fontBoldData = (await rootBundle.load('assets/fonts/Poppins-Bold.ttf')).buffer.asUint8List();
      final ttfBold = pw.Font.ttf(fontBoldData.buffer.asByteData());
      
      final PdfColor naranja = PdfColor.fromHex('#FF7755');
      final PdfColor rosa = PdfColor.fromHex('#F48CA4');

      pw.Widget buildSectionHeader(String title, pw.IconData icon) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 20, bottom: 10),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFCE4EC), // Light pink
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: rosa, width: 1),
          ),
          child: pw.Row(
            children: [
              pw.Text(title, style: pw.TextStyle(font: ttfBold, fontSize: 16, color: naranja)),
            ],
          ),
        );
      }

      pw.Widget buildDataRow(String label, String value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(label, style: pw.TextStyle(font: ttfBold, fontSize: 12)),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(value, style: pw.TextStyle(font: ttf, fontSize: 12)),
              ),
            ],
          ),
        );
      }

      final patron = reportData['patronSangrado'] as Map<String, dynamic>? ?? {};
      final dolor = reportData['sintomatologia'] as Map<String, dynamic>? ?? {};
      final topSyms = reportData['sintomasFrecuentes'] as List? ?? [];
      final flujoFrec = reportData['flujoMasFrecuente'] as String? ?? localizedStrings['notSpecified']!;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Cabecera
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bellota App', style: pw.TextStyle(font: ttfBold, fontSize: 24, color: naranja)),
                    pw.Text(localizedStrings['reportTitle']!, style: pw.TextStyle(font: ttf, fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('${localizedStrings['date']!}: $fechaHoy', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.Text('ID: $reportId', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
              ],
            ),
            pw.Divider(color: rosa, thickness: 2),
            pw.SizedBox(height: 20),

            // Información del Paciente
            buildSectionHeader(localizedStrings['patientInfo']!, const pw.IconData(0xe7fd)),
            buildDataRow(localizedStrings['name']!, userName),
            buildDataRow(localizedStrings['age']!, userAge.isNotEmpty ? userAge : localizedStrings['notSpecified']!),
            buildDataRow(localizedStrings['location']!, userLocation.isNotEmpty ? userLocation : localizedStrings['notSpecified']!),

            // Datos Ginecológicos
            buildSectionHeader(localizedStrings['gynData']!, const pw.IconData(0xe873)),
            buildDataRow(localizedStrings['cycleDuration']!, '$cycleDuration ${localizedStrings['days']}'),
            buildDataRow(localizedStrings['periodDuration']!, '$periodDuration ${localizedStrings['days']}'),
            buildDataRow(localizedStrings['medications']!, medications.isNotEmpty ? medications.join(', ') : localizedStrings['none']!),

            // Patrón de Sangrado
            buildSectionHeader(localizedStrings['bleedingPattern']!, const pw.IconData(0xe873)),
            buildDataRow(localizedStrings['flowIntensity']!, patron['intensidadFlujo']?.toString() ?? localizedStrings['notSpecified']!),
            buildDataRow(localizedStrings['clots']!, patron['coagulos']?.toString() ?? localizedStrings['notSpecified']!),
            buildDataRow(localizedStrings['frequentFlow']!, flujoFrec),

            // Sintomatología
            buildSectionHeader(localizedStrings['symptomatology']!, const pw.IconData(0xe873)),
            buildDataRow(localizedStrings['frequentSymptoms']!, topSyms.isNotEmpty ? topSyms.join(', ') : localizedStrings['none']!),
            buildDataRow(localizedStrings['painLevel']!, dolor['nivelDolor'] != null ? '${dolor['nivelDolor']}/10' : localizedStrings['notSpecified']!),
            buildDataRow(localizedStrings['breastExam']!, dolor['autoexamenMama']?.toString() ?? localizedStrings['notSpecified']!),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reporte_bellota_$reportId.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      AppLogger.e('Error generating PDF report: $e');
      return null;
    }
  }
}
