import 'package:flutter/material.dart';

class VoiceCommandButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;
  final String? hintText;

  const VoiceCommandButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening 
                ? Theme.of(context).colorScheme.error 
                : Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: isListening 
                    ? Theme.of(context).colorScheme.error.withOpacity(0.4)
                    : Theme.of(context).primaryColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 10,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 32,
            ),
            onPressed: onPressed,
            padding: const EdgeInsets.all(24),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isListening ? '正在听...' : (hintText ?? '点击开始语音输入'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}