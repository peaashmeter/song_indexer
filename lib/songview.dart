import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:html/parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:song_indexer/note_handler.dart';
import 'package:song_indexer/transpose_handler.dart';

import 'chords.dart';

class SongView extends StatefulWidget {
  final String html;
  final String title;
  final String artist;
  final String link;
  final bool isFavorite;
  final int initialTransposition;

  const SongView(
      {super.key,
      required this.html,
      required this.title,
      required this.artist,
      required this.link,
      required this.isFavorite,
      required this.initialTransposition});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> with TickerProviderStateMixin {
  late final ScrollController scrollController;

  late String text;
  double sliderHeight = 0;
  double sliderOpacity = 0;
  int speed = 0;
  double textSize = 15;
  bool isTuningSize = false;
  late bool isFavorite;

  late int transposition;

  @override
  void initState() {
    scrollController = ScrollController();
    text = getSongAsText(widget.html);

    isFavorite = widget.isFavorite;
    transposition = widget.initialTransposition;
    for (var i = 0; i < transposition; i++) {
      text = ChordsHandler().transposeUp(text);
    }

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w700),
              ),
              Text(
                widget.artist,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[100],
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back)),
          actions: [
            IconButton(
              onPressed: () => _editNote(),
              icon: Icon(Icons.edit_note_rounded),
            ),
            IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LetterList()));
                },
                icon: Icon(Icons.help_outline_rounded)),
            IconButton(
                onPressed: () async {
                  var prefs = await SharedPreferences.getInstance();
                  var favorite = prefs.getStringList('favorite')!;

                  if (!isFavorite) {
                    favorite.add(widget.link);
                  } else {
                    favorite.remove(widget.link);
                  }
                  await prefs.setStringList('favorite', favorite);
                  setState(() {
                    isFavorite = !isFavorite;
                  });
                },
                icon: Icon(isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded))
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange[50],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                      child: SizedBox(
                          height: sliderHeight,
                          child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                              opacity: sliderOpacity,
                              child: SliderTheme(
                                data: SliderThemeData(
                                    thumbColor: Colors.pink,
                                    activeTrackColor: Colors.purple,
                                    inactiveTrackColor: Colors.purple[50]),
                                child: Slider(
                                    value: textSize,
                                    min: 10,
                                    max: 20,
                                    onChanged: (value) {
                                      setState(() {
                                        textSize = value;
                                      });
                                    }),
                              )))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                speed = 0;
                                scrollController
                                    .jumpTo(scrollController.offset);
                              });
                            },
                            icon: Icon(
                              Icons.pause_circle_outline,
                              size: 32,
                              color: speed != 0 ? Colors.black : Colors.pink,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              var duration = getDurationOfAutoScroll(
                                  180, scrollController);
                              setState(() {
                                speed = 1;
                                scrollController.animateTo(
                                    scrollController.position.maxScrollExtent,
                                    duration: duration,
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
                              var duration = getDurationOfAutoScroll(
                                  120, scrollController);
                              setState(() {
                                speed = 2;
                                scrollController.animateTo(
                                    scrollController.position.maxScrollExtent,
                                    duration: duration,
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
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  isTuningSize = !isTuningSize;
                                  sliderHeight = isTuningSize ? 50 : 0;
                                  sliderOpacity = isTuningSize ? 1 : 0;
                                });
                              },
                              icon: Icon(
                                Icons.text_format_outlined,
                                size: 32,
                                color:
                                    !isTuningSize ? Colors.black : Colors.pink,
                              )),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                text = ChordsHandler().transposeUp(text);
                                transposition = (transposition + 1) % 12;
                              });
                              TransposeDataHandler()
                                  .addTransposition(widget.link, transposition);
                            },
                            icon: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                text = ChordsHandler().transposeDown(text);
                                transposition = (transposition - 1) % 12;
                              });
                              TransposeDataHandler()
                                  .addTransposition(widget.link, transposition);
                            },
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 32,
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  for (var i = 0; i < transposition; i++) {
                                    text = ChordsHandler().transposeDown(text);
                                  }
                                  transposition = 0;
                                });
                              },
                              icon: Icon(
                                Icons.restore_outlined,
                                color: transposition == 0
                                    ? Colors.black
                                    : Colors.pink,
                                size: 32,
                              ))
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: NotificationListener(
          onNotification: (n) {
            if (n is ScrollEndNotification) {
              SchedulerBinding.instance.addPostFrameCallback(
                (timeStamp) => setState(() {
                  speed = 0;
                }),
              );
            }
            return true;
          },
          child: SingleChildScrollView(
            controller: scrollController,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RichText(
                      text: TextSpan(
                          text: text.replaceAll('	', ''),
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                              fontSize: textSize,
                              color: Colors.blueGrey[900])),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  //Чем меньше нужно пролистать, тем меньше времени на пролистывание
  Duration getDurationOfAutoScroll(
      int fullTime, ScrollController scrollController) {
    var completed =
        scrollController.offset / scrollController.position.maxScrollExtent;
    var seconds = (fullTime * (1 - completed)).toInt();
    return Duration(seconds: seconds);
  }

  String getSongAsText(String html) {
    var document = parse(html);
    var text = document.querySelector('[itemprop="chordsBlock"]')?.text ?? '';

    return ChordsHandler().easeChords(text);
  }

  _editNote() async {
    final notesMap = await NotesDataHandler().getNotesMap();
    final initialNote = notesMap[widget.link] ?? '';
    final controller = TextEditingController(text: initialNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: Text(
            'Заметка',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey[900]),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
              )),
              maxLines: 5,
            ),
          )),
    ).then((_) => NotesDataHandler().setNote(widget.link, controller.text));
  }
}

class ChordsHandler {
  static const Map<String, String> chordMap = {
    'A#': 'Bb',
    'Db': 'C#',
    'D#': 'Eb',
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

  String transposeDown(String song) {
    var song_ = song;
    song_ = song_.replaceAllMapped(
        chordRegex, (match) => _transposeDownChord(match.group(0)!));
    return song_;
  }

  String _transposeDownChord(String chord) {
    var chord_ = chord.replaceAllMapped(chordRegex, (match) {
      var index = chordsSimple.indexOf(match.group(0)!);
      if (index == -1) {
        return chord;
      }
      return chordsSimple[(index - 1) % chordsSimple.length];
    });

    return chord_;
  }
}
