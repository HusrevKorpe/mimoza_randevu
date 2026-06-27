/// Named route table for the app shell.
abstract final class AppRoutes {
  /// Root path. Served by [AuthGate], which routes to splash / login / calendar
  /// based on auth state — so this is not registered in the route table.
  static const String login = '/';

  /// Randevu Defteri — main screen and deep-link target.
  static const String calendar = '/calendar';

  /// New appointment form.
  static const String newAppointment = '/new';

  /// Appointment detail.
  static const String detail = '/detail';

  /// Settings — appearance, reminders, working hours, account.
  static const String settings = '/settings';
}
