import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/bellota_colors.dart';

class MedicalReportPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;
  final String filePath;

  const MedicalReportPreviewScreen({
    super.key,
    required this.reportData,
    required this.filePath,
  });

  @override
  State<MedicalReportPreviewScreen> createState() => _MedicalReportPreviewScreenState();
}

class _MedicalReportPreviewScreenState extends State<MedicalReportPreviewScreen> {
  bool _isExporting = false;

  void _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      
      // Load the logo image
      final ByteData imageBytes = await rootBundle.load('assets/images/logo_pdf.png');
      final Uint8List logoData = imageBytes.buffer.asUint8List();
      final pw.MemoryImage logoImage = pw.MemoryImage(logoData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (context) {
            return _buildPdfContent(widget.reportData, logoImage);
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'reporte_bellota.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar PDF: $e')));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- PDF GENERATION CONTENT ---
  List<pw.Widget> _buildPdfContent(Map<String, dynamic> data, pw.MemoryImage logoImage) {
    final meta = data['metadata'] as Map? ?? {};
    final gen = data['seccion_1_informacion_general'] as Map? ?? {};
    final res = data['seccion_2_resumen_estadistico'] as Map? ?? {};
    final pat = data['seccion_3_patron_sangrado_flujo'] as Map? ?? {};
    final dol = data['seccion_4_dolor_sintomatologia'] as Map? ?? {};
    final alertas = data['seccion_5_alertas_automaticas'] as List? ?? [];

    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Image(logoImage, height: 60),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('REPORTE DE SALUD', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFDE7B6B))),
              pw.Text('Reporte menstrual y clínico ginecológico', style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 16),
      
      _buildPdfSection('1. INFORMACIÓN GENERAL'),
      _buildPdfRow('Paciente:', gen['paciente']?.toString() ?? '-'),
      _buildPdfRow('Edad:', gen['edad']?.toString() ?? '-'),
      _buildPdfRow('FUM:', gen['fum']?.toString() ?? '-'),
      _buildPdfRow('Anticonceptivos:', gen['anticonceptivos_medicamentos']?.toString() ?? '-'),
      
      pw.SizedBox(height: 12),
      _buildPdfSection('2. RESUMEN ESTADÍSTICO'),
      if (res['promedio_ciclo'] != null)
        _buildPdfRow('Promedio del ciclo:', '${res['promedio_ciclo']['valor']} (${res['promedio_ciclo']['estado']})'),
      if (res['promedio_sangrado'] != null)
        _buildPdfRow('Promedio de sangrado:', '${res['promedio_sangrado']['valor']} (${res['promedio_sangrado']['estado']})'),
      _buildPdfRow('Flujo más frecuente:', res['flujo_mas_frecuente']?.toString() ?? '-'),
      
      if (pat.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _buildPdfSection('3. PATRÓN DE SANGRADO Y FLUJO'),
        for (var entry in pat.entries) _buildPdfRow(entry.key.toString().replaceAll('_', ' '), entry.value.toString()),
      ],
      
      if (dol.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _buildPdfSection('4. DOLOR Y SINTOMATOLOGÍA'),
        for (var entry in dol.entries) _buildPdfRow(entry.key.toString().replaceAll('_', ' '), entry.value.toString()),
      ],
      
      if (alertas.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _buildPdfSection('5. ALERTAS AUTOMÁTICAS PARA CONSULTA MÉDICA'),
        for (var alerta in alertas) _buildPdfRow(alerta['tipo']?.toString() ?? '', alerta['detalle']?.toString() ?? ''),
      ],
      
      pw.SizedBox(height: 24),
      pw.Divider(),
      pw.Text(meta['aviso']?.toString() ?? '', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF757575), fontStyle: pw.FontStyle.italic)),
    ];
  }

  pw.Widget _buildPdfSection(String title) {
    return pw.Container(
      color: PdfColor.fromInt(0xFFEFCDC8),
      width: double.infinity,
      padding: pw.EdgeInsets.all(6),
      margin: pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF5A5A5A))),
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 2, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
          pw.Expanded(flex: 3, child: pw.Text(value, style: pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  // --- UI RENDER (For screen and PNG export) ---
  Widget _buildReportContent({bool isExport = false}) {
    final data = widget.reportData;
    final meta = data['metadata'] as Map? ?? {};
    final gen = data['seccion_1_informacion_general'] as Map? ?? {};
    final res = data['seccion_2_resumen_estadistico'] as Map? ?? {};
    final pat = data['seccion_3_patron_sangrado_flujo'] as Map? ?? {};
    final dol = data['seccion_4_dolor_sintomatologia'] as Map? ?? {};
    final alertas = data['seccion_5_alertas_automaticas'] as List? ?? [];

    return Container(
      color: Colors.white,
      padding: isExport ? EdgeInsets.all(24) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset('assets/images/logo_color.png', height: 60, errorBuilder: (_,_,_) => Icon(Icons.favorite, color: BellotaColors.chilero, size: 40)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REPORTE DE SALUD', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: BellotaColors.chilero)),
                    Text('Reporte menstrual y clínico ginecológico', style: GoogleFonts.poppins(fontSize: 12, color: BellotaColors.textoMedio)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          _buildSectionHeader('1. INFORMACIÓN GENERAL'),
          _buildDataTable({
            'Paciente': gen['paciente'],
            'Edad': gen['edad'],
            'Rango analizado': gen['rango_analizado'],
            'Anticonceptivos': gen['anticonceptivos_medicamentos'],
            'FUM': gen['fum'],
          }),

          SizedBox(height: 16),
          _buildSectionHeader('2. RESUMEN ESTADÍSTICO'),
          _buildDataTable({
            'Promedio del ciclo': res['promedio_ciclo'] != null ? '${res['promedio_ciclo']['valor']} (${res['promedio_ciclo']['estado']})' : null,
            'Promedio de sangrado': res['promedio_sangrado'] != null ? '${res['promedio_sangrado']['valor']} (${res['promedio_sangrado']['estado']})' : null,
            'Flujo más frecuente': res['flujo_mas_frecuente'],
          }),

          if (pat.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildSectionHeader('3. PATRÓN DE SANGRADO Y FLUJO'),
            _buildDataTable(pat.map((k, v) => MapEntry(k.replaceAll('_', ' '), v))),
          ],

          if (dol.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildSectionHeader('4. DOLOR Y SINTOMATOLOGÍA ACOMPAÑANTE'),
            _buildDataTable(dol.map((k, v) => MapEntry(k.replaceAll('_', ' '), v))),
          ],

          if (alertas.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildSectionHeader('5. ALERTAS AUTOMÁTICAS PARA CONSULTA MÉDICA'),
            Container(
              decoration: BoxDecoration(border: Border.all(color: BellotaColors.melon.withValues(alpha: 0.5))),
              child: Column(
                children: alertas.map((a) => Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Text(a['tipo']?.toString() ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text(a['detalle']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 12))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          
          SizedBox(height: 32),
          Text(meta['aviso']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 10, fontStyle: FontStyle.italic, color: BellotaColors.textoMedio)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: BellotaColors.melon.withValues(alpha: 0.3),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.only(bottom: 8),
      child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: BellotaColors.textoDark, fontSize: 14)),
    );
  }

  Widget _buildDataTable(Map<String, dynamic> data) {
    final entries = data.entries.where((e) => e.value != null).toList();
    return Container(
      decoration: BoxDecoration(border: Border.all(color: BellotaColors.melon.withValues(alpha: 0.5))),
      child: Column(
        children: entries.map((e) {
          final isEven = entries.indexOf(e) % 2 == 0;
          return Container(
            color: isEven ? Colors.white : Colors.grey.withValues(alpha: 0.05),
            padding: EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Text(e.key, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Text(e.value.toString(), style: GoogleFonts.poppins(fontSize: 12))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Vista Previa', style: GoogleFonts.poppins(color: BellotaColors.textoDark, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: BellotaColors.textoDark),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: _buildReportContent(isExport: false),
          ),
          if (_isExporting)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(child: CircularProgressIndicator(color: BellotaColors.chilero)),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportPdf,
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text('Guardar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BellotaColors.chilero,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ),
    );
  }
}
