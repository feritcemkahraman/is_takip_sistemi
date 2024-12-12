import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/report_model.dart';
import '../models/meeting_report_model.dart';
import '../constants/app_constants.dart';

class ExportService {
  // PDF Oluşturma
  Future<File> createPDF({
    required String title,
    required String description,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    Map<String, double>? columnWidths,
    List<Map<String, dynamic>>? charts,
  }) async {
    final pdf = pw.Document();

    // Başlık ve açıklama
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Paragraph(text: description),
          pw.SizedBox(height: 20),
          if (data.isNotEmpty)
            pw.Table.fromTextArray(
              context: context,
              headers: columns,
              data: data.map((row) {
                return columns.map((col) => row[col]?.toString() ?? '').toList();
              }).toList(),
              columnWidths: columnWidths,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: pw.EdgeInsets.all(5),
            ),
          if (charts != null && charts.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            ...charts.map((chart) {
              // Grafik verilerini PDF'e ekle
              return pw.Container(
                height: 200,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis([0, 1, 2, 3, 4, 5]),
                    yAxis: pw.FixedAxis([0, 20, 40, 60, 80, 100]),
                  ),
                  datasets: [
                    pw.LineDataSet(
                      data: List<pw.PointChartValue>.from(
                        chart['data'].map(
                          (point) => pw.PointChartValue(
                            point['x'].toDouble(),
                            point['y'].toDouble(),
                          ),
                        ),
                      ),
                      legend: chart['title'],
                      drawPoints: true,
                      isCurved: true,
                      color: PdfColors.blue,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );

    // PDF dosyasını kaydet
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/${title.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Excel Oluşturma
  Future<File> createExcel({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    Map<String, String>? columnTitles,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[title];

    // Başlıkları ekle
    for (var i = 0; i < columns.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = columnTitles?[columns[i]] ?? columns[i];
    }

    // Verileri ekle
    for (var i = 0; i < data.length; i++) {
      for (var j = 0; j < columns.length; j++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
            .value = data[i][columns[j]]?.toString() ?? '';
      }
    }

    // Excel dosyasını kaydet
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/${title.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  // Görev listesini dışa aktar
  Future<void> exportTasks(List<TaskModel> tasks, String format) async {
    try {
      if (tasks.isEmpty) {
        throw Exception('Dışa aktarılacak görev bulunamadı');
      }

      final data = tasks.map((task) {
        return {
          'title': task.title,
          'description': task.description,
          'status': AppConstants.statusLabels[task.status],
          'priority': AppConstants.priorityLabels[task.priority],
          'assignedTo': task.assignedTo,
          'dueDate': DateFormat('dd/MM/yyyy').format(task.dueDate),
          'createdAt': DateFormat('dd/MM/yyyy').format(task.createdAt),
        };
      }).toList();

      final columns = [
        'title',
        'description',
        'status',
        'priority',
        'assignedTo',
        'dueDate',
        'createdAt',
      ];

      final columnTitles = {
        'title': 'Başlık',
        'description': 'Açıklama',
        'status': 'Durum',
        'priority': 'Öncelik',
        'assignedTo': 'Atanan Kişi',
        'dueDate': 'Bitiş Tarihi',
        'createdAt': 'Oluşturma Tarihi',
      };

      File file;
      if (format == 'pdf') {
        file = await createPDF(
          title: 'Görev Listesi',
          description: 'Toplam ${tasks.length} görev',
          data: data,
          columns: columns,
          columnWidths: {
            0: 0.2,
            1: 0.3,
            2: 0.1,
            3: 0.1,
            4: 0.1,
            5: 0.1,
            6: 0.1,
          },
        );
      } else {
        file = await createExcel(
          title: 'Görevler',
          data: data,
          columns: columns,
          columnTitles: columnTitles,
        );
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Görev Listesi',
      );
    } catch (e) {
    final data = tasks.map((task) {
      return {
        'title': task.title,
        'description': task.description,
        'status': AppConstants.statusLabels[task.status],
        'priority': AppConstants.priorityLabels[task.priority],
        'assignedTo': task.assignedTo,
        'dueDate': DateFormat('dd/MM/yyyy').format(task.dueDate),
        'createdAt': DateFormat('dd/MM/yyyy').format(task.createdAt),
      };
    }).toList();

    final columns = [
      'title',
      'description',
      'status',
      'priority',
      'assignedTo',
      'dueDate',
      'createdAt',
    ];

    final columnTitles = {
      'title': 'Başlık',
      'description': 'Açıklama',
      'status': 'Durum',
      'priority': 'Öncelik',
      'assignedTo': 'Atanan Kişi',
      'dueDate': 'Bitiş Tarihi',
      'createdAt': 'Oluşturma Tarihi',
    };

    File file;
    if (format == 'pdf') {
      file = await createPDF(
        title: 'Görev Listesi',
        description: 'Toplam ${tasks.length} görev',
        data: data,
        columns: columns,
        columnWidths: {
          0: 0.2,
          1: 0.3,
          2: 0.1,
          3: 0.1,
          4: 0.1,
          5: 0.1,
          6: 0.1,
        },
      );
    } else {
      file = await createExcel(
        title: 'Görevler',
        data: data,
        columns: columns,
        columnTitles: columnTitles,
      );
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Görev Listesi',
    );
  }

  // Toplantı listesini dışa aktar
  Future<void> exportMeetings(List<MeetingModel> meetings, String format) async {
    final data = meetings.map((meeting) {
      return {
        'title': meeting.title,
        'description': meeting.description,
        'status': AppConstants.statusLabels[meeting.status],
        'startTime': DateFormat('dd/MM/yyyy HH:mm').format(meeting.startTime),
        'endTime': DateFormat('dd/MM/yyyy HH:mm').format(meeting.endTime),
        'location': meeting.isOnline
            ? '${meeting.meetingPlatform} (Online)'
            : meeting.location,
        'organizer': meeting.organizerId,
      };
    }).toList();

    final columns = [
      'title',
      'description',
      'status',
      'startTime',
      'endTime',
      'location',
      'organizer',
    ];

    final columnTitles = {
      'title': 'Başlık',
      'description': 'Açıklama',
      'status': 'Durum',
      'startTime': 'Başlangıç',
      'endTime': 'Bitiş',
      'location': 'Konum',
      'organizer': 'Organizatör',
    };

    File file;
    if (format == 'pdf') {
      file = await createPDF(
        title: 'Toplantı Listesi',
        description: 'Toplam ${meetings.length} toplantı',
        data: data,
        columns: columns,
        columnWidths: {
          0: 0.2,
          1: 0.3,
          2: 0.1,
          3: 0.1,
          4: 0.1,
          5: 0.1,
          6: 0.1,
        },
      );
    } else {
      file = await createExcel(
        title: 'Toplantılar',
        data: data,
        columns: columns,
        columnTitles: columnTitles,
      );
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Toplantı Listesi',
    );
  }

  // Raporu dışa aktar
  Future<void> exportReport(ReportModel report, String format) async {
    final data = [
      {
        'totalTasks': report.getTotalTasks(),
        'completedTasks': report.getCompletedTasks(),
        'overdueTasks': report.getOverdueTasks(),
        'completionRate': '${(report.getCompletionRate() * 100).toStringAsFixed(1)}%',
        'averageCompletionTime': '${report.getAverageTaskCompletionTime().toStringAsFixed(1)} gün',
      }
    ];

    final columns = [
      'totalTasks',
      'completedTasks',
      'overdueTasks',
      'completionRate',
      'averageCompletionTime',
    ];

    final columnTitles = {
      'totalTasks': 'Toplam Görev',
      'completedTasks': 'Tamamlanan',
      'overdueTasks': 'Geciken',
      'completionRate': 'Tamamlanma Oranı',
      'averageCompletionTime': 'Ortalama Süre',
    };

    // Grafik verileri
    final charts = [
      {
        'title': 'Görev Durumları',
        'data': report.getTaskStatusDistribution().entries.map((e) {
          return {
            'x': e.key,
            'y': e.value,
          };
        }).toList(),
      },
      {
        'title': 'Departman Performansı',
        'data': report.getDepartmentPerformance().entries.map((e) {
          return {
            'x': e.key,
            'y': e.value,
          };
        }).toList(),
      },
    ];

    File file;
    if (format == 'pdf') {
      file = await createPDF(
        title: report.title,
        description:
            '${DateFormat('dd/MM/yyyy').format(report.startDate)} - ${DateFormat('dd/MM/yyyy').format(report.endDate)}',
        data: data,
        columns: columns,
        charts: charts,
      );
    } else {
      file = await createExcel(
        title: report.title,
        data: data,
        columns: columns,
        columnTitles: columnTitles,
      );
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: report.title,
    );
  }

  // Toplantı raporunu dışa aktar
  Future<void> exportMeetingReport(
    MeetingReportModel report,
    String format,
  ) async {
    final data = [
      {
        'totalMeetings': report.getTotalMeetings(),
        'completedMeetings': report.getCompletedMeetings(),
        'cancelledMeetings': report.getCancelledMeetings(),
        'attendanceRate': '${(report.getMeetingAttendanceRate() * 100).toStringAsFixed(1)}%',
        'averageDuration': '${report.getAverageMeetingDuration().toStringAsFixed(1)} saat',
        'totalDecisions': report.getTotalDecisions(),
        'completedDecisions': report.getCompletedDecisions(),
        'decisionCompletionRate':
            '${(report.getDecisionCompletionRate() * 100).toStringAsFixed(1)}%',
      }
    ];

    final columns = [
      'totalMeetings',
      'completedMeetings',
      'cancelledMeetings',
      'attendanceRate',
      'averageDuration',
      'totalDecisions',
      'completedDecisions',
      'decisionCompletionRate',
    ];

    final columnTitles = {
      'totalMeetings': 'Toplam Toplantı',
      'completedMeetings': 'Tamamlanan',
      'cancelledMeetings': 'İptal Edilen',
      'attendanceRate': 'Katılım Oranı',
      'averageDuration': 'Ortalama Süre',
      'totalDecisions': 'Toplam Karar',
      'completedDecisions': 'Tamamlanan Karar',
      'decisionCompletionRate': 'Karar Tamamlanma Oranı',
    };

    // Grafik verileri
    final charts = [
      {
        'title': 'Toplantı Durumları',
        'data': report.getMeetingStatusDistribution().entries.map((e) {
          return {
            'x': e.key,
            'y': e.value,
          };
        }).toList(),
      },
      {
        'title': 'Departman Katılımı',
        'data': report.getDepartmentParticipation().entries.map((e) {
          return {
            'x': e.key,
            'y': e.value,
          };
        }).toList(),
      },
    ];

    File file;
    if (format == 'pdf') {
      file = await createPDF(
        title: report.title,
        description:
            '${DateFormat('dd/MM/yyyy').format(report.startDate)} - ${DateFormat('dd/MM/yyyy').format(report.endDate)}',
        data: data,
        columns: columns,
        charts: charts,
      );
    } else {
      file = await createExcel(
        title: report.title,
        data: data,
        columns: columns,
        columnTitles: columnTitles,
      );
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: report.title,
    );
  }
} 