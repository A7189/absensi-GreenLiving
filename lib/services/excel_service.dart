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

    // --- 1. SETUP STYLE DASAR ---
    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString("#1B5E20"), // Hijau Gelap
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle nameStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    // --- 2. HEADER TANGGAL ---
    List<String> fullDates = [];
    int daysCount = endDate.difference(startDate).inDays;
    
    // Header Kolom Tetap
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue("No")
      ..cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
      ..value = TextCellValue("Nama Pegawai")
      ..cellStyle = headerStyle;

    // Loop Tanggal Header
    for (int i = 0; i <= daysCount; i++) {
      DateTime d = startDate.add(Duration(days: i));
      String label = DateFormat('dd').format(d); // 01, 02
      fullDates.add(DateFormat('yyyy-MM-dd').format(d));

      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: 0));
      cell.value = TextCellValue(label);
      cell.cellStyle = headerStyle;
    }

    // --- 3. ISI DATA (LOGIC WARNA SHIFT) ---
    int rowIndex = 1;

    for (var emp in employees) {
      // No & Nama
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = IntCellValue(rowIndex)
        ..cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = TextCellValue(emp.name)
        ..cellStyle = nameStyle;

      // Loop Tanggal
      for (int i = 0; i < fullDates.length; i++) {
        String dateKey = fullDates[i];
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: rowIndex));
        
        var cellData = dataMap[emp.uid]?[dateKey];

        String text = "-";
        ExcelColor bgColor = ExcelColor.white;
        ExcelColor fontColor = ExcelColor.black;

        if (cellData != null) {
          String type = cellData['type'];
          String value = cellData['value'].toString();
          String shiftName = (cellData['shift'] ?? "").toString().toLowerCase();

          if (type == 'schedule') {
            if (value == 'Libur') {
              text = "Libur";
              bgColor = ExcelColor.fromHexString("#EEEEEE");
            } else {
              text = "-";
              bgColor = ExcelColor.fromHexString("#FFCDD2");
            }
          } 
          else if (type == 'attendance') {
            String time = value;
            String status = cellData['status'] ?? 'Hadir';
            
            if (status.contains('Late') || status.contains('Telat')) {
              text = "Telat\n($time)";
            } else {
              text = "Hadir\n($time)";
            }

            if (shiftName.contains('pagi')) {
              bgColor = ExcelColor.fromHexString("#FFF59D");
            } else if (shiftName.contains('siang')) {
              bgColor = ExcelColor.fromHexString("#A5D6A7");
            } else if (shiftName.contains('malam')) {
              bgColor = ExcelColor.fromHexString("#90CAF9");
            } else {
              bgColor = ExcelColor.white;
            }
          }
        }

        cell.value = TextCellValue(text);
        cell.cellStyle = CellStyle(
          backgroundColorHex: bgColor,
          fontColorHex: fontColor,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          textWrapping: TextWrapping.WrapText,
          fontSize: 10,
        );
      }
      rowIndex++;
    }

    // --- 4. LEGENDA WARNA ---
    int legendRow = rowIndex + 2;
    _writeLegend(sheet, legendRow, "Shift Pagi", ExcelColor.fromHexString("#FFF59D"));
    _writeLegend(sheet, legendRow + 1, "Shift Siang", ExcelColor.fromHexString("#A5D6A7"));
    _writeLegend(sheet, legendRow + 2, "Shift Malam", ExcelColor.fromHexString("#90CAF9"));
    _writeLegend(sheet, legendRow + 3, "Tidak Hadir (Alpha)", ExcelColor.fromHexString("#FFCDD2"));
    _writeLegend(sheet, legendRow + 4, "Libur", ExcelColor.fromHexString("#EEEEEE"));

    await _saveAndOpenFile(excel, fileName);
  }

  void _writeLegend(Sheet sheet, int row, String label, ExcelColor color) {
    var cellColor = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    cellColor.value = TextCellValue("   "); 
    cellColor.cellStyle = CellStyle(backgroundColorHex: color);

    var cellText = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
    cellText.value = TextCellValue(label);
    cellText.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Left);
  }

  // --- 🔥 LOGIC SAVE YANG AMAN (NO DELETE, NO PERMISSION ERROR) ---
  Future<void> _saveAndOpenFile(Excel excel, String fileName) async {
    String filePath;
    String safeName = fileName.replaceAll(RegExp(r'[^\w\s]+'), ''); 

    Directory? directory;
    if (Platform.isAndroid) {
      // Menggunakan folder khusus aplikasi (Android/data/...)
      // Aman dari Permission Denied di Android 11+
      directory = await getExternalStorageDirectory(); 
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    // Fallback jika directory null
    directory ??= await getApplicationDocumentsDirectory();
    
    filePath = "${directory.path}/$safeName.xlsx";
    File file = File(filePath);

    // ❌ DIBUANG: if (await file.exists()) await file.delete();
    // Kita langsung timpa saja (overwrite) agar tidak error 'PathNotFound'

    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Tulis file (otomatis menimpa file lama jika ada)
      file.writeAsBytesSync(excel.save()!);
      
      print("Sukses simpan di: $filePath");
      
      // Langsung buka filenya agar user tidak perlu mencari manual
      OpenFile.open(filePath);
      
    } catch (e) {
      print("Gagal save file: $e");
      rethrow; 
    }
  }
}