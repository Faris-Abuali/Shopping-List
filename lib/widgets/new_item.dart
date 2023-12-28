import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  // The global key ensures that the form can be referenced from anywhere in the
  // widget tree. This is useful for validating the form and resetting it.

  // and if the build method is executed again, the form will not rebuilt and instead
  // it keeps the state of the form.

  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  void _saveItem() async {
    final formState = _formKey.currentState!;
    final isValid = formState.validate();
    if (!isValid) return;
    // Save the item
    formState.save();

    setState(() {
      _isSending = true;
    });

    final url = Uri.https(
      'flutter-shopping-list-fb3de-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': _enteredName,
        'quantity': _enteredQuantity,
        'category': _selectedCategory.title,
      }),
    );

    print(response.body);
    print(response.statusCode);

    final Map<String, dynamic> responseData = json.decode(response.body);

    if (!context.mounted) return;

    // Pass the new item back to the previous screen
    Navigator.of(context).pop(
      GroceryItem(
        // id: DateTime.now().toString(),
        id: responseData['name'],
        name: _enteredName,
        quantity: _enteredQuantity,
        category: _selectedCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters';
                  }
                  return null;
                },
                onSaved: (newValue) => _enteredName = newValue!,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        initialValue: _enteredQuantity.toString(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quantity cannot be empty';
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed <= 0) {
                            return 'Must be a valid positive number';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          // We can safely use parse() here because we already
                          // validated the input.
                          _enteredQuantity = int.parse(newValue!);
                        }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 8),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        // Since this field is controlled by the _selectedCategory state,
                        // we need to update the state when the value changes, to ensure
                        // that the UI is in sync with the state.
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                      // onSaved: (newValue) {
                      //   // And no need to use onSaved here, since the onChanged callback
                      //   // is called whenever the value changes.
                      // },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add Item'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
