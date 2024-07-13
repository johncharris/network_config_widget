import 'package:nm/nm.dart';

class NmProvider {
  static final NmProvider _instance = NmProvider._();
  static NmProvider get instance => _instance;

  NmProvider._();

  final nmClient = NetworkManagerClient();

  Future connectNetworkManager() async {
    await nmClient.connect();
  }
}
