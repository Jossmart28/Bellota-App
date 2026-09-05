import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/bellota_colors.dart';
import '../l10n/app_translations.dart';
import '../l10n/language_notifier.dart';

class MedicalReportPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const MedicalReportPreviewScreen({
    super.key,
    required this.reportData,
  });

  @override
  State<MedicalReportPreviewScreen> createState() => _MedicalReportPreviewScreenState();
}

class _MedicalReportPreviewScreenState extends State<MedicalReportPreviewScreen> {
  bool _isExporting = false;
  bool _isPrinting = false;

  void _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final ByteData imageBytes = await rootBundle.load('assets/images/logo_pdf.png');
        logoImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
      } catch (_) {} // graceful fallback if logo missing

      final poppinsRegular = await PdfGoogleFonts.poppinsRegular();
      final poppinsBold = await PdfGoogleFonts.poppinsBold();
      final poppinsItalic = await PdfGoogleFonts.poppinsItalic();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          header: (context) => _buildPdfHeader(context, logoImage, poppinsBold),
          footer: (context) => _buildPdfFooter(context, poppinsItalic, poppinsRegular),
          build: (context) => _buildPdfContent(widget.reportData, logoImage, poppinsRegular, poppinsBold),
        ),
      );
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'reporte_bellota_${widget.reportData['metadata']['numero_reporte'] ?? ''}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslations.get('registration_form', 'share_pdf', languageNotifier.currentLang) + ' - Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _printPdf() async {
    setState(() => _isPrinting = true);
    try {
      final pdf = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final ByteData imageBytes = await rootBundle.load('assets/images/logo_pdf.png');
        logoImage = pw.MemoryImage(imageBytes.buffer.asUint8List());
      } catch (_) {}
      final poppinsRegular = await PdfGoogleFonts.poppinsRegular();
      final poppinsBold = await PdfGoogleFonts.poppinsBold();
      final poppinsItalic = await PdfGoogleFonts.poppinsItalic();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          header: (context) => _buildPdfHeader(context, logoImage, poppinsBold),
          footer: (context) => _buildPdfFooter(context, poppinsItalic, poppinsRegular),
          build: (context) => _buildPdfContent(widget.reportData, logoImage, poppinsRegular, poppinsBold),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  pw.Widget _buildPdfHeader(pw.Context context, pw.MemoryImage? logoImage, pw.Font bold) {
    if (context.pageNumber > 1) {
      // Mini-header for subsequent pages
      return pw.Column(children: [
        pw.Row(children: [
          pw.Text('Bellota — Reporte de Salud', style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColor.fromInt(0xFFD35D53))),
          pw.Spacer(),
          pw.Text(widget.reportData['metadata']?['numero_reporte']?.toString() ?? '', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF8A8A8A))),
        ]),
        pw.Divider(color: PdfColor.fromInt(0xFFEFCDC8), thickness: 1),
        pw.SizedBox(height: 4),
      ]);
    }
    // Full header for page 1
    return pw.Column(children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoImage != null) pw.Image(logoImage, height: 50),
          if (logoImage != null) pw.SizedBox(width: 14),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('REPORTE DE SALUD MENSTRUAL', style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColor.fromInt(0xFFD35D53))),
              pw.Text('Reporte menstrual y clínico ginecológico', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF8A8A8A))),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Divider(color: PdfColor.fromInt(0xFFD35D53), thickness: 1.5),
      pw.SizedBox(height: 8),
    ]);
  }

  pw.Widget _buildPdfFooter(pw.Context context, pw.Font italic, pw.Font regular) {
    final meta = widget.reportData['metadata'] as Map? ?? {};
    return pw.Column(children: [
      pw.Divider(color: PdfColor.fromInt(0xFFEFCDC8)),
      pw.Row(children: [
        pw.Expanded(
          child: pw.Text(
            meta['aviso']?.toString() ?? 'Este reporte no sustituye una valoración médica profesional.',
            style: pw.TextStyle(font: italic, fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E)),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text('Pág. ${context.pageNumber}/${context.pagesCount}', style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor.fromInt(0xFF9E9E9E))),
      ]),
    ]);
  }

  List<pw.Widget> _buildPdfContent(Map<String, dynamic> data, pw.MemoryImage? logoImage, pw.Font regular, pw.Font bold) {
    final gen = data['seccion_1_informacion_general'] as Map? ?? {};
    final res = data['seccion_2_resumen_estadistico'] as Map? ?? {};
    final pat = data['seccion_3_patron_sangrado_flujo'] as Map? ?? {};
    final dol = data['seccion_4_dolor_sintomatologia'] as Map? ?? {};
    final alertas = data['seccion_5_alertas_automaticas'] as List? ?? [];

    final widgets = <pw.Widget>[];

    // Section 1
    widgets.add(_buildPdfSectionTitle('1. INFORMACIÓN GENERAL', bold));
    widgets.add(_buildPdfTable({
      'Paciente': gen['paciente'],
      'Edad': gen['edad'],
      'FUM': gen['fum'],
      'Rango analizado': gen['rango_analizado'],
      'Total ciclos': gen['total_ciclos']?.toString(),
      'Anticonceptivos': gen['anticonceptivos_medicamentos'],
      'Ubicación': gen['ubicacion'],
    }, regular, bold));

    // Section 2
    widgets.add(_buildPdfSectionTitle('2. RESUMEN ESTADÍSTICO', bold));
    if (res['promedio_ciclo'] != null || res['promedio_sangrado'] != null) {
      widgets.add(
        pw.Row(
          children: [
            if (res['promedio_ciclo'] != null)
              pw.Expanded(child: _buildPdfMetricCard('Promedio Ciclo', res['promedio_ciclo']['valor'].toString(), res['promedio_ciclo']['referencia'].toString(), res['promedio_ciclo']['estado'].toString(), bold, regular)),
            if (res['promedio_ciclo'] != null && res['promedio_sangrado'] != null)
              pw.SizedBox(width: 8),
            if (res['promedio_sangrado'] != null)
              pw.Expanded(child: _buildPdfMetricCard('Promedio Sangrado', res['promedio_sangrado']['valor'].toString(), res['promedio_sangrado']['referencia'].toString(), res['promedio_sangrado']['estado'].toString(), bold, regular)),
          ],
        )
      );
      widgets.add(pw.SizedBox(height: 8));
    }
    
    widgets.add(_buildPdfTable({
      'Flujo más frecuente': res['flujo_mas_frecuente'],
      'FUM': res['fum'],
    }, regular, bold));

    if (res['sintomas_mas_frecuentes'] != null && (res['sintomas_mas_frecuentes'] as List).isNotEmpty) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(pw.Text('Síntomas frecuentes: ${(res['sintomas_mas_frecuentes'] as List).join(', ')}', style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColor.fromInt(0xFF5A2D2D))));
    }

    // Section 3
    if (pat.isNotEmpty) {
      widgets.add(_buildPdfSectionTitle('3. PATRÓN DE SANGRADO Y FLUJO', bold));
      widgets.add(_buildPdfTable(pat.map((k, v) => MapEntry(k.toString(), v)), regular, bold));
    }

    // Section 4
    if (dol.isNotEmpty) {
      widgets.add(_buildPdfSectionTitle('4. DOLOR Y SINTOMATOLOGÍA', bold));
      if (dol['nivel_dolor_eva'] != null) {
        widgets.add(_buildPdfEvaBar(dol['nivel_dolor_eva'].toString(), bold, regular));
      }
      final dolEntries = Map<String, dynamic>.from(dol)..remove('nivel_dolor_eva');
      if (dolEntries.isNotEmpty) {
        widgets.add(_buildPdfTable(dolEntries, regular, bold));
      }
    }

    // Section 5
    if (alertas.isNotEmpty) {
      widgets.add(_buildPdfSectionTitle('5. ALERTAS CLÍNICAS', bold));
      for (final a in alertas) {
        final tipo = a['tipo']?.toString() ?? '';
        final detalle = a['detalle']?.toString() ?? '';
        final isAlert = detalle.contains('Alerta') || detalle.contains('Alert') || tipo.contains('Alerta');
        final color = isAlert ? PdfColor.fromInt(0xFFD35D53) : PdfColor.fromInt(0xFF5D9B50);
        widgets.add(
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: 6),
            padding: pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
              color: isAlert ? PdfColor.fromInt(0xFFFCE9E7) : PdfColor.fromInt(0xFFE8F5E9),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(tipo, style: pw.TextStyle(font: bold, fontSize: 10, color: color)),
                pw.Text(detalle, style: pw.TextStyle(font: regular, fontSize: 10)),
              ],
            )
          )
        );
      }
    }

    return widgets;
  }

  pw.Widget _buildPdfSectionTitle(String title, pw.Font bold) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 14, bottom: 6),
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEFCDC8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColor.fromInt(0xFF5A2D2D))),
    );
  }

  pw.Widget _buildPdfTable(Map<String, dynamic> rows, pw.Font regular, pw.Font bold) {
    final entries = rows.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFEFCDC8), width: 0.5),
      columnWidths: {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(3)},
      children: entries.asMap().entries.map((entry) {
        final isEven = entry.key % 2 == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: isEven ? PdfColor.fromInt(0xFFFFF8F1) : PdfColors.white),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text(_formatLabel(entry.value.key), style: pw.TextStyle(font: bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text(_formatValue(entry.value.value), style: pw.TextStyle(font: regular, fontSize: 10)),
            ),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _buildPdfMetricCard(String title, String valor, String referencia, String estado, pw.Font bold, pw.Font regular) {
    final isNormal = estado.toLowerCase().contains('normal');
    final color = isNormal ? PdfColor.fromInt(0xFF5D9B50) : PdfColor.fromInt(0xFFD35D53);
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColor.fromInt(0xFF8A8A8A))),
          pw.SizedBox(height: 4),
          pw.Text(valor, style: pw.TextStyle(font: bold, fontSize: 16, color: color)),
          pw.Text(referencia, style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor.fromInt(0xFF8A8A8A))),
          pw.Container(
            margin: pw.EdgeInsets.only(top: 4),
            padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text(estado, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfEvaBar(String evaString, pw.Font bold, pw.Font regular) {
    double value = 0;
    try {
      value = double.parse(evaString.split('/')[0]);
    } catch (_) {}
    final pct = value / 10.0;
    final color = pct >= 0.8 ? PdfColor.fromInt(0xFFD35D53) : pct >= 0.5 ? PdfColor.fromInt(0xFFF4B8A2) : PdfColor.fromInt(0xFFB1D4AE);
    
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8),
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF8F1),
        border: pw.Border.all(color: color, width: 1.0),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text('Nivel de Dolor EVA', style: pw.TextStyle(font: bold, fontSize: 10)),
              pw.Spacer(),
              pw.Text(evaString, style: pw.TextStyle(font: bold, fontSize: 12, color: color)),
            ]
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 6,
            width: double.infinity,
            decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E0E0), borderRadius: pw.BorderRadius.circular(3)),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 150 * pct, // Approximation since width is not easily computable here, let's just use flex or fractional layout
                  decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(3)),
                )
              ]
            ),
          )
        ]
      )
    );
  }

  String _formatLabel(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  Widget _buildReportContent() {
    final data = widget.reportData;
    final meta = data['metadata'] as Map? ?? {};
    final gen = data['seccion_1_informacion_general'] as Map? ?? {};
    final res = data['seccion_2_resumen_estadistico'] as Map? ?? {};
    final pat = data['seccion_3_patron_sangrado_flujo'] as Map? ?? {};
    final dol = data['seccion_4_dolor_sintomatologia'] as Map? ?? {};
    final alertas = data['seccion_5_alertas_automaticas'] as List? ?? [];
    final lang = languageNotifier.currentLang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Image.asset('assets/images/logo_color.png', height: 50, errorBuilder: (_, _, _) => Icon(Icons.favorite_rounded, color: BellotaColors.chilero, size: 36)),
            SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTranslations.get('profile_and_report','health_report_title',lang), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: BellotaColors.chilero)),
                Text(AppTranslations.get('profile_and_report','health_report_subtitle',lang), style: GoogleFonts.poppins(fontSize: 11, color: BellotaColors.textoMedio)),
              ],
            )),
          ],
        ),
        Divider(color: BellotaColors.chilero, thickness: 1.5, height: 24),

        // Section 1
        _buildScreenSectionHeader(AppTranslations.get('profile_and_report','sec_general',lang)),
        _buildScreenDataTable({
          AppTranslations.get('profile_and_report','patient',lang): gen['paciente'],
          AppTranslations.get('profile_and_report','age',lang): gen['edad'],
          AppTranslations.get('profile_and_report','lmp',lang): gen['fum'],
          AppTranslations.get('profile_and_report','analyzed_range',lang): gen['rango_analizado'],
          AppTranslations.get('registration_form','total_cycles',lang): gen['total_ciclos']?.toString(),
          AppTranslations.get('profile_and_report','contraceptives',lang): gen['anticonceptivos_medicamentos'],
          AppTranslations.get('registration_form','location',lang): gen['ubicacion'],
        }),

        // Section 2
        SizedBox(height: 16),
        _buildScreenSectionHeader(AppTranslations.get('profile_and_report','sec_summary',lang)),
        // Metric cards row
        if (res['promedio_ciclo'] != null || res['promedio_sangrado'] != null)
          Row(
            children: [
              if (res['promedio_ciclo'] != null)
                Expanded(child: _buildScreenMetricCard(
                  AppTranslations.get('profile_and_report','cycle_average',lang),
                  res['promedio_ciclo']['valor'].toString(),
                  res['promedio_ciclo']['referencia'].toString(),
                  res['promedio_ciclo']['estado'].toString(),
                )),
              SizedBox(width: 8),
              if (res['promedio_sangrado'] != null)
                Expanded(child: _buildScreenMetricCard(
                  AppTranslations.get('profile_and_report','bleeding_average',lang),
                  res['promedio_sangrado']['valor'].toString(),
                  res['promedio_sangrado']['referencia'].toString(),
                  res['promedio_sangrado']['estado'].toString(),
                )),
            ],
          ),
        SizedBox(height: 8),
        _buildScreenDataTable({
          AppTranslations.get('profile_and_report','most_frequent_flow',lang): res['flujo_mas_frecuente'],
        }),
        if (res['sintomas_mas_frecuentes'] != null && (res['sintomas_mas_frecuentes'] as List).isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                Text(AppTranslations.get('registration_form','top_symptoms',lang) + ':', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: BellotaColors.textoDark)),
                ...(res['sintomas_mas_frecuentes'] as List).map((s) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: BellotaColors.chilero.withValues(alpha:0.10), borderRadius: BorderRadius.circular(20)),
                  child: Text(s.toString(), style: GoogleFonts.poppins(fontSize: 11, color: BellotaColors.chilero)),
                )),
              ],
            ),
          ),

        // Section 3
        if (pat.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildScreenSectionHeader(AppTranslations.get('profile_and_report','sec_pattern',lang)),
          _buildScreenDataTable({
            AppTranslations.get('registration_form','flow_intensity_label',lang): pat['intensidad_flujo'],
            AppTranslations.get('registration_form','clots_label',lang): pat['coagulos'],
            AppTranslations.get('registration_form','spotting_label',lang): pat['manchado_intermenstrual'],
            AppTranslations.get('registration_form','spotting_days_label',lang): pat['manchado_dias'],
            AppTranslations.get('registration_form','sex_symptoms_label',lang): pat['sintomas_relaciones_sexuales'],
          }),
        ],

        // Section 4
        if (dol.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildScreenSectionHeader(AppTranslations.get('profile_and_report','sec_pain',lang)),
          // EVA bar
          if (dol['nivel_dolor_eva'] != null) _buildScreenEvaBar(dol['nivel_dolor_eva'].toString()),
          _buildScreenDataTable({
            AppTranslations.get('registration_form','pain_character_label',lang): dol['caracter'],
            AppTranslations.get('registration_form','pain_days_label',lang): dol['dias_dolor_critico'],
            AppTranslations.get('registration_form','treatment_label',lang): dol['tratamiento'],
            AppTranslations.get('registration_form','physical_symptoms_label',lang): dol['sintomas_fisicos'],
            AppTranslations.get('registration_form','emotional_symptoms_label',lang): dol['sintomas_emocionales'],
            AppTranslations.get('registration_form','breast_exam_label',lang): dol['autoexamen_mama'],
          }),
        ],

        // Section 5
        if (alertas.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildScreenSectionHeader(AppTranslations.get('profile_and_report','sec_alerts',lang)),
          ...alertas.map((a) => _buildScreenAlertRow(a['tipo']?.toString() ?? '', a['detalle']?.toString() ?? '')),
        ],

        SizedBox(height: 24),
        Text(meta['aviso']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 10, fontStyle: FontStyle.italic, color: BellotaColors.textoMedio)),
      ],
    );
  }

  Widget _buildScreenSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BellotaColors.chilero.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: BellotaColors.chilero, width: 3)),
      ),
      child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: BellotaColors.textoDark, fontSize: 13)),
    );
  }

  Widget _buildScreenDataTable(Map<String, dynamic> data) {
    final entries = data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
    if (entries.isEmpty) return SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: BellotaColors.nancite),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: entries.asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          return Container(
            decoration: BoxDecoration(
              color: isEven ? BellotaColors.nancite.withValues(alpha: 0.5) : Colors.white,
              borderRadius: entry.key == 0
                  ? BorderRadius.vertical(top: Radius.circular(8))
                  : entry.key == entries.length - 1
                      ? BorderRadius.vertical(bottom: Radius.circular(8))
                      : BorderRadius.zero,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Text(entry.value.key, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: BellotaColors.textoDark))),
                Expanded(flex: 3, child: Text(entry.value.value?.toString() ?? '-', style: GoogleFonts.poppins(fontSize: 11, color: BellotaColors.textoMedio))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScreenMetricCard(String title, String valor, String referencia, String estado) {
    final isNormal = estado.toLowerCase().contains('normal');
    final color = isNormal ? BellotaColors.chiltoma : BellotaColors.chilero;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 10, color: BellotaColors.textoMedio)),
          SizedBox(height: 4),
          Text(valor, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(referencia, style: GoogleFonts.poppins(fontSize: 9, color: BellotaColors.textoMedio)),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Text(estado, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenEvaBar(String evaString) {
    double value = 0;
    try {
      value = double.parse(evaString.split('/')[0]);
    } catch (_) {}
    final pct = value / 10.0;
    final color = pct >= 0.8 ? BellotaColors.chilero : pct >= 0.5 ? BellotaColors.melon : BellotaColors.chiltoma;
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('EVA', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: BellotaColors.textoDark)),
              Spacer(),
              Text(evaString, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: BellotaColors.nancite,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenAlertRow(String tipo, String detalle) {
    final isAlert = detalle.contains('Alerta') || detalle.contains('Alert') || tipo.contains('Alerta');
    final color = isAlert ? BellotaColors.chilero : BellotaColors.chiltoma;
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: color, size: 18),
          SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tipo, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: BellotaColors.textoDark)),
              Text(detalle, style: GoogleFonts.poppins(fontSize: 11, color: BellotaColors.textoMedio, height: 1.4)),
            ],
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = languageNotifier.currentLang;
    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      appBar: AppBar(
        title: Text(AppTranslations.get('profile_and_report','preview',lang), style: GoogleFonts.poppins(color: BellotaColors.textoDark, fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: BellotaColors.blanco,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: BellotaColors.textoDark),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: BellotaColors.melon.withValues(alpha:0.10), blurRadius: 20, offset: Offset(0, 6)),
                ],
              ),
              child: _buildReportContent(),
            ),
          ),
          if (_isExporting || _isPrinting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(child: CircularProgressIndicator(color: BellotaColors.chilero)),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: BellotaColors.blanco,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 12, offset: Offset(0,-4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_isExporting || _isPrinting) ? null : _printPdf,
                icon: Icon(Icons.print_rounded, size: 18),
                label: Text(AppTranslations.get('registration_form','print_pdf',lang)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BellotaColors.chilero,
                  side: BorderSide(color: BellotaColors.chilero),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (_isExporting || _isPrinting) ? null : _exportPdf,
                icon: Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text(AppTranslations.get('registration_form','share_pdf',lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BellotaColors.chilero,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
