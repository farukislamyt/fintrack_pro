import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/preferences_provider.dart';

enum PasscodeMode { set, verify }

class PasscodeScreen extends ConsumerStatefulWidget {
  final PasscodeMode mode;
  const PasscodeScreen({super.key, required this.mode});

  @override
  ConsumerState<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends ConsumerState<PasscodeScreen> {
  String _enteredPin = '';
  String _firstPin = ''; // Used during 'set' mode
  bool _isConfirming = false;
  String _errorText = '';

  void _onKeyPress(String val) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += val;
      _errorText = '';
    });

    if (_enteredPin.length == 4) {
      _processPasscode();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _processPasscode() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (widget.mode == PasscodeMode.verify) {
      final isValid = ref.read(preferencesProvider.notifier).verifyPasscode(_enteredPin);
      if (isValid) {
        HapticFeedback.mediumImpact();
        if (mounted) context.go('/dashboard');
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _enteredPin = '';
          _errorText = 'Incorrect Passcode';
        });
      }
    } else {
      // Set Mode
      if (!_isConfirming) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _firstPin) {
          HapticFeedback.mediumImpact();
          await ref.read(preferencesProvider.notifier).setPasscode(_enteredPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passcode Set Successfully'))
            );
            context.pop();
          }
        } else {
          HapticFeedback.vibrate();
          setState(() {
            _enteredPin = '';
            _errorText = 'Pins do not match. Try again.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: widget.mode == PasscodeMode.set ? AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              _getTitle(),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ).animate().fade().slideY(begin: -0.2),
            const SizedBox(height: 12),
            if (_errorText.isNotEmpty)
              Text(_errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 14))
                .animate().shake(),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _enteredPin.length > i ? const Color(0xFFE2136E) : Colors.white10,
                  border: Border.all(color: Colors.white24),
                ),
              )),
            ),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (widget.mode == PasscodeMode.verify) return 'Enter Passcode';
    return _isConfirming ? 'Confirm Passcode' : 'Set New Passcode';
  }

  Widget _buildKeypad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 48),
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      children: [
        ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((n) => _KeyButton(n, () => _onKeyPress(n))),
        const SizedBox(),
        _KeyButton('0', () => _onKeyPress('0')),
        IconButton(
          onPressed: _onDelete,
          icon: const Icon(LucideIcons.delete, color: Colors.white, size: 28),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _KeyButton(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
