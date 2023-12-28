import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      'flutter-shopping-list-fb3de-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      final resBody = json.decode(response.body);
      // If resBody has an 'error' key, then use that as the error message
      var errorMessage =
          resBody['error'] ?? 'Failed to fetch items. Please try again later.';
      throw Exception(errorMessage); //to be caught by the FutureBuilder
    }

    // IMPORTANT: In case of empty list, Firebase response will be null, so we need to check for that case.
    if (response.body == 'null') {
      // No need to manually set the _isLoading state.
      return []; // return empty list because the _loadItems() method is expecting a List<GroceryItem>
    }

    final Map<String, dynamic> listData = json.decode(response.body);

    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;

      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      'flutter-shopping-list-fb3de-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });

      // Check if the context is still mounted before showing the snackbar
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete item: ${item.name}.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      // don't pass _loadItems() directly to `future:` because this will call
      //the API each time the build() method is re-executed.
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }

          // data won't be null if it reaches this point
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No items added yet!'),
            );
          }

          // Sure it will be a List<GroceryItem> because that's what we're returning from _loadItems()
          // when no error occurs.
          List<GroceryItem> data = snapshot.data!;

          // // 👇 a workaround from Lecture 232 comments.
          // _groceryItems = snapshot.data!;

          return ListView.builder(
            // itemCount: _groceryItems.length,
            itemCount: data.length,
            itemBuilder: (ctx, index) {
              // final item = _groceryItems[index];
              final item = data[index];
              return Dismissible(
                onDismissed: (direction) {
                  // _removeItem(_groceryItems[index]);
                  _removeItem(data[index]);
                },
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                ),
                key: ValueKey(item.id),
                child: ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: item.category.color,
                  ),
                  title: Text(item.name),
                  trailing: Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
