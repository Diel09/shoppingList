import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class AddListPage extends StatefulWidget {
  final String currentUser;
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddListPage({Key? key, required this.currentUser, this.docId, this.existingData}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AddListPageState createState() => _AddListPageState();
}

class _AddListPageState extends State<AddListPage> {
  final TextEditingController titleController = TextEditingController();
  late final TextEditingController _barcodeController = TextEditingController();
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _priceController = TextEditingController();

  final _itemFormKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      titleController.text = widget.existingData!['name'];
      items.addAll(List<Map<String, dynamic>>.from(widget.existingData!['items']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'List Name',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  _showAddItemDialog(context);
                },
                child: const Text('Add Item'),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(items[index]['name']),
                    subtitle: Text('Price: Php ${items[index]['price']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          items.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveList();
                Navigator.pop(context);
              },
              child: const Text('Save List'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveList() async {
    final firestore = FirebaseFirestore.instance;
    double totalPrice = 0.0;
    for (var item in items) {
      totalPrice += item['price'];
    }
    final listData = {
      'name': titleController.text,
      'items': items,
      'user_id': widget.currentUser,
      'total_price': totalPrice,
    };

    if (widget.docId != null) {
      await firestore.collection('shopping_lists').doc(widget.docId).update(listData);
    } else {
      await firestore.collection('shopping_lists').add(listData);
    }
  }
  void _showAddItemDialog(BuildContext context) {
    String itemName = '';
    String itemBarcode = '';
    double itemPrice = 0.0;
    _barcodeController.clear();
    _nameController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: Form(
            key: _itemFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    itemName = value!;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(labelText: 'Barcode'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a barcode';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          itemBarcode = value!;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () async {
                        String barcode =
                            await FlutterBarcodeScanner.scanBarcode(
                                '#ff6666', 'Cancel', false, ScanMode.BARCODE);
                        if (barcode == '1') {
                          setState(() {
                            _barcodeController.text = barcode;
                            _fetchItemDetails(barcode);
                          });
                        }
                      },
                    ),
                  ],
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    itemPrice = double.parse(value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_itemFormKey.currentState!.validate()) {
                  _itemFormKey.currentState!.save();
                  setState(() {
                    items.add({
                      'name': itemName,
                      'barcode': itemBarcode,
                      'price': itemPrice,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _fetchItemDetails(String barcode) async {
    CollectionReference lists = FirebaseFirestore.instance
        .collection('shopping_lists'); //initialize the list variable
    QuerySnapshot querySnapshot = await lists.get(); //fetch all the data

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        var items = doc['items'];
        for (var item in items) {
          if (item['barcode'] == barcode) {
            setState(() {
              _nameController.text = item['name'];
              _priceController.text = item['price'].toString();
            });
            return;
          }
        }
      }
    }
  }
}
