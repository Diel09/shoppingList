import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_list/pages/add_list.dart';
import 'package:grocery_list/pages/auth/login_page.dart';
import 'package:grocery_list/services/list_crud.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late final String _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping Lists"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddListPage(currentUser: _currentUser)),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getShoppingList(_currentUser),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<DocumentSnapshot> groceryList = snapshot.data!.docs;

            return ListView.builder(
              itemCount: groceryList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = groceryList[index];
                String docId = document.id;
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                String name = data['name'];
                double totalPrice = data['expense'] ?? 0;

                return ListTile(
                  title: Text(name),
                  subtitle: Text('Total Expense: Php $totalPrice'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddListPage(
                                currentUser: _currentUser,
                                docId: docId,
                                existingData: data,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmationDialog(docId);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _showItemsDialog(context, name, data['items'], docId);
                  },
                );
              },
            );
          } else {
            return const Text(
              'You have no List',
              style: TextStyle(fontSize: 24, color: Colors.black),
              );
          }
        },
      ),
    );
  }

  void _showItemsDialog(BuildContext context, String name, List items, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$name Items'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    bool isSelected = item['selected'] ?? false;

                    return CheckboxListTile(
                      title: Text(item['name']),
                      subtitle: Text('Price: Php ${item['price']}'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          item['selected'] = value!;
                        });
                        _updateTotalExpense(docId, items);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete List'),
          content: const Text('Are you sure you want to delete this list?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                firestoreService.deleteList(docId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _updateTotalExpense(String docId, List items) async {
    double totalExpense = 0;
    for (var item in items) {
      if (item['selected'] == true) {
        totalExpense += item['price'];
        item['checked'] != item['checked'];
      }
    }
    final CollectionReference lists =
        FirebaseFirestore.instance.collection('shopping_lists');

    await lists.doc(docId).update({'expense': totalExpense, 'items': items});
  }
}
