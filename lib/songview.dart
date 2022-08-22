import 'package:flutter/material.dart';

import 'package:html/parser.dart';

class SongView extends StatefulWidget {
  final String html;
  final String title;

  const SongView({super.key, required this.html, required this.title});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> {
  late ScrollController controller;
  int speed = 0;
  late String text;

  @override
  void initState() {
    controller = ScrollController();
    text = getSongAsText(widget.html);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          speed = 0;
                          controller.jumpTo(controller.offset);
                        });
                      },
                      icon: Icon(
                        Icons.pause_rounded,
                        size: 32,
                        color: speed != 0 ? Colors.black : Colors.pink,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          speed = 1;
                          controller.animateTo(
                              controller.position.maxScrollExtent,
                              duration: Duration(minutes: 3),
                              curve: Curves.linear);
                        });
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 32,
                        color: speed != 1 ? Colors.black : Colors.pink,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          speed = 2;
                          controller.animateTo(
                              controller.position.maxScrollExtent,
                              duration: Duration(minutes: 2),
                              curve: Curves.linear);
                        });
                      },
                      icon: Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: speed != 2 ? Colors.black : Colors.pink,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      text = ChordsHandler().transposeUp(text);
                    });
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 32,
                  ),
                )
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: speed == 0 ? null : NeverScrollableScrollPhysics(),
          controller: controller,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                          text: text,
                          style: TextStyle(
                              fontSize: 16, color: Colors.blueGrey[900])),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  String getSongAsText(String html) {
    var document = parse(html);
    var text = document.querySelector('[itemprop="chordsBlock"]')?.text ?? '';

    return ChordsHandler().easeChords(text);
  }
}

class ChordsHandler {
  static const Map<String, String> chordMap = {
    'A#': 'Bb',
    'Db': 'C#',
    'G#': 'Ab',
  };
  static const List<String> chordsSimple = [
    'A',
    'Bb',
    'B',
    'C',
    'C#',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab'
  ];

  static final chordRegex =
      RegExp(r'((Ab)|(A)|(Bb)|(B)|(C#)|(C)|(D)|(Eb)|(E)|(F#)|(F)|(G))');

  //Для транспозиции нужно перевести все аккорды в "простые" и проходить по массиву
  String easeChords(String song) {
    var song_ = song;
    for (var c in chordMap.entries) {
      song_ = song_.replaceAll(c.key, c.value);
    }
    return song_;
  }

  //К этому моменту все аккорды "простые"
  String transposeUp(String song) {
    var song_ = song;
    song_ = song_.replaceAllMapped(
        chordRegex, (match) => _transposeUpChord(match.group(0)!));
    return song_;
  }

  String _transposeUpChord(String chord) {
    var chord_ = chord.replaceAllMapped(chordRegex, (match) {
      var index = chordsSimple.indexOf(match.group(0)!);
      if (index == -1) {
        return chord;
      }
      return chordsSimple[(index + 1) % chordsSimple.length];
    });

    return chord_;
  }
}
