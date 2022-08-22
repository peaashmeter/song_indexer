import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:html/parser.dart';

class SongView extends StatefulWidget {
  final String html;
  final String title;
  final String artist;

  const SongView(
      {super.key,
      required this.html,
      required this.title,
      required this.artist});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> with TickerProviderStateMixin {
  late final ScrollController scrollController;

  late String text;
  double sliderHeight = 0;
  double sliderOpacity = 0;
  int speed = 0;
  double textSize = 16;
  bool isTuningSize = false;

  @override
  void initState() {
    scrollController = ScrollController();
    text = getSongAsText(widget.html);

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
            children: [
              Text(widget.title),
              Text(
                widget.artist,
                style: TextStyle(fontSize: 14, color: Colors.grey[100]),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
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
                                  min: 12,
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
                              scrollController.jumpTo(scrollController.offset);
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
                            setState(() {
                              speed = 1;
                              scrollController.animateTo(
                                  scrollController.position.maxScrollExtent,
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
                              scrollController.animateTo(
                                  scrollController.position.maxScrollExtent,
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
                              color: !isTuningSize ? Colors.black : Colors.pink,
                            )),
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
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              text = ChordsHandler().transposeDown(text);
                            });
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 32,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ],
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
                          text: text,
                          style: TextStyle(
                              fontSize: textSize, color: Colors.blueGrey[900])),
                    ),
                  ),
                ),
              ],
            ),
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
