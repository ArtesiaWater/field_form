import 'dart:async';

import 'package:camera/camera.dart';
import 'package:field_form/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
    this.resolution,
  }) : super(key: key);

  final CameraDescription camera;
  final String? resolution;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    var resolutionPreset;
    switch (widget.resolution ?? 'medium'){
      case 'low':
        resolutionPreset = ResolutionPreset.low;
        break;
      case 'medium':
        resolutionPreset = ResolutionPreset.medium;
        break;
      case 'high':
        resolutionPreset = ResolutionPreset.high;
        break;
      case 'veryHigh':
        resolutionPreset = ResolutionPreset.veryHigh;
        break;
      case 'ultraHigh':
        resolutionPreset = ResolutionPreset.ultraHigh;
        break;
      case 'max':
        resolutionPreset = ResolutionPreset.max;
        break;
      default:
        resolutionPreset = ResolutionPreset.medium;
    }
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      resolutionPreset,
      // Do not request audio permission
      enableAudio: false,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var texts = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts.takePicture),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            // If the picture was taken, return the image to the caller
            Navigator.pop(context, image);
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}