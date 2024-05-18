import 'package:flutter/material.dart';
import 'views/battleships.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Battleships',
    home: Scaffold(
      body: Battleships(),
    )
  ));
}
