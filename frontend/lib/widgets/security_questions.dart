import 'package:flutter/material.dart';

class SecurityQuestion {
  final String question;
  final bool isCustom;

  SecurityQuestion({
    required this.question,
    this.isCustom = false,
  });
}

class SecurityQuestionsWidget extends StatefulWidget {
  final List<SecurityQuestion> questions;
  final List<TextEditingController>? answerControllers;
  final bool isRecovery;
  final bool isLoading;
  final Function(int, String)? onCustomQuestionChanged;

  const SecurityQuestionsWidget({
    super.key,
    required this.questions,
    this.answerControllers,
    this.isRecovery = false,
    this.isLoading = false,
    this.onCustomQuestionChanged,
  });

  @override
  State<SecurityQuestionsWidget> createState() => _SecurityQuestionsWidgetState();
}

class _SecurityQuestionsWidgetState extends State<SecurityQuestionsWidget> {
  late List<TextEditingController> _questionControllers;

  @override
  void initState() {
    super.initState();
    _questionControllers = List.generate(
      widget.questions.length,
      (index) => TextEditingController(text: widget.questions[index].question),
    );
  }

  @override
  void dispose() {
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Security Questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...List.generate(widget.questions.length, (index) {
          final question = widget.questions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.isCustom) ...[
                  TextField(
                    controller: _questionControllers[index],
                    enabled: !widget.isLoading && !widget.isRecovery,
                    decoration: const InputDecoration(
                      labelText: 'Custom Security Question',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      widget.onCustomQuestionChanged?.call(index, value);
                    },
                  ),
                  const SizedBox(height: 5),
                ] else ...[
                  Text(
                    'Question ${index + 1}: ${question.question}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                ],
                TextField(
                  controller: widget.answerControllers?[index],
                  obscureText: !widget.isRecovery, // Hide answers in setup, show in recovery
                  enabled: !widget.isLoading,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Answer',
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}