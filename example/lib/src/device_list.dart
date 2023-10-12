import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

      FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
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

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        selectedDevice = device;
      });

      // Navigate to the next screen when connected
      _navigateToNextScreen();
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void disconnectDevice() async {
    if (selectedDevice != null) {
      await selectedDevice!.disconnect();
      setState(() {
        selectedDevice = null;
      });
    }
  }

  void _navigateToNextScreen() {
  if (isConnected) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NextScreen(
          device: selectedDevice!,
          onDisconnect: () {
            // Handle the disconnect logic when returning from NextScreen
            setState(() {
              selectedDevice = null;
            });
          },
        ),
      ),
    );
  }
}


  @override
  void dispose() {
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
        if (isConnected)
          ElevatedButton(
            onPressed: () {
              // Disconnect the device when the button is pressed
              disconnectDevice();
            },
            child: Text('Disconnect'),
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
                  // Connect to the selected device
                  connectToDevice(device);
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

class NextScreen extends StatelessWidget {
  final BluetoothDevice device;
  final void Function() onDisconnect;

  const NextScreen({Key? key, required this.device, required this.onDisconnect})
      : super(key: key);

  void disconnectAndNavigate(BuildContext context) async {
    await device.disconnect();

    // Notify the parent (DeviceList) that disconnect happened
    onDisconnect();

    // Navigate back to the DeviceList screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Next Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Connected to ${device.name}'),
            ElevatedButton(
              onPressed: () {
                disconnectAndNavigate(context);
              },
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
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
