import 'package:flutter/material.dart';
import 'package:frontend/services/preferences_service.dart';

class GoalsTargetsScreen extends StatefulWidget {
  const GoalsTargetsScreen({super.key});

  @override
  State<GoalsTargetsScreen> createState() => _GoalsTargetsScreenState();
}

class _GoalsTargetsScreenState extends State<GoalsTargetsScreen> {
  int _stepsGoal = 10000;
  int _caloriesGoal = 500;
  // double _sleepGoal = 8.0;
  double _waterGoal = 2.0;
  double _distanceGoal = 5.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    final steps = await PreferencesService.getStepsGoal();
    final calories = await PreferencesService.getCaloriesGoal();
    // final sleep = await PreferencesService.getSleepGoal();
    final water = await PreferencesService.getWaterGoal();
    final distance = await PreferencesService.getDistanceGoal();

    setState(() {
      _stepsGoal = steps;
      _caloriesGoal = calories;
      // _sleepGoal = sleep;
      _waterGoal = water;
      _distanceGoal = distance;
      _isLoading = false;
    });
  }

  Future<void> _saveGoals() async {
    await PreferencesService.setStepsGoal(_stepsGoal);
    await PreferencesService.setCaloriesGoal(_caloriesGoal);
    // await PreferencesService.setSleepGoal(_sleepGoal);
    await PreferencesService.setWaterGoal(_waterGoal);
    await PreferencesService.setDistanceGoal(_distanceGoal);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals saved successfully!'),
          backgroundColor: Color(0xFF4ECDC4),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Goals & Targets',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your daily goals to stay motivated and track your progress.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildGoalCard(
                    'Steps',
                    'Daily step count target',
                    Icons.directions_walk,
                    const Color(0xFF4ECDC4),
                    _stepsGoal.toDouble(),
                    1000.0,
                    50000.0,
                    1000.0,
                    (value) {
                      setState(() {
                        _stepsGoal = value.toInt();
                      });
                    },
                    (value) => '${value.toInt()} steps',
                  ),
                  const SizedBox(height: 16),
                  _buildGoalCard(
                    'Calories',
                    'Daily calorie burn target',
                    Icons.local_fire_department,
                    const Color(0xFFFF6B6B),
                    _caloriesGoal.toDouble(),
                    100,
                    3000,
                    50,
                    (value) {
                      setState(() {
                        _caloriesGoal = value.toInt();
                      });
                    },
                    (value) => '${value.toInt()} kcal',
                  ),
                  // const SizedBox(height: 16),
                  // _buildGoalCard(
                  //   'Sleep',
                  //   'Daily sleep hours target',
                  //   Icons.bedtime,
                  //   const Color(0xFF9B59B6),
                  //   _sleepGoal,
                  //   4.0,
                  //   12.0,
                  //   0.5,
                  //   (value) {
                  //     setState(() {
                  //       _sleepGoal = value;
                  //     });
                  //   },
                  //   (value) => '${value.toStringAsFixed(1)} hours',
                  // ),
                  const SizedBox(height: 16),
                  _buildGoalCard(
                    'Water',
                    'Daily water intake target',
                    Icons.water_drop,
                    const Color(0xFF3498DB),
                    _waterGoal,
                    0.5,
                    5.0,
                    0.1,
                    (value) {
                      setState(() {
                        _waterGoal = value;
                      });
                    },
                    (value) => '${value.toStringAsFixed(1)} L',
                  ),
                  const SizedBox(height: 16),
                  _buildGoalCard(
                    'Distance',
                    'Daily distance target',
                    Icons.straighten,
                    const Color(0xFFFFD700),
                    _distanceGoal,
                    1.0,
                    20.0,
                    0.5,
                    (value) {
                      setState(() {
                        _distanceGoal = value;
                      });
                    },
                    (value) => '${value.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveGoals,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Goals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    double currentValue,
    double min,
    double max,
    double divisions,
    ValueChanged<double> onChanged,
    String Function(double) valueFormatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueFormatter(currentValue),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Slider(
            value: currentValue,
            min: min,
            max: max,
            divisions: ((max - min) / divisions).toInt(),
            onChanged: onChanged,
            activeColor: color,
            inactiveColor: Colors.white.withOpacity(0.1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valueFormatter(min),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              Text(
                valueFormatter(max),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
