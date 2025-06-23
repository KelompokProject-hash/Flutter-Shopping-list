import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
   const NewItem({super.key, this.item});

  final GroceryItem? item;

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = "";
  var _enteredQuantity = 1;
  var _enteredCategory = categories[Categories.vegetables]!;
  var _reqInProgress = false;

   @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _enteredName = widget.item!.name;
      _enteredQuantity = widget.item!.quantity;
      _enteredCategory = widget.item!.category;
    }
  }

  void saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _reqInProgress = true;
      });
final bodyPayload = json.encode({
        'name': _enteredName,
        'quantity': _enteredQuantity,
        'category': _enteredCategory.title,
      });

      try {
        http.Response response;
        if (widget.item == null) { // Adding new item
          final url = Uri.https(
              'shopping-list-e7d65-default-rtdb.asia-southeast1.firebasedatabase.app',
              'shopping-list.json');
          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: bodyPayload,
          );
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (!context.mounted) return;
          Navigator.of(context).pop(GroceryItem(
              id: responseData['name'],
              name: _enteredName,
              quantity: _enteredQuantity,
              category: _enteredCategory));
        } else { // Editing existing item
          final url = Uri.https(
              'shopping-list-e7d65-default-rtdb.asia-southeast1.firebasedatabase.app',
              'shopping-list/${widget.item!.id}.json');
          response = await http.put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: bodyPayload,
          );
          if (!context.mounted) return;
          Navigator.of(context).pop(GroceryItem(
              id: widget.item!.id, // Keep original ID
              name: _enteredName,
              quantity: _enteredQuantity,
              category: _enteredCategory));
        }
      } catch (error) {
        // Handle error, maybe show a SnackBar
        setState(() { _reqInProgress = false; });
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? "Add New Item" : "Edit Item"
      ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text("Name"),
                ),
                initialValue: _enteredName,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return "Invalid input";
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text("Quantity"),
                      ),
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return "Invalid input";
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _enteredCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                    width: 4,
                                    height: 18,
                                    color: category.value.color),
                                const SizedBox(width: 8),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _enteredCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _reqInProgress
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text("Reset"),
                  ),
                  const SizedBox(width: 5),
                  ElevatedButton(
                    onPressed: _reqInProgress
                        ? null
                        : saveItem, // disable press with null
                    child: _reqInProgress
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator())
                         : Text(widget.item == null ? "Add Item" : "Update Item"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
