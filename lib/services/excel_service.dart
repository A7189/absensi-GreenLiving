import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xcel; 
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:absensi_greenliving/models/user_models.dart';

class ExcelService {

  Future<void> exportAttendanceSplit(
    String fileName, 
    List<UserModel> employees,
    Map<String, Map<String, dynamic>> dataMap, 
    DateTime startDate,
    DateTime endDate
  ) async {
    
    final xcel.Workbook workbook = xcel.Workbook();
    String periodStr = "${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}";

    var securityList = employees.where((e) => e.role.toLowerCase().contains('security') || e.role.toLowerCase().contains('satpam')).toList();
    var cleanerList = employees.where((e) => e.role.toLowerCase().contains('cleaner') || e.role.toLowerCase().contains('kebersihan') || e.role.toLowerCase().contains('sapu') || e.role.toLowerCase().contains('taman') || e.role.toLowerCase().contains('sampah')).toList();

    // SHEET 1: SATPAM
    final xcel.Worksheet sheet1 = workbook.worksheets[0];
    sheet1.name = "Laporan Satpam";
    _populateSheet(workbook, sheet1, "Laporan Satpam", securityList, dataMap, startDate, endDate, periodStr);

    // SHEET 2: KEBERSIHAN
    final xcel.Worksheet sheet2 = workbook.worksheets.addWithName("Laporan Kebersihan");
    _populateSheet(workbook, sheet2, "Laporan Kebersihan", cleanerList, dataMap, startDate, endDate, periodStr);

    await _saveAndOpenFile(workbook, fileName);
  }

