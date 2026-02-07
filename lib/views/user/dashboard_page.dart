import 'package:absensi_greenliving/controllers/attedance_controler.dart';
import 'package:absensi_greenliving/controllers/dashboard_controler.dart';
import 'package:absensi_greenliving/models/shift_models.dart'; // 🔥 Import Model
import 'package:absensi_greenliving/models/user_models.dart';
import 'package:absensi_greenliving/services/database_service.dart'; // 🔥 Import DB
import 'package:absensi_greenliving/views/user/history_page.dart';
import 'package:absensi_greenliving/views/user/leave_request_page.dart';
import 'package:absensi_greenliving/views/user/schedule_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 INJECT 2 CONTROLLER
    final attController = Get.put(AttendanceController());
    final dashController = Get.put(DashboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: Stack(
        children: [
          _buildHeaderGradient(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  // 🔥 FITUR BARU: PULL TO REFRESH
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await dashController.refreshData();
                    },
                    color: const Color(0xFF1B5E20),
                    child: SingleChildScrollView(
                      // Pake AlwaysScrollable biar bisa ditarik walau konten sedikit
                      physics: const AlwaysScrollableScrollPhysics(), 
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // --- KARTU STATUS ABSEN ---
                          Obx(() {
                            if (attController.currentStatus.value == 'checkOut') {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.2))
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF1B5E20)),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Absensi Hari Ini Selesai",
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF1B5E20),
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            // TAMPILKAN KARTU TOMBOL
                            return _buildAttendanceCard(attController);
                          }),
                          
                          const SizedBox(height: 20),
                          
                          // --- WIDGET TANGGAL & LOKASI ---
                          Obx(() => _buildDateAndWeekStatus(attController, dashController)),
                          
                          const SizedBox(height: 20),
                          
                          _buildCircularStats(dashController),
                          
                          const SizedBox(height: 20),
                          _buildMenuGrid(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 🔥 LOGIC BARU: TOMBOL ABSEN ---
  Widget _buildAttendanceCard(AttendanceController controller) {
    bool isCheckIn = controller.currentStatus.value == 'pending';
    
    String title = isCheckIn ? 'Absen Masuk' : 'Absen Pulang';
    String subtitle = isCheckIn ? 'Silakan tap tombol di bawah untuk masuk' : 'Silakan tap tombol di bawah untuk pulang';
    Color iconColor = isCheckIn ? const Color(0xFFE57373) : Colors.orange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (controller.isLoading.value) return;

          User? firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) return;
          
          // 1. Siapkan Data User
          UserModel currentUser = UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? "Satpam",
            email: firebaseUser.email ?? "no-email",
            role: "security",
            joinDate: DateTime.now(),
            officeLat: controller.officeLat.value, 
            officeLng: controller.officeLng.value, 
          );

          // 🔥 2. TARIK DATA SHIFT DARI DB (UPDATE LOGIC)
          final db = DatabaseService();
          
          // Pakai getTodayShift (baca dari shift_schedule root)
          ShiftModel? todayShift = await db.getTodayShift(currentUser.uid);

          // 3. Kirim ke Controller
          // Controller akan validasi: Libur? Telat? Pulang Cepat?
          await controller.submitAttendance(currentUser, todayShift);
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Obx(() => controller.isLoading.value 
                ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator())
                : Icon(Icons.touch_app_rounded, color: iconColor, size: 30)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                    ),
                    Text(
                      subtitle, 
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC LINGKARAN CUTI & JAM ---
  Widget _buildCircularStats(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. KEHADIRAN
          Obx(() => _buildProgressCircle(
            "${(controller.presencePercentage.value * 100).toInt()}%", 
            'Kehadiran', 
            const Color(0xFF1B5E20), 
            controller.presencePercentage.value
          )),
          
          // 2. CUTI
          Obx(() => _buildProgressCircle(
            "${controller.cutiCount.value}", 
            'Cuti', 
            Colors.blueAccent, 
            (controller.cutiCount.value / 12) 
          )),
          
          // 3. JAM KERJA (TIMER)
          Obx(() => _buildProgressCircle(
            "${controller.remainingShiftHours.value}", 
            'Jam Kerja', 
            Colors.orange, 
            controller.shiftProgress.value
          )),
        ],
      ),
    );
  }

  // --- WIDGET LAIN TETAP SAMA ---

  Widget _buildDateAndWeekStatus(AttendanceController attCtrl, DashboardController dashCtrl) {
    final now = DateTime.now();
    final String currentMonth = DateFormat('MMM', 'id_ID').format(now);
    final String currentDayName = DateFormat('EEEE', 'id_ID').format(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${now.day} ',
                            style: GoogleFonts.poppins(
                              fontSize: 36, 
                              fontWeight: FontWeight.bold, 
                              color: const Color(0xFF1B5E20)
                            ),
                          ),
                          TextSpan(
                            text: currentMonth, 
                            style: GoogleFonts.poppins(
                              fontSize: 18, 
                              color: const Color(0xFF1B5E20), 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      currentDayName, 
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Green Living Residence', 
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10), 
              Obx(() {
                double dist = attCtrl.currentDistance.value;
                bool isNear = attCtrl.isWithinRadius.value;
                String distanceText = dist > 1000 
                    ? "${(dist/1000).toStringAsFixed(1)} km"
                    : "${dist.toInt()} m";

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isNear ? Colors.green[50] : Colors.red[50], 
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(
                      color: isNear ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      width: 1.5
                    )
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNear ? Icons.verified_user_rounded : Icons.location_off_rounded, 
                        size: 26, 
                        color: isNear ? Colors.green[700] : Colors.red[400]
                      ),
                      const SizedBox(width: 10), 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            distanceText,
                            style: GoogleFonts.poppins(
                              fontSize: 16, 
                              color: isNear ? Colors.green[800] : Colors.red[600],
                              fontWeight: FontWeight.w800,
                              height: 1.0
                            ),
                          ),
                          Text(
                            "dari Pos",
                            style: GoogleFonts.poppins(
                              fontSize: 10, 
                              color: isNear ? Colors.green[800] : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 25),
          const Text('Status Mingguan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildLiveWeekDays(dashCtrl.weeklyStatus),
          )
        ],
      ),
    );
  }

  List<Widget> _buildLiveWeekDays(List<String> statusList) {
    const days = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];
    return List.generate(days.length, (index) {
      String status = statusList.length > index ? statusList[index] : 'pending';
      Widget icon;
      if (status == 'done') {
        icon = const Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 28);
      } else if (status == 'absent') {
        icon = const Icon(Icons.cancel, color: Color(0xFFE57373), size: 28);
      } else {
        icon = Icon(Icons.radio_button_unchecked, color: Colors.grey[300], size: 28);
      }
      return Column(
        children: [
          Text(days[index], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          icon,
        ],
      );
    });
  }

  Widget _buildProgressCircle(String val, String label, Color color, double progress) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 65,
              width: 65,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                color: color,
                backgroundColor: color.withOpacity(0.1),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHeaderGradient() {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Presensi',
            style: GoogleFonts.dancingScript(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final List<Map<String, dynamic>> menus = [
      {'icon': Icons.calendar_month_outlined, 'label': 'Jadwal', 'onTap': () => Get.to(() => const SchedulePage())},
      {'icon': Icons.work_off_outlined, 'label': 'Izin', 'onTap': () => Get.to(() => const LeaveRequestPage())},
      {'icon': Icons.history_outlined, 'label': 'Riwayat', 'onTap': () => Get.to(() => const HistoryPage())},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: menu['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFF1B5E20).withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(menu['icon'] as IconData, color: const Color(0xFF1B5E20), size: 32),
                  const SizedBox(height: 10),
                  Text(
                    menu['label'] as String,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}