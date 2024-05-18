// ignore_for_file: unused_import

import 'dart:convert';
import '../utils/sessionmanager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'loginScreen.dart';
import 'homeScreen.dart';

bool isLoggedIn = false;
String loggedInUsername = '';

class Battleships extends StatefulWidget {
  const Battleships({super.key});

  @override
  State<Battleships> createState() => _BattleshipsState();
}

class _BattleshipsState extends State<Battleships> {

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await SessionManager.isLoggedIn();
    final username = await SessionManager.getLoggedInUsername();

    if (mounted) {
      setState(() {
        isLoggedIn = loggedIn;
        loggedInUsername = username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battleships',
      home: isLoggedIn ? HomeScreen(null, isLoggedIn, loggedInUsername) : const LoginScreen(),
    );
  }
}