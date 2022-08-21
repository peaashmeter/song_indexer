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

  @override
  void initState() {
    controller = ScrollController();
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
                      controller.animateTo(controller.position.maxScrollExtent,
                          duration: Duration(minutes: 3), curve: Curves.linear);
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
                      controller.animateTo(controller.position.maxScrollExtent,
                          duration: Duration(minutes: 2), curve: Curves.linear);
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
                          text: getSongAsText(widget.html),
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
    return text;
  }
}

class ChordsHandler {
  static const List<String> chordLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  //Допускаем, что все аккорды написаны правильно
  static final chordRegex = RegExp(r'([ABCDEFG]\S*(\s|\n))');
}
