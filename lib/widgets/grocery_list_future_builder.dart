import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

// NOTE: add and remove doesnt work, this is just a demo for loading the body with FutureBuilder

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _shoppingList = [];
  late Future<List<GroceryItem>> _fLoadedItems;

  @override
  void initState() {
    super.initState();

    _fLoadedItems = loadShoppingListItems();
  }

  Future<List<GroceryItem>> loadShoppingListItems() async {
    final url = Uri.https(
        'shopping-list-e7d65-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception("Server error");
    }

    if (response.body == 'null') {
      return [];
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

    return httpItems;
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
      body: FutureBuilder(
        future: _fLoadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (snapshot.data!.isEmpty) {
            const Center(child: Text("No items to display"));
          }
          final _shoppingList = snapshot.data!;
          return ListView.builder(
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
        },
      ),
    );
  }
}
