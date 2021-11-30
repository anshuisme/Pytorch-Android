import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Pytorch Mobile'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel torchChannel =
      MethodChannel('com.pytorch_channel');

  @override
  void initState() {
    super.initState();
    __gettingModelFile()
        .then((void value) => print('File Created Successfully'));
  }

  String documentsPath = '', prediction = '';

  Future<void> __gettingModelFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();

    setState(() {
      documentsPath = directory.path;
    });

    final String resnet50 = join(directory.path, 'model.pt');
    final ByteData data = await rootBundle.load('assets/models/model.pt');

    final List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    if (!File(resnet50).existsSync()) {
      await File(resnet50).writeAsBytes(bytes);
    }
  }

  Future<void> _getPrediction() async {
    final ByteData imageData = await rootBundle.load('assets/eren.png');

    try {
      final String result = await torchChannel.invokeMethod(
        'predict_image',
        <String, dynamic>{
          'model_path': '$documentsPath/model.pt',
          'image_data': imageData.buffer
              .asUint8List(imageData.offsetInBytes, imageData.lengthInBytes),
          'data_offset': imageData.offsetInBytes,
          'data_length': imageData.lengthInBytes
        },
      );

      setState(() {
        prediction = result;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(documentsPath ?? ''),
            Stack(children: <Widget>[
              Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 300,
                    child: Image.asset('assets/eren.png'),
                  )),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    (prediction ?? '').toUpperCase(),
                    style: const TextStyle(fontSize: 25),
                  )),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    TextButton(
                      child: const Text('Classify Image'),
                      onPressed: _getPrediction,
                    )
                  ])
            ])
          ],
        ),
      ),
    );
  }
}
