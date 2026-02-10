import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:absensi_greenliving/models/user_models.dart';

class ExcelService {

  Future<void> exportAttendanceMatrix(
    String fileName, 
    List<UserModel> employees,
    Map<String, Map<String, dynamic>> dataMap, 
    DateTime startDate,
    DateTime endDate
  ) async {
    var excel = Excel.createExcel();
    String sheetName = "Laporan_Absensi";
    Sheet sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // STYLE
    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString("#1B5E20"),
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    // HEADER TANGGAL
    List<String> fullDates = [];
    int daysCount = endDate.difference(startDate).inDays;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue("No")..cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
      ..value = TextCellValue("Nama Pegawai")..cellStyle = headerStyle;

    for (int i = 0; i <= daysCount; i++) {
      DateTime d = startDate.add(Duration(days: i));
      fullDates.add(DateFormat('yyyy-MM-dd').format(d));
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: 0));
      cell.value = TextCellValue(DateFormat('dd').format(d));
      cell.cellStyle = headerStyle;
    }

    // ISI DATA
    int rowIndex = 1;
    for (var emp in employees) {
      // Kolom No & Nama
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = IntCellValue(rowIndex)..cellStyle = centerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = TextCellValue(emp.name)
        ..cellStyle = CellStyle(verticalAlign: VerticalAlign.Center, horizontalAlign: HorizontalAlign.Left);

      // Loop Tanggal
      for (int i = 0; i < fullDates.length; i++) {
        String dateKey = fullDates[i];
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: rowIndex));
        var cellData = dataMap[emp.uid]?[dateKey];

        String text = "-";
        ExcelColor bgColor = ExcelColor.white;
        ExcelColor fontColor = ExcelColor.black; // Default Hitam

        if (cellData != null) {
          String type = cellData['type'];
          String value = cellData['value'].toString();
          
          // Ambil nama shift (lowercase)
          String shiftName = (cellData['shift'] ?? "").toString().toLowerCase();

          // --- KASUS 1: Cuma Jadwal ---
          if (type == 'schedule') {
            if (value == 'Libur') {
              text = "Libur";
              bgColor = ExcelColor.fromHexString("#EEEEEE"); // Abu-abu
            } else {
              text = "-";
              bgColor = ExcelColor.fromHexString("#FFCDD2"); // Merah Muda (Alpha)
            }
          } 
          // --- KASUS 2: Data Absen Masuk ---
          else if (type == 'attendance') {
            String time = value;
            String status = cellData['status'] ?? 'Hadir';
            
            // 🔥 FORMAT TEKS: SELALU "Hadir (Jam)"
            // Gak ada lagi tulisan "Terlambat" di sel
            text = "Hadir\n($time)";

            // 🔥 LOGIC WARNA FONT: MERAH KALAU TELAT
            if (status.toLowerCase().contains('terlambat') || status.toLowerCase().contains('late')) {
              fontColor = ExcelColor.red; 
            }

            // 🔥 LOGIC BACKGROUND SHIFT
            if (shiftName.contains('pagi')) {
              bgColor = ExcelColor.fromHexString("#FFF59D"); // Kuning
            } else if (shiftName.contains('siang')) {
              bgColor = ExcelColor.fromHexString("#A5D6A7"); // Hijau
            } else if (shiftName.contains('malam')) {
              bgColor = ExcelColor.fromHexString("#90CAF9"); // Biru
            } else if (shiftName.contains('libur')) {
              bgColor = ExcelColor.fromHexString("#EEEEEE"); 
            } else {
              bgColor = ExcelColor.white; 
            }
          }
        }

        cell.value = TextCellValue(text);
        cell.cellStyle = CellStyle(
          backgroundColorHex: bgColor,
          fontColorHex: fontColor, // Merah kalau telat, Hitam kalau tepat
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          textWrapping: TextWrapping.WrapText,
          fontSize: 10,
          // Bold kalau telat biar makin kelihatan (Opsional, hapus baris ini kalau gak mau)
          bold: fontColor == ExcelColor.red ? true : false, 
        );
      }
      rowIndex++;
    }

    // LEGENDA WARNA (Footer)
    int lRow = rowIndex + 2;
    _writeLegend(sheet, lRow, "Shift Pagi (Kuning)", ExcelColor.fromHexString("#FFF59D"));
    _writeLegend(sheet, lRow + 1, "Shift Siang (Hijau)", ExcelColor.fromHexString("#A5D6A7"));
    _writeLegend(sheet, lRow + 2, "Shift Malam (Biru)", ExcelColor.fromHexString("#90CAF9"));
    _writeLegend(sheet, lRow + 3, "Tidak Hadir (Merah Muda)", ExcelColor.fromHexString("#FFCDD2"));
    _writeLegend(sheet, lRow + 4, "Libur (Abu-abu)", ExcelColor.fromHexString("#EEEEEE"));
    
    // Note Text Color
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: lRow + 5))
      ..value = TextCellValue("Catatan: Jam warna MERAH artinya TERLAMBAT") // Update Catatan
      ..cellStyle = CellStyle(fontColorHex: ExcelColor.red, bold: true);

    await _saveAndOpenFile(excel, fileName);
  }

  void _writeLegend(Sheet sheet, int row, String label, ExcelColor color) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
      ..value = TextCellValue("   ")
      ..cellStyle = CellStyle(backgroundColorHex: color);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
      ..value = TextCellValue(label);
  }

  Future<void> _saveAndOpenFile(Excel excel, String fileName) async {
    String filePath;
    String safeName = fileName.replaceAll(RegExp(r'[^\w\s]+'), ''); 

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory(); 
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    directory ??= await getApplicationDocumentsDirectory();
    
    filePath = "${directory.path}/$safeName.xlsx";
    File file = File(filePath);

    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      file.writeAsBytesSync(excel.save()!);
      OpenFile.open(filePath);
    } catch (e) {
      print("Gagal save file: $e");
      rethrow; 
    }
  }
}