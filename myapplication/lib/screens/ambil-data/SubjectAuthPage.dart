import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/ambil-data/data_collection_page.dart';

class SubjectAuthPage extends StatefulWidget {
  @override
  _SubjectAuthPageState createState() => _SubjectAuthPageState();
}

class _SubjectAuthPageState extends State<SubjectAuthPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = "Laki-laki";
  bool _isLoginMode = true; // Defaultnya halaman Login

  void _handleSubmit() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Username dan Password wajib diisi!");
      return;
    }

    try {
      showDialog(context: context, builder: (context) => Center(child: CircularProgressIndicator()));

      if (_isLoginMode) {
        // --- LOGIKA LOGIN ---
        var doc = await FirebaseFirestore.instance.collection('users_skripsi').doc(username).get();
        
        if (doc.exists && doc.data()!['password'] == password) {
          Navigator.pop(context); // Tutup loading
          _goToCollectionPage(doc.data()!);
        } else {
          Navigator.pop(context);
          _showSnackBar("Username atau Password salah!");
        }
      } else {
        // --- LOGIKA REGISTER ---
        if (_weightController.text.isEmpty) {
          Navigator.pop(context);
          _showSnackBar("Berat badan wajib diisi untuk registrasi!");
          return;
        }

        await FirebaseFirestore.instance.collection('users_skripsi').doc(username).set({
          'username': username,
          'password': password,
          'gender': _gender,
          'weight': double.parse(_weightController.text),
          'created_at': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);
        _showSnackBar("Registrasi Berhasil!");
        setState(() => _isLoginMode = true); // Pindah ke login setelah sukses daftar
      }
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar("Error: $e");
    }
  }

  void _goToCollectionPage(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataCollectionPage(
          username: userData['username'],
          gender: userData['gender'],
          weight: userData['weight'].toString(),
        ),
      ),
    );
  }

  void _showSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? "Login Subjek" : "Daftar Subjek Baru")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(_isLoginMode ? Icons.lock_person : Icons.person_add, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
            ),
            
            // Field Tambahan jika Register
            if (!_isLoginMode) ...[
              SizedBox(height: 15),
              DropdownButtonFormField(
                value: _gender,
                decoration: InputDecoration(labelText: "Jenis Kelamin", border: OutlineInputBorder()),
                items: ["Laki-laki", "Perempuan"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _gender = val.toString()),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Berat Badan (kg)", border: OutlineInputBorder()),
              ),
            ],
            
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: Text(_isLoginMode ? "MASUK" : "DAFTAR SEKARANG"),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode ? "Belum punya data? Daftar di sini" : "Sudah terdaftar? Login di sini"),
            )
          ],
        ),
      ),
    );
  }
}