import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // comment out while troubleshooting
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum Difficulty { easy, medium, hard }

// Replace with your Supabase project values
const String SUPABASE_URL = 'https://hcdpwbaaltoxiagnearl.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjZHB3YmFhbHRveGlhZ25lYXJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2Mjc1NjgsImV4cCI6MjA2NzIwMzU2OH0.WFPXrwVPeXfNtpj5jzNLMOrdZ0iPuyWWEs-LRXnisYw';

// Simple AI implemented in this file so the app runs without external ai.dart
Future<int> chooseAIMove(List<String> board, Difficulty diff, String aiMark) async {
  final rng = Random();
  final delayMs = diff == Difficulty.easy
      ? 150
      : diff == Difficulty.medium
          ? 350
          : 600;
  await Future.delayed(Duration(milliseconds: delayMs));

  List<int> empties = [];
  for (var i = 0; i < board.length; i++) {
    if (board[i] == '') empties.add(i);
  }
  if (empties.isEmpty) return 0;

  if (diff == Difficulty.easy) {
    return empties[rng.nextInt(empties.length)];
  }

  // helper to convert board to ints (X=1, O=-1, empty=0)
  List<int> toInts(List<String> b) =>
      b.map((e) => e == 'X' ? 1 : e == 'O' ? -1 : 0).toList();

  int aiPlayer = aiMark == 'X' ? 1 : -1;

  Map<String, int> minimax(List<int> b, int currentPlayer, int depth, int maxDepth) {
    int winner() {
      const lines = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6],
      ];
      for (var ln in lines) {
        final a = b[ln[0]];
        final i = b[ln[1]];
        final c = b[ln[2]];
        if (a != 0 && a == i && i == c) return a;
      }
      return 0;
    }

    final w = winner();
    if (w != 0) {
      if (w == aiPlayer) return {'index': -1, 'score': 10 - depth};
      return {'index': -1, 'score': depth - 10};
    }
    if (!b.contains(0)) return {'index': -1, 'score': 0};
    if (depth >= maxDepth) return {'index': -1, 'score': 0};

    List<int> available = [];
    for (var i = 0; i < b.length; i++) if (b[i] == 0) available.add(i);

    // simple ordering: center, corners, sides
    int posScore(int idx) {
      if (idx == 4) return 3;
      if ({0, 2, 6, 8}.contains(idx)) return 2;
      return 1;
    }

    available.sort((a, b) => posScore(b).compareTo(posScore(a)));

    int bestIndex = -1;
    int bestScore = currentPlayer == aiPlayer ? -9999 : 9999;

    for (var idx in available) {
      final nb = List<int>.from(b);
      nb[idx] = currentPlayer;
      final res = minimax(nb, -currentPlayer, depth + 1, maxDepth);
      final score = res['score']!;
      if (currentPlayer == aiPlayer) {
        if (score > bestScore) {
          bestScore = score;
          bestIndex = idx;
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestIndex = idx;
        }
      }
    }
    return {'index': bestIndex, 'score': bestScore};
  }

  if (diff == Difficulty.medium) {
    // 30% chance to make a random mistake
    if (rng.nextDouble() < 0.30) return empties[rng.nextInt(empties.length)];
    final ints = toInts(board);
    final res = minimax(ints, aiPlayer, 0, 4);
    final idx = res['index']!;
    return idx >= 0 ? idx : empties[rng.nextInt(empties.length)];
  }

  // hard = perfect play
  final ints = toInts(board);
  final res = minimax(ints, aiPlayer, 0, 9);
  final idx = res['index']!;
  return idx >= 0 ? idx : empties[rng.nextInt(empties.length)];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TicTacToe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.transparent, // let gradient show
      ),
      home: Scaffold(
        // Keep a transparent scaffold so the page-level gradients are visible
        backgroundColor: Colors.transparent,
        body: MyHomePage(),
      ),
    );
  }
}

