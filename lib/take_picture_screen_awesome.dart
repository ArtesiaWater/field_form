import 'dart:io';

import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:image/image.dart' as img;

// A screen that allows users to take a picture using a given camera.
class TakePictureScreenAwesome extends StatelessWidget {
  const TakePictureScreenAwesome({
    key,
    required this.filePath,
    this.title,
    this.resolution,
  }) : super(key: key);

  final String filePath;
  final String? title;
  final String? resolution;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title ?? ""),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: Container(
          color: Colors.white,
          child: CameraAwesomeBuilder.awesome(
            saveConfig: SaveConfig.photo(
                // pathBuilder: (sensors) async {
                //   return SingleCaptureRequest(filePath, sensors.first);
                // },
                exifPreferences: ExifPreferences(saveGPSLocation: true),
            ),
            onMediaTap: (mediaCapture) {
              resizeImage(mediaCapture.captureRequest.path, filePath, resolution);
              Navigator.pop(context, true);
            },
            onMediaCaptureEvent: (event) {
             if (event.status == MediaCaptureStatus.success){
               resizeImage(event.captureRequest.path, filePath, resolution);
               // If the picture was taken, return the image to the caller
               Navigator.pop(context, true);
             }
            }
          ),
        )
    );
  }
}

void resizeImage (filePathOriginal, filePathNew, resolution) async {
  var width;
  switch (resolution ?? 'medium'){
    case 'low':
      width = 240;
      break;
    case 'medium':
      width = 480;
      break;
    case 'high':
      width = 720;
      break;
    case 'veryHigh':
      width = 1080;
      break;
    case 'ultraHigh':
      width = 2160;
      break;
    case 'max':
      width = null;
      break;
    default:
    // if not specified, set to medium width again
      width = 480;
  }
  if (width != null){
    print("resizing image file....");
    final image = img.decodeJpg(File(filePathOriginal).readAsBytesSync());
    if (image != null){
      final resizedImage = img.copyResize(image, width: width);
      File(filePathNew).writeAsBytesSync(await img.encodeJpg(resizedImage));
      //img.encodeJpgFile(filePath, resizedImage);
    }
  } else {
    await File(filePathOriginal).copy(filePathNew);
  }
}

