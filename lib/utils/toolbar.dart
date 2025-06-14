import 'package:flutter/material.dart';

/// Abstract class that all the toolbar classes extend
abstract class Toolbar {
  const Toolbar();
}

/// Style group
class StyleButtons extends Toolbar {
  final bool style;

  const StyleButtons({
    this.style = true,
  });
}

/// Font setting group
class FontSettingButtons extends Toolbar {
  final bool fontName;
  final bool fontSize;
  final bool fontSizeUnit;

  const FontSettingButtons({
    this.fontName = true,
    this.fontSize = true,
    this.fontSizeUnit = true,
  });
}

/// Font group
class FontButtons extends Toolbar {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool clearAll;
  final bool strikethrough;
  final bool superscript;
  final bool subscript;

  const FontButtons({
    this.bold = true,
    this.italic = true,
    this.underline = true,
    this.clearAll = true,
    this.strikethrough = true,
    this.superscript = true,
    this.subscript = true,
  });

  List<Icon> getIcons1() {
    var icons = <Icon>[];
    if (bold) icons.add(const Icon(Icons.format_bold));
    if (italic) icons.add(const Icon(Icons.format_italic));
    if (underline) icons.add(const Icon(Icons.format_underline));
    if (clearAll) icons.add(const Icon(Icons.format_clear));
    return icons;
  }

  List<Icon> getIcons2() {
    var icons = <Icon>[];
    if (strikethrough) icons.add(const Icon(Icons.format_strikethrough));
    if (superscript) icons.add(const Icon(Icons.superscript));
    if (subscript) icons.add(const Icon(Icons.subscript));
    return icons;
  }
}

/// Color bar group
class ColorButtons extends Toolbar {
  final bool foregroundColor;
  final bool highlightColor;

  const ColorButtons({
    this.foregroundColor = true,
    this.highlightColor = true,
  });

  List<Icon> getIcons() {
    var icons = <Icon>[];
    if (foregroundColor)
      icons.add(const Icon(Icons.format_color_text, size: 20));
    if (highlightColor)
      icons.add(const Icon(Icons.format_color_fill, size: 20));
    return icons;
  }
}

/// List group
class ListButtons extends Toolbar {
  final bool ul;
  final bool ol;
  final bool listStyles;

  const ListButtons({
    this.ul = true,
    this.ol = true,
    this.listStyles = true,
  });

  List<Icon> getIcons() {
    var icons = <Icon>[];
    if (ul) icons.add(const Icon(Icons.format_list_bulleted));
    if (ol) icons.add(const Icon(Icons.format_list_numbered));
    return icons;
  }
}

/// Paragraph group
class ParagraphButtons extends Toolbar {
  final bool alignLeft;
  final bool alignCenter;
  final bool alignRight;
  final bool alignJustify;
  final bool increaseIndent;
  final bool decreaseIndent;
  final bool textDirection;
  final bool lineHeight;
  final bool caseConverter;

  const ParagraphButtons({
    this.alignLeft = true,
    this.alignCenter = true,
    this.alignRight = true,
    this.alignJustify = true,
    this.increaseIndent = true,
    this.decreaseIndent = true,
    this.textDirection = true,
    this.lineHeight = true,
    this.caseConverter = true,
  });

  List<Icon> getIcons1() {
    var icons = <Icon>[];
    if (alignLeft) icons.add(const Icon(Icons.format_align_left));
    if (alignCenter) icons.add(const Icon(Icons.format_align_center));
    if (alignRight) icons.add(const Icon(Icons.format_align_right));
    if (alignJustify) icons.add(const Icon(Icons.format_align_justify));
    return icons;
  }

  List<Icon> getIcons2() {
    var icons = <Icon>[];
    if (increaseIndent) icons.add(const Icon(Icons.format_indent_increase));
    if (decreaseIndent) icons.add(const Icon(Icons.format_indent_decrease));
    return icons;
  }
}

/// Insert group
class InsertButtons extends Toolbar {
  final bool link;
  final bool picture;
  final bool audio;
  final bool video;
  final bool otherFile;
  final bool table;
  final bool hr;

  const InsertButtons({
    this.link = true,
    this.picture = true,
    this.audio = true,
    this.video = true,
    this.otherFile = false,
    this.table = true,
    this.hr = true,
  });

  List<Icon> getIcons() {
    var icons = <Icon>[];
    if (link) icons.add(const Icon(Icons.link));
    if (picture) icons.add(const Icon(Icons.image_outlined));
    if (audio) icons.add(const Icon(Icons.audiotrack_outlined));
    if (video) icons.add(const Icon(Icons.videocam_outlined));
    if (otherFile) icons.add(const Icon(Icons.attach_file));
    if (table) icons.add(const Icon(Icons.table_chart_outlined));
    if (hr) icons.add(const Icon(Icons.horizontal_rule));
    return icons;
  }
}

/// Miscellaneous group
class OtherButtons extends Toolbar {
  final bool fullscreen;
  final bool codeview;
  final bool undo;
  final bool redo;
  final bool help;
  final bool copy;
  final bool paste;

  const OtherButtons({
    this.fullscreen = true,
    this.codeview = true,
    this.undo = true,
    this.redo = true,
    this.help = true,
    this.copy = true,
    this.paste = true,
  });

  List<Icon> getIcons1() {
    var icons = <Icon>[];
    if (fullscreen) icons.add(const Icon(Icons.fullscreen));
    if (codeview) icons.add(const Icon(Icons.code));
    if (undo) icons.add(const Icon(Icons.undo));
    if (redo) icons.add(const Icon(Icons.redo));
    if (help) icons.add(const Icon(Icons.help_outline));
    return icons;
  }

  List<Icon> getIcons2() {
    var icons = <Icon>[];
    if (copy) icons.add(const Icon(Icons.copy));
    if (paste) icons.add(const Icon(Icons.paste));
    return icons;
  }
}
