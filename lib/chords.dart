import 'package:flutter/material.dart';
import 'package:song_indexer/songview.dart';

class LetterList extends StatefulWidget {
  const LetterList({super.key});

  @override
  State<LetterList> createState() => _LetterListState();
}

class _LetterListState extends State<LetterList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Аккорды',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: ChordsHandler.chordsSimple
            .map((chord) => Ink(
                  decoration: BoxDecoration(color: Colors.orange.withAlpha(10)),
                  child: InkWell(
                    splashColor: Colors.pink.withAlpha(30),
                    onTap: (() {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChordList(letter: chord)));
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          chord,
                          style: TextStyle(fontSize: 40, fontFamily: 'Nunito'),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class ChordList extends StatelessWidget {
  final String letter;
  const ChordList({Key? key, required this.letter}) : super(key: key);

  static List<String> chords = [
    '',
    'm',
    '6',
    '7',
    '9',
    'm6',
    'm7',
    'maj7',
    'dim',
    '+',
    'sus'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Аккорды',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        children: chords
            .map((chord) => Ink(
                  decoration: BoxDecoration(color: Colors.orange.withAlpha(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$letter$chord',
                              style:
                                  TextStyle(fontSize: 20, fontFamily: 'Nunito'),
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          Image.asset(
                            'assets/chords/$letter$chord.png',
                            scale: 2.5,
                          )
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
