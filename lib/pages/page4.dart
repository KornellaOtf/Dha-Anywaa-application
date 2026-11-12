import 'package:dha_anywaaa/Questions.dart';
import 'package:dha_anywaaa/result_page.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Page4 extends StatefulWidget {
  const Page4({super.key});
  @override
  State<Page4> createState() => _Page4State();
}

class _Page4State extends State<Page4> {
  late final PageController _controller;
  int _currentPage = 0;
  int _selectedIndex = -1;
  int _pageSelectedIndex = -1;
  int _finalResult = 0;
  final List<int> _answeredIds = [];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _controller.addListener(() {
      final p = _controller.page?.round() ?? 0;
      if (p != _currentPage) setState(() => _currentPage = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1.0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [kShadowCard],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGold.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.pause_circle_rounded,
                          color: kGold, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text('Take a break?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          height: 1.25)),

                  // Message
                  const SizedBox(height: 8),
                  Text(
                      'Your progress on this quiz won\'t be saved. You can always try again later.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, height: 1.5, color: c.textSub)),
                  const SizedBox(height: 24),

                  // Side-by-side buttons
                  Row(
                    children: [
                      // Quit
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: kRust,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: kRust.withValues(alpha: 0.3))),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Quit',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Keep going
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Keep going',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return quit ?? false;
  }

  final List<Questions> _questionsList = [
    Questions(id: 1,  answer_index: 'Rïï',     image: 'assets/word_images/giraffe.png',     question: 'Lääy man cwøli nïdï?',                                         options: ['Rii', 'Riï', 'Rïï', 'Arëën']..shuffle()),
    Questions(id: 2,  answer_index: 'Dhieng',  image: 'assets/word_images/cow.png',         question: 'Lääy man cwøli nïdï?',                                         options: ['Acwöt', 'Maath', 'Rwaath', 'Dhieng']..shuffle()),
    Questions(id: 3,  answer_index: 'ä',       image: 'assets/word_images/maize.png',       question: 'Ab__c',                                                         options: ['ä', 'ää', 'ï', 'a']..shuffle()),
    Questions(id: 4,  answer_index: 'Bøøgø',   image: 'assets/word_images/leaf.png',        question: 'Gïn cwøli nïdï',                                               options: ['Bøøgø', 'Bøøngø', 'Bøønhø', 'Bøønyø']..shuffle()),
    Questions(id: 5,  answer_index: 'ïë',      image: 'assets/word_images/hyena.png',       question: 'Od__k',                                                         options: ['ie', 'ïë', 'ïe', 'ië']..shuffle()),
    Questions(id: 6,  answer_index: 'Digwey',  image: 'assets/word_images/lizard.png',      question: 'Lääy man cwøli nïdï?',                                         options: ['Digweey', 'Digweyi', 'Digwey', 'Dïgweyi']..shuffle()),
    Questions(id: 7,  answer_index: 'Maac',    image: 'assets/word_images/maac.png',        question: 'Man agïna ngø?',                                               options: ['Mac', 'Mäc', 'Maac', 'Äpö']..shuffle()),
    Questions(id: 8,  answer_index: 'Gwienø',  image: 'assets/word_images/hen.png',         question: 'Man awinynyangø?',                                             options: ['Gienø', 'Gwienø', 'Gwieno', 'Gwienö']..shuffle()),
    Questions(id: 9,  answer_index: 'Ng',      image: 'assets/word_images/lion.png',        question: '__UU.',                                                         options: ['Ny', 'Nh', 'N', 'Ng']..shuffle()),
    Questions(id: 10, answer_index: 'Nyaang',  image: 'assets/word_images/croc.png',        question: 'Man a lääna ngø?',                                             options: ['Ngaany', 'Nyaanh', 'Ngweec', 'Nyaang']..shuffle()),
    Questions(id: 11, answer_index: 'Øttø',    image: 'assets/word_images/house.png',       question: 'Man angøøni?',                                                 options: ['Øtø', 'Øttø', 'Øtto', 'Ötto']..shuffle()),
    Questions(id: 12, answer_index: 'Iith',    image: 'assets/word_images/iith.png',        question: 'Man agïnë ni kany en?',                                        options: ['Ïth', 'Ïïth', 'Iith', 'Ith']..shuffle()),
    Questions(id: 13, answer_index: 'Adiit',   image: 'assets/word_images/adiit.png',       question: 'Man awinynyangø?',                                             options: ['Adiit', 'Adiith', 'Adit', 'Adïït']..shuffle()),
    Questions(id: 14, answer_index: 'Aleerø',  image: 'assets/word_images/aleero.png',      question: 'Man awinynyangø?',                                             options: ['Alerø', 'Alëërø', 'Aleerø', 'Adwär']..shuffle()),
    Questions(id: 15, answer_index: 'Culukuk', image: 'assets/word_images/culukuk.png',     question: 'Man awinynyangø?',                                             options: ['Aleerø', 'Culukuk', 'Ditoogo', 'Awëëlö']..shuffle()),
    Questions(id: 16, answer_index: 'Dhïthuuth', image: 'assets/word_images/dhithuuth.png', question: 'Man awinynyangø?',                                             options: ['Owaaw', 'Akäna', 'Cilooro', 'Dhïthuuth']..shuffle()),
    Questions(id: 17, answer_index: 'Dibal',   image: 'assets/word_images/dibal.png',       question: 'Man awinynyangø?',                                             options: ['Oköölö', 'Agaak', 'Dibal', 'Dibëël']..shuffle()),
    Questions(id: 18, answer_index: 'Ojwaak',  image: 'assets/word_images/ojwaak.png',      question: 'Man awinynyangø?',                                             options: ['Ojwaak', 'Alwöör', 'Olwaarø', 'Aciik']..shuffle()),
    Questions(id: 19, answer_index: 'Okøøk',   image: 'assets/word_images/okook.png',       question: 'Man awinynyangø?',                                             options: ['Okøøk', 'Olwaarø', 'Aciik', 'Akuuru']..shuffle()),
    Questions(id: 20, answer_index: 'Owaaw',   image: 'assets/word_images/owaaw.png',       question: 'Man awinynyangø?',                                             options: ['Abwööla Täämö', 'Akäna', 'Dhïthuuth', 'Owaaw']..shuffle()),
    Questions(id: 21, answer_index: 'Owïïlï',  image: 'assets/word_images/owiili.png',      question: 'Man awinynyangø?',                                             options: ['Owiili', 'Owïïlï', 'Ociruunya', 'Obwöla']..shuffle()),
    Questions(id: 22, answer_index: 'Ä  Ë  Ï  Ö  U', image: 'assets/word_images/blank_image.png', question: 'Goore mo cwøl ni cwaak ojabo amooe?',                   options: ['A  E  I  O  Ø', 'A  E  B  C  Y', 'A  U  G  J  K', 'Ä  Ë  Ï  Ö  U']..shuffle()),
    Questions(id: 23, answer_index: 'Kwön marra', image: 'assets/word_images/blank_image.png', question: 'Kwön mano thaal ki møga abäc mo nyaaththa cwøli nïdï?.',     options: ['Kwön bëëlö.', 'Kwön abäc mo nyaathta.', 'Kwön marra', 'Kwön mara']..shuffle()),
    Questions(id: 24, answer_index: 'O cämö ki wïth caami mo thööth', image: 'assets/word_images/blank_image.png', question: 'Gweyi dhaanhø maae maa ninäk mo dhaanhø_______.', options: ['O ruu ni cämö', 'O cämö ki wïth caami mo thööth', 'O ruu ni bäng gïn mo ee camø', 'O määthö ki pïï mo thööth']..shuffle()),
    Questions(id: 25, answer_index: 'A  E  I  O  Ø', image: 'assets/word_images/blank_image.png', question: 'Goore mo cwøl ni cwaak odiyyø amooe?',                   options: ['A  E  I  O  Ø', 'A  E  B  C  Y', 'A  U  G  J  K', 'Ä  Ë  Ï  Ö  U']..shuffle()),
    Questions(id: 26, answer_index: 'O ruu ni bäng gïn mo ee camø', image: 'assets/word_images/blank_image.png', question: 'Akwöp dhaanhø maae maa ninäk mo dhaanhø_______.', options: ['O ruu ni cämö', 'O cämö ki cam mo dwøng', 'O ruu ni bäng gïn mo ee camø', 'O cämo ki wïth caami mo thööth']..shuffle()),
    Questions(id: 27, answer_index: 'Waa',     image: 'assets/word_images/blank_image.png', question: 'Cöök wäru mana näk dhaagø cwøli gø nïdï?',                     options: ['Mara', 'Wära', 'Waa', 'Näära']..shuffle()),
    Questions(id: 28, answer_index: 'Omøt',    image: 'assets/word_images/blank_image.png', question: 'ninäk mo kiper dhaagø dikøbø na Ariet, kiper dïcwøø o købi nïdï?', options: ['Owäär', 'Obäng', 'Ojulu', 'Omøt']..shuffle()),
    Questions(id: 29, answer_index: 'Okëëlö / Akëëlö', image: 'assets/word_images/blank_image.png', question: 'nyilaal mano nywøl køøt cïp jwøki cwøli nïdï?',       options: ['Owäär / Awäär', 'Okëëlö / Akëëlö', 'Opiew / Apiew', 'Ojwaatø / Ajwaatø']..shuffle()),
    Questions(id: 30, answer_index: 'Nyigwøø ki Cham', image: 'assets/word_images/blank_image.png', question: 'nyeng mooa näk mo di caa kiper dhaagø ki dicwøø amooe dëët mooyi?', options: ['Nyigwøø ki Cham', 'Nyigwøø  ko Oriemmi', 'Nyimulu ko Okëëlö', 'Ojwaatø ka Ajwaatø']..shuffle()),
    Questions(id: 31, answer_index: 'Ocale',   image: 'assets/word_images/blank_image.png', question: 'Nyeng mano cak ki køøt juu mo peny amane?',                     options: ['Okëëlö', 'Ocale', 'Oriemmi', 'Abäng']..shuffle()),
  ]..shuffle();

  Color _optionBgColor(int pageIdx, int listIdx) {
    if (_pageSelectedIndex != pageIdx) return context.c.card;
    final q        = _questionsList[pageIdx];
    final correct  = q.options[listIdx] == q.answer_index;
    final selected = _selectedIndex == listIdx;
    if (selected && correct)  return const Color(0xFF28A745).withValues(alpha: 0.20);
    if (selected && !correct) return const Color(0xFFDC3545).withValues(alpha: 0.20);
    if (correct)              return const Color(0xFF28A745).withValues(alpha: 0.10);
    return context.c.card;
  }

  Color _optionBorderColor(int pageIdx, int listIdx) {
    if (_pageSelectedIndex != pageIdx) return context.c.border;
    final q        = _questionsList[pageIdx];
    final correct  = q.options[listIdx] == q.answer_index;
    final selected = _selectedIndex == listIdx;
    if (selected && correct)  return const Color(0xFF28A745);
    if (selected && !correct) return const Color(0xFFDC3545);
    if (correct)              return const Color(0xFF28A745).withValues(alpha: 0.5);
    return context.c.border;
  }

  /// Fill-in-the-blank feedback: once the correct option is tapped, the blank
  /// (a run of underscores) is replaced by the answer so the learner sees the
  /// whole completed word, e.g. `__UU.` -> `NgUU.`. The inserted letters are
  /// highlighted in gold. Wrong picks leave the blank untouched.
  static const _questionStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.3);

  Widget _questionText(Questions q, int pageIdx) {
    final answeredCorrect = _pageSelectedIndex == pageIdx &&
        _selectedIndex >= 0 &&
        _selectedIndex < q.options.length &&
        q.options[_selectedIndex] == q.answer_index;
    final blank = RegExp('_+').firstMatch(q.question);
    if (answeredCorrect && blank != null) {
      return Text.rich(TextSpan(style: _questionStyle, children: [
        TextSpan(text: q.question.substring(0, blank.start)),
        TextSpan(
            text: q.answer_index,
            style: const TextStyle(color: kGold)),
        TextSpan(text: q.question.substring(blank.end)),
      ]));
    }
    return Text(q.question, style: _questionStyle);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: context.c.bg,
        body: PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questionsList.length,
          itemBuilder: (context, pageIdx) {
            final q          = _questionsList[pageIdx];
            final isAnswered = _pageSelectedIndex == pageIdx;

            return SafeArea(
              child: Column(children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(children: [
                    Material(
                      elevation: 3,
                      shape: const CircleBorder(),
                      color: context.c.card,
                      child: IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: context.c.text),
                        onPressed: () async {
                          final should = await _onWillPop();
                          if (should && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Question ${pageIdx + 1} of ${_questionsList.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    // Live score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: kGreen.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '$_finalResult/${_questionsList.length}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.c.accent),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),

                // ── Progress bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0,
                          end: (pageIdx + 1) / _questionsList.length),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 6,
                        backgroundColor: context.c.border,
                        color: kGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Question image (picture questions only) ─────────────
                if (!q.image.contains('blank_image')) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: context.c.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [kShadowCard],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        q.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Question card ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kGreen,
                      boxShadow: [
                        BoxShadow(
                          color: kGreen.withValues(alpha: 0.32),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHOOSE THE WORD',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.8,
                                  color: kGold,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          _questionText(q, pageIdx),
                        ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Options ─────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (_, listIdx) {
                      final isCorrect =
                          q.options[listIdx] == q.answer_index;
                      final isSelected =
                          _selectedIndex == listIdx &&
                              _pageSelectedIndex == pageIdx;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AbsorbPointer(
                          absorbing: isAnswered,
                          child: _OptionTile(
                            label: q.options[listIdx],
                            letter: ['A', 'B', 'C', 'D'][listIdx],
                            answered: isAnswered,
                            selected: isSelected,
                            correct: isCorrect,
                            bgColor:
                                _optionBgColor(pageIdx, listIdx),
                            borderColor:
                                _optionBorderColor(pageIdx, listIdx),
                            onTap: () {
                              _answeredIds.add(q.id);
                              final count = _answeredIds
                                  .where((n) => n == q.id)
                                  .length;
                              setState(() {
                                _pageSelectedIndex = pageIdx;
                                _selectedIndex = listIdx;
                                if (isCorrect && count == 1) {
                                  _finalResult++;
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Next / finish ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isAnswered
                            ? [
                                BoxShadow(
                                  color: kGreen.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : const [kShadowSoft],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              kGreen.withValues(alpha: 0.35),
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        onPressed: isAnswered
                            ? () {
                                if ((pageIdx + 1) ==
                                    _questionsList.length) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          settings: const RouteSettings(name: 'quiz_result'),
                                          builder: (_) => Result(
                                              finalResult:
                                                  _finalResult,
                                              total: _questionsList
                                                  .length)));
                                } else {
                                  _controller.nextPage(
                                      duration: const Duration(
                                          milliseconds: 400),
                                      curve: Curves.easeInOut);
                                }
                              }
                            : null,
                        child: Text(
                          (pageIdx + 1) == _questionsList.length
                              ? 'See results  →'
                              : 'Next question  →',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

// ── Animated option tile ──────────────────────────────────────────────────────
class _OptionTile extends StatefulWidget {
  final String label;
  final String letter;
  final bool answered;
  final bool selected;
  final bool correct;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.letter,
    required this.answered,
    required this.selected,
    required this.correct,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _pressed = false;
  bool _popped = false;

  @override
  void didUpdateWidget(covariant _OptionTile old) {
    super.didUpdateWidget(old);
    if (widget.answered && !old.answered) {
      // Trigger pop animation when answered
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _popped = true);
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _popped = false);
      });
    }
  }

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
        scale: _popped
            ? 1.02
            : (_pressed ? 0.97 : 1.0),
        duration: Duration(
            milliseconds: _popped ? 200 : 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.borderColor, width: 1.5),
            boxShadow: [kShadowSoft],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: CircleAvatar(
              radius: 17,
              backgroundColor: widget.answered && widget.selected
                  ? widget.correct
                      ? const Color(0xFF28A745).withValues(alpha: 0.15)
                      : const Color(0xFFDC3545).withValues(alpha: 0.15)
                  : context.c.border,
              child: Text(
                widget.letter,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: widget.answered && widget.selected
                      ? widget.correct
                          ? const Color(0xFF28A745)
                          : const Color(0xFFDC3545)
                      : context.c.textSub,
                ),
              ),
            ),
            title: Text(widget.label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.c.text)),
            subtitle: widget.answered && (widget.selected || widget.correct)
                ? Text(
                    widget.selected
                        ? (widget.correct ? 'Correct' : 'Not quite')
                        : 'Correct answer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.correct
                          ? const Color(0xFF28A745)
                          : kRust,
                    ),
                  )
                : null,
            trailing: widget.answered
                ? (widget.selected
                    ? Icon(
                        widget.correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: widget.correct
                            ? const Color(0xFF28A745)
                            : const Color(0xFFDC3545),
                        size: 22,
                      )
                    : (widget.correct
                        ? const Icon(Icons.check_circle_outline_rounded,
                            color: Color(0xFF28A745), size: 20)
                        : null))
                : null,
          ),
        ),
      ),
    );
  }
}
