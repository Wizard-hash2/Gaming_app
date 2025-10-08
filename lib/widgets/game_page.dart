import 'package:flutter/material.dart';
import '../game/board.dart';
import '../game/ai.dart';

class GamePage extends StatefulWidget {
  final String playerName;
  const GamePage({Key? key, required this.playerName}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Board _board = Board();
  final TicTacToeAI _ai = TicTacToeAI();

  Difficulty _difficulty = Difficulty.medium;
  bool _userIsO = true; // user = O by default
  bool _userTurn = true;
  bool _thinking = false;
  String _status = 'Your move';
  bool _gameStarted = false;
  bool _userStarts = true;

  // prevent overlapping AI calls
  bool _aiMoving = false;

  int get _userPlayer => _userIsO ? Board.O : Board.X;
  int get _aiPlayer => -_userPlayer;

  @override
  void initState() {
    super.initState();
    // Show setup dialog once on startup
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStartDialog());
  }

  Future<void> _showStartDialog() async {
    // Use StatefulBuilder so dialog controls update properly
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Difficulty tempDiff = _difficulty;
        bool tempUserIsO = _userIsO;
        bool tempUserStarts = _userStarts;

        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Game setup'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Choose difficulty'),
                  const SizedBox(height: 8),
                  Column(
                    children: Difficulty.values.map((d) {
                      return RadioListTile<Difficulty>(
                        title: Text(d.toString().split('.').last.toUpperCase()),
                        value: d,
                        groupValue: tempDiff,
                        onChanged: (v) {
                          if (v == null) return;
                          setDialogState(() => tempDiff = v);
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  const Text('Choose player'),
                  RadioListTile<bool>(
                    title: const Text('You play O'),
                    value: true,
                    groupValue: tempUserIsO,
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => tempUserIsO = v);
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('You play X'),
                    value: false,
                    groupValue: tempUserIsO,
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => tempUserIsO = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Who starts'),
                  ToggleButtons(
                    isSelected: [tempUserStarts, !tempUserStarts],
                    onPressed: (i) => setDialogState(() => tempUserStarts = i == 0),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('You'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('AI'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // apply choices and start
                  setState(() {
                    _difficulty = tempDiff;
                    _userIsO = tempUserIsO;
                    _userStarts = tempUserStarts;
                  });
                  Navigator.of(ctx).pop();
                  _startNewGame(userStarts: _userStarts);
                },
                child: const Text('Start Game'),
              ),
            ],
          );
        });
      },
    );

    if (!mounted) return;
    setState(() => _gameStarted = true);
  }

  void _startNewGame({required bool userStarts}) {
    // Cancel any in-progress AI work
    _aiMoving = false;

    setState(() {
      for (var i = 0; i < 9; i++) {
        _board.cells[i] = Board.EMPTY;
      }
      _userTurn = userStarts;
      _status = _userTurn ? 'Your move' : 'AI thinking...';
      _thinking = !_userTurn;
    });

    if (!_userTurn) _doAIMove();
  }

  void _onCellTap(int idx) async {
    if (!_gameStarted) return;
    if (_thinking) return;
    if (!_userTurn) return;
    if (_board.cells[idx] != Board.EMPTY) return;

    setState(() {
      _board.makeMove(idx, _userPlayer);
    });

    _checkEndOrSwitch();
  }

  void _checkEndOrSwitch() {
    final w = _board.winner();
    if (w != 0) {
      setState(() {
        _status = w == _userPlayer ? 'You win!' : 'AI wins!';
        _thinking = false;
        _userTurn = false;
      });
      return;
    }
    if (_board.isFull()) {
      setState(() {
        _status = 'Draw';
        _thinking = false;
        _userTurn = false;
      });
      return;
    }

    // switch to AI
    setState(() {
      _userTurn = false;
      _thinking = true;
      _status = 'AI thinking...';
    });
    _doAIMove();
  }

  Future<void> _doAIMove() async {
    if (_aiMoving) return; // prevent duplicate AI calls
    _aiMoving = true;

    try {
      final idx = await _ai.chooseMove(_board.clone(), _difficulty, aiPlayer: _aiPlayer);

      // If widget was disposed while AI was thinking, bail out
      if (!mounted) return;

      // ensure cell still free and game still ongoing
      if (_board.cells[idx] == Board.EMPTY && _board.winner() == 0) {
        setState(() {
          _board.makeMove(idx, _aiPlayer);
        });
      }
    } catch (e) {
      // ignore errors from AI selection
    } finally {
      _aiMoving = false;

      if (!mounted) return;

      final w = _board.winner();
      if (w != 0) {
        setState(() {
          _status = w == _userPlayer ? 'You win!' : 'AI wins!';
          _thinking = false;
          _userTurn = false;
        });
        return;
      }
      if (_board.isFull()) {
        setState(() {
          _status = 'Draw';
          _thinking = false;
          _userTurn = false;
        });
        return;
      }

      setState(() {
        _userTurn = true;
        _thinking = false;
        _status = 'Your move';
      });
    }
  }

  Widget _buildCell(int idx) {
    final val = _board.cells[idx];
    String text;
    if (val == Board.X) text = 'X';
    else if (val == Board.O) text = 'O';
    else text = '';
    return GestureDetector(
      onTap: () => _onCellTap(idx),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black45),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final whoStarts = _userTurn ? 'You' : 'AI';
    return Scaffold(
      appBar: AppBar(
        title: Text('Tic-Tac-Toe AI - ${widget.playerName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Show setup again before restarting
              _showStartDialog();
            },
            tooltip: 'Restart and choose options',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Display current settings (chosen by user at start)
            Row(
              children: [
                Text('Difficulty: ${_difficulty.toString().split('.').last.toUpperCase()}'),
                const SizedBox(width: 16),
                Text('You play: ${_userIsO ? 'O' : 'X'}'),
                const SizedBox(width: 16),
                Text('Starts: ${_userStarts ? 'You' : 'AI'}'),
              ],
            ),
            const SizedBox(height: 12),
            Text('Status: $_status     (${whoStarts} to move)'),
            const SizedBox(height: 12),
            // Board should take remaining available space
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 9,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemBuilder: (context, idx) => _buildCell(idx),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _showStartDialog(),
                  child: const Text('Restart & Choose'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _startNewGame(userStarts: true),
                  child: const Text('Restart (You)'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _startNewGame(userStarts: false),
                  child: const Text('Restart (AI)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}