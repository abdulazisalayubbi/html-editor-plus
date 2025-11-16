import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html_editor_plus/html_editor.dart'
    hide NavigationActionPolicy, UserScript, ContextMenu;
import 'package:html_editor_plus/utils/utils.dart';

/// The HTML Editor widget itself, for mobile (uses InAppWebView)
class HtmlEditorWidget extends StatefulWidget {
  const HtmlEditorWidget({
    super.key,
    required this.controller,
    this.callbacks,
    required this.plugins,
    required this.htmlEditorOptions,
    required this.htmlToolbarOptions,
    required this.otherOptions,
    this.disabled = true,
  });

  final HtmlEditorController controller;
  final Callbacks? callbacks;
  final List<Plugins> plugins;
  final HtmlEditorOptions htmlEditorOptions;
  final HtmlToolbarOptions htmlToolbarOptions;
  final OtherOptions otherOptions;
  final bool disabled;
  @override
  State<HtmlEditorWidget> createState() => _HtmlEditorWidgetMobileState();
}

/// State for the mobile Html editor widget
///
/// A stateful widget is necessary here to allow the height to dynamically adjust.
class _HtmlEditorWidgetMobileState extends State<HtmlEditorWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Tracks whether the callbacks were initialized or not to prevent re-initializing them
  bool callbacksInitialized = false;

  /// The file path to the html code
  late String filePath;

  /// String to use when creating the key for the widget
  late String key;

  /// Helps get the height of the toolbar to accurately adjust the height of
  /// the editor when the keyboard is visible.
  GlobalKey toolbarKey = GlobalKey();

  /// Cached widget to prevent rebuild
  Widget? _cachedWidget;

  String get _assetsPath => "packages/html_editor_plus/assets";

  @override
  void initState() {
    key = getRandString(10);
    if (widget.htmlEditorOptions.filePath != null) {
      filePath = widget.htmlEditorOptions.filePath!;
    } else if (widget.plugins.isEmpty) {
      filePath = '$_assetsPath/summernote-no-plugins.html';
    } else {
      filePath = '$_assetsPath/summernote.html';
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super for AutomaticKeepAliveClientMixin
    
    // Build widget tree only once and cache it permanently
    if (_cachedWidget != null) {
      return _cachedWidget!;
    }
    
    _cachedWidget = RepaintBoundary(
      child: SizedBox(
        height: widget.otherOptions.height,
        child: DecoratedBox(
          decoration: widget.otherOptions.decoration,
          child: Column(
            children: [
              if (widget.htmlToolbarOptions.toolbarPosition ==
                  ToolbarPosition.aboveEditor)
                ToolbarWidget(
                    key: toolbarKey,
                    controller: widget.controller,
                    htmlToolbarOptions: widget.htmlToolbarOptions,
                    callbacks: widget.callbacks),
              Expanded(
                child: InAppWebView(
                  initialFile: filePath,
                  onWebViewCreated: (InAppWebViewController controller) {
                    widget.controller.editorController = controller;
                    controller.addJavaScriptHandler(
                        handlerName: 'FormatSettings',
                        callback: (e) {
                          if (widget.controller.toolbar != null) {
                            var json = e[0] as Map<String, dynamic>;
                            widget.controller.toolbar!.updateToolbar(json);
                          }
                        });
                  },
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: true,
                    useShouldOverrideUrlLoading: true,
                    useHybridComposition:
                        widget.htmlEditorOptions.androidUseHybridComposition,
                    loadWithOverviewMode: false,
                    contentInsetAdjustmentBehavior:
                        ScrollViewContentInsetAdjustmentBehavior.AUTOMATIC,

                    // Allow manual zoom but prevent auto-zoom on small text
                    supportZoom: true,
                    minimumFontSize: 16,
                    hardwareAcceleration: true,

                    // Reduce layout shifts
                    layoutAlgorithm: LayoutAlgorithm.NORMAL,
                    
                    // Disable iOS input accessory view for smoother keyboard
                    disableInputAccessoryView: true,
                    
                    // Disable vertical scroll bar to reduce render overhead
                    disableVerticalScroll: false,
                    disableHorizontalScroll: true,
                    
                    // Disable context menu for faster interaction
                    disableContextMenu: false,
                  ),
                  initialUserScripts:
                      widget.htmlEditorOptions.mobileInitialScripts
                          as UnmodifiableListView<UserScript>?,
                  contextMenu: widget.htmlEditorOptions.mobileContextMenu
                      as ContextMenu?,
                  shouldOverrideUrlLoading: (controller, action) async {
                    if (!action.request.url.toString().contains(filePath)) {
                      return (await widget.callbacks?.onNavigationRequestMobile
                                  ?.call(action.request.url.toString()))
                              as NavigationActionPolicy? ??
                          NavigationActionPolicy.ALLOW;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    // Disable console message processing for performance
                  },
                  onWindowFocus: (controller) async {
                    // Removed ensureVisible to prevent keyboard lag
                  },
                  onLoadStop:
                      (InAppWebViewController controller, Uri? uri) async {
                    var url = uri.toString();
                    var maximumFileSize = 10485760;
                    await controller.evaluateJavascript(source: """
  var meta = document.querySelector('meta[name=viewport]');
  if (meta) {
      meta.setAttribute('content',
        'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes'
      );
  }
""");
                    if (url.contains(filePath)) {
                      // Ensure editor background is white on mobile (enabled and disabled)
                      await controller.evaluateJavascript(
                        source: """
                          (function(){
                            var css = '\n'
                              + 'html, body { background-color: #ffffff !important; overflow-y: auto !important; -webkit-overflow-scrolling: touch !important; }\\n'
                              + '.note-editor .note-editing-area, .note-editor .note-editing-area .note-editable { background-color: #ffffff !important; }\\n'
                              + '.note-editor.note-airframe .note-editing-area .note-editable[contenteditable=false],\\n'
                              + '.note-editor.note-frame .note-editing-area .note-editable[contenteditable=false]{ background-color:#ffffff !important; }\\n'
                              + '.note-editor .note-editing-area .note-editable table,\\n'
                              + '.note-editor .note-editing-area .note-editable table td,\\n'
                              + '.note-editor .note-editing-area .note-editable table th,\\n'
                              + '.note-editor .note-editing-area .note-editable table * { background-color: #ffffff !important; }\\n'
                              + '.note-editable { -webkit-user-select: text; user-select: text; overflow: visible !important; }\\n'
                              + '.note-editor { overflow: visible !important; }\\n';
                            var style = document.createElement('style');
                            style.type = 'text/css';
                            style.appendChild(document.createTextNode(css));
                            document.head.appendChild(style);
                            document.documentElement.style.backgroundColor = '#ffffff';
                            document.body.style.backgroundColor = '#ffffff';
                          })();
                        """,
                      );
                      var summernoteToolbar = '[\n';
                      var summernoteCallbacks = '''callbacks: {
                          onKeydown: function(e) {
                              var chars = \$(".note-editable").text();
                              var totalChars = chars.length;
                              ${widget.htmlEditorOptions.characterLimit != null ? '''allowedKeys = (
                                  e.which === 8 ||  /* BACKSPACE */
                                  e.which === 35 || /* END */
                                  e.which === 36 || /* HOME */
                                  e.which === 37 || /* LEFT */
                                  e.which === 38 || /* UP */
                                  e.which === 39 || /* RIGHT*/
                                  e.which === 40 || /* DOWN */
                                  e.which === 46 || /* DEL*/
                                  e.ctrlKey === true && e.which === 65 || /* CTRL + A */
                                  e.ctrlKey === true && e.which === 88 || /* CTRL + X */
                                  e.ctrlKey === true && e.which === 67 || /* CTRL + C */
                                  e.ctrlKey === true && e.which === 86 || /* CTRL + V */
                                  e.ctrlKey === true && e.which === 90    /* CTRL + Z */
                              );
                              if (!allowedKeys && \$(e.target).text().length >= ${widget.htmlEditorOptions.characterLimit}) {
                                  e.preventDefault();
                              }''' : ''}
                              window.flutter_inappwebview.callHandler('totalChars', totalChars);
                          },
                      ''';
                      if (widget.plugins.isNotEmpty) {
                        summernoteToolbar = "$summernoteToolbar['plugins', [";
                        for (var p in widget.plugins) {
                          summernoteToolbar = summernoteToolbar +
                              (p.getToolbarString().isNotEmpty
                                  ? "'${p.getToolbarString()}'"
                                  : '') +
                              (p == widget.plugins.last
                                  ? ']]\n'
                                  : p.getToolbarString().isNotEmpty
                                      ? ', '
                                      : '');
                          if (p is SummernoteAtMention) {
                            summernoteCallbacks = """$summernoteCallbacks
                              \nsummernoteAtMention: {
                                getSuggestions: async function(value) {
                                  var result = await window.flutter_inappwebview.callHandler('getSuggestions', value);
                                  var resultList = result.split(',');
                                  return resultList;
                                },
                                onSelect: (value) => {
                                  window.flutter_inappwebview.callHandler('onSelectMention', value);
                                },
                              },
                            """;
                            controller.addJavaScriptHandler(
                                handlerName: 'getSuggestions',
                                callback: (value) {
                                  return p.getSuggestionsMobile!
                                      .call(value.first.toString())
                                      .toString()
                                      .replaceAll('[', '')
                                      .replaceAll(']', '');
                                });
                            if (p.onSelect != null) {
                              controller.addJavaScriptHandler(
                                  handlerName: 'onSelectMention',
                                  callback: (value) {
                                    p.onSelect!.call(value.first.toString());
                                  });
                            }
                          }
                        }
                      }
                      if (widget.callbacks != null) {
                        if (widget.callbacks!.onImageLinkInsert != null) {
                          summernoteCallbacks = """$summernoteCallbacks
                              onImageLinkInsert: function(url) {
                                window.flutter_inappwebview.callHandler('onImageLinkInsert', url);
                              },
                            """;
                        }
                        if (widget.callbacks!.onImageUpload != null) {
                          summernoteCallbacks = """$summernoteCallbacks
                              onImageUpload: function(files) {
                                var reader = new FileReader();
                                var base64 = "<an error occurred>";
                                reader.onload = function (_) {
                                  base64 = reader.result;
                                  var newObject = {
                                     'lastModified': files[0].lastModified,
                                     'lastModifiedDate': files[0].lastModifiedDate,
                                     'name': files[0].name,
                                     'size': files[0].size,
                                     'type': files[0].type,
                                     'base64': base64
                                  };
                                  window.flutter_inappwebview.callHandler('onImageUpload', JSON.stringify(newObject));
                                };
                                reader.onerror = function (_) {
                                  var newObject = {
                                     'lastModified': files[0].lastModified,
                                     'lastModifiedDate': files[0].lastModifiedDate,
                                     'name': files[0].name,
                                     'size': files[0].size,
                                     'type': files[0].type,
                                     'base64': base64
                                  };
                                  window.flutter_inappwebview.callHandler('onImageUpload', JSON.stringify(newObject));
                                };
                                reader.readAsDataURL(files[0]);
                              },
                            """;
                        }
                        if (widget.callbacks!.onImageUploadError != null) {
                          summernoteCallbacks = """$summernoteCallbacks
                                onImageUploadError: function(file, error) {
                                  if (typeof file === 'string') {
                                    window.flutter_inappwebview.callHandler('onImageUploadError', file, error);
                                  } else {
                                    var newObject = {
                                       'lastModified': file.lastModified,
                                       'lastModifiedDate': file.lastModifiedDate,
                                       'name': file.name,
                                       'size': file.size,
                                       'type': file.type,
                                    };
                                    window.flutter_inappwebview.callHandler('onImageUploadError', JSON.stringify(newObject), error);
                                  }
                                },
                            """;
                        }
                      }
                      summernoteToolbar = '$summernoteToolbar],';
                      summernoteCallbacks = '$summernoteCallbacks}';
                      await controller.evaluateJavascript(source: """
                          \$('#summernote-2').summernote({
                              placeholder: "${widget.htmlEditorOptions.hint ?? ""}",
                              tabsize: 2,
                              height: ${widget.otherOptions.height - (toolbarKey.currentContext?.size?.height ?? 0)},
                              toolbar: $summernoteToolbar
                              disableGrammar: false,
                              spellCheck: ${widget.htmlEditorOptions.spellCheck},
                              maximumFileSize: $maximumFileSize,
                              ${widget.htmlEditorOptions.customOptions}
                              $summernoteCallbacks
                          });

                          \$('#summernote-2').on('summernote.change', function(_, contents, \$editable) {
                            window.flutter_inappwebview.callHandler('onChangeContent', contents);
                          });

                          var selectionChangeTimeout;
                          var lastUpdate = 0;
                          function onSelectionChange() {
                            var now = Date.now();
                            if (now - lastUpdate < 300) return;
                            clearTimeout(selectionChangeTimeout);
                            selectionChangeTimeout = setTimeout(function() {
                              try {
                                lastUpdate = Date.now();
                                let selection = document.getSelection();
                                if (!selection || !selection.focusNode) return;
                                
                                var focusNode = selection.focusNode;
                                var isBold = false;
                                var isItalic = false;
                                var isUnderline = false;
                                var isStrikethrough = false;
                                var isSuperscript = false;
                                var isSubscript = false;
                                var isUL = false;
                                var isOL = false;
                                var isLeft = false;
                                var isRight = false;
                                var isCenter = false;
                                var isFull = false;
                                var parent;
                                var fontName;
                                var fontSize = 16;
                                var foreColor = "000000";
                                var backColor = "FFFF00";
                                var focusNode2 = \$(focusNode);
                                var parentList = focusNode2.closest("div.note-editable ol, div.note-editable ul");
                                var parentListType = parentList.css('list-style-type');
                                var lineHeight = \$(focusNode.parentNode).css('line-height');
                                var direction = \$(focusNode.parentNode).css('direction');
                                if (document.queryCommandState) {
                                  isBold = document.queryCommandState('bold');
                                  isItalic = document.queryCommandState('italic');
                                  isUnderline = document.queryCommandState('underline');
                                  isStrikethrough = document.queryCommandState('strikeThrough');
                                  isSuperscript = document.queryCommandState('superscript');
                                  isSubscript = document.queryCommandState('subscript');
                                  isUL = document.queryCommandState('insertUnorderedList');
                                  isOL = document.queryCommandState('insertOrderedList');
                                  isLeft = document.queryCommandState('justifyLeft');
                                  isRight = document.queryCommandState('justifyRight');
                                  isCenter = document.queryCommandState('justifyCenter');
                                  isFull = document.queryCommandState('justifyFull');
                                }
                                if (document.queryCommandValue) {
                                  parent = document.queryCommandValue('formatBlock');
                                  fontSize = document.queryCommandValue('fontSize');
                                  foreColor = document.queryCommandValue('foreColor');
                                  backColor = document.queryCommandValue('hiliteColor');
                                  fontName = document.queryCommandValue('fontName');
                                }
                                var message = {
                                  'style': parent,
                                  'fontName': fontName,
                                  'fontSize': fontSize,
                                  'font': [isBold, isItalic, isUnderline],
                                  'miscFont': [isStrikethrough, isSuperscript, isSubscript],
                                  'color': [foreColor, backColor],
                                  'paragraph': [isUL, isOL],
                                  'listStyle': parentListType,
                                  'align': [isLeft, isCenter, isRight, isFull],
                                  'lineHeight': lineHeight,
                                  'direction': direction,
                                };
                                window.flutter_inappwebview.callHandler('FormatSettings', message);
                              } catch(e) {}
                            }, 300);
                          }
                      """);
                      await controller.evaluateJavascript(
                          source:
                              "document.onselectionchange = onSelectionChange;");
                      await controller.evaluateJavascript(
                          source:
                              "document.getElementsByClassName('note-editable')[0].setAttribute('inputmode', '${widget.htmlEditorOptions.inputType.name}');");
                      // Set background white only
                      controller.evaluateJavascript(
                        source: """
                          (function(){
                            var editable = document.querySelector('.note-editable');
                            if(editable) editable.style.backgroundColor = '#ffffff';
                          })();
                        """,
                      );
                      if ((Theme.of(context).brightness == Brightness.dark ||
                              widget.htmlEditorOptions.darkMode == true) &&
                          widget.htmlEditorOptions.darkMode != false) {
                        //todo fix for iOS (https://github.com/pichillilorenzo/flutter_inappwebview/issues/695)
                        var darkCSS =
                            '<link href="${"${widget.htmlEditorOptions.filePath != null ? "file:///android_asset/flutter_assets/packages/html_editor_plus/assets/" : ""}summernote-lite-dark.css"}" rel="stylesheet">';
                        await controller.evaluateJavascript(
                            source: "\$('head').append('$darkCSS');");
                      }
                      //set the text once the editor is loaded
                      if (widget.htmlEditorOptions.initialText != null) {
                        widget.controller
                            .setText(widget.htmlEditorOptions.initialText!);
                      }
                      //adjusts the height of the editor when it is loaded
                      if (widget.htmlEditorOptions.autoAdjustHeight) {
                        controller.addJavaScriptHandler(
                            handlerName: 'setHeight',
                            callback: (height) {
                              // Height adjustment removed for performance
                            });
                      }
                      widget.controller.editorController!.addJavaScriptHandler(
                          handlerName: 'totalChars',
                          callback: (keyCode) {
                            widget.controller.characterCount =
                                keyCode.first as int;
                          });
                      //disable editor if necessary
                      if (widget.htmlEditorOptions.disabled &&
                          !callbacksInitialized) {
                        widget.controller.disable();
                      }
                      //initialize callbacks
                      if (widget.callbacks != null && !callbacksInitialized) {
                        addJSCallbacks(widget.callbacks!);
                        addJSHandlers(widget.callbacks!);
                        callbacksInitialized = true;
                      }
                      //call onInit callback
                      if (widget.callbacks != null &&
                          widget.callbacks!.onInit != null) {
                        widget.callbacks!.onInit!.call();
                      }
                      //add onChange handler
                      controller.addJavaScriptHandler(
                          handlerName: 'onChangeContent',
                          callback: (contents) {
                            // Remove shouldEnsureVisible from onChange to prevent scroll jumping while typing
                            if (widget.callbacks != null &&
                                widget.callbacks!.onChangeContent != null) {
                              widget.callbacks!.onChangeContent!
                                  .call(contents.first.toString());
                            }
                          });
                    }
                  },
                ),
              ),
              if (widget.htmlToolbarOptions.toolbarPosition ==
                      ToolbarPosition.belowEditor &&
                  !widget.htmlEditorOptions.disabled)
                ToolbarWidget(
                    key: toolbarKey,
                    controller: widget.controller,
                    htmlToolbarOptions: widget.htmlToolbarOptions,
                    callbacks: widget.callbacks),
            ],
          ),
        ),
      ),
    );
    return _cachedWidget!;
  }

  /// adds the callbacks set by the user into the scripts
  void addJSCallbacks(Callbacks c) {
    if (c.onBeforeCommand != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.before.command', function(_, contents) {
            window.flutter_inappwebview.callHandler('onBeforeCommand', contents);
          });
        """);
    }
    if (c.onChangeCodeview != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.change.codeview', function(_, contents, \$editable) {
            window.flutter_inappwebview.callHandler('onChangeCodeview', contents);
          });
        """);
    }
    if (c.onDialogShown != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.dialog.shown', function() {
            window.flutter_inappwebview.callHandler('onDialogShown', 'fired');
          });
        """);
    }
    if (c.onEnter != null) {
      // widget.controller.editorController!.evaluateJavascript(source: """
      //     // \$('#summernote-2').on('summernote.enter', function() {
      //     //   window.flutter_inappwebview.callHandler('onEnter', 'fired');
      //     // });
      //   """);
      print("onEnter triggered");
    }
    if (c.onFocus != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.focus', function() {
            window.flutter_inappwebview.callHandler('onFocus', 'fired');
          });
        """);
    }
    if (c.onBlur != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.blur', function() {
            window.flutter_inappwebview.callHandler('onBlur', 'fired');
          });
        """);
    }
    if (c.onBlurCodeview != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.blur.codeview', function() {
            window.flutter_inappwebview.callHandler('onBlurCodeview', 'fired');
          });
        """);
    }
    if (c.onKeyDown != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.keydown', function(_, e) {
            window.flutter_inappwebview.callHandler('onKeyDown', e.keyCode);
          });
        """);
    }
    if (c.onKeyUp != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.keyup', function(_, e) {
            window.flutter_inappwebview.callHandler('onKeyUp', e.keyCode);
          });
        """);
    }
    if (c.onMouseDown != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.mousedown', function(_) {
            window.flutter_inappwebview.callHandler('onMouseDown', 'fired');
          });
        """);
    }
    if (c.onMouseUp != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.mouseup', function(_) {
            window.flutter_inappwebview.callHandler('onMouseUp', 'fired');
          });
        """);
    }
    if (c.onPaste != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.paste', function(_) {
            window.flutter_inappwebview.callHandler('onPaste', 'fired');
          });
        """);
    }
    if (c.onScroll != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.scroll', function(_) {
            window.flutter_inappwebview.callHandler('onScroll', 'fired');
          });
        """);
    }
  }

  /// creates flutter_inappwebview JavaScript Handlers to handle any callbacks the
  /// user has defined
  void addJSHandlers(Callbacks c) {
    if (c.onBeforeCommand != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onBeforeCommand',
          callback: (contents) {
            c.onBeforeCommand!.call(contents.first.toString());
          });
    }
    if (c.onChangeCodeview != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onChangeCodeview',
          callback: (contents) {
            c.onChangeCodeview!.call(contents.first.toString());
          });
    }
    if (c.onDialogShown != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onDialogShown',
          callback: (_) {
            c.onDialogShown!.call();
          });
    }
    if (c.onEnter != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onEnter',
          callback: (_) {
            c.onEnter!.call();
          });
    }
    if (c.onFocus != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onFocus',
          callback: (_) {
            c.onFocus!.call();
          });
    }
    if (c.onBlur != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onBlur',
          callback: (_) {
            c.onBlur!.call();
          });
    }
    if (c.onBlurCodeview != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onBlurCodeview',
          callback: (_) {
            c.onBlurCodeview!.call();
          });
    }
    if (c.onImageLinkInsert != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onImageLinkInsert',
          callback: (url) {
            c.onImageLinkInsert!.call(url.first.toString());
          });
    }
    if (c.onImageUpload != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onImageUpload',
          callback: (files) {
            var file = fileUploadFromJson(files.first);
            c.onImageUpload!.call(file);
          });
    }
    if (c.onImageUploadError != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onImageUploadError',
          callback: (args) {
            if (!args.first.toString().startsWith('{')) {
              c.onImageUploadError!.call(
                  null,
                  args.first,
                  args.last.contains('base64')
                      ? UploadError.jsException
                      : args.last.contains('unsupported')
                          ? UploadError.unsupportedFile
                          : UploadError.exceededMaxSize);
            } else {
              var file = fileUploadFromJson(args.first.toString());
              c.onImageUploadError!.call(
                  file,
                  null,
                  args.last.contains('base64')
                      ? UploadError.jsException
                      : args.last.contains('unsupported')
                          ? UploadError.unsupportedFile
                          : UploadError.exceededMaxSize);
            }
          });
    }
    if (c.onKeyDown != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onKeyDown',
          callback: (keyCode) {
            c.onKeyDown!.call(keyCode.first);
          });
    }
    if (c.onKeyUp != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onKeyUp',
          callback: (keyCode) {
            c.onKeyUp!.call(keyCode.first);
          });
    }
    if (c.onMouseDown != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onMouseDown',
          callback: (_) {
            c.onMouseDown!.call();
          });
    }
    if (c.onMouseUp != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onMouseUp',
          callback: (_) {
            c.onMouseUp!.call();
          });
    }
    if (c.onPaste != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onPaste',
          callback: (_) {
            c.onPaste!.call();
          });
    }
    if (c.onScroll != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onScroll',
          callback: (_) {
            c.onScroll!.call();
          });
    }
  }
}
