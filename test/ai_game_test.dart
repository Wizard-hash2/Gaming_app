import 'package:flutter_test/flutter_test.dart';
import 'package:app1/features/ai_game/ai_game_controller.dart';
import 'package:app1/features/ai_game/ai_player.dart';
import 'package:app1/features/ai_game/difficulty.dart';

void main() {
  group('AI Game Tests', () {
    late AiGameController gameController;

    setUp(() {
      gameController = AiGameController();
    });

    test('Initial game state should be empty', () {
      expect(gameController.board, equals(List.filled(9, '')));
    });

    test('User can place an O on the board', () {
      gameController.userMove(0);
      expect(gameController.board[0], equals('O'));
    });

    test('AI should make a move after user', () {
      gameController.userMove(0);
      gameController.aiMove(Difficulty.medium);
      expect(gameController.board[0], equals('O'));
      expect(gameController.board.contains('X'), isTrue);
    });

    test('Game should detect a win for user', () {
      gameController.userMove(0);
      gameController.userMove(1);
      gameController.userMove(2);
      expect(gameController.checkWin('O'), isTrue);
    });

    test('Game should detect a win for AI', () {
      gameController.userMove(0);
      gameController.aiMove(Difficulty.medium);
      gameController.userMove(1);
      gameController.aiMove(Difficulty.medium);
      gameController.userMove(2);
      expect(gameController.checkWin('X'), isTrue);
    });

    test('Game should reset correctly', () {
      gameController.userMove(0);
      gameController.resetGame();
      expect(gameController.board, equals(List.filled(9, '')));
    });
  });
}