import 'package:html_editor_plus/html_editor.dart' hide HtmlEditorController;
import 'package:html_editor_plus/src/html_editor_controller_mobile.dart';
import 'package:html_editor_plus/src/widgets/html_editor_widget_mobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// HtmlEditor class for mobile
class HtmlEditor extends StatelessWidget {
  const HtmlEditor({
    super.key,
    required this.controller,
    this.callbacks,
    this.htmlEditorOptions = const HtmlEditorOptions(),
    this.htmlToolbarOptions = const HtmlToolbarOptions(),
    this.otherOptions = const OtherOptions(),
    this.plugins = const [],
    this.disabled = true,
  });

  /// The controller that is passed to the widget, which allows multiple [HtmlEditor]
  /// widgets to be used on the same page independently.
  final HtmlEditorController controller;

  /// Sets & activates Summernote's callbacks. See the functions available in
  /// [Callbacks] for more details.
  final Callbacks? callbacks;

  /// Defines options for the html editor
  final HtmlEditorOptions htmlEditorOptions;

  /// Defines options for the editor toolbar
  final HtmlToolbarOptions htmlToolbarOptions;

  /// Defines other options
  final OtherOptions otherOptions;

  /// Sets the list of Summernote plugins enabled in the editor.
  final List<Plugins> plugins;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return HtmlEditorWidget(
        key: key,
        controller: controller,
        callbacks: callbacks,
        plugins: plugins,
        htmlEditorOptions: htmlEditorOptions,
        htmlToolbarOptions: htmlToolbarOptions,
        otherOptions: otherOptions,
        disabled: disabled,
      );
    } else {
      return const Text(
          'Flutter Web environment detected, please make sure you are importing package:html_editor_plus/html_editor.dart');
    }
  }
}
