import 'package:flutter/material.dart';

class SetupProgressIndicator extends StatelessWidget {
  final int currentStep;

  const SetupProgressIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = 3; // Passphrase, Security Questions, Complete

    return Column(
      children: [
        LinearProgressIndicator(
          value: (currentStep + 1) / totalSteps,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) => 
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= currentStep ? Colors.blue : Colors.grey,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index <= currentStep ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ['Passphrase', 'Questions', 'Complete'][index],
                  style: TextStyle(
                    fontSize: 12,
                    color: index <= currentStep ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}