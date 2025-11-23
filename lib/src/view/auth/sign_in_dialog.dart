import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/auth/auth_controller.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/widgets/buttons.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';

/// Shows the sign-in dialog where users can enter their credentials.
Future<void> showSignInDialog(BuildContext context, WidgetRef ref) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => const SignInDialog(),
    );
  } else {
    return showDialog<void>(
      context: context,
      builder: (context) => const SignInDialog(),
    );
  }
}

class SignInDialog extends ConsumerStatefulWidget {
  const SignInDialog({super.key});

  @override
  ConsumerState<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<SignInDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your username or email';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).signIn(
        username,
        password,
        remember: _remember,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 提取詳細的錯誤訊息
      String errorDetails = e.toString();
      
      // 嘗試從錯誤訊息中提取更多資訊
      if (errorDetails.contains('Login failed')) {
        // 保持原始錯誤訊息
      } else if (errorDetails.contains('SocketException') || errorDetails.contains('Failed host lookup')) {
        errorDetails = 'Network error: Cannot connect to lichess.org\n\nPlease check your internet connection.';
      } else if (errorDetails.contains('TimeoutException')) {
        errorDetails = 'Request timeout\n\nThe server took too long to respond.';
      } else if (errorDetails.contains('FormatException')) {
        errorDetails = 'Invalid response from server\n\nThe server returned an unexpected format.';
      }
      
      setState(() {
        _errorMessage = errorDetails;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoAlertDialog(
        title: const Text('Sign In'),
        content: _buildContent(context, isLoading, isIOS: true),
        actions: [
          CupertinoDialogAction(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: isLoading ? null : _handleSignIn,
            child: isLoading
                ? const CupertinoActivityIndicator()
                : const Text('Sign In'),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: const Text('Sign In'),
        content: _buildContent(context, isLoading, isIOS: false),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: isLoading ? null : _handleSignIn,
            child: isLoading
                ? const ButtonLoadingIndicator()
                : const Text('Sign In'),
          ),
        ],
      );
    }
  }

  Widget _buildContent(BuildContext context, bool isLoading, {required bool isIOS}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (isIOS)
          CupertinoTextField(
            controller: _usernameController,
            placeholder: 'Username or Email',
            enabled: !isLoading,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          )
        else
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username or Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            enabled: !isLoading,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        const SizedBox(height: 12),
        if (isIOS)
          CupertinoTextField(
            controller: _passwordController,
            placeholder: 'Password',
            obscureText: _obscurePassword,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignIn(),
            suffix: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              child: Icon(
                _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 20,
              ),
            ),
          )
        else
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSignIn(),
          ),
        const SizedBox(height: 8),
        if (isIOS)
          Row(
            children: [
              CupertinoSwitch(
                value: _remember,
                onChanged: isLoading ? null : (value) {
                  setState(() {
                    _remember = value;
                  });
                },
              ),
              const SizedBox(width: 8),
              const Text('Remember me'),
            ],
          )
        else
          SwitchListTile(
            title: const Text('Remember me'),
            value: _remember,
            onChanged: isLoading ? null : (value) {
              setState(() {
                _remember = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
