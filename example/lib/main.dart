import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyAppInternal(),
    );
  }
}

class MyAppInternal extends StatefulWidget {
  const MyAppInternal({Key? key}) : super(key: key);

  @override
  _MyAppInternalState createState() => _MyAppInternalState();
}

class _MyAppInternalState extends State<MyAppInternal> {
  StreamSubscription<ScanResult>? scanSubscription;
  List<ScanResult> scanResults = [];
  bool dfuRunning = false;
  int? dfuRunningInx;
  double dfuProgress = 0.0;

 Future<void> doDfu(String deviceId) async {
  print("Start DFU");

  // Show the start DFU dialog
  showStartDfuMessage();

  stopScan();
  dfuRunning = true;

  try {
    // Show the file picker dialog
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    // Check if the user selected a file
    print('dddddddddddddddddddddddddddddddd');
    if (result != null) {
      File file = File(result.files.single.path!);

      // Show the progress dialog
      showProgressDialog();

      final s = await NordicDfu().startDfu(
        deviceId,
        file.path,
        fileInAsset: false,
        onDeviceDisconnecting: (string) {
          debugPrint('Device Address: $string');
        },
        onProgressChanged: (
          deviceAddress,
          percent,
          speed,
          avgSpeed,
          currentPart,
          partsTotal,
        ) {
          setState(() {
            dfuProgress = percent.toDouble();
          });

          debugPrint('Device Address: $deviceAddress, Percent: $percent');

          if (percent == 100) {
            // Firmware update complete

            // Close the progress dialog when the update is complete
            Navigator.of(context).pop();
          }
        },
      );
      print("DFU Completed with result: $s");
    } else {
      // User canceled file picking
      print("File picking canceled");
    }

    dfuRunning = false;
  } catch (e) {
    dfuRunning = false;
    debugPrint(e.toString());

    // Show error dialog
    showErrorDialog(e.toString());
  }
}

// Function to show the start DFU dialog
void showStartDfuMessage() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('DFU Started'),
        content: Text('Device Firmware Update process has started.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

// Function to show the progress dialog
void showProgressDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside of the dialog
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('DFU Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Firmware update in progress...'),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: dfuProgress / 100.0,
              minHeight: 20,
            ),
            SizedBox(height: 16),
            Text('${dfuProgress.toStringAsFixed(2)}%'),
          ],
        ),
      );
    },
  );
}

// Function to show the error dialog
void showErrorDialog(String errorMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('DFU Error'),
        content: Text('An error occurred during the DFU process:\n\n$errorMessage'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}



  // void showFileSelectDialog() async {
   
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['zip'],
  //   );

  //   if (result != null) {
  //     File file = File(result.files.single.path!);

  //     await doDfu(file.path);

  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: Text('File Selected'),
  //           content: Text('Firmware update file selected successfully.'),
  //           actions: <Widget>[
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: Text('OK'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }

  // void showStartDfuMessage() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('DFU Started'),
  //         content: Text('Device Firmware Update process has started.'),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  FlutterBluePlus flutterBlue = FlutterBluePlus();

  void startScan() async {
    print("Start Scanning");

    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

      await Future.delayed(Duration(seconds: 5));
      await FlutterBluePlus.stopScan();

      FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        setState(() {
          scanResults = results;
          print('Discovered devices: $scanResults');
        });
      });
    } catch (e) {
      print('Error while scanning: $e');
      print('Error details: ${e.runtimeType}');
      print('Error stack trace: $e');
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
    scanSubscription = null;
    setState(() => scanSubscription = null);
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = scanSubscription != null;
    final hasDevice = scanResults.isNotEmpty;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: <Widget>[
            if (isScanning)
              IconButton(
                icon: const Icon(Icons.pause_circle_filled),
                onPressed: dfuRunning ? null : stopScan,
              )
            else
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: dfuRunning ? null : startScan,
              ),
            // ElevatedButton(
            //   onPressed: showFileSelectDialog,
            //   child: Text('Select Firmware File'),
            // )
          ],
        ),
        body: !hasDevice
            ? const Center(
                child: Text('No device'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemBuilder: _deviceItemBuilder,
                separatorBuilder: (context, index) => const SizedBox(height: 5),
                itemCount: scanResults.length,
              ),
      ),
    );
  }

  Widget _deviceItemBuilder(BuildContext context, int index) {
    final result = scanResults[index];
    return DeviceItem(
      isRunningItem: dfuRunningInx == index,
      scanResult: result,
      onPress: dfuRunning
          ? () async {
              await NordicDfu().abortDfu();
              setState(() {
                dfuRunningInx = null;
              });
            }
          : () async {
              setState(() {
                dfuRunningInx = index;
              });
              await doDfu(result.device.remoteId.str);
              setState(() {
                dfuRunningInx = null;
              });
            },
    );
  }
}

class DeviceItem extends StatelessWidget {
  final ScanResult scanResult;
  final VoidCallback? onPress;
  final bool? isRunningItem;

  const DeviceItem({
    required this.scanResult,
    this.onPress,
    this.isRunningItem,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var name = 'MYDevice';
    if (scanResult.device.platformName.isNotEmpty) {
      name = scanResult.device.platformName;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            const Icon(Icons.bluetooth),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name),
                  Text(scanResult.device.remoteId.str),
                  Text('RSSI: ${scanResult.rssi}'),
                ],
              ),
            ),
            TextButton(
              onPressed: onPress,
              child: isRunningItem!
                  ? const Text('Abort Dfu')
                  : const Text('Start Dfu'),
            ),
          ],
        ),
      ),
    );
  }
}
