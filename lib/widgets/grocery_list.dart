import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _shoppingList = [];
  String _error = "";

  var _isLoading = true;

  @override
  void initState() {
    super.initState();

    loadShoppingListItems();
  }

  void loadShoppingListItems() async {
    final url = Uri.https(
        'shopping-list-e7d65-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = "Failed to fetch data";
      });
    }

    if (response.body == 'null') {
      // firebase returns 'null' on error
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> httpItems = [];
    for (final item in listData.entries) {
      final Category tmpCategory = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      httpItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: tmpCategory));
    }

    setState(() {
      _shoppingList = httpItems;
      _isLoading = false;
    });
  }

  void addNewItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItem()));

    if (newItem == null) {
      return;
    } else {
      setState(() {
        _shoppingList.add(newItem);
      });
    }
  }

  void removeItem(GroceryItem item) async {
    final index = _shoppingList.indexOf(item);
    setState(() {
      _shoppingList.remove(item);
    });

    final url = Uri.https(
        'shopping-list-e7d65-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _shoppingList.insert(index, item);
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error deleting item'),
        duration: Duration(seconds: 4),
      ));
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Item successfully deleted'),
        duration: Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No items to display"),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_shoppingList.isNotEmpty) {
      content = ListView.builder(
        itemCount: _shoppingList.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_shoppingList[index].id),
          onDismissed: (direction) {
            removeItem(_shoppingList[index]);
          },
          child: ListTile(
            title: Text(_shoppingList[index].name),
            leading: Container(
              width: 4,
              height: 24,
              color: _shoppingList[index].category.color,
            ),
            trailing: Text(_shoppingList[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error != "") {
      content = Center(child: Text(_error));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Groceries"),
        actions: [
          IconButton(
            onPressed: addNewItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
