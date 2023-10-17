import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';  // Import for ByteData
import 'package:flutter/material.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_app_settings/open_app_settings.dart';
import 'package:flutter/services.dart' show rootBundle;

class MyAppInternal extends StatefulWidget {
  final String deviceId;

  const MyAppInternal({Key? key, required this.deviceId}) : super(key: key);

  @override
  _MyAppInternalState createState() => _MyAppInternalState();
}

class _MyAppInternalState extends State<MyAppInternal> {
  bool dfuRunning = false;
  double dfuProgress = 0.0;

  Future<void> doDfu(String deviceId) async {
  print("Start DFU");

  dfuRunning = true;

  try {
    print("Loading firmware file from assets...");
    ByteData data = await rootBundle.load('assets/file.zip');
    List<int> bytes = data.buffer.asUint8List();
    String firmwareData = base64.encode(bytes);

    print("Firmware data length: ${firmwareData.length}");

    // Show the progress dialog
    showProgressDialog();

    NordicDfu nordicDfu = NordicDfu();
    print("DFU process started...");

    await nordicDfu.startDfu(
      deviceId,
      firmwareData,
      // You may need to handle progress updates differently
      // based on the new API or methods available in the package.
    );

    print("DFU Completed");
  } catch (e) {
    dfuRunning = false;
    debugPrint("DFU Error: ${e.toString()}");

    // Show error dialog
    // showErrorDialog(e.toString());
  }
}


  // void showPermissionDeniedDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Permission Denied'),
  //         content: Text('Storage permission is required for DFU. Please enable it in the app settings.'),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               // Open the app settings when the user clicks OK
  //               OpenAppSettings.openAppSettings();
  //             },
  //             child: Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DFU Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            print("Button pressed");
            String deviceId = widget.deviceId;
            doDfu(deviceId);
          },
          child: Text('Start DFU'),
        ),
      ),
    );
  }
}
