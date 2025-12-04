import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';

class ClipboardService with ClipboardListener {
  // 1. Singleton Pattern
  ClipboardService._internal();
  static final ClipboardService instance = ClipboardService._internal();

  // 2. Stream & State
  final StreamController<String> _clipboardController =
      StreamController.broadcast();
  Stream<String> get clipboardStream => _clipboardController.stream;

  String? _lastClipboard;
  Timer? _pollingTimer;
  bool _isInitialized = false;

  // 3. Initialize (Safe to call multiple times)
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent double init
    _isInitialized = true;

    // Set initial value so we don't re-trigger immediately
    ClipboardData? initial = await Clipboard.getData('text/plain');
    _lastClipboard = initial?.text;

    _startPolling();
  }

  // 4. Desktop Listener Override
  @override
  void onClipboardChanged() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    _checkForChange(data?.text);
  }

  // 5. Mobile Polling Logic
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      ClipboardData? data = await Clipboard.getData('text/plain');
      _checkForChange(data?.text);
    });
  }

  // 6. Logic to Deduplicate and Emit
  void _checkForChange(String? newText) {
    if (newText != null && newText.isNotEmpty && newText != _lastClipboard) {
      _lastClipboard = newText;
      print("checking for clip $newText");
      _clipboardController.add(newText);
    }
  }

  // 7. Set Clipboard (Avoid infinite loop)
  Future<void> setClipboard(String text) async {
    if (text == _lastClipboard) return;
    _lastClipboard = text; // Update local cache first
    await Clipboard.setData(ClipboardData(text: text));
  }

  // 8. Cleanup
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      clipboardWatcher.removeListener(this);
      clipboardWatcher.stop();
    }
    _pollingTimer?.cancel();
    _clipboardController.close();
    _isInitialized = false;
  }
}
