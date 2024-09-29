import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:song_indexer/chords.dart';
import 'package:song_indexer/song_list.dart';

import 'author_list.dart';
import 'song.dart';

const endpoint = 'http://45.91.8.102:8081';

late SharedPreferences prefs;
late StreamHandler streamHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var jsonString = await rootBundle.loadString('index/songs.json');
  var savePath = (await getApplicationDocumentsDirectory()).path;

  prefs = await SharedPreferences.getInstance();
  if (prefs.getStringList('favorite') == null) {
    await prefs.setStringList('favorite', []);
  }

  streamHandler = StreamHandler(jsonString, savePath);

  runApp(SongApp());
}

class SongApp extends StatefulWidget {
  const SongApp({Key? key}) : super(key: key);

  @override
  State<SongApp> createState() => _SongAppState();
}

class _SongAppState extends State<SongApp> {
  List<Song> songs = [];
  List<String> artists = [];
  int loaded = 0;

  late StreamSubscription<Song> subscription;
  @override
  void initState() {
    subscription = streamHandler.stream.listen((song) {
      setState(() {
        songs = songs..add(song);
        if (!artists.contains(song.artist)) {
          artists = artists..add(song.artist);
        }
      });
    });
    streamHandler.addListener(() {
      subscription = streamHandler.stream.listen((song) {
        setState(() {
          songs = songs..add(song);
          if (!artists.contains(song.artist)) {
            artists = artists..add(song.artist);
          }
        });
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
                    borderRadius: BorderRadius.all(Radius.circular(25.0)))),
            useMaterial3: false),
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
}

class StreamHandler extends ChangeNotifier {
  final String jsonString;
  final String savePath;

  late int index;

  late bool downloading;

  late Stream<Song> stream;
  late dynamic json;

  StreamHandler(this.jsonString, this.savePath) {
    stream = fetchDatabase();
    index = 0;
    json = jsonDecode(jsonString);
    downloading = prefs.getBool('downloading') ?? true;
  }

  Stream<Song> fetchDatabase() async* {
    var client = HttpClient();

    for (var song in (json['songs'] as List).skip(index)) {
      var decoded = Song.fromJson(jsonDecode(song));
      var pathToFile = '$savePath/${decoded.link}';

      var file = File(pathToFile);
      if (await file.exists()) {
        index++;
        yield decoded;

        continue;
      }

      if (!downloading) break;

      try {
        await file.create(recursive: true);
        var uri =
            Uri.parse('$endpoint/${decoded.link.replaceAll('songs/', '')}');
        var request = await client.getUrl(uri);
        var response = await request.close();
        response.pipe(File(pathToFile).openWrite());
        index++;
        yield decoded;
      } catch (e) {
        index++;
        continue;
      }
    }
  }

  void pause() {
    downloading = false;
  }

  void resume() {
    downloading = true;
    stream = fetchDatabase();
    notifyListeners();
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
              SwitchTile(
                  title: 'Скачивание песен',
                  iconData: Icons.downloading_outlined,
                  onChanged: (value) async {
                    await prefs.setBool('downloading', value);

                    value ? streamHandler.resume() : streamHandler.pause();
                  })
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

class SwitchTile extends StatefulWidget {
  final String title;

  final IconData iconData;
  final Function(bool) onChanged;

  const SwitchTile(
      {Key? key,
      required this.title,
      required this.iconData,
      required this.onChanged})
      : super(key: key);

  @override
  State<SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<SwitchTile> {
  late bool downloading;

  @override
  void initState() {
    downloading = prefs.getBool('downloading') ?? true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        leading: Icon(widget.iconData),
        title: Text(
          widget.title,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 20),
        ),
        trailing: Switch(
            value: downloading,
            onChanged: (value) async {
              setState(() {
                downloading = value;
              });
              await widget.onChanged(value);
            }),
      ),
    );
  }
}
