import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:song_indexer/main.dart';
import 'package:song_indexer/songview.dart';

import 'song_indexer.dart';

class SongList extends StatefulWidget {
  final FutureOr<List<Song>> Function() songsGenerator;
  final List<Song> songs;

  const SongList(
      {super.key, required this.songsGenerator, required this.songs});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  late TextEditingController editingController;
  late List<Song> songs;

  @override
  void initState() {
    editingController = TextEditingController();
    songs = widget.songs;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сборник песен'),
        actions: [
          IconButton(
              onPressed: (() async {
                var song = songs[Random().nextInt(songs.length)];
                var dir = (await getApplicationDocumentsDirectory()).path;
                late String html;
                if (await File('$dir/${song.link}').exists()) {
                  html = await File('$dir/${song.link}').readAsString();
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
                var isFavorite = await checkIfFavorite(song.link);

                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongView(
                        html: html,
                        title: song.name,
                        artist: song.artist,
                        link: song.link,
                        isFavorite: isFavorite,
                      ),
                    ));
              }),
              icon: Icon(Icons.casino_rounded))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: editingController,
              decoration: InputDecoration(
                  labelText: "Поиск",
                  hintText: "Поиск",
                  prefixIcon: Icon(Icons.search_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)))),
              onChanged: (String query) {
                setState(() {
                  songs = filterSongs(query);
                });
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
                shrinkWrap: true,
                itemCount: songs.length,
                separatorBuilder: (context, index) {
                  return Divider();
                },
                itemBuilder: ((context, index) {
                  return SongCard(
                      title: songs[index].name,
                      artist: songs[index].artist,
                      pop: songs[index].popularity,
                      link: songs[index].link,
                      maxpop: songs.first.popularity,
                      refreshSongsCallback: (() async {
                        var songs_ = await widget.songsGenerator();
                        setState(() {
                          songs = songs_;
                        });
                      }));
                })),
          ),
        ],
      ),
    );
  }

  List<Song> filterSongs(String query) {
    return List.from(widget.songs.where((song) =>
        song.artist.toLowerCase().contains(query.toLowerCase()) ||
        song.name.toLowerCase().contains(query.toLowerCase())));
  }

  Future<bool> checkIfFavorite(String link) async {
    var prefs = await SharedPreferences.getInstance();
    var favorite = prefs.getStringList('favorite');
    return favorite!.contains(link);
  }
}
