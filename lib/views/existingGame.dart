// ignore_for_file: must_be_immutable, unused_import, avoid_print, unrelated_type_equality_checks, unnecessary_null_comparison, unnecessary_string_interpolations, use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'games.dart';
import 'package:battleships/utils/sessionmanager.dart';

const String baseUrl = "http://165.227.117.48";
http.Response? httpResponse;

class ExistingGame extends StatefulWidget {
  int gameId;
  ExistingGame(this.gameId, {super.key});

  @override
  State<ExistingGame> createState() => _ExistingGameState();
}

class _ExistingGameState extends State<ExistingGame> {
  List<List<Color>> gridColors = List.generate(5, (i) => List.generate(5, (j) => Colors.white));
  List<List<String>> gridText = List.generate(5, (i) => List.generate(5, (j) => ''));
  int selectedCount = 0;
  int selectedRow = 0;
  int selectedColumn = 0;
  int currTurn = -1;
  int currPosition = -1;
  int currStatus = -1;
  bool sunkShip = false;
  List<String> currShot = [];
  List<String> currWreck = [];
  List<String> currSunk = [];
  List<String> ships = [];
  bool isCellSelected = false;

  @override
  void initState() {
    super.initState();
    fetchExistingGame();
  }

  int countSelectedCells() {
    int count = 0;
    for (var row in gridColors) {
      for (var color in row) {
        if (color == Colors.blue) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> getGameData(int gameId) async {
    if(gameId != null) {
      final url = Uri.parse('$baseUrl/games/$gameId');
      final response = await http.get(
        url,
        headers: {
          'Content-type': 'application/json',
          'Authorization': await SessionManager.getSessionToken(),
        },
      );
      final Map<String, dynamic> gameData;
      if (response.statusCode == 200) {
        gameData = await json.decode(response.body);
        final List<String> existingShips = List<String>.from(gameData['ships']);
        setState(() {
          ships = existingShips;
        });
      }
    }
  }

  Future<void> fetchExistingGame() async {
    final url = Uri.parse('$baseUrl/games/${widget.gameId}');
    final response = await http.get(
      url,
      headers: {
        'Content-type': 'application/json',
        'Authorization': await SessionManager.getSessionToken(),
      },
    );
    final Map<String, dynamic> gameData;
    if (response.statusCode == 200) {
      gameData = await json.decode(response.body);
      final List<String> existingShips = List<String>.from(gameData['ships']);
      final List<String> existingShots = List<String>.from(gameData['shots']);
      final List<String> existingWreck = List<String>.from(gameData['wrecks']);
      final List<String> existingSunk = List<String>.from(gameData['sunk']);
      setState(() {
        currTurn = gameData['turn'];
        currPosition = gameData['position'];
        currStatus = gameData['status'];
        currShot = existingShots;
        currWreck = existingWreck;
        currSunk = existingSunk;
        ships = existingShips;
      });
    }
  }

  Future<Map<String, dynamic>?> putGameData(int gameId, int selectedRow, int selectedColumn) async {
    Map<String, dynamic>? responseBody;

    try {
      final putResponse = await http.put(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': await SessionManager.getSessionToken()
        },
        body: jsonEncode({
          "shot": '${String.fromCharCode('A'.codeUnitAt(0) + selectedRow)}${selectedColumn + 1}',
        }),
      );

      http.Response httpResponse = putResponse;
      if (httpResponse.statusCode == 200) {
        responseBody = json.decode(httpResponse.body);
      }
    } catch (error) {
      print("Error during HTTP put request: $error");
    }

    return responseBody;
  }

  Future<void> showWinLoseDialog(BuildContext context, int status, int currPosition, int currTurn) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: (status == currPosition) ? const Text('You Won!') : const Text('You Lost!'),
          content: (status == currPosition) ? const Text('Congratulations! You have won the game.') : const Text('The Opponent Won.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget buildGridCellContent(bool hasShip, bool hasBomb, bool hasSunk, bool hasWreck, int currTurn, int currPosition, int currStatus) {
  if(hasSunk && hasShip) {
    return const Text(
      "🚢 💥",
      style: TextStyle(fontSize: 20),
    );
  } else if (hasShip && hasBomb) {
    return const Text(
      "🚢 💣",
      style: TextStyle(fontSize: 20),
    );
  } else if (hasBomb && hasSunk && !hasWreck) {
    return const Text(
      "💥",
      style: TextStyle(fontSize: 20),
    );
  } else if (hasBomb && !hasSunk &&  hasWreck) {
    return const Text(
      "💣 🫧",
      style: TextStyle(fontSize: 20),
    );
  } else if (hasSunk && hasWreck) {
    return const Text(
      "💥 🫧",
      style: TextStyle(fontSize: 20),
    );
  } else if (hasShip) {
    return const Text(
      "🚢",
      style: TextStyle(fontSize: 20),
    );
  } else if (hasBomb) {
    return const Text(
      "💣",
      style: TextStyle(fontSize: 20),
    );
  } else if(hasSunk) {
    return const Text(
      "💥",
      style: TextStyle(fontSize: 20),
    );
  } else if(hasWreck) {
    return const Text(
      "🫧",
      style: TextStyle(fontSize: 20),
    );
  } else {
    return Container();
  }
}

  @override
  Widget build(BuildContext context) {
    if (currTurn == -1 || currPosition == -1) {
      Future.delayed(const Duration(seconds: 1), () {
      });

      return const CircularProgressIndicator();
    } else {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Place Ships'),
            centerTitle: true,
          ),
          body: Column(children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: MediaQuery.sizeOf(context).width / (MediaQuery.sizeOf(context).height - 2*kToolbarHeight),
                ),
                itemCount: 6 * 7,
                itemBuilder: (context, index) {
                  final row = index ~/ 7;
                  final col = index % 7;
                  if (row == 0 && col == 0) {
                    return Container();
                  } else if (row == 0) {
                    if (col == 6) {
                      return Container();
                    }
                    return Center(
                      child: Text(
                        '$col',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  } else if (col == 0) {
                    return Center(
                      child: Text(
                        String.fromCharCode('A'.codeUnitAt(0) + row - 1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  } else if (col == 6) {
                    return Container();
                  } else {
                    final label = '${String.fromCharCode('A'.codeUnitAt(0) + row - 1)}$col';
                    final hasShip = ships.contains(label);
                    final hasBomb = currShot.contains(label);
                    final hasSunk = currSunk.contains(label);
                    final hasWreck = currWreck.contains(label);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (countSelectedCells() == 0) {
                            if (gridColors[row - 1][col - 1] == Colors.blue) {
                              gridColors[row - 1][col - 1] = Colors.white;
                              ships.remove(
                                  '${String.fromCharCode('A'.codeUnitAt(0) + row)}$col');
                              isCellSelected = false;
                            } else {
                              gridColors[row - 1][col - 1] = Colors.blue;
                              selectedRow = row - 1;
                              selectedColumn = col - 1;
                              isCellSelected = true;
                            }
                          } else if (isCellSelected &&
                              gridColors[row - 1][col - 1] == Colors.blue) {
                            gridColors[selectedRow][selectedColumn] = Colors.white;
                            ships.remove(
                                '${String.fromCharCode('A'.codeUnitAt(0) + selectedRow + 1)}${selectedColumn + 1}');
                            isCellSelected = false;
                          } else if (!isCellSelected &&
                              gridColors[row - 1][col - 1] == Colors.blue) {
                            gridColors[row - 1][col - 1] = Colors.white;
                            ships.remove(
                                '${String.fromCharCode('A'.codeUnitAt(0) + row)}$col');
                          } else if (!isCellSelected &&
                              countSelectedCells() < 5 &&
                              gridColors[row - 1][col - 1] != Colors.blue) {
                            gridColors[row - 1][col - 1] = Colors.blue;
                            selectedRow = row - 1;
                            selectedColumn = col - 1;
                            isCellSelected = true;
                          }
                        });
                      },
                      onHover: (isHovered) {
                        setState(() {
                          if (countSelectedCells() == 0) {
                            if (isHovered) {
                              if (gridColors[row - 1][col - 1] != Colors.blue) {
                                gridColors[row - 1][col - 1] = Colors.lightBlue; 
                              }
                            } else {
                              if (gridColors[row - 1][col - 1] != Colors.blue) {
                                gridColors[row - 1][col - 1] = Colors.white;
                              }
                            }
                          } else {
                            if (isHovered) {
                              if (gridColors[row - 1][col - 1] != Colors.blue) {
                                gridColors[row - 1][col - 1] = Colors.red;
                              }
                            } else {
                              if (gridColors[row - 1][col - 1] != Colors.blue) {
                                gridColors[row - 1][col - 1] = Colors.white;
                              }
                            }
                          }
                        });
                      },
                        child: Card(
                          color: gridColors[row - 1][col - 1],
                          child: Align(
                            alignment: Alignment.center,
                            child: buildGridCellContent(hasShip, hasBomb, hasSunk, hasWreck, currTurn, currPosition, currStatus),
                          ),
                        ),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: ElevatedButton(
                  onPressed: ((currTurn == currPosition) && (currStatus == 3)) ? () async {
                    if (countSelectedCells() == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You must place a bomb',
                            textAlign: TextAlign.center,
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else {
                      if (currShot.contains('${String.fromCharCode('A'.codeUnitAt(0) + selectedRow)}${selectedColumn + 1}')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Shot Already Played',
                              textAlign: TextAlign.center,
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                      Map<String, dynamic>? putResponseBody = await putGameData(widget.gameId, selectedRow, selectedColumn);
                      sunkShip = putResponseBody!['sunk_ship'];
                      String scaffoldText = sunkShip == true ? "Enemy Ship Hit!" : "No Enemy Ship Hit";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            scaffoldText,
                            textAlign: TextAlign.center,
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      await getGameData(widget.gameId);
                      await fetchExistingGame();

                      if (currStatus == 1 || currStatus == 2) {
                        showWinLoseDialog(context, currStatus, currPosition, currTurn);
                      }

                      setState(() {
                        isCellSelected = false;
                        gridColors[selectedRow][selectedColumn] = Colors.white;
                      });
                      // Navigator.pop(context, {'game': responseBody});
                    }
                  } : null,
                  child: const Text('Submit'),
                )
              ),
            ),
          ]));
    }
  }
}