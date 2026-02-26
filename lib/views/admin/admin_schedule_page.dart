import 'package:absensi_greenliving/controllers/admin_schedule_controler.dart';
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminSchedulePage extends StatelessWidget {
  const AdminSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(AdminScheduleController());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: Stack(
        children: [
          // 1. BACKGROUND HEADER GRADIENT
          Container(
            height: 200, 
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight
              )
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. TOP BAR
                _buildTopBar(context, controller),
                
                const SizedBox(height: 30),
                
                // 3. MAIN CONTENT (PUTIH MELENGKUNG)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
                    ),
                    // 🔥 FITUR BARU: TARIK BUAT REFRESH PEGAWAI & JADWAL
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // Panggil fungsi reload data dari controller
                       controller.fetchEmployees(); // 🔥 INIT: Refresh List Pegawai
                        await controller.fetchUserShifts(); // 🔥 INIT: Refresh Jadwal User yg dipilih
                      },
                      color: const Color(0xFF1B5E20), 
                      child: SingleChildScrollView( 
                        physics: const AlwaysScrollableScrollPhysics(), 
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.8, // Hack biar GridView dapet height
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              
                              // LABEL PEGAWAI
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Align(
                                  alignment: Alignment.centerLeft, 
                                  child: Text("Pilih Personil:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))
                                ),
                              ),
                              const SizedBox(height: 10),
                              
                              // LIST PEGAWAI
                              _buildEmployeeList(controller),
                              
                              const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),

                              // HEADER BULAN (NAVIGASI)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Navigasi Bulan (BALIK KE POSISI SEMULA)
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => controller.changeMonth(-1),
                                          icon: const Icon(Icons.chevron_left, color: Colors.black87),
                                          tooltip: "Bulan Lalu",
                                        ),
                                        InkWell(
                                          onTap: () => _pickMonthDate(context, controller),
                                          child: Obx(() => Text(
                                            DateFormat('MMMM yyyy', 'id_ID').format(controller.currentMonth.value),
                                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                          )),
                                        ),
                                        IconButton(
                                          onPressed: () => controller.changeMonth(1),
                                          icon: const Icon(Icons.chevron_right, color: Colors.black87),
                                          tooltip: "Bulan Depan",
                                        ),
                                      ],
                                    ),
                                    
                                    // Tombol Auto Pola
                                    ElevatedButton.icon(
                                      onPressed: () => _showGenerateDialog(context, controller),
                                      icon: const Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
                                      label: Text("Auto Pola", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1B5E20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),

                              // GRID KALENDER (Pake Expanded di dalem Column yang udah di-wrap height)
                              Expanded(child: _buildCalendarGrid(controller)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC PICKER BULAN ---
  void _pickMonthDate(BuildContext context, AdminScheduleController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.currentMonth.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)), // Hijau Branding
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.setSpecificMonth(picked);
    }
  }

  // --- WIDGET TOP BAR ---
  Widget _buildTopBar(BuildContext context, AdminScheduleController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    child: Stack(
      alignment: Alignment.center, 
      children: [
        const Text(
          "Manajer Jadwal",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => _showMasterConfigDialog(context, controller),
          ),
        ),
      ],
    ),
  );
}
  // --- WIDGET LIST PEGAWAI ---
  Widget _buildEmployeeList(AdminScheduleController controller) {
    return SizedBox(
      height: 100,
      child: Obx(() { 
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.employees.isEmpty) return const Center(child: Text("- Tidak ada pegawai -"));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          scrollDirection: Axis.horizontal,
          itemCount: controller.employees.length,
          separatorBuilder: (c, i) => const SizedBox(width: 15),
          itemBuilder: (context, index) {
            UserModel user = controller.employees[index];
            return Obx(() {
              bool isSelected = controller.selectedUser.value?.uid == user.uid;
              return GestureDetector(
                onTap: () => controller.selectUser(user),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer( 
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1B5E20) : Colors.transparent, 
                          width: isSelected ? 3 : 1
                        ),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] 
                            : [],
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: isSelected ? const Color(0xFF1B5E20) : Colors.grey[200],
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 18
                          )
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.name.split(' ')[0], 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF1B5E20) : Colors.grey
                      )
                    ),
                  ],
                ),
              );
            });
          },
        );
      }),
    );
  }

  // --- WIDGET GRID KALENDER ---
  Widget _buildCalendarGrid(AdminScheduleController controller) {
    return Obx(() {
      if (controller.selectedUser.value == null) return const Center(child: Text("Pilih personil dulu di atas 👆"));
      if (controller.isShiftLoading.value) return const Center(child: CircularProgressIndicator());

      int daysInMonth = DateTime(controller.currentMonth.value.year, controller.currentMonth.value.month + 1, 0).day;

      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8,
        ),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          DateTime date = DateTime(controller.currentMonth.value.year, controller.currentMonth.value.month, index + 1);
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          
          String? shiftId = controller.userShifts[dateKey];

          // Logic Warna
          Color color = Colors.grey[50]!;
          Color textColor = Colors.grey;
          String label = "Off";
          
          if (shiftId != null) {
            // Cek Flexi/Sampah dulu biar ungu
            if (shiftId.toLowerCase().contains('flexi') || shiftId.toLowerCase().contains('sampah')) {
              color = Colors.purple[50]!; textColor = Colors.purple[900]!; label = "Flexi";
            } else if (shiftId.toLowerCase().contains('pagi')) { 
              color = Colors.orange[50]!; textColor = Colors.orange[900]!; label = "Pagi";
            } else if (shiftId.toLowerCase().contains('siang')) { 
              color = Colors.blue[50]!; textColor = Colors.blue[900]!; label = "Siang";
            } else if (shiftId.toLowerCase().contains('malam')) { 
              color = const Color(0xFFE8F5E9); textColor = const Color(0xFF1B5E20); label = "Malam";
            } else if (shiftId.toLowerCase().contains('libur')) {
              color = Colors.red[50]!; textColor = Colors.red[900]!; label = "Libur";
            } else {
               color = Colors.teal[50]!; textColor = Colors.teal[900]!; label = shiftId;
            }
          }

          return InkWell(
            onTap: () => _showSingleShiftDialog(context, controller, date),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: color, 
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: textColor.withOpacity(0.1))
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 10, color: textColor), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // --- DIALOG GENERATE (Auto Pola - Dinamis) ---
  void _showGenerateDialog(BuildContext context, AdminScheduleController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              
              Text("Generate Pola Otomatis", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Pilih jenis shift awal. Sistem akan otomatis menentukan pola.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              
              // 1. OPSI SATPAM (Manual karena Logic Rotasi Khusus)
              const Text("Pola Rotasi (Khusus Satpam)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildStartOption(context, controller, "Mulai Rotasi dari PAGI", "Pagi", Colors.orange, Icons.wb_sunny),
              const SizedBox(height: 5),
              _buildStartOption(context, controller, "Mulai Rotasi dari SIANG", "Siang", Colors.blue, Icons.cloud),
              const SizedBox(height: 5),
              _buildStartOption(context, controller, "Mulai Rotasi dari MALAM", "Malam", const Color(0xFF1B5E20), Icons.nights_stay),
              
              const SizedBox(height: 20),

              const Text("Pola Tetap (Tukang / Staff Lain)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              

              Obx(() {
                 // Filter shift yg bukan satpam
                 var otherShifts = controller.masterShifts.where((s) {
                    String id = s['id'].toString();
                    return !['Pagi', 'Siang', 'Malam'].contains(id);
                 }).toList();
                 
                 if (otherShifts.isEmpty) return const Text("- Tidak ada shift lain -");

                 return Column(
                   children: otherShifts.map((shift) {
                     String id = shift['id'];
                     // Tentukan Icon & Warna biar cantik
                     IconData icon = Icons.work;
                     Color color = Colors.grey;
                     
                     if (id.toLowerCase().contains('sampah')) { icon = Icons.delete; color = Colors.brown; }
                     else if (id.toLowerCase().contains('sapu')) { icon = Icons.cleaning_services; color = Colors.teal; }
                     else if (id.toLowerCase().contains('taman')) { icon = Icons.park; color = Colors.green; }
                     
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 5),
                       child: _buildStartOption(context, controller, "Shift Tetap: $id", id, color, icon),
                     );
                   }).toList(),
                 );
              }),

              const SizedBox(height: 10),
              _buildStartOption(context, controller, "Set Full LIBUR", "Libur", Colors.red, Icons.weekend),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // 🔥 [MODIFIED] Opsi sekarang memicu DatePicker sebelum Execute
  Widget _buildStartOption(BuildContext context, AdminScheduleController controller, String title, String shiftId, Color color, IconData icon) {
    var shiftData = controller.masterShifts.firstWhereOrNull((element) => element['id'] == shiftId);
    String timeInfo = (shiftId == "Libur") ? "Off Day" : (shiftData != null ? "${shiftData['startTime']} - ${shiftData['endTime']}" : "-");
    
    return InkWell(
      onTap: () async {
        Get.back(); // Tutup bottom sheet
        
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: controller.currentMonth.value, 
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          helpText: "PILIH TANGGAL MULAI POLA",
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          controller.executeGenerate(startShiftId: shiftId, startDate: pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
          const SizedBox(width: 15), 
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(timeInfo, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          const Icon(Icons.calendar_month, size: 16, color: Colors.grey)
        ]),
      ),
    );
  }

  // --- DIALOG SINGLE EDIT ---
  void _showSingleShiftDialog(BuildContext context, AdminScheduleController controller, DateTime date) {
    Get.bottomSheet(Container(
      padding: const EdgeInsets.all(20), 
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
      child: SingleChildScrollView( // Biar gak overflow kalau list panjang
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Edit ${DateFormat('dd MMM').format(date)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
          const SizedBox(height: 15),
          
          // Opsi Manual Standar
          ListTile(title: const Text("Pagi"), onTap: (){controller.updateSingleShift(date, "Pagi"); Get.back();}, leading: const Icon(Icons.wb_sunny, color: Colors.orange)),
          ListTile(title: const Text("Siang"), onTap: (){controller.updateSingleShift(date, "Siang"); Get.back();}, leading: const Icon(Icons.cloud, color: Colors.blue)),
          ListTile(title: const Text("Malam"), onTap: (){controller.updateSingleShift(date, "Malam"); Get.back();}, leading: const Icon(Icons.nights_stay, color: Color(0xFF1B5E20))),
          ListTile(title: const Text("Libur"), onTap: (){controller.updateSingleShift(date, "Libur"); Get.back();}, leading: const Icon(Icons.weekend, color: Colors.red)),

          const Divider(),
          const Text("Shift Lainnya", style: TextStyle(color: Colors.grey, fontSize: 12)),
          
      Obx(() {
             var otherShifts = controller.masterShifts.where((s) {
                String id = s['id'].toString();
                // Filter biar Pagi/Siang/Malam gak dobel
                return !['Pagi', 'Siang', 'Malam'].contains(id);
             }).toList();

             if (otherShifts.isEmpty) return const Padding(padding: EdgeInsets.all(10), child: Text("- Tidak ada shift lain -"));

             return Column(
               children: otherShifts.map((s) {
                  String id = s['id'];
                  
                  // 🔥 LOGIC IKON & WARNA (Sama kayak Auto Pola)
                  IconData icon = Icons.work;
                  Color color = Colors.grey;
                  
                  if (id.toLowerCase().contains('sampah')) { icon = Icons.delete; color = Colors.brown; }
                  else if (id.toLowerCase().contains('sapu')) { icon = Icons.cleaning_services; color = Colors.teal; }
                  else if (id.toLowerCase().contains('taman')) { icon = Icons.park; color = Colors.green; }

                  return ListTile(
                    title: Text(id), 
                    onTap: (){controller.updateSingleShift(date, id); Get.back();}, 
                    leading: Icon(icon, color: color) // Pake ikon yang udah dipilih
                  );
               }).toList(),
             );
          })

        ]),
      )
    ));
  }

  // --- DIALOG MASTER CONFIG ---
  void _showMasterConfigDialog(BuildContext context, AdminScheduleController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Konfigurasi Master Shift", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            _buildConfigItem(context, controller, "Shift Pagi", "Pagi", Icons.wb_sunny, Colors.orange),
            _buildConfigItem(context, controller, "Shift Siang", "Siang", Icons.cloud, Colors.blue),
            _buildConfigItem(context, controller, "Shift Malam", "Malam", Icons.nights_stay, const Color(0xFF1B5E20)),
            // Opsi Flexi jarang diedit tapi bisa ditampilin kalau mau
          ],
        ),
      )
    );
  }

  Widget _buildConfigItem(BuildContext context, AdminScheduleController controller, String label, String id, IconData icon, Color color) {
    return ListTile(
      title: Text(label), subtitle: const Text("Ketuk untuk ubah jam"),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
      trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
      onTap: () async {
        Get.back();
        // Disini harus fetch data dulu dari controller
        try {
          var data = await controller.getShiftDetail(id);
          _showEditForm(context, controller, id, data);
        } catch (e) {
          Get.snackbar("Error", "Gagal ambil data shift");
        }
      },
    );
  }

  void _showEditForm(BuildContext context, AdminScheduleController controller, String id, Map<String, dynamic> currentData) {
    final startC = TextEditingController(text: currentData['startTime']);
    final endC = TextEditingController(text: currentData['endTime']);
    final tolC = TextEditingController(text: currentData['Tolerance'].toString());

    Get.defaultDialog(
      title: "Edit $id",
      content: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(controller: startC, decoration: const InputDecoration(labelText: "Jam Masuk (07.00)")),
            const SizedBox(height: 10),
            TextField(controller: endC, decoration: const InputDecoration(labelText: "Jam Pulang (15.00)")),
            const SizedBox(height: 10),
            TextField(controller: tolC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Toleransi (Menit)")),
          ],
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
        onPressed: () {
          controller.updateMasterShift(id, startC.text, endC.text, tolC.text);
          Get.back();
        }, 
        child: const Text("SIMPAN", style: TextStyle(color: Colors.white))
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
}