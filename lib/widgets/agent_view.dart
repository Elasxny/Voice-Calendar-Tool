import 'package:flutter/material.dart';
import 'voice_command_button.dart';

class AgentView extends StatelessWidget {
  final bool isListening;
  final VoidCallback onToggleListening;
  final String statusMessage;
  final String recognizedText;

  const AgentView({
    super.key,
    required this.isListening,
    required this.onToggleListening,
    required this.statusMessage,
    required this.recognizedText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.smart_toy,
                        size: 64,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '智能语音助手',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '点击下方按钮开始语音输入',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          VoiceCommandButton(
            isListening: isListening,
            onPressed: onToggleListening,
            hintText: '点击开始语音输入',
          ),
          const SizedBox(height: 16),
          Text(
            statusMessage,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (recognizedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '识别到：$recognizedText',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}