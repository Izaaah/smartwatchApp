import 'package:flutter/material.dart';
import 'package:frontend/services/preferences_service.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  String _selectedUnit = 'metric';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnitSystem();
  }

  Future<void> _loadUnitSystem() async {
    final unit = await PreferencesService.getUnitSystem();
    setState(() {
      _selectedUnit = unit;
      _isLoading = false;
    });
  }

  Future<void> _saveUnitSystem(String system) async {
    await PreferencesService.setUnitSystem(system);
    setState(() {
      _selectedUnit = system;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Unit system changed to ${system == 'metric' ? 'Metric' : 'Imperial'}!'),
          backgroundColor: const Color(0xFF4ECDC4),
          duration: const Duration(seconds: 2),
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
          'Units',
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
                    'Choose your preferred unit system for measurements.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildUnitOption(
                    'Metric',
                    'Kilometers, Kilograms, Celsius',
                    Icons.straighten,
                    const Color(0xFF4ECDC4),
                    'metric',
                    [
                      'Distance: Kilometers (km)',
                      'Weight: Kilograms (kg)',
                      'Height: Centimeters (cm)',
                      'Temperature: Celsius (°C)',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUnitOption(
                    'Imperial',
                    'Miles, Pounds, Fahrenheit',
                    Icons.straighten,
                    const Color(0xFF9B59B6),
                    'imperial',
                    [
                      'Distance: Miles (mi)',
                      'Weight: Pounds (lbs)',
                      'Height: Feet & Inches (ft)',
                      'Temperature: Fahrenheit (°F)',
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(16),
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
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF3498DB),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Unit Conversion',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'All measurements will be automatically converted based on your selection. Your existing data will remain unchanged.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUnitOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String value,
    List<String> details,
  ) {
    final isSelected = _selectedUnit == value;

    return InkWell(
      onTap: () => _saveUnitSystem(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              ...details.map((detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: color,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          detail,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}






