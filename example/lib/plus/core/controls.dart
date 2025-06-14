import 'package:flutter/material.dart';

class EditorControls extends StatelessWidget {
  final List<Widget> controls;

  const EditorControls({super.key, required this.controls});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 16,
            runSpacing: 10,
            children: controls,
          ),
        ),
      );
}
