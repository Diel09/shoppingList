import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('shopping_lists');

  //create
  Future<void> addlist(String note) {
    return notes.add({'note': note, 'timestamp': Timestamp.now()});
  }

  //read
  Stream<QuerySnapshot> getNotesStream() {
    final notesStream =
        notes.orderBy('timestamp', descending: true).snapshots();
    return notesStream;
  }

  //update
  Future<void> updateNote(String docId, String newNote) {
    return notes.doc(docId).update({
      'note': newNote,
      'timestamp': Timestamp.now(),
    });
  }
  //delete

  Future<void> deleteNote(String docId) {
    return notes.doc(docId).delete();
  }
}
