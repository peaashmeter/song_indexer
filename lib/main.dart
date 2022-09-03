import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:song_indexer/chords.dart';
import 'package:song_indexer/song_indexer.dart';
import 'package:song_indexer/song_list.dart';
import 'package:song_indexer/songview.dart';

import 'author_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var indexJsonString = await rootBundle.loadString('index/songs.json');
  var savePath = (await getApplicationDocumentsDirectory()).path;

  var prefs = await SharedPreferences.getInstance();
  if (prefs.getStringList('favorite') == null) {
    prefs.setStringList('favorite', []);
  }

  //File songsFile = File('index/songs.json');

  //var jsonString = await songsFile.readAsString();

  runApp(SongApp(indexJsonString, savePath));
}

class SongApp extends StatefulWidget {
  final String jsonString;
  final String savePath;

  const SongApp(this.jsonString, this.savePath, {Key? key}) : super(key: key);

  @override
  State<SongApp> createState() => _SongAppState();
}

class _SongAppState extends State<SongApp> {
  List<Song> songs = [];
  List<String> artists = [];
  bool isLoaded = false;
  int loaded = 0;
  @override
  void initState() {
    fetchDatabase().listen((song) {
      setState(() {
        songs = songs..add(song);
        if (!artists.contains(song.artist)) {
          artists = artists..add(song.artist);
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Сборник Песен',
        theme: ThemeData(
            primarySwatch: Colors.pink,
            appBarTheme: AppBarTheme(backgroundColor: Colors.pink[400]),
            inputDecorationTheme: InputDecorationTheme(
                hintStyle: TextStyle(fontFamily: 'Nunito'),
                labelStyle: TextStyle(fontFamily: 'Nunito'),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                    borderRadius: BorderRadius.all(Radius.circular(25.0))))),
        home: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Text('Сборник песен'),
                ],
              ),
            ),
            body: MainMenu(songs, artists)));
  }

  Stream<Song> fetchDatabase() async* {
    var json = jsonDecode(widget.jsonString);

    var client = HttpClient();
    print(json['songs'].length);

    for (var song in json['songs']) {
      var decoded = Song.fromJson(jsonDecode(song));
      var pathToFile = '${widget.savePath}/${decoded.link}';

      var file = File(pathToFile);
      if (await file.exists()) {
        yield decoded;
        continue;
      }

      try {
        await file.create(recursive: true);
        var uri = Uri.parse(
            'http://159.65.114.2:8081/${decoded.link.replaceAll('songs/', '')}');
        var request = await client.getUrl(uri);
        var response = await request.close();
        response.pipe(File(pathToFile).openWrite());
        yield decoded;
      } catch (e) {
        print(e);
        continue;
      }
    }
  }

  Future handleStream(Stream<Song> songStream) async {
    await for (final song in songStream) {
      setState(() {
        songs = songs..add(song);
        artists = artists..add(song.artist);
      });
    }
  }
}

class MainMenu extends StatelessWidget {
  final List<Song> songs;
  final List<String> authors;
  const MainMenu(this.songs, this.authors, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          color: Colors.orange.withAlpha(10),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              InkWell(
                  splashColor: Colors.pink.withAlpha(30),
                  onTap: (() => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AuthorList(
                                authors: authors,
                                songs: songs,
                              )))),
                  child: MenuTile(
                    title: 'Исполнители',
                    subtitle: 'Песни, сгруппированные по исполнителям',
                    iconData: Icons.person,
                  )),
              InkWell(
                  splashColor: Colors.pink.withAlpha(30),
                  onTap: (() => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SongList(
                                songsGenerator: () => songs,
                                songs: songs,
                              )))),
                  child: MenuTile(
                    title: 'Все песни',
                    subtitle: 'Песни, отсортированные по популярности',
                    iconData: Icons.music_note_rounded,
                  )),
              InkWell(
                splashColor: Colors.pink.withAlpha(30),
                onTap: (() async {
                  Future<List<Song>> Function() songsGenerator;
                  songsGenerator = () async {
                    var prefs = await SharedPreferences.getInstance();
                    var favorites = prefs.getStringList('favorite') ?? [];
                    return songs
                        .where((s) => favorites.contains(s.link))
                        .toList();
                  };
                  var songs_ = await songsGenerator();

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SongList(
                                songs: songs_,
                                songsGenerator: songsGenerator,
                              )));
                }),
                child: MenuTile(
                    title: 'Избранное',
                    subtitle: 'Любимые песни',
                    iconData: Icons.favorite),
              ),
              InkWell(
                  splashColor: Colors.pink.withAlpha(30),
                  onTap: (() {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => LetterList()));
                  }),
                  child: MenuTile(
                      title: 'Аккорды',
                      subtitle: 'Как это играть',
                      iconData: Icons.help_rounded)),
            ],
          ),
        ),
      ]),
    );
  }
}

class MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;

  const MenuTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.iconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        leading: Icon(iconData),
        title: Text(
          title,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 20),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontFamily: 'Nunito'),
        ),
      ),
    );
  }
}
