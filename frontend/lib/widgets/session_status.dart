import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_state.dart';

class SessionStatusWidget extends StatelessWidget {
  const SessionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, authState, child) {
        if (!authState.isLoggedIn) {
          return const SizedBox.shrink();
        }

        final remainingTime = authState.getRemainingSessionTime();
        final sessionStartTime = authState.sessionStartTime;
        
        String timeText = 'Unknown';
        if (remainingTime != null) {
          if (remainingTime.inMinutes > 0) {
            timeText = '${remainingTime.inMinutes} min';
          } else if (remainingTime.inSeconds > 0) {
            timeText = '${remainingTime.inSeconds} sec';
          } else {
            timeText = 'Expired';
          }
        }

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text('Time remaining: $timeText'),
                if (sessionStartTime != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Started: ${_formatDateTime(sessionStartTime)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}