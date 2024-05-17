import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class AddListPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddListPage({super.key, this.docId, this.existingData});

  @override
  // ignore: library_private_types_in_public_api
  _AddListPageState createState() => _AddListPageState();
}

class _AddListPageState extends State<AddListPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemFormKey = GlobalKey<FormState>();
  String _listTitle = '';
  final List<Map<String, dynamic>> _items = [];
  late final TextEditingController _barcodeController = TextEditingController();
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _listTitle = widget.existingData!['name'];
      _items.addAll(
          List<Map<String, dynamic>>.from(widget.existingData!['items']));
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.docId == null ? 'Add Shopping List' : 'Edit Shopping List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _listTitle,
                decoration: const InputDecoration(labelText: 'List Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _listTitle = value!;
                },
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
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_items[index]['name']),
                      subtitle: Text(
                          'Barcode: ${_items[index]['barcode']}, Price: Php ${_items[index]['price']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _items.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveList,
                child: const Text('Save List'),
              ),
            ],
          ),
        ),
      ),
    );
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
                                '#ff6666', 'Cancel', true, ScanMode.BARCODE);
                        if (barcode != '-1') {
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
                    _items.add({
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

  void _saveList() async {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      _formKey.currentState!.save();
      double totalPrice = 0;
      for (var item in _items) {
        totalPrice += item['price'];
      }

      // Add or update the shopping list with items in Firestore
      CollectionReference lists =
          FirebaseFirestore.instance.collection('shopping_lists');
      if (widget.docId == null) {
        await lists.add({
          'name': _listTitle,
          'items': _items,
          'total_price': totalPrice,
          'expense': 0,
          'timestamp': Timestamp.now()
        });
      } else {
        await lists.doc(widget.docId).update({
          'name': _listTitle,
          'items': _items,
          'total_price': totalPrice,
          'timestamp': Timestamp.now()
        });
      }

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }
}
