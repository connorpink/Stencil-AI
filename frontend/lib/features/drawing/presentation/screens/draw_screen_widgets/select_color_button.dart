import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class SelectColorButton extends StatelessWidget {
  final Color color;
  final bool currentlySelected;
  final void Function(Color) handleColorSelected;

  const SelectColorButton ({
    required this.color,
    required this.currentlySelected,
    required this.handleColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){ handleColorSelected(color); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration:  BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: currentlySelected ? Colors.grey : Colors.transparent
          )
        ),
      ),
    );
  }
}