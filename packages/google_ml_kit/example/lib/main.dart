import 'package:aws_rekognition_api/rekognition-2016-06-27.dart'
    show AwsClientCredentials, Rekognition;
import 'package:camera/camera.dart' show CameraDescription, availableCameras;
import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        Card,
        Center,
        Colors,
        Column,
        EdgeInsets,
        ExpansionTile,
        FontWeight,
        ListTile,
        MaterialApp,
        MaterialPageRoute,
        Navigator,
        Padding,
        SafeArea,
        Scaffold,
        ScaffoldMessenger,
        SingleChildScrollView,
        SizedBox,
        SnackBar,
        StatelessWidget,
        Text,
        TextStyle,
        Theme,
        Widget,
        WidgetsFlutterBinding,
        runApp;

import 'vision_detector_views/face_detector_view.dart';

List<CameraDescription> cameras = [];
final rekoService = Rekognition(
  region: 'us-east-1',
  credentials: AwsClientCredentials(
    secretKey: 'eLP/PP3V9g8O7DoJoslnso6A4doKyl3N7327nvwY',
    accessKey: 'AKIA4YLFYXQWTBZNKR4I',
  ),
);

String collectionName = 'collectionId';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  try {
    final value = await rekoService.describeCollection(collectionId: collectionName);
    print('faceModelVersion :: ${value.faceModelVersion}');
    print('collectionARN :: ${value.collectionARN}');
    print('creationTimestamp :: ${value.creationTimestamp}');
    print('faceCount :: ${value.faceCount}');
  } catch (e) {
    print('ErrorAws :: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google ML Kit Demo App'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ExpansionTile(
                    title: const Text('Vision APIs'),
                    children: [
                      // CustomCard('Barcode Scanning', BarcodeScannerView()),
                      CustomCard('Face Detection', FaceDetectorView()),
                      // CustomCard('Image Labeling', ImageLabelView()),
                      // CustomCard('Object Detection', ObjectDetectorView()),
                      // CustomCard('Text Recognition', TextRecognizerView()),
                      // CustomCard('Digital Ink Recognition', DigitalInkView()),
                      // CustomCard('Pose Detection', PoseDetectorView()),
                      // CustomCard('Selfie Segmentation', SelfieSegmenterView()),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ExpansionTile(
                    title: const Text('Natural Language APIs'),
                    children: [
                      // CustomCard('Language ID', LanguageIdentifierView()),
                      // CustomCard(
                      //     'On-device Translation', LanguageTranslatorView()),
                      // CustomCard('Smart Reply', SmartReplyView()),
                      // CustomCard('Entity Extraction', EntityExtractionView()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage, {this.featureCompleted = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).primaryColor,
        title: Text(
          _label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (!featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    const Text('This feature has not been implemented yet')));
          } else {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => _viewPage));
          }
        },
      ),
    );
  }
}