// Login with Supabase authentication
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AnimationController _logoController;
  bool _loading = false;

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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _nameController.text.trim();
    final password = _passwordController.text;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;

      // try sign-in
      final signInRes = await supabase.auth.signInWithPassword(email: email, password: password);
      final signedIn = (signInRes.session != null) || (signInRes.user != null);

      if (!signedIn) {
        // if sign-in gave no session/user, try sign-up
        final signUpRes = await supabase.auth.signUp(email: email, password: password);
        final signedUp = (signUpRes.user != null) || (signUpRes.session != null);
        if (!signedUp) throw Exception('Unable to sign in or sign up. Check Supabase settings.');
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GamePage(playerName: email)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth error: ${e.toString()}')));
      }
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openSignUpPage() async {
    const url = 'https://kenwork.onrender.com/auth';
    final uri = Uri.parse(url);
    // Prefer external application to open in a new window/tab
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // fallback: try simple string launcher
        if (!await launchUrlString(url, webOnlyWindowName: '_blank')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open signup page')));
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open signup page')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // updated blue → purple → teal gradient for a modern, visually-appealing look
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // deep midnight
            Color(0xFF4F46E5), // indigo/purple
            Color(0xFF06B6D4), // teal/cyan accent
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth.toDouble(); // ensure double
            return SingleChildScrollView(
              child: Card(
                elevation: 18,
                margin: EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: width,
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
                                labelText: 'Email',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
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
                                icon: _loading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.login),
                                label: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(_loading ? 'Signing in...' : 'Login'),
                                ),
                                style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                                onPressed: _loading ? null : _submit,
                              ),
                            ),
                            SizedBox(height: 12),
                            TextButton(
                              onPressed: _openSignUpPage,
                              child: Text('Don\'t have an account? Sign up here', style: TextStyle(color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

  // AI settings
  Difficulty _difficulty = Difficulty.medium;
  bool _aiThinking = false;

  // Scoreboard
  int _playerWins = 0; // player (X)
  int _aiWins = 0;     // AI (O)
  int _draws = 0;

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

  // Produce 1-2 character initials from a display name or email
  String _userInitials(String name) {
    final s = (name ?? '').trim();
    if (s.isEmpty) return '';
    // split on space or common separators (for emails use part before @)
    final beforeAt = s.contains('@') ? s.split('@').first : s;
    final parts = beforeAt.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return beforeAt.substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    final first = parts[0][0];
    final second = parts[1][0];
    return (first + second).toUpperCase();
  }

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
      return;
    }

    // If it's now AI's turn, trigger AI
    if (_current == 'O') {
      _performAIMove();
    }
  }

  void _performAIMove() async {
    // prevent double AI calls
    if (_aiThinking) return;
    _aiThinking = true;
    setState(() {}); // show spinner

    final aiMark = 'O';
    final idx = await chooseAIMove(List<String>.from(_board), _difficulty, aiMark);

    // apply move if still valid
    if (!mounted) return;
    if (_board[idx] == '' && _winner == null) {
      setState(() {
        _board[idx] = aiMark;
        _moves++;
        _winner = _checkWinner();
        if (_winner == null && _moves == 9) _winner = 'Draw';
        if (_winner == null) _current = _current == 'X' ? 'O' : 'X';
      });

      if (_winner != null) {
        Future.delayed(Duration(milliseconds: 250), () => _showResult());
      }
    }

    _aiThinking = false;
    setState(() {});
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
    // update scoreboard once per finished game
    setState(() {
      if (_winner == 'Draw') _draws++;
      else if (_winner == 'X') _playerWins++;
      else if (_winner == 'O') _aiWins++;
    });
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

  Future<void> _logout() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut();
    } catch (e) {
      // ignore sign-out errors but still navigate
    }
    if (!mounted) return;
    // reset local scores on logout
    setState(() {
      _playerWins = 0;
      _aiWins = 0;
      _draws = 0;
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MyHomePage()),
      (route) => false,
    );
  }

  void _reset() {
    setState(() {
      _board = List.filled(9, '');
      _current = 'X';
      _winner = null;
      _moves = 0;
      _winningLine = null;
      _aiThinking = false;
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

  Widget _buildBoard(BuildContext context) {
    // kept as a safe stub — the build() uses the inline Container/GridView.
    // You can reimplement a responsive helper here if desired.
    return SizedBox.shrink();
  }

  Widget _buildScoreChip(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(value.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show gradient behind the scaffold body and make the AppBar blend with it
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // avatar + title (avatar shows user initials as a simple cartoon-like badge)
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                _userInitials(widget.playerName),
                style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tic-Tac-Toe - ${widget.playerName}',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _reset, icon: Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: Icon(Icons.logout)),
        ],
        // scoreboard shown under the AppBar title
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0, left: 12.0, right: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreChip('You', _playerWins, Colors.deepPurpleAccent),
                SizedBox(width: 12),
                _buildScoreChip('Draws', _draws, Colors.amber),
                SizedBox(width: 12),
                _buildScoreChip('AI', _aiWins, Colors.tealAccent.shade700),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF6D28D9),
              Color(0xFF06B6D4),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = 32.0;
            final availableWidth = constraints.maxWidth - padding;
            final availableHeight = constraints.maxHeight - padding - 120; // reserve header/control space
            final gridSize = min(availableWidth, availableHeight).clamp(200.0, 1000.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 16),
                      Center(child: Text('Current: $_current', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white))),
                      SizedBox(height: 8),
                      // AI difficulty selector and status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('AI: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                          DropdownButton<Difficulty>(
                            dropdownColor: Colors.deepPurple.shade700,
                            value: _difficulty,
                            items: Difficulty.values
                                .map((d) => DropdownMenuItem(value: d, child: Text(d.toString().split('.').last.toUpperCase())))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _difficulty = v);
                            },
                          ),
                          if (_aiThinking) ...[
                            SizedBox(width: 12),
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          ],
                        ],
                      ),
                      SizedBox(height: 16),

                      // Expand the board to take remaining space (prevents RenderFlex overflow)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: gridSize,
                            height: gridSize,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                              border: Border.all(color: Colors.white12),
                            ),
                            child: GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: 9,
                              itemBuilder: (context, index) {
                                return Material(
                                  color: _cellColor(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _handleTap(index),
                                    child: Semantics(
                                      label: 'Cell ${index + 1}, ${_board[index] == '' ? 'empty' : _board[index]}',
                                      button: true,
                                      child: Center(child: _buildMark(_board[index])),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 18),
                      if (_winner != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(child: Text('Result: $_winner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                        ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
