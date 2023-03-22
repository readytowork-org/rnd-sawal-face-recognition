import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_view.dart';
import 'painters/face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableTracking: true,
      enableClassification: true,
      // minFaceSize: 1,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Face Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isNotEmpty && faces.length < 2) {
      if (inputImage.inputImageData?.size != null &&
          inputImage.inputImageData?.imageRotation != null) {
        final face = faces.first;
        final painter = FaceDetectorPainter(
            faces,
            inputImage.inputImageData!.size,
            inputImage.inputImageData!.imageRotation);
        _customPaint = CustomPaint(painter: painter);
        _text =
            '${face.trackingId}\t\nleftEyeOpenProbability :: ${face.leftEyeOpenProbability}\nrightEyeOpenProbability :: ${face.rightEyeOpenProbability}\nsmilingProbability :: ${face.smilingProbability}}';
      } else {
        _customPaint = null;
        _text = 'Error';
      }
    } else {
      _customPaint = null;
      _text = 'Make sure there is one & only one person in frame';
    }
    _isBusy = false;
    if (mounted) {
      setState(() {
        _customPaint = _customPaint;
        _isBusy = _isBusy;
        _text = _text;
      });
    }
  }
}
