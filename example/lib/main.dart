import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:flutter/material.dart';
import 'package:location_permissions/location_permissions.dart';

class TheProblem {
  static String _current;

  static String get current {
    return _current ?? newCurrent();
  }

  static String newCurrent() {
    print('first time');
    _current = 'First time';
    return _current;
  }

  static String overrideCurrent() {
    print('second time');
    _current = 'Second time';
    return _current;
  }
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ReceivePort port = ReceivePort();

  String currentValue = '';
  static final _isolateName = 'LocatorIsolate';

  @override
  void initState() {
    super.initState();

    if (IsolateNameServer.lookupPortByName(_isolateName) != null) {
      IsolateNameServer.removePortNameMapping(_isolateName);
    }

    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);

    port.listen(
      (dynamic current) async {
        print('current from callback: $current');
        setState(() {
          currentValue = current;
        });
      },
    );
    BackgroundLocator.initialize();
  }

  static void callback(LocationDto locationDto) async {
    final SendPort send = IsolateNameServer.lookupPortByName(_isolateName);

    String current = TheProblem.current;
    send?.send(current);
  }

  static void notificationCallback() => null;

  @override
  Widget build(BuildContext context) {
    final start = SizedBox(
      width: double.maxFinite,
      child: RaisedButton(
        child: Text('Start'),
        onPressed: () {
          _checkLocationPermission();
        },
      ),
    );
    final stop = SizedBox(
      width: double.maxFinite,
      child: RaisedButton(
        child: Text('Stop'),
        onPressed: () {
          BackgroundLocator.unRegisterLocationUpdate()
              .then((value) => print('unRegisterLocationUpdate finished'));
        },
      ),
    );
    final current = SizedBox(
      width: double.maxFinite,
      child: RaisedButton(
        child: Text('override current'),
        onPressed: () {
          TheProblem.overrideCurrent();
          setState(() {
            currentValue = TheProblem.current;
          });
        },
      ),
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter background Locator'),
        ),
        body: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                start,
                stop,
                current,
                Text(
                  currentValue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkLocationPermission() async {
    final access = await LocationPermissions().checkPermissionStatus();
    switch (access) {
      case PermissionStatus.unknown:
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await LocationPermissions().requestPermissions(
          permissionLevel: LocationPermissionLevel.locationAlways,
        );
        if (permission == PermissionStatus.granted) {
          _startLocator();
        } else {
          // show error
        }
        break;
      case PermissionStatus.granted:
        _startLocator();
        break;
    }
  }

  void _startLocator() {
    BackgroundLocator.registerLocationUpdate(
      callback,
      androidNotificationCallback: notificationCallback,
      settings: LocationSettings(
          notificationTitle: "Start Location Tracking example",
          notificationMsg: "Track location in background exapmle",
          wakeLockTime: 20,
          autoStop: false,
          interval: 1),
    );
  }
}
