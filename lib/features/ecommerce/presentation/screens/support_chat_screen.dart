import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/support_agent_provider.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatMessage {
  final String text;
  final bool fromUser;

  const _SupportChatMessage(this.text, {required this.fromUser});
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  static const _maxMessageLength = 500;

  final _controller = TextEditingController();
  final _messages = <_SupportChatMessage>[];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_SupportChatMessage(text, fromUser: true));
      _sending = true;
    });
    _controller.clear();

    String reply;
    try {
      reply = await ref.read(supportAgentDatasourceProvider).ask(text);
    } catch (error) {
      reply = error.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_SupportChatMessage(reply, fromUser: false));
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    return Scaffold(
      appBar: AppBar(title: const Text('Asistente de pedidos')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    decoration: BoxDecoration(
                      color: message.fromUser
                          ? const Color(0xFF0A7CFF)
                          : const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.fromUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: _maxMessageLength,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Pregunta por tus pedidos',
                        counterText: '',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
