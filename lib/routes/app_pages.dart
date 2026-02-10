
import 'package:absensi_greenliving/views/admin/admin_dashboard_page.dart';
import 'package:absensi_greenliving/views/admin/admin_employe_page.dart';
import 'package:absensi_greenliving/views/admin/admin_excel_page.dart';
import 'package:absensi_greenliving/views/admin/admin_history_page.dart';
import 'package:absensi_greenliving/views/admin/admin_leave_approval.dart';
import 'package:absensi_greenliving/views/admin/admin_livemonitoring_page.dart';
import 'package:absensi_greenliving/views/admin/admin_schedule_page.dart';
import 'package:absensi_greenliving/views/auth/login_page.dart';
import 'package:absensi_greenliving/views/auth/register_page.dart';
import 'package:absensi_greenliving/views/profile/profile_page.dart';
import 'package:absensi_greenliving/views/splash/splash_page.dart';
import 'package:absensi_greenliving/views/user/add_leave_page.dart';
import 'package:absensi_greenliving/views/user/dashboard_page.dart';
import 'package:absensi_greenliving/views/user/history_page.dart';
import 'package:absensi_greenliving/views/user/leave_request_page.dart';
import 'package:absensi_greenliving/views/user/schedule_page.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../views/main_wrapper.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.MAIN,
      page: () {
        final bool isAdmin = Get.arguments ?? false;
        return MainWrapper(isAdmin: isAdmin);
      },
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
  name: Routes.REGISTER,
  page: () => const RegisterPage(),
  transition: Transition.rightToLeft,
  ),
   GetPage(
      name: Routes.SCHEDULE,
      page: () => const SchedulePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfilePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.HISTORY,
      page: () => const HistoryPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.LEAVE_REQUEST,
      page: () => const LeaveRequestPage(),
      transition: Transition.fadeIn,
    ),
     GetPage(
      name: Routes.ADMIN_DASHBOARD,
      page: () => const AdminDashboardPage(),
      transition: Transition.fadeIn,
    ),
     GetPage(
      name: Routes.ADMIN_SCHEDULE,
      page: () => const AdminSchedulePage(),
      transition: Transition.fadeIn,
    ),
      GetPage(
        name: Routes.ADMIN_LEAVE_APPROVAL,
        page: () => const AdminLeaveApprovalPage(),
        transition: Transition.fadeIn,
      ),
      GetPage(
        name: Routes.ADMIN_EMPLOYEE,
        page: () => const AdminEmployeePage(),
        transition: Transition.fadeIn,
      ),
      GetPage(
        name: Routes.ADMIN_HISTORY,
        page: () => const AdminHistoryPage(),
        transition: Transition.fadeIn,
      ),
      GetPage(
        name: Routes.ADMIN_LIVE_MONITORING,
        page: () => const AdminLiveMonitoringPage(),
        transition: Transition.fadeIn,
      ),
      GetPage(
      name: Routes.ADD_LEAVE,
      page: () => const AddLeavePage(),
      transition: Transition.fadeIn,
    ),
      GetPage(
      name: Routes.ADMIN_EXCEL,
      page: () => const AdminExcelPage(),
      transition: Transition.fadeIn,
    ),
  ];
}