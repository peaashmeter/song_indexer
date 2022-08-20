import 'package:flutter/material.dart';

import 'package:html/parser.dart';

class SongView extends StatelessWidget {
  final String html;
  final String title;

  const SongView({super.key, required this.html, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: SingleChildScrollView(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      text: TextSpan(
                          text: getSongAsText(html),
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
