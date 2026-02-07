import 'package:absensi_greenliving/controllers/admin_dashboard_controler.dart'; // Sesuaikan typo nama file Nda
import 'package:absensi_greenliving/controllers/admin_excel_controler.dart';
import 'package:absensi_greenliving/routes/app_routes.dart';
import 'package:absensi_greenliving/views/admin/admin_leave_approval.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 1. INJECT KEDUA CONTROLLER
    final controller = Get.put(AdminDashboardController());
    final excelController = Get.put(ExcelController()); // Controller khusus Excel

    // Warna Corporate
    final Color primaryGreen = const Color(0xFF1B5E20);
    final Color bgGrey = const Color(0xFFF2F7F2); 

    return Scaffold(
      backgroundColor: bgGrey,
      body: Stack(
        children: [
          // BACKGROUND HEADER IJO MELENGKUNG
          _buildHeaderGradient(),

          SafeArea(
            child: RefreshIndicator(
              // FITUR TARIK UNTUK REFRESH
              onRefresh: () async => controller.loadDashboardData(),
              color: primaryGreen,
              child: Column(
                children: [
                  // TOP BAR
                  _buildTopBar(),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), // Wajib biar bisa ditarik
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // HERO CARD (Live Monitoring)
                          Obx(() => _buildHeroStatusCard(
                            primaryGreen, 
                            controller.activeGuards.value, 
                            controller.totalGuards.value
                          )),

                          const SizedBox(height: 30),
                          
                          Text(
                            "Quick Actions",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 15),

                          // MENU GRID PREMIUM
                          // 🔥 Kirim excelController ke widget bawah
                          Obx(() => _buildPremiumGrid(primaryGreen, controller, excelController)),
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HEADER IJO MELENGKUNG ---
  Widget _buildHeaderGradient() {
    return Container(
      height: 260, 
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

  // --- WIDGET TOP BAR ---
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Pagi,',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
              Text(
                'Admin Panel',
                style: GoogleFonts.dancingScript(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Icon(Icons.security, color: Color(0xFF1B5E20), size: 28),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET HERO CARD (LIVE MONITORING) ---
  Widget _buildHeroStatusCard(Color primaryColor, int active, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label "Monitoring"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green, // Dot Hijau nyala
                        shape: BoxShape.circle
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Live Monitoring", 
                      style: GoogleFonts.poppins(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 20),
          
          // ANGKA DINAMIS DARI DB
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$active", // Jumlah Aktif
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "/ $total Personil", // Total Security
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          Text(
            "Sedang Bertugas Sekarang",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 25),
          
          // Avatar Stack (Visualisasi Aktif)
          Row(
            children: [
              SizedBox(
                height: 40,
                width: 120, 
                child: Stack(
                  children: List.generate(active > 4 ? 4 : active, (index) {
                    return Positioned(
                      left: index * 25.0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green[100],
                          child: Text("S${index+1}", style: const TextStyle(fontSize: 10, color: Colors.green)),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              
              // Tombol Panah Hijau
              Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  onPressed: () => Get.toNamed(Routes.ADMIN_LIVE_MONITORING),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- WIDGET GRID MENU ---
  // 🔥 Ditambah parameter excelCtrl
  Widget _buildPremiumGrid(Color primaryColor, AdminDashboardController controller, ExcelController excelCtrl) {
    
    // LOGIC PERIZINAN
    int pending = controller.pendingCount.value;
    bool hasPending = pending > 0;
    
    final List<Map<String, dynamic>> menus = [
      {
        'title': 'Perizinan',
        'subtitle': hasPending ? '$pending Pending' : 'Izin Hari Ini',
        'icon': Icons.assignment_turned_in_rounded,
        'isAlert': hasPending,
        'onTap': () => Get.to(() => const AdminLeaveApprovalPage())?.then((_) => controller.loadDashboardData()),
      },
      {
        'title': 'Export Data',
        'subtitle': 'To Excel',
        'icon': Icons.data_array_rounded,
        'isAlert': false,
        // 🔥 PANGGIL CONTROLLER EXCEL YANG BARU
        'onTap': () => excelCtrl.downloadMonthlyRecap(), 
      },
      {
        'title': 'Riwayat',
        'subtitle': 'Log Absensi',
        'icon': Icons.history_toggle_off_rounded,
        'isAlert': false,
        'onTap': () => Get.toNamed(Routes.ADMIN_HISTORY), 
      },
      {
        'title': 'Pegawai',
        'subtitle': 'Data Satpam',
        'icon': Icons.people_alt_rounded,
        'isAlert': false,
        'onTap': () => Get.toNamed(Routes.ADMIN_EMPLOYEE), 
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.0, 
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: menu['onTap'] ?? menu['onPressed'], 
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon Hijau
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(menu['icon'], color: primaryColor, size: 24),
                      ),
                      // Dot Alert Merah
                      if (menu['isAlert'])
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        menu['subtitle'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}