import 'package:flutter/material.dart';

class FakeAppScreen extends StatelessWidget {
  const FakeAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Notes', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            color: Colors.yellow[50],
            child: ListTile(
              title: Text('Note ${index + 1}'),
              subtitle: const Text('This is a completely normal note. Nothing to see here.'),
              trailing: const Icon(Icons.edit_note),
            ),
          );
        },
      ),
    );
  }
}
