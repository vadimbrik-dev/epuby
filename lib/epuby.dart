library epuby;

import 'dart:typed_data';

import 'package:bookvar/bookvar.dart' as bookvar;
import 'package:flutter/material.dart';

class ElementStyle {
  final TextStyle textStyle;
  final EdgeInsets padding;

  ElementStyle({required this.textStyle, required this.padding});
}

class BookThemeData {
  final double scaleFactor;
  final EdgeInsets padding;
  final ElementStyle header;
  final ElementStyle paragraph;

  const BookThemeData({
    required this.padding,
    required this.header,
    required this.paragraph,
    required this.scaleFactor,
  });
}

class BookTheme extends InheritedWidget {
  final BookThemeData data;

  const BookTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  static BookThemeData of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<BookTheme>();
    assert(result != null, 'No BookTheme found in context');
    return result!.data;
  }

  @override
  bool updateShouldNotify(_) => true;
}

class BookRenderer {
  BookThemeData theme;

  BookRenderer({required this.theme});

  ElementStyle getStyle(bookvar.Element element) {
    final ElementStyle style;

    switch (element.runtimeType) {
      case bookvar.Header:
        style = theme.header;
        break;
      case bookvar.Paragraph:
        style = theme.paragraph;
        break;
      default:
        throw Exception('Undefined element type');
    }

    return style;
  }

  Widget render(bookvar.Element element) {
    if (element is bookvar.TextElement) {
      final ElementStyle style = getStyle(element);
      final TextAlign align;

      switch (element.runtimeType) {
        case bookvar.Header:
          align = TextAlign.start;
          break;
        case bookvar.Paragraph:
          align = TextAlign.justify;
          break;
        default:
          throw Exception('Undefined element type');
      }

      return Padding(
        padding: style.padding,
        child: Text(
          element.content,
          style: style.textStyle,
          textScaleFactor: theme.scaleFactor,
          textAlign: align,
        ),
      );
    }
    if (element is bookvar.Image) {
      final buffer = Uint8List.fromList(element.buffer);
      return Center(
        child: Image.memory(buffer),
      );
    }
    throw Exception('Undefined element type');
  }
}
