import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:wiredash/wiredash.dart';

class WiredashService extends ChangeNotifier {
  WiredashService._();
  static final WiredashService instance = WiredashService._();

  // Constant project credentials for LMK App
  static const String projectId = 'lmk-70yfc18';
  static const String secret = 'H2ALJlc_24QHDB0SOOGHlJkfjuUhLzdy';

  String get configuredProjectId => projectId;
  String get configuredSecret => secret;

  bool get isConfigured => projectId.isNotEmpty && secret.isNotEmpty;

  // Crash and Bug auto-capture state
  String? lastError;
  String? lastStackTrace;
  DateTime? lastErrorTime;
  DateTime? _lastPromptTime;
  bool _isPrompting = false;

  /// Launch Wiredash interactive feedback flow
  static void show(
    BuildContext context, {
    String? userEmail,
    String? userId,
  }) {
    try {
      if (userEmail != null || userId != null) {
        Wiredash.of(context).setUserProperties(
          userEmail: userEmail,
          userId: userId,
        );
      }
      Wiredash.of(context).show(inheritMaterialTheme: true);
    } catch (e) {
      debugPrint('Error opening Wiredash: $e');
    }
  }

  /// Automatically records crash details and prompts the user to report it via Wiredash
  void handleCrash(
    Object error,
    StackTrace? stack, {
    required BuildContext? context,
  }) {
    lastError = error.toString();
    lastStackTrace = stack?.toString();
    lastErrorTime = DateTime.now();

    debugPrint('Wiredash captured error: $lastError');

    // Throttle prompt to avoid spamming if multiple errors occur in a loop
    final now = DateTime.now();
    if (_lastPromptTime != null &&
        now.difference(_lastPromptTime!) < const Duration(seconds: 30)) {
      return;
    }

    if (context == null || !context.mounted || _isPrompting) return;

    _lastPromptTime = now;
    _isPrompting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        _isPrompting = false;
        return;
      }

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.bug, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 10),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'An unexpected issue occurred. Would you like to report this bug and share a screenshot via Wiredash to help us fix it?',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  error.toString().split('\n').first,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _isPrompting = false;
              },
              child: const Text('Dismiss'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _isPrompting = false;
                Wiredash.of(context).show(inheritMaterialTheme: true);
              },
              icon: const Icon(LucideIcons.penTool, size: 14),
              label: const Text('Report with Wiredash'),
            ),
          ],
        ),
      ).then((_) {
        _isPrompting = false;
      });
    });
  }
}
