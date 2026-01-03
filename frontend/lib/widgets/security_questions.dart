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
  final List<String>? predefinedQuestions;

  const SecurityQuestionsWidget({
    super.key,
    required this.questions,
    this.answerControllers,
    this.isRecovery = false,
    this.isLoading = false,
    this.onCustomQuestionChanged,
    this.predefinedQuestions,
  });

  @override
  State<SecurityQuestionsWidget> createState() => _SecurityQuestionsWidgetState();
}

class _SecurityQuestionsWidgetState extends State<SecurityQuestionsWidget> {
  late List<TextEditingController> _questionControllers;
  List<String?> _selectedQuestions = [];

  @override
  void initState() {
    super.initState();
    _questionControllers = List.generate(
      widget.questions.length,
      (index) => TextEditingController(text: widget.questions[index].question),
    );
    _selectedQuestions = List.generate(widget.questions.length, (index) => widget.questions[index].question.isNotEmpty ? widget.questions[index].question : null);
  }

  @override
  void didUpdateWidget(covariant SecurityQuestionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questions.length != widget.questions.length) {
      for (var controller in _questionControllers) {
        controller.dispose();
      }
      _questionControllers = List.generate(
        widget.questions.length,
        (index) => TextEditingController(text: widget.questions[index].question),
      );
      _selectedQuestions = List.generate(widget.questions.length, (index) => widget.questions[index].question.isNotEmpty ? widget.questions[index].question : null);
    }
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
    int controllerIndex = -1;
    return Column(
      children: [
        const Text(
          'Security Questions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...List.generate(widget.questions.length, (index) {
          final question = widget.questions[index];
          final isSelected = _selectedQuestions[index] != null && _selectedQuestions[index]!.isNotEmpty;
          if (isSelected) controllerIndex++;
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
                ] else if (widget.predefinedQuestions != null) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedQuestions[index],
                    items: widget.predefinedQuestions!.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                    onChanged: widget.isLoading || widget.isRecovery ? null : (value) {
                      setState(() {
                        _selectedQuestions[index] = value;
                      });
                      widget.onCustomQuestionChanged?.call(index, value ?? '');
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Security Question',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 5),
                ] else ...[
                  Text(
                    'Question ${index + 1}: ${question.question}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                ],
                if (isSelected) ...[
                  TextField(
                    controller: widget.answerControllers?[controllerIndex],
                    obscureText: !widget.isRecovery, // Hide answers in setup, show in recovery
                    enabled: !widget.isLoading,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Answer',
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}