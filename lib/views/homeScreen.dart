// ignore_for_file: unnecessary_null_comparison, must_be_immutable, unused_local_variable, unused_import, use_build_context_synchronously

import 'dart:io';

import 'package:battleships/views/battleships.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/sessionmanager.dart';
import 'games.dart';
import 'loginScreen.dart';
import 'newGame.dart';
import 'existingGame.dart';

final String baseUrl = "http://165.227.117.48";

class HomeScreen extends StatefulWidget {
  Future<List<Games>>? newGameResult;
  String username;
  bool isLoggedIn;
  HomeScreen(this.newGameResult, this.isLoggedIn, this.username, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  bool gamesSelected = false;
  http.Response? httpResponse;
  Map<String, dynamic>? responseBody;
  Future<List<Games>>? activeGames;
  Future<List<Games>>? completedGames;
  List<Games> combinedGames = [];
  int? statusOfGame;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    final url = Uri.parse('$baseUrl/games');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': await SessionManager.getSessionToken(),
      },
    );

    if (widget.newGameResult != null) {
      combinedGames.addAll((await widget.newGameResult!).map((dynamic game) {
        return Games(
          id: game['id'],
          player1: game['player1'],
          player2: game['player2'],
          position: game['position'],
          status: game['status'],
          turn: game['turn'],
        );
      }));
    }

    setState(() {
      httpResponse = response;
      responseBody = json.decode(httpResponse!.body);
      if (responseBody?['games'] != null) {
        combinedGames.clear();
        combinedGames.addAll(
          (responseBody?['games'] as List<dynamic>).map((dynamic game) {
            return Games(
              id: game['id'],
              player1: game['player1'],
              player2: game['player2'],
              position: game['position'],
              status: game['status'],
              turn: game['turn'],
            );
          })
        );
      }
      activeGames = Future.value([]);

      for (var game in combinedGames) {
        statusOfGame = game.status;
        if (statusOfGame != null && (statusOfGame == 1 || statusOfGame == 2)) {
          completedGames = Future.value(combinedGames
              .where((game) => game.status == 1 || game.status == 2)
              .toList());
        } else if (statusOfGame != null &&
            (statusOfGame == 0 || statusOfGame == 3)) {
          activeGames = Future.value(combinedGames
              .where((game) => game.status == 0 || game.status == 3)
              .toList());
        }
      }
    });
  }

  Future<void> _refreshGames() async {
    await fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 0;

    void _changeSelection(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    Future<void> _doLogout() async {
      await SessionManager.clearSession();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ));
    }

    Future<void> _checkLoginStatus() async {
      final loggedIn = await SessionManager.isLoggedIn();
      final username = await SessionManager.getLoggedInUsername();

      if (!loggedIn) {
        await SessionManager.clearSession();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ));
      } else {
        setState(() {
          widget.isLoggedIn = loggedIn;
          widget.username = username;
        });
      }
    }

    return FutureBuilder<List<Games>>(
      future: gamesSelected == true ? completedGames : activeGames,
      initialData: const [],
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Battleships"),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () { 
                    _refreshGames();
                    _checkLoginStatus(); 
                  }
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.blue),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Battleships",
                            textAlign: TextAlign.justify,
                            textScaleFactor: 2.0,
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 10),
                        widget.isLoggedIn
                            ? Text("Logged in as ${widget.username}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white))
                            : const Text("Logged in as Guest",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white))
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text("New Game"),
                    selected: selectedIndex == 1,
                    onTap: () async {
                      _changeSelection(1);
                      _checkLoginStatus();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                            NewGame(""))).then((value) async {
                              setState(() {
                                fetchGames();
                              });
                            Navigator.pop(context);
                            });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.android),
                    title: const Text("New Game (AI)"),
                    selected: selectedIndex == 2,
                    onTap: () {
                      _changeSelection(2);
                      _checkLoginStatus();
                      showDialog<String?>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                                'Which AI do you want to play against?'),
                            content: SingleChildScrollView(
                             child: ListBody(
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop('random');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 8.0),
                                          Text('Random'),
                                        ],
                                      ),
                                  )
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop('perfect');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 8.0),
                                          Text('Perfect'),
                                        ],
                                      ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop('oneship');
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 8.0),
                                          Text('One Ship (A1)'),
                                        ],
                                      ),
                                  )
                                ),
                              ],
                            ),
                            ),
                          );
                        },
                      ).then((String? selectedResult) {
                        if (selectedResult != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  NewGame(selectedResult),
                            ),
                          ).then((value) async {
                            setState(() {
                              fetchGames();
                            });
                            Navigator.pop(context);
                          });
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.format_list_bulleted),
                    title: gamesSelected == false
                        ? const Text("Show Completed Games")
                        : const Text("Show Active Games"),
                    selected: selectedIndex == 3,
                    onTap: () {
                      _checkLoginStatus();
                      setState(() {
                        _changeSelection(3);
                        fetchGames();
                        Navigator.pop(context);
                        gamesSelected = !gamesSelected;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
                    selected: selectedIndex == 4,
                    onTap: () {
                      _doLogout();
                      _changeSelection(4);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            body: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final Games game = snapshot.data![index];
                  final int id = game.id!;
                  final String player1 = game.player1 ?? '';
                  final String player2 = game.player2 ?? '';
                  final int position = game.position ?? 0;
                  final int status = game.status ?? 0;
                  final int turn = game.turn ?? 0;

                  return Dismissible(
                    key: Key(game.id.toString()),
                    onDismissed: (_) async {
                      setState(() {
                        snapshot.data!.removeAt(index);
                      });
                      final url =
                          Uri.parse('$baseUrl/games/$id');
                      final response = await http.delete(
                        url,
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization':
                              await SessionManager.getSessionToken(),
                        },
                      );
                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Item with ID $id has been deleted.'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Failed to delete item. Please try again.'),
                          ),
                        );
                      }
                    },
                    background: Container(
                      color: Colors.red,
                      child: const Icon(Icons.delete),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _checkLoginStatus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ExistingGame(game.id!),
                          ),
                        ).then((value) => {
                              fetchGames()
                        });
                      },
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('#$id'),
                            player2 == ''
                                ? const Text('Waiting for opponent')
                                : Text('$player1 vs $player2'),
                            status == 0
                                ? const Text('Match Making')
                                : status == 1
                                    ? const Text('Won By Player 1')
                                    : status == 2
                                        ? const Text('Won By Player 2')
                                        : status == 3
                                            ? ((turn == position)
                                                ? const Text('Your Turn')
                                                : const Text('Their Turn'))
                                            : const Text("")
                          ],
                        ),
                      ),
                    ),
                  );
                }),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('${snapshot.error}'),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}