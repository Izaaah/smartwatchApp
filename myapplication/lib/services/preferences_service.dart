import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // Keys for SharedPreferences
  static const String _stepsGoalKey = 'steps_goal';
  static const String _caloriesGoalKey = 'calories_goal';
  static const String _sleepGoalKey = 'sleep_goal';
  static const String _waterGoalKey = 'water_goal';
  static const String _distanceGoalKey = 'distance_goal';
  static const String _unitSystemKey = 'unit_system'; // 'metric' or 'imperial'

  // Default values
  static const int defaultStepsGoal = 10000;
  static const int defaultCaloriesGoal = 500;
  static const double defaultSleepGoal = 8.0; // hours
  static const double defaultWaterGoal = 2.0; // liters
  static const double defaultDistanceGoal = 5.0; // km
  static const String defaultUnitSystem = 'metric';

  // Steps Goal
  static Future<void> setStepsGoal(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepsGoalKey, steps);
  }

  static Future<int> getStepsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepsGoalKey) ?? defaultStepsGoal;
  }

  // Calories Goal
  static Future<void> setCaloriesGoal(int calories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_caloriesGoalKey, calories);
  }

  static Future<int> getCaloriesGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_caloriesGoalKey) ?? defaultCaloriesGoal;
  }

  // Sleep Goal
  static Future<void> setSleepGoal(double hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sleepGoalKey, hours);
  }

  static Future<double> getSleepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_sleepGoalKey) ?? defaultSleepGoal;
  }

  // Water Goal
  static Future<void> setWaterGoal(double liters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_waterGoalKey, liters);
  }

  static Future<double> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_waterGoalKey) ?? defaultWaterGoal;
  }

  // Distance Goal
  static Future<void> setDistanceGoal(double km) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_distanceGoalKey, km);
  }

  static Future<double> getDistanceGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_distanceGoalKey) ?? defaultDistanceGoal;
  }

  // Unit System
  static Future<void> setUnitSystem(String system) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitSystemKey, system);
  }

  static Future<String> getUnitSystem() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unitSystemKey) ?? defaultUnitSystem;
  }

  // Helper methods for unit conversion
  static String getDistanceUnit(String system) {
    return system == 'metric' ? 'km' : 'mi';
  }

  static String getWeightUnit(String system) {
    return system == 'metric' ? 'kg' : 'lbs';
  }

  static String getHeightUnit(String system) {
    return system == 'metric' ? 'cm' : 'ft';
  }

  static String getTemperatureUnit(String system) {
    return system == 'metric' ? '°C' : '°F';
  }

  static double convertDistance(double km, String toSystem) {
    if (toSystem == 'imperial') {
      return km * 0.621371; // km to miles
    }
    return km;
  }

  static double convertWeight(double kg, String toSystem) {
    if (toSystem == 'imperial') {
      return kg * 2.20462; // kg to lbs
    }
    return kg;
  }
}






