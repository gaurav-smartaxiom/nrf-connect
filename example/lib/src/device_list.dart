import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mcumgr_flutter_example/src/firmware_list.dart'; 
import 'package:mcumgr_flutter_example/src/dfuupdate.dart';

class DeviceList extends StatefulWidget {
  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  late StreamSubscription<List<ScanResult>> scanSubscription;
  List<ScanResult> scanResults = [];

  // Added variable to store the selected device
  BluetoothDevice? selectedDevice;

  bool get isConnected => selectedDevice != null;

  @override
  void initState() {
    super.initState();

    // Start scanning for devices when the widget is initialized
    startScan();
  }

  void startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

      await Future.delayed(Duration(seconds: 5));
      await FlutterBluePlus.stopScan();

      scanSubscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        setState(() {
          scanResults = results;
          print('Discovered devices: $scanResults');
        });
      });
    } catch (e) {
      print('Error while scanning: $e');
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
  }

  Future<void> connectOrDisconnectToDevice(BluetoothDevice device) async {
    if (isConnected) {
      // Disconnect the device
      await disconnectDevice();
    } else {
      // Connect to the selected device
      await connectToDevice(device);

      // Navigate to DfuUpdateScreen when connected
       _navigateToFirmwareList(device.id.toString());
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        selectedDevice = device;
      });
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  Future<void> disconnectDevice() async {
    if (selectedDevice != null) {
      try {
        await selectedDevice!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }

      setState(() {
        selectedDevice = null;
      });
    }
  }
 void _navigateToFirmwareList(String deviceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirmwareList(deviceId: deviceId),
      ),
    );
  }

  @override
  void dispose() {
    // Disconnect the device when the widget is disposed
    disconnectDevice();
    // Stop scanning and cancel the subscription when the widget is disposed
    stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Start a new scan when the button is pressed
            startScan();
          },
          child: Text('Start Scan'),
        ),
        ElevatedButton(
          onPressed: () {
            // Connect or disconnect the device when the button is pressed
            if (scanResults.isNotEmpty) {
              connectOrDisconnectToDevice(scanResults.first.device);
            }
          },
          child: Text(isConnected ? 'Disconnect' : 'Connect'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) {
              final device = scanResults[index].device;
              return ListTile(
                title: Text(device.name ?? 'Unknown'),
                subtitle: Text(device.id.toString()),
                trailing: Text('${scanResults[index].rssi} dB'),
                onTap: () {
                  // Connect or disconnect to/from the selected device when tapped
                  connectOrDisconnectToDevice(device);
                },
              );
            },
          ),
        ),
        // Display the selected device information
        if (selectedDevice != null)
          Text('Selected Device: ${selectedDevice!.name}'),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth Scanner'),
        ),
        body: DeviceList(),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}
