import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unfold/core/detect.dart';
import 'package:unfold/core/ole.dart';
import 'package:unfold/core/unfold_doc.dart';

import 'fixtures.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('unfold-test-');
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  test('markdown heading round-trip and preview contain the heading', () {
    final path = p.join(tmp.path, 'note.md');
    File(path).writeAsStringSync('# Unfold Title\n\nHello body.\n');
    final doc = UnfoldDocument.open(path);
    expect(doc.kind, FileKind.markdown);
    expect(doc.caps.edit, isTrue);
    expect(doc.caps.preview, isTrue);
    expect(doc.text, contains('Unfold Title'));
    expect(doc.previewHtml(), contains('Unfold Title'));
    expect(doc.plainFromHtml(), contains('Unfold Title'));
    doc.text = '${doc.text}\nEdited line.';
    final exported = p.join(tmp.path, 'note-out.md');
    doc.exportTo(exported);
    final htmlOut = p.join(tmp.path, 'note.html');
    doc.exportTo(htmlOut);
    expect(File(exported).readAsStringSync(), contains('Edited line.'));
    expect(File(exported).readAsStringSync(), contains('Unfold Title'));
    expect(File(htmlOut).readAsStringSync(), contains('Unfold Title'));
    doc.save();
    final again = UnfoldDocument.open(path);
    expect(again.text, contains('Edited line.'));
    expect(again.previewHtml(), contains('Unfold Title'));
  });

  test('plain text and html open, edit, export real content', () {
    final txt = p.join(tmp.path, 'a.txt');
    File(txt).writeAsStringSync('plain unfold text');
    final t = UnfoldDocument.open(txt);
    expect(t.kind, FileKind.plainText);
    expect(t.text, contains('plain unfold text'));
    t.text = '${t.text}\nmore';
    final txtOut = p.join(tmp.path, 'a-out.txt');
    t.exportTo(txtOut);
    expect(File(txtOut).readAsStringSync(), contains('more'));

    final html = p.join(tmp.path, 'page.html');
    File(html).writeAsStringSync('<h1>Html Heading</h1><p>Body copy.</p>');
    final h = UnfoldDocument.open(html);
    expect(h.kind, FileKind.html);
    expect(h.plainFromHtml(), contains('Html Heading'));
    expect(h.previewHtml(), contains('Html Heading'));
  });

  test('PDF search, annotate, rotate, delete, export reflect real changes', () {
    final path = p.join(tmp.path, 'doc.pdf');
    File(path).writeAsBytesSync(
      buildTestPdf(['Hello Unfold', 'Second page BetaPage']),
    );
    final doc = UnfoldDocument.open(path);
    expect(doc.kind, FileKind.pdf);
    expect(doc.pdf!.pageCount, 2);
    final hits = doc.search('Hello Unfold');
    expect(hits, isNotEmpty);
    expect(hits.first.snippet, contains('Hello Unfold'));
    expect(doc.pdf!.pageText(1), contains('BetaPage'));

    doc.addPdfNote(0, 'margin note');
    doc.rotatePdfPage(0, 90);
    final exported = p.join(tmp.path, 'doc-out.pdf');
    doc.exportTo(exported);
    expect(File(exported).lengthSync(), greaterThan(100));

    final again = UnfoldDocument.open(exported);
    expect(again.search('Hello Unfold'), isNotEmpty);
    expect(again.pdf!.notesOn(0), contains('margin note'));
    expect(again.pdf!.rotationOf(0), 90);
    expect(again.pdf!.pageCount, 2);

    again.deletePdfPage(0);
    final trimmed = p.join(tmp.path, 'doc-trim.pdf');
    again.exportTo(trimmed);
    final last = UnfoldDocument.open(trimmed);
    expect(last.pdf!.pageCount, 1);
    expect(last.pdf!.pageText(0), contains('BetaPage'));
    expect(last.search('Hello Unfold'), isEmpty);
  });

  test('DOCX yields the known body text', () {
    final path = p.join(tmp.path, 'letter.docx');
    File(path).writeAsBytesSync(buildTestDocx('Known DOCX body'));
    final doc = UnfoldDocument.open(path);
    expect(doc.kind, FileKind.docx);
    expect(doc.text, contains('Known DOCX body'));
    final out = p.join(tmp.path, 'letter.txt');
    doc.exportTo(out);
    expect(File(out).readAsStringSync(), contains('Known DOCX body'));
  });

  test('legacy DOC yields the known body text', () {
    final path = p.join(tmp.path, 'letter.doc');
    File(path).writeAsBytesSync(DocCodec.encode('Known DOC body'));
    expect(detectKind(path, File(path).readAsBytesSync()), FileKind.doc);
    final doc = UnfoldDocument.open(path);
    expect(doc.kind, FileKind.doc);
    expect(doc.text, contains('Known DOC body'));
  });

  test('EPUB lists chapter text from a real package', () {
    final path = p.join(tmp.path, 'book.epub');
    File(path).writeAsBytesSync(buildTestEpub('Epub Heading', 'Epub paragraph body'));
    final doc = UnfoldDocument.open(path);
    expect(doc.kind, FileKind.epub);
    expect(doc.text, contains('Epub Heading'));
    expect(doc.text, contains('Epub paragraph body'));
    expect(doc.chapters, isNotEmpty);
    expect(doc.chapters.first.text, contains('Epub paragraph body'));
  });

  test('PNG rotate changes dimensions as expected', () {
    final path = p.join(tmp.path, 'pic.png');
    File(path).writeAsBytesSync(buildTestPng());
    final doc = UnfoldDocument.open(path);
    expect(doc.kind, FileKind.image);
    expect(doc.imageWidth, 20);
    expect(doc.imageHeight, 10);
    doc.rotateImage90();
    expect(doc.imageWidth, 10);
    expect(doc.imageHeight, 20);
    final out = p.join(tmp.path, 'pic-rot.png');
    doc.exportTo(out);
    final again = UnfoldDocument.open(out);
    expect(again.imageWidth, 10);
    expect(again.imageHeight, 20);
  });

  test('ZIP lists and extracts a known entry', () {
    final path = p.join(tmp.path, 'pack.zip');
    File(path).writeAsBytesSync(buildTestZip('hello.txt', 'zip-payload-unfold'));
    final doc = UnfoldDocument.open(path);
    expect(doc.kind, FileKind.zip);
    expect(doc.zipNames, contains('hello.txt'));
    final dest = p.join(tmp.path, 'extracted');
    doc.extractZipTo(dest);
    expect(File(p.join(dest, 'hello.txt')).readAsStringSync(), 'zip-payload-unfold');
    final one = p.join(tmp.path, 'one');
    doc.extractZipTo(one, only: 'hello.txt');
    expect(File(p.join(one, 'hello.txt')).readAsStringSync(), contains('zip-payload-unfold'));
  });
}
