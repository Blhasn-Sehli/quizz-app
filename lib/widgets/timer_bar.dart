import 'package:flutter/material.dart';

class TimerBar extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;
  final double height;

  const TimerBar({
    Key? key,
    required this.timeRemaining,
    required this.totalTime,
    this.height = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = timeRemaining / totalTime;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: progress > 0.5
                  ? [Colors.green[400]!, Colors.green[600]!]
                  : progress > 0.25
                      ? [Colors.orange[400]!, Colors.orange[600]!]
                      : [Colors.red[400]!, Colors.red[600]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: progress > 0.5
                    ? Colors.green.withAlpha((0.5 * 255).round())
                    : progress > 0.25
                        ? Colors.orange.withAlpha((0.5 * 255).round())
                        : Colors.red.withAlpha((0.5 * 255).round()),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
