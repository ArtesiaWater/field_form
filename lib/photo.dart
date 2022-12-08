import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pdfx/pdfx.dart';

import 'constants.dart';

class PhotoScreen extends StatelessWidget {
  PhotoScreen({key, required this.file}) : super(key: key);

  final File file;

  @override
  Widget build(BuildContext context) {
    var body;
    if (file.path.endsWith('.pdf')) {
      // body = SfPdfViewer.file(file);
      final pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(file.path),
      );
      // display a pdf
      body = PdfViewPinch(
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
          backgroundColor: Constant.primaryColor,
        ),
        body: body,
    );
  }
}