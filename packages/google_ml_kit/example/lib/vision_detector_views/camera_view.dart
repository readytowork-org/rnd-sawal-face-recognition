import 'dart:io';

import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' show Image;
import 'package:camera/camera.dart'
    show CameraController, CameraImage, CameraLensDirection, CameraPreview, ImageFormatGroup, Plane, ResolutionPreset;
import 'package:flutter/foundation.dart' show Key, WriteBuffer;
import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        Center,
        Colors,
        Container,
        CustomPaint,
        ElevatedButton,
        Key,
        MediaQuery,
        Positioned,
        Row,
        Scaffold,
        Size,
        Stack,
        StackFit,
        State,
        StatefulWidget,
        Text,
        Transform,
        Widget;
import 'package:google_mlkit_commons/google_mlkit_commons.dart'
    show
        InputImage,
        InputImageData,
        InputImageFormatValue,
        InputImagePlaneMetadata,
        InputImageRotationValue;

import '../main.dart';

enum ScreenMode { liveFeed, gallery }

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
      required this.title,
      required this.customPaint,
      this.text,
      required this.onImage,
      this.onScreenModeChanged,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  int _cameraIndex = 0;
  final bool _changingCameraLens = false;

  @override
  void initState() {
    super.initState();

    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) => element.lensDirection == widget.initialDirection,
        ),
      );
    }

    _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _body(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _body() {
    return _liveFeedBody();
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? Center(
                      child: const Text('Changing camera lens'),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null) widget.customPaint!,
          Text(widget.text ?? ''),
          Positioned(
            bottom: 32,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final value = await rekoService.createCollection(
                          collectionId: collectionName);
                      print('collectionArn :: ${value.collectionArn}');
                      print('faceModelVersion :: ${value.faceModelVersion}');
                      print('statusCode :: ${value.statusCode}');
                    } catch (e) {
                      print('ErrorAws :: $e');
                    }
                  },
                  child: Text('Create coll'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final value = await rekoService.deleteCollection(
                          collectionId: collectionName);

                      print('statusCode :: ${value.statusCode}');
                    } catch (e) {
                      print('ResetError :: $e');
                    }
                  },
                  child: Text('resetCollection'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    print('face capturing..');

                    try {
                      await _controller?.stopImageStream();
                      final value = await _controller?.takePicture();
                      final byte = await value?.readAsBytes();

                      final rko = await rekoService.indexFaces(
                        collectionId: collectionName,
                        image: Image(bytes: byte),
                        externalImageId: DateTime.now().toIso8601String(),
                        maxFaces: 1,
                      );

                      rko.faceRecords?.forEach((element) {
                        print('face.confidence :: ${element.face?.confidence}');
                        print(
                            'face.externalImageId :: ${element.face?.externalImageId}');
                        print('face.faceId :: ${element.face?.faceId}');
                        print('face.imageId :: ${element.face?.imageId}');

                        element.faceDetail?.emotions?.forEach((element) {
                          print('emotion :: ${element.type}');
                        });
                      });
                      _controller?.startImageStream(_processCameraImage);
                    } catch (e) {
                      print('ErrorIndexing :: $e');
                    }
                  },
                  child: Text('capture'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    print('face capturing..');
                    await _controller?.stopImageStream();
                    final value = await _controller?.takePicture();
                    final byte = await value?.readAsBytes();

                    try {
                      final value = await rekoService.searchFacesByImage(
                        collectionId: collectionName,
                        image: Image(bytes: byte),
                      );
                      value.faceMatches?.forEach((element) {
                        print('similarity :: ${element.similarity}');

                        print('face.faceId :: ${element.face?.faceId}');
                        print('face.confidence :: ${element.face?.confidence}');
                        print(
                            'face.externalImageId :: ${element.face?.externalImageId}');
                      });
                      _controller?.startImageStream(_processCameraImage);
                    } catch (e) {
                      print('DetectError :: $e');
                    }
                  },
                  child: Text('detect'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage);
  }
}
