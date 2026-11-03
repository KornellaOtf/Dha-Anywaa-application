import 'package:dha_anywaaa/Questions.dart';
import 'package:dha_anywaaa/result_page.dart';
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quit quiz?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going',
                style: TextStyle(color: Color(0xFF1B4332))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B3A2A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    return quit ?? false;
  }

  final List<Questions> _questionsList = [
    Questions(id: 1,  answer_index: 'Rïï',     image: 'assets/word_images/giraffe.png',     question: 'Lääy man cwøli nïdï?',                                         options: ['Rii', 'Riï', 'Rïï', 'Arëën']..shuffle()),
    Questions(id: 2,  answer_index: 'Dhieng',  image: 'assets/word_images/cow.png',         question: 'Lääy man cwøli nïdï?',                                         options: ['Acwöt', 'Maath', 'Rwaath', 'Dhieng']..shuffle()),
    Questions(id: 3,  answer_index: 'ä',       image: 'assets/word_images/maize.png',       question: 'Ab__c',                                                         options: ['ä', 'ää', 'ï', 'a']..shuffle()),
    Questions(id: 4,  answer_index: 'Bøøgø',   image: 'assets/word_images/leaf.png',        question: 'Gïn cwøli nïdï',                                               options: ['Bøøgø', 'Bøøngø', 'Bøønhø', 'Bøønyø']..shuffle()),
    Questions(id: 5,  answer_index: 'ïë',      image: 'assets/word_images/hayna.png',       question: 'Od__k',                                                         options: ['ie', 'ïë', 'ïe', 'ië']..shuffle()),
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

  Color _optionColor(int pageIdx, int listIdx) {
    if (_pageSelectedIndex != pageIdx) return Colors.white;
    final q = _questionsList[pageIdx];
    final correct  = q.options[listIdx] == q.answer_index;
    final selected = _selectedIndex == listIdx;
    if (selected && correct)  return const Color(0xFFD4EDDA);
    if (selected && !correct) return const Color(0xFFFFE5E5);
    if (correct)              return const Color(0xFFD4EDDA).withOpacity(0.6);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF5F0E8);
    const green = Color(0xFF1B4332);
    const gold  = Color(0xFFC9993A);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: bg,
        body: PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questionsList.length,
          itemBuilder: (context, pageIdx) {
            final q          = _questionsList[pageIdx];
            final isAnswered = _pageSelectedIndex == pageIdx;

            return SafeArea(
              child: Column(children: [
                // ── top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18,
                            color: Color(0xFF1C1C1C)),
                        onPressed: () async {
                          final should = await _onWillPop();
                          if (should && context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Question ${pageIdx + 1} of ${_questionsList.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    // Live score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_finalResult/${_questionsList.length}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: green),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                // ── progress bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pageIdx + 1) / _questionsList.length,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(green),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── question card ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHOOSE THE WORD',
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  color: gold,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(q.question,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ]),
                  ),
                ),
                const SizedBox(height: 12),
                // ── options ───────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (_, listIdx) {
                      final isCorrect =
                          q.options[listIdx] == q.answer_index;
                      final isSelected = _selectedIndex == listIdx &&
                          _pageSelectedIndex == pageIdx;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AbsorbPointer(
                          absorbing: isAnswered,
                          child: GestureDetector(
                            onTap: () {
                              _answeredIds.add(q.id);
                              final count = _answeredIds
                                  .where((n) => n == q.id)
                                  .length;
                              setState(() {
                                _pageSelectedIndex = pageIdx;
                                _selectedIndex    = listIdx;
                                if (isCorrect && count == 1) {
                                  _finalResult++;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _optionColor(pageIdx, listIdx),
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFFE8E8E8),
                                  radius: 16,
                                  child: Text(
                                      ['A', 'B', 'C', 'D'][listIdx],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                title: Text(q.options[listIdx],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                trailing: isAnswered
                                    ? (isSelected
                                        ? Text(
                                            isCorrect
                                                ? 'Correct'
                                                : 'Not quite',
                                            style: TextStyle(
                                                color: isCorrect
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 13))
                                        : (isCorrect
                                            ? Text('Correct',
                                                style: TextStyle(
                                                    color:
                                                        Colors.green[700],
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 13))
                                            : null))
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // ── next / finish button ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            green.withOpacity(0.4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      // Disabled until user answers
                      onPressed: isAnswered
                          ? () {
                              if ((pageIdx + 1) ==
                                  _questionsList.length) {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
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
                            ? 'See results'
                            : 'Next question',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
