import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';


void main(){
  runApp(
      MaterialApp(
          title: 'SmileyFace',
          home: FacePage(),
        debugShowCheckedModeBanner: false,
      )
  );
}

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  ui.Image _myImage;
  bool _isLoading = true;

  void getAndDetect() async{
    final imageFile = await ImagePicker.pickImage(
        source: ImageSource.gallery
    );
    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector(
        FaceDetectorOptions(
            mode: FaceDetectorMode.accurate,
            enableClassification: true
        )
    );
    final faces = await faceDetector.processImage(image);
    final myImage = await loadImage(imageFile);
    if(mounted){
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _myImage = myImage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LET\'S PUT A SMILE ON THAT FACE',
          style: TextStyle(fontSize: 22, fontStyle: FontStyle.italic),
        ),
        backgroundColor: Colors.lightGreen,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
        child: Center(
          child: _isLoading
              ? Center(child: Text('Press the button'),)
              :
          FittedBox(
              child: SizedBox(
                  width: _myImage.width.toDouble(),
                  height: _myImage.height.toDouble(),
                  child: Smiley(image: _myImage, faces: _faces,)
              )
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getAndDetect,
        backgroundColor: Colors.lightGreen,
        tooltip: "Pick an image",
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

Future<ui.Image> loadImage(File file) async{
  final data = await file.readAsBytes();
  return await decodeImageFromList(data);
}


class Smiley extends StatelessWidget {

  final ui.Image image;
  final List<Face> faces;

  Smiley({this.faces, this.image});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
          painter: SmileyPainter(faces: faces, image: image),
        );
  }
}

class SmileyPainter extends CustomPainter{

  final List<Face> faces;
  final ui.Image image;
  SmileyPainter({this.faces, this.image});

  @override
  void paint(ui.Canvas canvas, ui.Size size) async{
    if(image==null){
      canvas.drawCircle(Offset(10,10), 5, Paint());
    }
    else{
      canvas.drawImage(image, Offset.zero, Paint());

      final paint = Paint()..color = Colors.yellow;

      for (var i = 0; i < faces.length; i++) {
        if(faces[i].smilingProbability>0.7){
          final radius =
              Math.min(faces[i].boundingBox.width, faces[i].boundingBox.height) / 2;
          final center = faces[i].boundingBox.center;
          final smilePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius / 8;
          canvas.drawCircle(center, radius, paint);
          canvas.drawArc(
              Rect.fromCircle(
                  center: center.translate(0, radius / 8), radius: radius / 2),
              0,
              Math.pi,
              false,
              smilePaint);
          //Draw the eyes
          canvas.drawCircle(Offset(center.dx - radius / 2, center.dy - radius / 2),
              radius / 8, Paint());
          canvas.drawCircle(Offset(center.dx + radius / 2, center.dy - radius / 2),
              radius / 8, Paint());
        }

      }
    }
  }

  @override
  bool shouldRepaint(SmileyPainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}


