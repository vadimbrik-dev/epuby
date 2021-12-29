library epuby;

import 'package:flutter/material.dart';
import 'package:html/parser.dart';

Size calculateTextBounds(
    {required Size container,
    required TextSpan text,
    required EdgeInsets padding}) {
  final painter = TextPainter(text: text, textDirection: TextDirection.ltr)
    ..layout(maxWidth: container.width - padding.horizontal);
  return Size(
    painter.width + padding.horizontal,
    painter.height + padding.vertical,
  );
}

abstract class BookElement {
  final String content;
  final TextStyle style;
  final EdgeInsets padding;

  BookElement({
    required this.content,
    required this.style,
    required this.padding,
  });

  BookElement copyWithContent(String content);

  Widget get widget => Padding(
        padding: padding,
        child: Text(content, style: style, textAlign: TextAlign.justify),
      );

  Size calculateBounds(Size container) {
    final text = TextSpan(text: content, style: style);
    final painter = TextPainter(text: text, textDirection: TextDirection.ltr)
      ..layout(maxWidth: container.width - padding.horizontal);

    return Size(
      painter.width + padding.horizontal,
      painter.height + padding.vertical,
    );
  }
}

class ParagraphElement extends BookElement {
  static const _localPadding =
      EdgeInsets.symmetric(vertical: 8, horizontal: 24);

  ParagraphElement({
    required String content,
    required TextStyle style,
  }) : super(content: content, style: style, padding: _localPadding);

  @override
  ParagraphElement copyWithContent(String content) =>
      ParagraphElement(content: content, style: style);
}

class HeaderElement extends BookElement {
  static const _localPadding =
      EdgeInsets.only(top: 28, bottom: 8, left: 24, right: 24);

  HeaderElement({
    required String content,
    required TextStyle style,
  }) : super(content: content, style: style, padding: _localPadding);

  @override
  HeaderElement copyWithContent(String content) =>
      HeaderElement(content: content, style: style);
}

class PageContainer {
  final List<BookElement> _elements = [];
  final Size bounds;
  PageContainer({required this.bounds});

  void append(BookElement element) {
    _elements.add(element);
  }

  List<Widget> get widgets => _elements.map((e) => e.widget).toList();

  bool canAppend(BookElement element) =>
      element.calculateBounds(bounds).height < freeSpace;

  double get freeSpace => bounds.height - filledSpace;

  double get filledSpace => _elements.fold(
      0,
      (accumulator, element) =>
          accumulator + element.calculateBounds(bounds).height);
}

class BookContainer {
  final List<PageContainer> _pages = [];
  final Size bounds;

  BookContainer({required this.bounds}) {
    _pages.add(PageContainer(bounds: bounds));
  }

  List<PageContainer> get pages => _pages;

  void append(BookElement element) {
    if (_pages.last.canAppend(element)) {
      _pages.last.append(element);
    } else {
      final words = element.content.split(' ');
      var first = '';

      for (final word in words) {
        final string = '$first $word';
        final text = TextSpan(text: string, style: element.style);
        final height = calculateTextBounds(
                container: bounds, text: text, padding: element.padding)
            .height;

        if (height >= _pages.last.freeSpace) {
          break;
        }

        first = string;
      }

      if (first.isNotEmpty) {
        append(element.copyWithContent(first));
      }

      _pages.add(PageContainer(bounds: bounds));

      if (first != element.content) {
        final second = element.content.substring(first.length);
        append(element.copyWithContent(second));
      }
    }
  }
}

class XmlToBookAdapter {
  final String content;

  XmlToBookAdapter({required this.content});

  BookContainer render(
      {required Size bounds,
      required TextStyle headerStyle,
      required TextStyle paragraphStyle}) {
    final document = parse(content);
    final nodes = document
        .querySelectorAll("h1, h2, h3, h4, h5, h6, p")
        .where((element) => element.text.trim().isNotEmpty)
        .toList();
    final bookContainer = BookContainer(bounds: bounds);

    for (final node in nodes) {
      switch (node.localName) {
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          bookContainer
              .append(HeaderElement(content: node.text, style: headerStyle));
          break;
        case 'p':
          bookContainer.append(
              ParagraphElement(content: node.text, style: paragraphStyle));
          break;
      }
    }
    return bookContainer;
  }
}
