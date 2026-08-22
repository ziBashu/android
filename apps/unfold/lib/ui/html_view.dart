import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'tokens.dart';

class SimpleHtmlView extends StatelessWidget {
  const SimpleHtmlView({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final parsed = html_parser.parse(html);
    final body = parsed.body ?? parsed.documentElement;
    return DefaultTextStyle(
      style: const TextStyle(
        color: UnfoldTokens.ink,
        fontSize: 16,
        height: 1.45,
      ),
      child: body == null ? Text(html) : _node(body),
    );
  }

  Widget _node(dom.Node node) {
    if (node is dom.Text) {
      final t = node.text;
      if (t.trim().isEmpty) return const SizedBox.shrink();
      return Text(t);
    }
    if (node is! dom.Element) return const SizedBox.shrink();
    final children = node.nodes.map(_node).where((w) => w is! SizedBox).toList();
    final tag = node.localName ?? '';
    switch (tag) {
      case 'h1':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        );
      case 'h2':
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        );
      case 'h3':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 6),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        );
      case 'p':
      case 'div':
      case 'section':
      case 'article':
      case 'body':
      case 'html':
        return Padding(
          padding: tag == 'p' ? const EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      case 'em':
      case 'i':
        return DefaultTextStyle.merge(
          style: const TextStyle(fontStyle: FontStyle.italic),
          child: Wrap(children: children),
        );
      case 'strong':
      case 'b':
        return DefaultTextStyle.merge(
          style: const TextStyle(fontWeight: FontWeight.w700),
          child: Wrap(children: children),
        );
      case 'li':
        return Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
            ],
          ),
        );
      case 'ul':
      case 'ol':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
      case 'br':
        return const SizedBox(height: 8);
      case 'pre':
      case 'code':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          color: UnfoldTokens.key,
          child: Text(node.text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        );
      case 'blockquote':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: UnfoldTokens.forest, width: 3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
  }
}
