import 'package:shared_preferences/shared_preferences.dart';

class TargetWeightService {
  static const _key = 'target_weight';
  static const double defaultValue = 65.0;

  static Future<double> get() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_key) ?? defaultValue;
  }

  static Future<void> set(double value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_key, value);
  }
}