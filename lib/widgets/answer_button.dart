import 'package:flutter/material.dart';

class AnswerButton extends StatefulWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final bool isEnabled;
  final double percentage;
  final VoidCallback? onPressed;

  const AnswerButton({
    Key? key,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.isEnabled = true,
    this.percentage = 0,
    this.onPressed,
  }) : super(key: key);

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton> {
  Color getButtonColor() {
    const colors = [
      Color(0xFFE21B3C), // Red
      Color(0xFF1368CE), // Blue
      Color(0xFFFFA602), // Yellow
      Color(0xFF26890C), // Green
    ];
    return colors[widget.index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: widget.showResult
              ? (widget.isCorrect ? Colors.green[700] : widget.isSelected ? Colors.red[700] : getButtonColor())
              : widget.isSelected
                  ? getButtonColor().withAlpha((0.6 * 255).round())
                  : getButtonColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.3 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isEnabled && !widget.showResult ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        ['▲', '◆', '●', '■'][widget.index],
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Show tick when answer is selected (during answering)
                  if (widget.isSelected && !widget.showResult)
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                  // Show tick for correct answer after reveal
                  if (widget.showResult && widget.isCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  if (widget.percentage > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.percentage.toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
