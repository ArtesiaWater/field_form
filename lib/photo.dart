import 'dart:io';

import 'package:flutter/material.dart';
import 'package:native_pdf_view/native_pdf_view.dart';
import 'package:path/path.dart';

class PhotoScreen extends StatelessWidget {
  PhotoScreen({key, required this.file}) : super(key: key);

  final File file;

  @override
  Widget build(BuildContext context) {
    var body;
    if (file.path.endsWith('.pdf')) {
      final pdfController = PdfController(
        document: PdfDocument.openFile(file.path),
      );
      // display a pdf
      body = PdfView(
        controller: pdfController,
      );
    } else {
      // display an image
      body = InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
            child: Image.file(file)
        )
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(basename(file.path)),
          backgroundColor: Colors.green[700],
        ),
        body: body,
    );
  }
}