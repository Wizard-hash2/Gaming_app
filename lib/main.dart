import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TicTacToe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Scaffold(
        body: MyHomePage(),
      ),
    );
  }
}

// Login with animated logo and gradient background
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, $name')));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GamePage(playerName: name)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // gradient background
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade400, Colors.cyan.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 18,
            margin: EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated circular logo
                  SizedBox(
                    height: 110,
                    width: 110,
                    child: RotationTransition(
                      turns: _logoController,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(colors: [Colors.white, Colors.indigo]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: Center(
                          child: Text('OX', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Sign in', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            labelText: 'Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter a password' : null,
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.login),
                            label: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Login'),
                            ),
                            style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tic-Tac-Toe with nicer visuals and animations
class GamePage extends StatefulWidget {
  final String playerName;
  const GamePage({required this.playerName, Key? key}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  List<String> _board = List.filled(9, '');
  String _current = 'X';
  String? _winner;
  int _moves = 0;
  List<int>? _winningLine;

  static const List<List<int>> _winningLines = [
    [0,1,2],
    [3,4,5],
    [6,7,8],
    [0,3,6],
    [1,4,7],
    [2,5,8],
    [0,4,8],
    [2,4,6],
  ];

  // small animation for the placed mark
  void _handleTap(int idx) {
    if (_board[idx] != '' || _winner != null) return;
    setState(() {
      _board[idx] = _current;
      _moves++;
      _winner = _checkWinner();
      if (_winner == null && _moves == 9) _winner = 'Draw';
      if (_winner == null) _current = _current == 'X' ? 'O' : 'X';
    });
    if (_winner != null) {
      Future.delayed(Duration(milliseconds: 250), () => _showResult());
    }
  }

  String? _checkWinner() {
    for (var line in _winningLines) {
      final a = _board[line[0]];
      final b = _board[line[1]];
      final c = _board[line[2]];
      if (a != '' && a == b && b == c) {
        _winningLine = line;
        return a;
      }
    }
    _winningLine = null;
    return null;
  }

  void _showResult() {
    final title = _winner == 'Draw' ? 'Draw' : 'Winner: $_winner';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(_winner == 'Draw' ? 'Nobody won. Try again.' : 'Player $_winner wins!'),
        actions: [
          TextButton(onPressed: () { Navigator.of(context).pop(); _reset(); }, child: Text('Play again')),
          TextButton(onPressed: () { Navigator.of(context).pop(); }, child: Text('Close')),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _board = List.filled(9, '');
      _current = 'X';
      _winner = null;
      _moves = 0;
      _winningLine = null;
    });
  }

  Color _cellColor(int idx) {
    if (_winningLine != null && _winningLine!.contains(idx)) return Colors.yellow.shade200;
    return Colors.white;
  }

  Widget _buildMark(String mark) {
    if (mark == '') return SizedBox.shrink();
    final color = mark == 'X' ? Colors.deepPurple : Colors.teal;
    final icon = mark == 'X' ? Icons.close : Icons.circle_outlined;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: Duration(milliseconds: 250),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Icon(icon, size: 56, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // nice gradient app bar look via flexible space
      appBar: AppBar(
        title: Text('Tic-Tac-Toe - ${widget.playerName}'),
        elevation: 6,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo, Colors.cyan]),
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _reset, tooltip: 'Reset'),
          IconButton(icon: Icon(Icons.logout), onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MyApp()), (r) => false), tooltip: 'Logout'),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.cyan.shade50, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Text('Current: $_current', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                    itemBuilder: (context, index) {
                      return Material(
                        color: _cellColor(index),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _handleTap(index),
                          child: Center(child: _buildMark(_board[index])),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_winner != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_winner == 'Draw' ? Icons.sentiment_neutral : Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    _winner == 'Draw' ? 'It\'s a draw' : 'Winner: $_winner',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(onPressed: _reset, icon: Icon(Icons.replay), label: Text('Reset')),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => MyApp()), (r) => false),
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}