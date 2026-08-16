import 'package:cloud_firestore/cloud_firestore.dart';

class AjustesService {
  static Future<Map<String, dynamic>> getAjustes() async {
    final doc = await FirebaseFirestore.instance
        .collection('ajustes')
        .doc('configuracion')
        .get();
    return doc.exists ? doc.data()! : {};
  }

  static bool tieneTimbrado(Map<String, dynamic> ajustes) {
    return ajustes['timbrado'] != null &&
        ajustes['timbrado'].toString().trim().isNotEmpty;
  }
}