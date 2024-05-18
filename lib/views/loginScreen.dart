import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/sessionmanager.dart';
import 'homeScreen.dart';

const String baseUrl = "http://165.227.117.48";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _login(context),
                  child: const Text('Log in'),
                ),
                TextButton(
                  onPressed: () => _register(context),
                  child: const Text('Register'),
                ),
              ],  
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    final username = usernameController.text;
    final password = passwordController.text;

    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(url, 
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      })
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final sessionToken = json.decode(response.body)['access_token'];
      final expiryTime = DateTime.now().millisecondsSinceEpoch + (1 * 60 * 60 * 1000);
      await SessionManager.setSessionToken(sessionToken, expiryTime, username);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(null, true, username),
      ));
    } else {
      showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('User might not be registered or the username and password may be incorrect. Try Again!'),
            ],
          ),
        ),
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
  }

  Future<void> _register(BuildContext context) async {
    final username = usernameController.text;
    final password = passwordController.text;

    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(url, 
      headers: {
        'Content-Type': 'application/json', 
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      })
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final sessionToken = json.decode(response.body)['access_token'];
      final expiryTime = DateTime.now().millisecondsSinceEpoch + (1 * 60 * 60 * 1000);
      await SessionManager.setSessionToken(sessionToken, expiryTime, username);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(null, true, username),
      ));
    } else {
      showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${json.decode(response.body)['error']}'),
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
  }
}