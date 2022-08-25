import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          primarySwatch: Colors.blue,
        ),
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
      yield decoded;

      try {
        await file.create(recursive: true);
        var uri = Uri.parse(
            'http://159.65.114.2:8081/${decoded.link.replaceAll('songs/', '')}');
        var request = await client.getUrl(uri);
        var response = await request.close();
        response.pipe(File(pathToFile).openWrite());
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: (() => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AuthorList(
                            authors: authors,
                            songs: songs,
                          )))),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outlined,
                    size: 48,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Исполнители',
                      style: TextStyle(fontSize: 28),
                    ),
                  )
                ],
              ),
            ),
            Divider(
              thickness: 5,
            ),
            GestureDetector(
              onTap: (() => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SongList(
                            songs: songs,
                            songsGenerator: () => songs,
                          )))),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 48,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Все песни',
                      style: TextStyle(fontSize: 28),
                    ),
                  )
                ],
              ),
            ),
            Divider(
              thickness: 5,
            ),
            GestureDetector(
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
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    size: 48,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Избранное',
                      style: TextStyle(fontSize: 28),
                    ),
                  )
                ],
              ),
            ),
            Divider(
              thickness: 5,
            ),
          ],
        ),
      ),
    );
  }
}

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
    return GestureDetector(
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
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  artist,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width / 3,
                              right: 8),
                          child: Icon(Icons.trending_up_rounded),
                        ),
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple, Colors.pink],
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          width: 100 * sqrt(pop) / sqrt(maxpop),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
