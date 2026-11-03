import 'package:dha_anywaaa/components/savedData.dart';
import 'package:flutter/material.dart';

class NameEntry extends StatefulWidget {
  const NameEntry({super.key});
  State<NameEntry> createState() => _NameEntryState();
}

class _NameEntryState extends State<NameEntry> {
  final SavedData savedData = SavedData();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String name = '';

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF5F0E8);
    const green = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text('Welcome to',
                    style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
                const SizedBox(height: 4),
                const Text('Obwöc paac',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C))),
                const SizedBox(height: 4),
                const Text('Dha Anywaa learning hub',
                    style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
                const SizedBox(height: 60),
                TextFormField(
                  onChanged: (val) => setState(() => name = val),
                  validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                  decoration: InputDecoration(
                    labelText: 'Enter your name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: green, width: 2),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        savedData.setName(name);
                        Navigator.pushReplacementNamed(context, 'home_page');
                      }
                    },
                    child: const Text('Get started →',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
