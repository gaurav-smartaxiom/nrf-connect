import 'package:flutter/material.dart';

class  DfuUpdateScreen extends StatelessWidget {
  final String firmwareAsset;
  final String deviceId;

  const DfuUpdateScreen({
    Key? key,
    required this.firmwareAsset,
    required this.deviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DFU Update'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('DFU Update for Device: $deviceId'),
            Text('Firmware Asset: $firmwareAsset'),
            // Add your DFU update logic/UI here
          ],
        ),
      ),
    );
  }
}
