import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:song_indexer/songview.dart';

class SongCard extends StatelessWidget {
  final String title;
  final String artist;
  final int pop;
  final int maxpop;
  final String link;
  final Function() refreshSongsCallback;

  const SongCard(
      {super.key,
      required this.title,
      required this.artist,
      required this.pop,
      required this.maxpop,
      required this.link,
      required this.refreshSongsCallback});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (() async {
        var dir = (await getApplicationDocumentsDirectory()).path;
        late String html;

        if (await File('$dir/$link').exists()) {
          html = await File('$dir/$link').readAsString();
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Ой!'),
              content: Text('Кажется, песня еще не загрузилась.'),
            ),
          );
          return;
        }

        var isFavorite = await checkIfFavorite(link);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongView(
                html: html,
                title: title,
                artist: artist,
                link: link,
                isFavorite: isFavorite,
              ),
            )).then((value) => refreshSongsCallback.call());
      }),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 1.67,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900]),
                  ),
                  Text(artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[800],
                        fontFamily: 'Nunito',
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.trending_up_rounded),
                ),
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.pink],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  width: 100 * sqrt(pop) / sqrt(maxpop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> checkIfFavorite(String link) async {
    var prefs = await SharedPreferences.getInstance();
    var favorite = prefs.getStringList('favorite');
    return favorite!.contains(link);
  }
}
