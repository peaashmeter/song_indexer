import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:song_indexer/song_indexer.dart';
import 'package:song_indexer/webview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var indexJsonString = await rootBundle.loadString('index/songs.json');
  var savePath = (await getApplicationDocumentsDirectory()).path;

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
  List<String> authors = [];
  bool isLoaded = false;
  int loaded = 0;
  @override
  void initState() {
    fetchDatabase().then((s) {
      List<String> a = [];
      for (var song in s) {
        if (!a.contains(song.artist)) {
          a.add(song.artist);
        }
      }

      setState(
        () {
          isLoaded = true;
          songs = s;
          authors = a;
        },
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      return MaterialApp(
          title: 'Сборник Песен',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Scaffold(
              appBar: AppBar(
                title: Text('Сборник песен'),
              ),
              body: MainMenu(songs, authors)));
    } else {
      return MaterialApp(
          title: 'Сборник Песен',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Scaffold(
              appBar: AppBar(
                title: Text('Сборник песен'),
              ),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Загружено песен: $loaded'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              )));
    }
  }

  Future<List<Song>> fetchDatabase() async {
    var json = jsonDecode(widget.jsonString);

    var client = HttpClient();

    List<Song> songList = [];
    for (var song in json['songs']) {
      var decoded = Song.fromJson(jsonDecode(song));
      var pathToFile = '${widget.savePath}/${decoded.link}';

      var file = File(pathToFile);

      if (file.existsSync()) {
        songList.add(decoded);
        setState(() {
          loaded++;
        });
        continue;
      } else {
        try {
          await file.create(recursive: true);
          var uri = Uri.parse(
              'http://159.65.114.2:8081/${decoded.link.replaceAll('songs/', '')}');
          var request = await client.getUrl(uri);
          var response = await request.close()
            ..pipe(File(pathToFile).openWrite());
          songList.add(decoded);
          setState(() {
            loaded++;
          });
        } catch (e) {
          continue;
        }
      }
    }

    return songList;
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
                  Text(
                    'Исполнители',
                    style: TextStyle(fontSize: 28),
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
                      builder: (context) => SongList(songs: songs)))),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 48,
                  ),
                  Text(
                    'Все песни',
                    style: TextStyle(fontSize: 28),
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

class SongList extends StatefulWidget {
  final List<Song> songs;

  const SongList({super.key, required this.songs});

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
                var html = await File('$dir/${song.link}').readAsString();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongView(
                        html: html,
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
                    name: songs[index].name,
                    artist: songs[index].artist,
                    link: songs[index].link,
                  );
                })),
          ),
        ],
      ),
    );
  }

  List<Song> filterSongs(String query) {
    return List.from(widget.songs.where((song) =>
        song.artist.toLowerCase().contains(query) ||
        song.name.toLowerCase().contains(query)));
  }
}

class AuthorList extends StatefulWidget {
  final List<Song> songs;
  final List<String> authors;

  const AuthorList({super.key, required this.songs, required this.authors});

  @override
  State<AuthorList> createState() => _AuthorListState();
}

class _AuthorListState extends State<AuthorList> {
  late TextEditingController editingController;
  late List<String> authors;

  @override
  void initState() {
    editingController = TextEditingController();
    authors = widget.authors;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сборник песен'),
        actions: [
          IconButton(
              onPressed: (() {
                var author = Random().nextInt(authors.length);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongList(
                            songs: widget.songs
                                .where((s) => s.artist == authors[author])
                                .toList())));
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
                  authors = filterSongs(query);
                });
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
                shrinkWrap: true,
                itemCount: authors.length,
                separatorBuilder: (context, index) {
                  return Divider();
                },
                itemBuilder: ((context, index) {
                  return GestureDetector(
                    onTap: (() => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SongList(
                                songs: widget.songs
                                    .where((s) => s.artist == authors[index])
                                    .toList())))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        authors[index],
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                })),
          ),
        ],
      ),
    );
  }

  List<String> filterSongs(String query) {
    return List.from(widget.authors
        .where((a) => a.toLowerCase().contains(query.toLowerCase())));
  }
}

class SongCard extends StatelessWidget {
  final String name;
  final String artist;
  final String link;

  const SongCard(
      {super.key,
      required this.name,
      required this.artist,
      required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (() async {
        var dir = (await getApplicationDocumentsDirectory()).path;
        var html = await File('$dir/$link').readAsString();
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongView(
                html: html,
              ),
            ));
      }),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 18),
            ),
            Text(
              artist,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }
}
