import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  // Tetap gunakan Map agar cocok dengan data dari profile.dart
  final Map<String, dynamic>? user; 
  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String _selectedGender = 'male';
  bool _isLoading = false;

  // PERBAIKAN: Gunakan Map, bukan model User
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    
    // PERBAIKAN: Cara akses data dari Map menggunakan ['key']
    _emailController = TextEditingController(text: _currentUser?['email']?.toString() ?? '');
    _nameController = TextEditingController(text: _currentUser?['username']?.toString() ?? '');
    _ageController = TextEditingController(text: _currentUser?['age']?.toString() ?? '');
    _heightController = TextEditingController(text: _currentUser?['height']?.toString() ?? '');
    _weightController = TextEditingController(text: _currentUser?['weight']?.toString() ?? '');
    _selectedGender = _currentUser?['gender']?.toString() ?? 'male';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // PERBAIKAN: Simpan data langsung ke Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update data ke koleksi 'users' di Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'age': int.tryParse(_ageController.text) ?? 0,
          'gender': _selectedGender,
          'height': double.tryParse(_heightController.text) ?? 0.0,
          'weight': double.tryParse(_weightController.text) ?? 0.0,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Kembali ke ProfileScreen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... UI tetap sama seperti kode Anda sebelumnya ...
    return Scaffold(
      backgroundColor: const Color(0xFF0F1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        actions: [
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
            : TextButton(onPressed: _saveProfile, child: const Text('Save', style: TextStyle(color: Color(0xFF4ECDC4))))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined),
              const SizedBox(height: 20),
              _buildTextField(controller: _nameController, label: 'Username', icon: Icons.person_outlined),
              const SizedBox(height: 20),
              _buildTextField(controller: _ageController, label: 'Age', icon: Icons.calendar_today, type: TextInputType.number),
              const SizedBox(height: 20),
              _buildGenderField(),
              const SizedBox(height: 20),
              _buildTextField(controller: _heightController, label: 'Height', icon: Icons.height, type: TextInputType.number),
              const SizedBox(height: 20),
              _buildTextField(controller: _weightController, label: 'Weight', icon: Icons.monitor_weight, type: TextInputType.number),
            ],
          ),
        ),
      ),
    );
  }

  // Helper UI (Samakan dengan yang Anda miliki)
  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
        filled: true,
        fillColor: const Color(0xFF1A1F3A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      dropdownColor: const Color(0xFF1A1F3A),
      style: const TextStyle(color: Colors.white),
      items: ['male', 'female', 'other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (v) => setState(() => _selectedGender = v!),
      decoration: InputDecoration(
        labelText: 'Gender',
        filled: true,
        fillColor: const Color(0xFF1A1F3A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}