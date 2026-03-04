import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String date(DateTime d) => DateFormat('EEEE, d MMM yyyy').format(d);
  static String shortDate(DateTime d) => DateFormat('d MMM').format(d);
  static String time(DateTime d) => DateFormat('h:mm a').format(d);
  static String calories(int kcal) => NumberFormat('#,###').format(kcal) + ' kcal';
  static String weight(double kg) => '${kg.toStringAsFixed(1)} kg';
  static String liters(double L) => '${L.toStringAsFixed(1)}L';
  static String hours(double h) => '${h.toStringAsFixed(1)}h';
  static String steps(int s) => NumberFormat('#,###').format(s);
  static String bmi(double bmi) => bmi.toStringAsFixed(1);

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
