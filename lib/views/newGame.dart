// ignore_for_file: must_be_immutable, unused_local_variable, unnecessary_null_comparison, use_build_context_synchronously

import 'package:battleships/utils/sessionmanager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "http://165.227.117.48";
http.Response? httpResponse;

class NewGame extends StatefulWidget {
  String? selectedResult;
  NewGame(this.selectedResult, {super.key});

  @override
  State<NewGame> createState() => _NewGameState();
}

class _NewGameState extends State<NewGame> {
  List<List<Color>> gridColors = List.generate(5, (i) => List.generate(5, (j) => Colors.white));
  List<String> ships = [];
  int gameId = 0;

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

  Future<Map<String, dynamic>> postGameData(List<String> ships, String? aiResult) async {
    Map<String, dynamic> responseBody = {};
    try {
      final postResponse = await http.post(
        Uri.parse('$baseUrl/games'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': await SessionManager.getSessionToken(),
        },
        body: aiResult == '' ? jsonEncode({
          "ships": ships,
        }) : jsonEncode({
          "ships": ships,
          "ai": aiResult,
        }),
      );

      if (postResponse.statusCode == 200) {
        responseBody = json.decode(postResponse.body);
      }
    } catch (error) {
      print("Error during HTTP post request: $error");
    }
    return responseBody;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Ships'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
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
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (gridColors[row - 1][col - 1] == Colors.blue) {
                          gridColors[row - 1][col - 1] = Colors.white;
                          ships.remove(label);
                        } else if (countSelectedCells() < 5) {
                          gridColors[row - 1][col - 1] = Colors.blue;
                          ships.add(label.toString());
                        }
                      });
                    },
                    onHover: (isHovered) {
                      setState(() {
                        if (countSelectedCells() < 5) {
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
                          if (isHovered && gridColors[row - 1][col - 1] != Colors.blue) {
                            gridColors[row - 1][col - 1] = Colors.red; 
                          } else if (!isHovered && gridColors[row - 1][col - 1] != Colors.blue) {
                            gridColors[row - 1][col - 1] = Colors.white;
                          }
                        }
                      });
                    },
                    child: Card(
                      color: gridColors[row - 1][col - 1],
                    )
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
                onPressed: () async {
                  if (countSelectedCells() < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You must place 5 ships',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else {
                    if(countSelectedCells() == 5) {
                      Map<String, dynamic> responseBody = await postGameData(ships, widget.selectedResult);
                      gameId = responseBody['id'] ?? 0;
                      Future<void> getRestponseBody = getGameData(gameId);
                      Navigator.pop(context, {'game': responseBody});
                    } 
                  }
                },
                child: const Text('Submit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
