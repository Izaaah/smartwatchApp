import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/ambil-data/data_collection_page.dart';

class SubjectSetupPage extends StatefulWidget {
  @override
  _SubjectSetupPageState createState() => _SubjectSetupPageState();
}

class _SubjectSetupPageState extends State<SubjectSetupPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = "Laki-laki";
  bool _isRegistered = false;

  // Fungsi Registrasi & Simpan Profil
  void _startSession() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Isi semua data dulu ya!")));
      return;
    }

    // Simpan/Update profil subjek ke Firestore
    await FirebaseFirestore.instance.collection('users_skripsi').doc(_usernameController.text).set({
      'username': _usernameController.text,
      'password': _passwordController.text, // Password sederhana agar data tidak tercampur
      'gender': _gender,
      'weight': double.parse(_weightController.text),
      'last_session': FieldValue.serverTimestamp(),
    });

    // Lanjut ke halaman perekaman dengan membawa data username
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataCollectionPage(
          username: _usernameController.text,
          gender: _gender,
          weight: _weightController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrasi Subjek Skripsi")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.assignment_ind, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username (Nama Singkat)", border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
            ),
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
              decoration: InputDecoration(labelText: "Berat Badan (Kg)", border: OutlineInputBorder()),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startSession,
                child: Text("MULAI AMBIL DATA", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}