import 'package:flutter/material.dart';
import 'package:network_config_widget/nm_provider.dart';
import 'package:nm/nm.dart';
import 'package:network_config_widget/wifi_device_page.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  Future<List<NetworkManagerDevice>> _getDevices() async {
    await NmProvider.instance.connectNetworkManager();

    for (var device in NmProvider.instance.nmClient.allDevices) {
      print('${device.deviceType} ${device.hwAddress} ${device.state}');
    }
    var devices = NmProvider.instance.nmClient.devices;

    return devices;
  }

  late Future<List<NetworkManagerDevice>> _devicesFuture;

  @override
  void initState() {
    _devicesFuture = _getDevices();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Settings"),
      ),
      body: FutureBuilder(
        future: _devicesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var device = snapshot.data![index];
              return ListTile(
                leading: Icon(_getDeviceTypeIcon(device)),
                title: Text(device.interface),
                onTap: () {
                  if (device.wireless != null)
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WifiDevicePage(device),
                        ));
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData? _getDeviceTypeIcon(NetworkManagerDevice device) {
    if (device.wireless != null) return Icons.wifi;
    if (device.wired != null) return Icons.settings_ethernet;
    return null;
  }
}
