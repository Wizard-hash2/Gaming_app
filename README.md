# Tic‑Tac‑Toe — Flutter (Supabase auth + AI opponent)

This repository contains a Flutter Tic‑Tac‑Toe app that demonstrates:
- Email/password authentication using Supabase (sign-in and sign-up).
- Single‑player gameplay against a configurable AI (easy, medium, hard).
- Cross‑platform support (Android, iOS, web, desktop) using Flutter.

## Project structure (important files)
- lib/main.dart — App entry point. Contains:
  - Supabase initialization.
  - Login screen (email/password).
  - GamePage: UI for the Tic‑Tac‑Toe board, game state, and controls.
  - AI integration via chooseAIMove (minimax algorithm).
- lib/game/ai.dart — (if present) alternate/extended AI implementation.
- pubspec.yaml — Dependencies (make sure `supabase_flutter` is present).
- android/, ios/, web/, windows/, macos/, linux/ — Platform-specific project files.

## How the app works (high level)
1. main()
   - Ensures Flutter bindings are initialized.
   - Initializes Supabase client with project URL and anon key.
   - Starts the Flutter app.

2. Login UI
   - Validates email & password.
   - Calls Supabase auth:
     - Attempt sign-in via signInWithPassword.
     - If sign-in fails (no session/user), attempts signUp.
   - On success, navigates to GamePage with player email as identifier.

3. GamePage
   - Local state: `_board` (List<String>), `_current` player ('X'|'O'), `_winner`, `_moves`, `_winningLine`.
   - Player taps a cell to place a mark. After a player move:
     - Check winner via `_checkWinner`.
     - If game not finished and it's AI's turn, call `_performAIMove()`.

4. AI (`chooseAIMove`)
   - Easy: random empty cell.
   - Medium: runs limited-depth minimax plus a 30% chance of a random move to simulate mistakes.
   - Hard: full-depth minimax for perfect play.
   - Minimax details:
     - Board converted to ints: X=1, O=-1, empty=0.
     - Terminal states return scores: positive when AI wins (score = 10 - depth), negative when opponent wins (depth - 10), and 0 for draws.
     - Move ordering heuristic: center > corners > sides to guide search and improve pruning effectiveness (no alpha-beta implemented in this variant).
     - Returned index is validated before applying; AI actions are separated from UI thread via async delays to show “thinking”.

## How the AI was coded (technical)
- Conversion helper: map board strings to integers to compute lines quickly.
- Winner check: iterate the 8 winning lines and compare three positions for equality and non-empty.
- Minimax function:
  - Recursively attempts each available move, flips current player, and increases `depth`.
  - Stops recursion when:
    - A terminal winner is found.
    - The board is full (draw).
    - Reached `maxDepth` (used for medium difficulty to limit search).
  - Scores incorporate depth to prefer faster wins and slower losses.
- Randomness for difficulty:
  - easy: purely random choice among empties.
  - medium: 30% probability to choose a random move to simulate non-perfect play.
  - hard: no randomness (perfect play at full depth).

## Setup — local development (Android)
1. Ensure Flutter is installed and configured for Android.
2. Edit `lib/main.dart` (or create a `lib/config.dart`) and set:
   - `SUPABASE_URL` = your Supabase project URL.
   - `SUPABASE_ANON_KEY` = your Supabase anon (public) key.
   IMPORTANT: For production, do not commit keys. Use secure secrets or platform-specific environment config.
3. Add dependency in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     supabase_flutter: ^1.4.0
   ```
4. From project root (where pubspec.yaml lives):
   - flutter pub get
   - flutter run  # or flutter run -d emulator-5554
   - flutter build apk  # to produce an Android APK

## Supabase configuration
- In the Supabase dashboard:
  - Go to Authentication → Settings and enable Email/Password provider if required.
  - The anon key must have permissions for auth endpoints (standard).
- For debugging authentication errors, check:
  - Project URL and anon key are correct.
  - Network access from device/emulator.
  - Supabase project has Email provider enabled.

## Troubleshooting tips
- "Couldn't resolve package 'supabase_flutter'":
  - Ensure `pubspec.yaml` is in the same folder as `lib/`.
  - Run `flutter clean` then `flutter pub get`.
  - Restart your editor/IDE if the analyzer fails to update.
- Null errors for `Supabase`:
  - Ensure Supabase.initialize(...) runs before runApp() and pub packages are resolved.
- Debugging auth:
  - Use `ScaffoldMessenger` snackbars (already present) to view Supabase exception messages.

## Extending & production notes
- Replace in-source keys with environment variables or platform secure storage.
- Add persistent user profiles in Supabase (e.g., store statistics in a `matches` table).
- Consider adding alpha‑beta pruning to speed up the minimax search for larger boards or more complex heuristics.
- Add unit tests for game logic (winner detection, move validation) — tests exist in `test/` as examples.

## How to present this tomorrow (suggested slide order)
1. Brief overview & goals.
2. Architecture diagram (main → auth → game → AI).
3. Live demo: login → play vs AI (switch difficulties).
4. Code walkthrough:
   - show chooseAIMove and explain minimax lines and scoring.
   - show _submit authentication flow.
   - show _checkWinner and UI highlights for winning line.
5. Deployment steps and security caveats.
6. Q&A and next steps.

---
If you want, I can:
- Create a dedicated lib/config.dart and move SUPABASE constants there and update .gitignore suggestions.
- Add short inline comments in main.dart for the specific functions you will highlight during the presentation.
- Generate a one‑page slide text outline you can copy into PowerPoint/Google Slides.