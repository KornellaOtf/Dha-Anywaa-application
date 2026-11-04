import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: kText),
              onPressed: () {
                if (_zoom) {
                  setState(() => _zoom = false);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        title: const Text('Numbers',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: kText)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kGreen.withOpacity(0.2)),
                ),
                child: Text('$_learnedCount/${_numbers.length}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kGreen)),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: _zoom
            ? _buildDetail(key: ValueKey('num_detail_$_index'))
            : _buildGrid(key: const ValueKey('num_grid')),
      ),
    );
  }

  // ── Detail ──────────────────────────────────────────────────────────────────

  Widget _buildDetail({Key? key}) {
    final item    = _numbers[_index];
    final learned = _learned[_index];

    return KeyedSubtree(
      key: key,
      child: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 12),

          // ── Big numeral card ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: detailCardDeco(learned: learned),
              child: Column(children: [
                // Number circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: learned
                          ? [kGreen, kGreenMid]
                          : [kGreen.withOpacity(0.1), kGold.withOpacity(0.1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (learned ? kGreen : kGold).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      item['number']!,
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: learned ? Colors.white : kGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(item['anyDis']!,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: learned ? kGreen : kText)),
                const SizedBox(height: 4),
                Text(item['description']!,
                    style: const TextStyle(fontSize: 16, color: kTextSub)),
                if (learned) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kGreen.withOpacity(0.25)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_rounded,
                          color: kGreen, size: 15),
                      SizedBox(width: 5),
                      Text('Learned',
                          style: TextStyle(
                              fontSize: 13,
                              color: kGreen,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // ── Nav buttons ───────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _NumNavBtn(
              icon: Icons.chevron_left_rounded,
              enabled: _index > 0,
              onTap: () => setState(() => _index--),
            ),
            const SizedBox(width: 16),
            // Counter badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [kShadowSoft],
              ),
              child: Text('${_index + 1} / ${_numbers.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(width: 16),
            _NumNavBtn(
              icon: Icons.chevron_right_rounded,
              enabled: _index < _numbers.length - 1,
              onTap: () => setState(() => _index++),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Mark as learned ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: learned
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: kGreen.withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleLearned(_index),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Learned'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [kShadowSoft]),
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleLearned(_index),
                        icon: const Icon(Icons.add_task_outlined, size: 18),
                        label: const Text('Mark as learned'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kGreen,
                          side: const BorderSide(color: kGreen, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Grid ────────────────────────────────────────────────────────────────────

  Widget _buildGrid({Key? key}) {
    return KeyedSubtree(
      key: key,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _numbers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (_, i) {
          final item    = _numbers[i];
          final learned = _learned[i];
          return _NumGridCell(
            item: item,
            learned: learned,
            onTap: () => setState(() { _zoom = true; _index = i; }),
          );
        },
      ),
    );
  }
}

// ── Grid cell ─────────────────────────────────────────────────────────────────
class _NumGridCell extends StatefulWidget {
  final Map<String, String> item;
  final bool learned;
  final VoidCallback onTap;

  const _NumGridCell(
      {required this.item, required this.learned, required this.onTap});

  @override
  State<_NumGridCell> createState() => _NumGridCellState();
}

class _NumGridCellState extends State<_NumGridCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: gridCellDeco(learned: widget.learned),
          child: Stack(children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Number badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.learned
                        ? kGreen.withOpacity(0.15)
                        : kGreen.withOpacity(0.08),
                  ),
                  child: Center(
                    child: Text(
                      widget.item['number']!,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: widget.learned ? kGreen : kGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(widget.item['anyDis']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kText)),
                Text(widget.item['description']!,
                    style: const TextStyle(
                        fontSize: 12, color: kTextSub)),
              ],
            ),
            if (widget.learned)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: kGreen, size: 14),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────
class _NumNavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NumNavBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: enabled ? 4 : 0,
      shape: const CircleBorder(),
      color: Colors.white,
      shadowColor: kGreen.withOpacity(0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon,
              color: enabled ? kText : Colors.grey[400], size: 26),
        ),
      ),
    );
  }
}
