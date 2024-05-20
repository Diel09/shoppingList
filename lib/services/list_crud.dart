import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final CollectionReference lists =
      FirebaseFirestore.instance.collection('shopping_lists');
  //read
  Stream<QuerySnapshot> getShoppingList(String id) {
    final listStream = lists.where('user_id', isEqualTo: id).snapshots();
    return listStream;
  }
  
  //delete
  void deleteList(String docId) async {
    await lists.doc(docId).delete();
  }
}
