import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PhotoScreen extends StatelessWidget {
  PhotoScreen({key, required this.file}) : super(key: key);

  final File file;

  @override
  Widget build(BuildContext context) {
    var body;
    if (file.path.endsWith('.pdf')) {
      // display a pdf
      body = PDFView(
        filePath: file.path,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onError: (error) {
          print(error.toString());
        },
        onPageError: (page, error) {
          print('$page: ${error.toString()}');
        },
      );
    } else {
      // display a picture
      body = Image.file(file);
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Properties'),
          backgroundColor: Colors.green[700],
        ),
        body: body,
    );
  }
}