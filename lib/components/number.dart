import 'package:dha_anywaaa/components/savedData.dart';
import 'package:flutter/material.dart';

// Numbers need a custom grid (big numeral display) so we keep a slim
// StatefulWidget instead of delegating to DetailScreen.
class Number extends StatefulWidget {
  const Number({super.key});
  @override
  State<Number> createState() => _NumberState();
}

class _NumberState extends State<Number> {
  bool _zoom = false;
  int _index = 0;
  int _learnedCount = 0;
  late List<bool> _learned;
  final SavedData _savedData = SavedData();

  static const String _category = 'number';

  static const List<Map<String, String>> _numbers = [
    {'number': '1',  'description': 'One',   'anyDis': 'Aciel'},
    {'number': '2',  'description': 'Two',   'anyDis': 'Ariew'},
    {'number': '3',  'description': 'Three', 'anyDis': 'Adäk'},
    {'number': '4',  'description': 'Four',  'anyDis': 'Angween'},
    {'number': '5',  'description': 'Five',  'anyDis': 'Abïc'},
    {'number': '6',  'description': 'Six',   'anyDis': 'Abïciel'},
    {'number': '7',  'description': 'Seven', 'anyDis': 'Abïriø'},
    {'number': '8',  'description': 'Eight', 'anyDis': 'Abära'},
    {'number': '9',  'description': 'Nine',  'anyDis': 'Abïngween'},
    {'number': '10', 'description': 'Ten',   'anyDis': 'Apaar'},
  ];

  @override
  void initState() {
    super.initState();
    _learned = List.filled(_numbers.length, false);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    int count = 0;
    final loaded = <bool>[];
    for (int i = 0; i < _numbers.length; i++) {
      final v = await _savedData.isLearned(_category, i);
      loaded.add(v);
      if (v) count++;
    }
    if (!mounted) return;
    setState(() { _learned = loaded; _learnedCount = count; });
  }

  Future<void> _toggleLearned(int i) async {
    final val = !_learned[i];
    await _savedData.setLearned(_category, i, value: val);
    final count = await _savedData.learnedCount(_category, _numbers.length);
    if (!mounted) return;
    setState(() { _learned[i] = val; _learnedCount = count; });
  }

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF5F0E8);
    const green = Color(0xFF1B4332);
    const rust  = Color(0xFF8B3A2A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF1C1C1C)),
              onPressed: () {
                if (_zoom) setState(() => _zoom = false);
                else Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Text('Numbers'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_learnedCount/${_numbers.length}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: green)),
              ),
            ),
          ),
        ],
      ),
      body: _zoom ? _buildDetail(green, rust) : _buildGrid(green),
    );
  }

  Widget _buildDetail(Color green, Color rust) {
    final item    = _numbers[_index];
    final learned = _learned[_index];

    return SingleChildScrollView(
      child: Column(children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: learned ? green.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: learned ? Border.all(color: green, width: 1.5) : null,
            ),
            child: Column(children: [
              Text(item['number']!,
                  style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: green)),
              const SizedBox(height: 8),
              Text(item['anyDis']!,
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: green)),
              Text(item['description']!,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
              if (learned) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_rounded, color: green, size: 16),
                  const SizedBox(width: 4),
                  Text('Learned',
                      style: TextStyle(
                          fontSize: 13, color: green, fontWeight: FontWeight.w600)),
                ]),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
            radius: 28, backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF1C1C1C)),
              onPressed: () { if (_index > 0) setState(() => _index--); },
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 36, backgroundColor: rust,
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 28, backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF1C1C1C)),
              onPressed: () {
                if (_index < _numbers.length - 1) setState(() => _index++);
              },
            ),
          ),
        ]),
        const SizedBox(height: 16),
        learned
            ? ElevatedButton.icon(
                onPressed: () => _toggleLearned(_index),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Learned'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () => _toggleLearned(_index),
                icon: const Icon(Icons.radio_button_unchecked, size: 18),
                label: const Text('Mark as learned'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: BorderSide(color: green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildGrid(Color green) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _numbers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.0),
      itemBuilder: (_, i) {
        final item    = _numbers[i];
        final learned = _learned[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() { _zoom = true; _index = i; }),
          child: Container(
            decoration: BoxDecoration(
              color: learned ? green.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: learned ? Border.all(color: green.withOpacity(0.4)) : null,
            ),
            child: Stack(children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(item['number']!,
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: green)),
                const SizedBox(height: 4),
                Text(item['anyDis']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1C1C1C))),
                Text(item['description']!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF666666))),
              ]),
              if (learned)
                Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.check_circle_rounded,
                      color: green, size: 18)),
            ]),
          ),
        );
      },
    );
  }
}
