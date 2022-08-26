import 'dart:math';

import 'package:flutter/material.dart';

import 'package:song_indexer/song_list.dart';

import 'song_indexer.dart';

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
        title: Text(
          'Исполнители',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
              onPressed: (() {
                var index = Random().nextInt(authors.length);
                List<Song> songGenerator() {
                  return widget.songs
                      .where((s) => s.artist == authors[index])
                      .toList();
                }

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongList(
                              songs: songGenerator(),
                              songsGenerator: songGenerator,
                            )));
              }),
              icon: Icon(Icons.casino_rounded))
        ],
      ),
      body: Column(
        verticalDirection: VerticalDirection.up,
        children: [
          Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: authors.length,
                itemBuilder: ((context, index) {
                  return Ink(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.deepOrange[50]!, Colors.white])),
                    child: InkWell(
                      onTap: (() {
                        List<Song> songGenerator() {
                          return widget.songs
                              .where((s) => s.artist == authors[index])
                              .toList();
                        }

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SongList(
                                      songs: songGenerator(),
                                      songsGenerator: songGenerator,
                                    )));
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          authors[index],
                          style: TextStyle(fontSize: 24, fontFamily: 'Nunito'),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ),
                  );
                })),
          ),
          Material(
            color: Colors.deepOrange[50],
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: editingController,
                decoration: InputDecoration(
                  labelText: "Поиск",
                  hintText: "Поиск",
                  prefixIcon: Icon(Icons.search_outlined),
                ),
                onChanged: (String query) {
                  setState(() {
                    authors = filterArtists(query);
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> filterArtists(String query) {
    return List.from(widget.authors
        .where((a) => a.toLowerCase().contains(query.toLowerCase())));
  }
}
