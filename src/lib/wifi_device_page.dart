import 'dart:async';
import 'dart:convert';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:network_config_widget/nm_provider.dart';
import 'package:nm/nm.dart';

class WifiDevicePage extends StatefulWidget {
  const WifiDevicePage(this.device, {super.key});

  final NetworkManagerDevice device;

  @override
  State<WifiDevicePage> createState() => _WifiDevicePageState();
}

class _WifiDevicePageState extends State<WifiDevicePage> {
  StreamSubscription? wirelessPropertiesSubscription;

  @override
  void initState() {


    var wireless = widget.device.wireless!;

    wirelessPropertiesSubscription =
        wireless.propertiesChanged.listen((propertyNames) {
      setState(() {});
    });

_scan();

    super.initState();
  }

  @override
  void dispose() {
    wirelessPropertiesSubscription?.cancel();
    super.dispose();
  }

  NetworkManagerDevice get device => widget.device;
  NetworkManagerDeviceWireless get wifiDevice => device.wireless!;

  @override
  Widget build(BuildContext context) {
    var accessPoints =
        wifiDevice.accessPoints.where((ap) => ap.ssid.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(device.ipInterface),
        actions: [
          IconButton(
            onPressed: () => _scan(),
            icon: const Icon(Icons.wifi_find),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: accessPoints.length,
        itemBuilder: (context, index) {
          var ap = accessPoints[index];
          var ssid = utf8.decode(ap.ssid);
          return ListTile(
              onTap: () => _connectToAccessPoint(ap),
              title: Text(ssid,
                  style:
                      (ap.hwAddress == wifiDevice.activeAccessPoint?.hwAddress)
                          ? const TextStyle(fontWeight: FontWeight.bold)
                          : null),
              trailing: _getApIcon(ap));
        },
      ),
    );
  }

  _scan() async {
    await widget.device.wireless!.requestScan();
  }

  _connectToAccessPoint(NetworkManagerAccessPoint ap) async {
    // Check for PSK requirement
    if (ap.rsnFlags.isNotEmpty) {
      var psk = await showDialog<String>(
        context: context,
        builder: (context) => _GetPskDialog(ap),
      );
      if (psk == null) {
        // The user was prompted, but canceled.
        return;
      }

      await NmProvider.instance.nmClient.addAndActivateConnection(
          device: widget.device,
          accessPoint: ap,
          connection: {
            '802-11-wireless-security': {
              'key-mgmt': const DBusString('wpa-psk'),
              'psk': DBusString(psk)
            }
          });
      // nmClient.addAndActivateConnection(device: widget.device,accessPoint: ap);
    }
  }

  Future<NetworkManagerSettingsConnection?> getAccessPointConnectionSettings(
      NetworkManagerDevice device,
      NetworkManagerAccessPoint accessPoint) async {
    var ssid = utf8.decode(accessPoint.ssid);

    var settings = await Future.wait(device.availableConnections.map(
        (e) async => {'settings': await e.getSettings(), 'connection': e}));
    NetworkManagerSettingsConnection? accessPointSettings;
    for (var element in settings) {
      var s = element['settings'] as dynamic;
      if (s != null) {
        var connection = s['connection'] as Map<String, DBusValue>?;
        if (connection != null) {
          var id = connection['id'];
          if (id != null) {
            if (id.toNative() == ssid) {
              accessPointSettings =
                  element['connection'] as NetworkManagerSettingsConnection;
              break;
            }
          }
        }
      }
    }
    return accessPointSettings;
  }

  Widget _getApIcon(NetworkManagerAccessPoint ap) {

if (ap.hwAddress == wifiDevice.activeAccessPoint?.hwAddress) {
  if (device.state != NetworkManagerDeviceState.activated){
    return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator());
  }
}

    if (ap.strength > 80) return const Icon(Icons.signal_wifi_4_bar);
    if (ap.strength > 60) return const Icon(Icons.network_wifi_3_bar);
    if (ap.strength > 40) return const Icon(Icons.network_wifi_3_bar);
    if (ap.strength > 20) return const Icon(Icons.network_wifi_2_bar);
    return const Icon(Icons.network_wifi_1_bar);
  }
}

class _GetPskDialog extends StatefulWidget {
  const _GetPskDialog(this.ap, {super.key});
  final NetworkManagerAccessPoint ap;
  @override
  State<_GetPskDialog> createState() => __GetPskDialogState();
}

class __GetPskDialogState extends State<_GetPskDialog> {
  String _psk = "";
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Connect to ${utf8.decode(widget.ap.ssid)}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            obscureText: true,
            onChanged: (newValue) => _psk = newValue,
            decoration: const InputDecoration(labelText: "Password"),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        TextButton(
            onPressed: () {
              Navigator.pop(context, _psk);
            },
            child: const Text("Connect"))
      ],
    );
  }
}
