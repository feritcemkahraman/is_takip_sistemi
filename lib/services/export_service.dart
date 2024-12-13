import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:csv/csv.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/report_model.dart';
import '../models/workflow_model.dart';
import 'package:intl/intl.dart';

class ExportService {
  // PDF formatında dışa aktarma
  Future<ExportResult> exportToPdf(List<dynamic> items, String type) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // Başlık ve tarih
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Rapor',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Oluşturulma Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              _buildPdfContent(items, type),
            ],
          ),
        ),
      );

      // PDF dosyasını kaydet
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/rapor_${now.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      return ExportResult(
        success: true,
        filePath: file.path,
        message: 'PDF dosyası başarıyla oluşturuldu',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'PDF oluşturma hatası: $e',
      );
    }
  }

  // Excel formatında dışa aktarma
  Future<ExportResult> exportToExcel(List<dynamic> items, String type) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sayfa1'];
      final now = DateTime.now();

      // Başlıklar
      final headers = _getExcelHeaders(type);
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = headers[i]
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }

      // Veriler
      final data = _getExcelData(items, type);
      for (var i = 0; i < data.length; i++) {
        final row = data[i];
        for (var j = 0; j < row.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
            ..value = row[j];
        }
      }

      // Excel dosyasını kaydet
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/rapor_${now.millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);

      return ExportResult(
        success: true,
        filePath: file.path,
        message: 'Excel dosyası başarıyla oluşturuldu',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Excel oluşturma hatası: $e',
      );
    }
  }

  // Görevleri dışa aktar
  Future<ExportResult> exportTasks(List<TaskModel> tasks, String format) async {
    try {
      switch (format.toLowerCase()) {
        case 'pdf':
          return await exportToPdf(tasks, 'task');
        case 'excel':
          return await exportToExcel(tasks, 'task');
        default:
          throw Exception('Desteklenmeyen format: $format');
      }
    } catch (e) {
      print('Görev dışa aktarma hatası: $e');
      rethrow;
    }
  }

  // Toplantıları dışa aktar
  Future<ExportResult> exportMeetings(
    List<MeetingModel> meetings,
    String format,
  ) async {
    try {
      final now = DateTime.now();
      final fileName = 'meetings_${now.millisecondsSinceEpoch}.$format';
      final filePath = await getTemporaryDirectory().then((value) => '${value.path}/$fileName');

      if (format == 'xlsx') {
        final excel = Excel.createExcel();
        final sheet = excel['Toplantılar'];

        // Başlık satırı
        sheet.appendRow([
          'Başlık',
          'Açıklama',
          'Başlangıç',
          'Bitiş',
          'Platform',
          'Toplantı URL',
          'Organizatör',
          'Katılımcılar',
        ]);

        // Toplantı verileri
        for (final meeting in meetings) {
          sheet.appendRow([
            meeting.title,
            meeting.description,
            DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime),
            DateFormat('dd/MM/yyyy HH:mm').format(meeting.endTime),
            meeting.platform,
            meeting.meetingUrl,
            meeting.organizer,
            meeting.participants.join(', '),
          ]);
        }

        // Excel dosyasını kaydet
        final excelBytes = excel.encode();
        if (excelBytes == null) {
          throw Exception('Excel dosyası oluşturulamadı');
        }

        await File(filePath).writeAsBytes(excelBytes);
      } else if (format == 'csv') {
        final csv = [
          [
            'Başlık',
            'Açıklama',
            'Başlangıç',
            'Bitiş',
            'Platform',
            'Toplantı URL',
            'Organizatör',
            'Katılımcılar',
          ],
          ...meetings.map((meeting) => [
                meeting.title,
                meeting.description,
                DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime),
                DateFormat('dd/MM/yyyy HH:mm').format(meeting.endTime),
                meeting.platform,
                meeting.meetingUrl,
                meeting.organizer,
                meeting.participants.join(', '),
              ]),
        ];

        final csvString = const ListToCsvConverter().convert(csv);
        await File(filePath).writeAsString(csvString);
      } else {
        throw Exception('Desteklenmeyen dosya formatı: $format');
      }

      return ExportResult(
        success: true,
        filePath: filePath,
        message: 'Toplantılar başarıyla dışa aktarıldı.',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Toplantılar dışa aktarılırken hata oluştu: $e',
      );
    }
  }

  // PDF içeriği oluşturma
  pw.Widget _buildPdfContent(List<dynamic> items, String type) {
    switch (type) {
      case 'task':
        return _buildTasksPdfContent(items.cast<TaskModel>());
      case 'meeting':
        return _buildMeetingsPdfContent(items.cast<MeetingModel>());
      case 'workflow':
        return _buildWorkflowsPdfContent(items.cast<WorkflowModel>());
      default:
        return pw.Container();
    }
  }

  // Görevler için PDF içeriği
  pw.Widget _buildTasksPdfContent(List<TaskModel> tasks) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Başlık satırı
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildPdfCell('ID', header: true),
            _buildPdfCell('Başlık', header: true),
            _buildPdfCell('Atanan', header: true),
            _buildPdfCell('Durum', header: true),
            _buildPdfCell('Termin', header: true),
          ],
        ),
        // Veri satırları
        ...tasks.map(
          (task) => pw.TableRow(
            children: [
              _buildPdfCell(task.id),
              _buildPdfCell(task.title),
              _buildPdfCell(task.assignedTo),
              _buildPdfCell(task.status),
              _buildPdfCell(
                DateFormat('dd/MM/yyyy').format(task.dueDate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Toplantılar için PDF içeriği
  pw.Widget _buildMeetingsPdfContent(List<MeetingModel> meetings) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Başlık satırı
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildPdfCell('ID', header: true),
            _buildPdfCell('Başlık', header: true),
            _buildPdfCell('Organizatör', header: true),
            _buildPdfCell('Durum', header: true),
            _buildPdfCell('Tarih', header: true),
          ],
        ),
        // Veri satırları
        ...meetings.map(
          (meeting) => pw.TableRow(
            children: [
              _buildPdfCell(meeting.id),
              _buildPdfCell(meeting.title),
              _buildPdfCell(meeting.organizerId),
              _buildPdfCell(meeting.meetingStatus),
              _buildPdfCell(
                DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // İş akışları için PDF içeriği
  pw.Widget _buildWorkflowsPdfContent(List<WorkflowModel> workflows) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Başlık satırı
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildPdfCell('ID', header: true),
            _buildPdfCell('Başlık', header: true),
            _buildPdfCell('Oluşturan', header: true),
            _buildPdfCell('Durum', header: true),
            _buildPdfCell('Termin', header: true),
          ],
        ),
        // Veri satırları
        ...workflows.map(
          (workflow) => pw.TableRow(
            children: [
              _buildPdfCell(workflow.id),
              _buildPdfCell(workflow.title),
              _buildPdfCell(workflow.createdBy),
              _buildPdfCell(workflow.status),
              _buildPdfCell(
                DateFormat('dd/MM/yyyy').format(workflow.deadline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PDF hücre oluşturma
  pw.Widget _buildPdfCell(String text, {bool header = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: header ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  // Excel başlıkları
  List<String> _getExcelHeaders(String type) {
    switch (type) {
      case 'task':
        return ['ID', 'Başlık', 'Atanan', 'Durum', 'Termin'];
      case 'meeting':
        return ['ID', 'Başlık', 'Organizatör', 'Durum', 'Tarih'];
      case 'workflow':
        return ['ID', 'Başlık', 'Oluşturan', 'Durum', 'Termin'];
      default:
        return [];
    }
  }

  // Görevler için Excel verileri
  List<List<String>> _getTaskExcelData(List<TaskModel> tasks) {
    return tasks.map((task) => [
      task.id,
      task.title,
      task.assignedTo,
      task.status,
      DateFormat('dd/MM/yyyy').format(task.dueDate),
    ]).toList();
  }

  // Toplantılar için Excel verileri
  List<List<String>> _getMeetingExcelData(List<MeetingModel> meetings) {
    return meetings.map((meeting) => [
      meeting.id,
      meeting.title,
      meeting.organizerId,
      meeting.meetingStatus,
      DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime),
    ]).toList();
  }

  // İş akışları için Excel verileri
  List<List<String>> _getWorkflowExcelData(List<WorkflowModel> workflows) {
    return workflows.map((workflow) => [
      workflow.id,
      workflow.title,
      workflow.createdBy,
      workflow.status,
      DateFormat('dd/MM/yyyy').format(workflow.deadline),
    ]).toList();
  }

  // Excel verileri
  List<List<String>> _getExcelData(List<dynamic> items, String type) {
    switch (type) {
      case 'task':
        return _getTaskExcelData(items.cast<TaskModel>());
      case 'meeting':
        return _getMeetingExcelData(items.cast<MeetingModel>());
      case 'workflow':
        return _getWorkflowExcelData(items.cast<WorkflowModel>());
      default:
        return [];
    }
  }

  // Dosya paylaşma
  Future<void> shareFile(String filePath, String subject) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
      );
    } catch (e) {
      print('Dosya paylaşma hatası: $e');
      rethrow;
    }
  }
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String message;

  ExportResult({
    required this.success,
    this.filePath,
    required this.message,
  });
}