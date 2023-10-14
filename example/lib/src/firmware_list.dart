import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcumgr_flutter_example/src/update_screen.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FirmwareList extends StatelessWidget {
  final String deviceId;

  const FirmwareList({Key? key, required this.deviceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firmware List'),
      ),
      body: FutureBuilder(
        future: rootBundle.loadString('AssetManifest.json'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading firmware list.'));
          } else {
            final data = snapshot.data as String;
            final json = jsonDecode(data);
            final images = json.keys.toList();

            return ListView.separated(
              separatorBuilder: (context, index) => Divider(),
              itemCount: images.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  _navigateToUpdateScreen(context, images[index]);
                },
                child: ListTile(
                  title: Text(p.split(images[index]).last),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _navigateToUpdateScreen(BuildContext context, String asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScreen(
          asset: asset,
          deviceId: deviceId,
        ),
      ),
    );
  }
}