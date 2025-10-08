import 'dart:math';
import '../game/board.dart';

enum Difficulty { easy, medium, hard }

// Simple container for minimax result (moved to top level — Dart doesn't support nested classes)
class _MoveScore {
  final int index;
  final int score;
  _MoveScore(this.index, this.score);
}

class TicTacToeAI {
  final Random _rng = Random();

  // Main entry used by UI
  Future<int> chooseMove(Board board, Difficulty diff, {required int aiPlayer}) async {
    // small thinking delay to improve UX
    final delayMs = diff == Difficulty.easy
        ? 150
        : diff == Difficulty.medium
            ? 350
            : 600;
    await Future.delayed(Duration(milliseconds: delayMs));

    final empties = _availableMoves(board);
    if (empties.isEmpty) return 0;

    if (diff == Difficulty.easy) {
      return empties[_rng.nextInt(empties.length)];
    }

    // Medium: sometimes make a random (mistake) move
    if (diff == Difficulty.medium) {
      if (_rng.nextDouble() < 0.30) {
        return empties[_rng.nextInt(empties.length)];
      }
      // otherwise use a limited-depth minimax
      final mv = _minimax(board.clone(), aiPlayer, aiPlayer, 0, 4);
      return mv.index >= 0 ? mv.index : empties[_rng.nextInt(empties.length)];
    }

    // Hard: full minimax (perfect play)
    final best = _minimax(board.clone(), aiPlayer, aiPlayer, 0, 9);
    return best.index >= 0 ? best.index : empties[_rng.nextInt(empties.length)];
  }

  List<int> _availableMoves(Board b) {
    final moves = <int>[];
    for (var i = 0; i < b.cells.length; i++) {
      if (b.cells[i] == Board.EMPTY) moves.add(i);
    }
    return moves;
  }

  // Minimax returning best move index and score
  _MoveScore _minimax(Board b, int aiPlayer, int currentPlayer, int depth, int maxDepth) {
    final w = b.winner();
    if (w != 0) {
      if (w == aiPlayer) return _MoveScore(-1, 10 - depth); // prefer faster wins
      return _MoveScore(-1, depth - 10); // prefer slower losses
    }
    if (b.isFull()) {
      return _MoveScore(-1, 0);
    }
    if (depth >= maxDepth) {
      return _MoveScore(-1, 0); // depth-limited: neutral heuristic
    }

    final available = _availableMoves(b);

    // move ordering heuristic: prefer center, corners, then sides
    int scorePos(int idx) {
      if (idx == 4) return 3; // center best
      if (idx == 0 || idx == 2 || idx == 6 || idx == 8) return 2; // corners
      return 1; // sides
    }

    available.sort((a, b) => scorePos(b).compareTo(scorePos(a)));

    int bestIndex = -1;
    int bestScore = currentPlayer == aiPlayer ? -9999 : 9999;

    for (final idx in available) {
      final nb = b.clone();
      nb.makeMove(idx, currentPlayer);

      final result = _minimax(nb, aiPlayer, -currentPlayer, depth + 1, maxDepth);
      final score = result.score;

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

    return _MoveScore(bestIndex, bestScore);
  }
}