  void _populateSheet(
    xcel.Workbook workbook,
    xcel.Worksheet sheet, 
    String title, 
    List<UserModel> roleEmployees, 
    Map<String, Map<String, dynamic>> dataMap,
    DateTime startDate,
    DateTime endDate,
    String periodStr
  ) {
    
    sheet.showGridlines = false; // Gridlines mati biar bersih

    // --- STYLE ---
    // Header (Hijau)
    final xcel.Style headerStyle = workbook.styles.add('HeaderStyle_${sheet.name}');
    headerStyle.backColor = '#1B5E20'; 
    headerStyle.fontColor = '#FFFFFF'; 
    headerStyle.bold = true;
    headerStyle.hAlign = xcel.HAlignType.center;
    headerStyle.vAlign = xcel.VAlignType.center;
    headerStyle.borders.all.lineStyle = xcel.LineStyle.thin; 
    headerStyle.borders.all.color = '#FFFFFF';

    // Data Tengah
    final xcel.Style dataStyle = workbook.styles.add('DataStyle_${sheet.name}');
    dataStyle.hAlign = xcel.HAlignType.center;
    dataStyle.vAlign = xcel.VAlignType.center;
    dataStyle.borders.all.lineStyle = xcel.LineStyle.thin; 
    dataStyle.borders.all.color = '#D3D3D3'; 

    // Nama (Kiri)
    final xcel.Style nameStyle = workbook.styles.add('NameStyle_${sheet.name}');
    nameStyle.hAlign = xcel.HAlignType.left;
    nameStyle.vAlign = xcel.VAlignType.center;
    nameStyle.borders.all.lineStyle = xcel.LineStyle.thin;
    nameStyle.borders.all.color = '#D3D3D3';

    // Merah (Telat/Tanpa Keterangan)
    final xcel.Style redStyle = workbook.styles.add('RedStyle_${sheet.name}');
    redStyle.fontColor = '#FF0000'; 
    redStyle.bold = true;
    redStyle.hAlign = xcel.HAlignType.center;
    redStyle.vAlign = xcel.VAlignType.center;
    redStyle.borders.all.lineStyle = xcel.LineStyle.thin;
    redStyle.borders.all.color = '#D3D3D3';

    // Kuning / Biru (Untuk Izin)
    final xcel.Style permitStyle = workbook.styles.add('PermitStyle_${sheet.name}');
    permitStyle.fontColor = '#E65100'; // Oranye biar beda
    permitStyle.bold = true;
    permitStyle.hAlign = xcel.HAlignType.center;
    permitStyle.vAlign = xcel.VAlignType.center;
    permitStyle.borders.all.lineStyle = xcel.LineStyle.thin;
    permitStyle.borders.all.color = '#D3D3D3';


    // --- KOP JUDUL ---
    sheet.getRangeByIndex(1, 1).setText(title.toUpperCase());
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 14;
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#1B5E20';
    sheet.getRangeByIndex(2, 1).setText("Periode: $periodStr");
    sheet.getRangeByIndex(2, 1).cellStyle.italic = true;

    // --- HEADER TABEL ---
    List<String> columns = ['Tanggal', 'Nama Pegawai', 'Shift', 'Masuk', 'Keluar', 'Keterangan'];
    for (int i = 0; i < columns.length; i++) {
      final xcel.Range range = sheet.getRangeByIndex(4, i + 1);
      range.setText(columns[i]);
      range.cellStyle = headerStyle;
    }

    // --- ISI DATA ---
    int rowIdx = 5;
    int daysCount = endDate.difference(startDate).inDays;

    for (int i = 0; i <= daysCount; i++) {
      DateTime d = startDate.add(Duration(days: i));
      String dateKey = DateFormat('yyyy-MM-dd').format(d);
      String dateDisplay = DateFormat('dd/MM/yyyy').format(d);

      for (var emp in roleEmployees) {
        var cellData = dataMap[emp.uid]?[dateKey];
        
        if (cellData != null) {
          bool showRow = false;
          String shift = "-";
          String inTime = "-";
          String outTime = "-";
          String status = "-";
          xcel.Style rowStyle = dataStyle; // Default style

          // 1. DATA ABSENSI (Hadir)
          if (cellData['type'] == 'attendance') {
            showRow = true;
            shift = cellData['shift'] ?? '-';
            inTime = cellData['in'].toString();
            outTime = cellData['out'].toString();
            status = cellData['status'] ?? '-';
            
            if (status.toLowerCase().contains('terlambat')) {
              rowStyle = redStyle;
            }
          } 
          // 2. DATA IZIN (Sakit/Cuti)
          else if (cellData['type'] == 'permission') {
            showRow = true;
            shift = "-"; // Shift dikosongin atau strip
            inTime = "IZIN"; // Indikator visual
            outTime = "IZIN";
            // Format: "Sakit (Demam)" atau "Cuti (Nikahan)"
            status = "${cellData['value']} (${cellData['reason']})";
            rowStyle = permitStyle; // Pake warna oranye
          }
          // 3. JADWAL (Tapi gak absen)
          else if (cellData['type'] == 'schedule' && cellData['value'].toString().toLowerCase() != 'libur') {
            showRow = true;
            shift = cellData['value'].toString();
            status = "Tanpa Keterangan";
            rowStyle = redStyle;
          }

          if (showRow) {
            sheet.getRangeByIndex(rowIdx, 1).setText(dateDisplay);
            sheet.getRangeByIndex(rowIdx, 1).cellStyle = dataStyle;

            sheet.getRangeByIndex(rowIdx, 2).setText(emp.name);
            sheet.getRangeByIndex(rowIdx, 2).cellStyle = nameStyle;

            sheet.getRangeByIndex(rowIdx, 3).setText(shift);
            sheet.getRangeByIndex(rowIdx, 3).cellStyle = dataStyle;

            sheet.getRangeByIndex(rowIdx, 4).setText(inTime);
            sheet.getRangeByIndex(rowIdx, 4).cellStyle = dataStyle;

            sheet.getRangeByIndex(rowIdx, 5).setText(outTime);
            sheet.getRangeByIndex(rowIdx, 5).cellStyle = dataStyle;

            // Keterangan
            final xcel.Range statusCell = sheet.getRangeByIndex(rowIdx, 6);
            statusCell.setText(status);
            statusCell.cellStyle = rowStyle; // Style ngikutin kondisi (Merah/Oranye/Hitam)

            rowIdx++;
          }
        }
      }
    }

    // 🔥 FIX AUTO FIT (Dijejalin per kolom khusus di area tabel biar pasti melebar rapi)
    if (rowIdx > 4) {
      for (int c = 1; c <= 6; c++) {
        sheet.getRangeByIndex(4, c, rowIdx - 1, c).autoFitColumns();
      }
    }
  }

  Future<void> _saveAndOpenFile(xcel.Workbook workbook, String fileName) async {
    String safeName = fileName.replaceAll(RegExp(r'[^\w\s\-\(\)\.]'), ''); 
    if (!safeName.endsWith('.xlsx')) safeName += '.xlsx';

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory(); 
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    directory ??= await getApplicationDocumentsDirectory();
    
    String filePath = "${directory.path}/$safeName";
    final List<int> bytes = workbook.saveAsStream();
    File file = File(filePath);
    try {
        if (!await directory.exists()) await directory.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
        workbook.dispose();
        OpenFile.open(filePath);
    } catch (e) {
        print("Gagal save file: $e");
    }
  }
}