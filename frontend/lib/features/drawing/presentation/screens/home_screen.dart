import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Map<dynamic, dynamic>> _drawingBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  void _initializeHive() {
    _drawingBox = Hive.box<Map<dynamic, dynamic>>('drawings');
    setState(() {});
  }

  void _openDrawing(String name) async {
    context.go('/draw', extra: name);
  }

  void _deleteDrawing(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Drawing"),
        content: Text('Are you sure you want to delete $name'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ]
      )
    );

    if (confirm == true) {
      _drawingBox.delete(name);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drawing $name deleted!'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Art Gallery'),
        actions: [
          IconButton(
            onPressed: () {
              final authCubit = context.read<AuthCubit>();
              authCubit.logout();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: DrawingCollection(
        collection: _drawingBox,
        openDrawing:  _openDrawing,
        deleteDrawing: _deleteDrawing,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.draw),
        onPressed: () {
          context.go('/draw');
          setState(() {});
        },
      ),
    );
  }
}



// Widget for displaying a collection of drawings in a dynamic grid layout
class DrawingCollection extends StatelessWidget {
  final Box<Map<dynamic, dynamic>> collection;
  final void Function(String name) openDrawing;
  final void Function(String name) deleteDrawing;

  const DrawingCollection({
    super.key,
    required this.collection,
    required this.openDrawing,
    required this.deleteDrawing,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: collection.listenable(),
      builder: (context, _, __) {
        final drawingNames = collection.keys.cast<String>().toList();
        final items = collection.values.toList();
        if (items.isEmpty) {
          return const Center(child: Text('No drawings yet'));
        }
        else {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: drawingNames.length,
            itemBuilder: (context, index) {
              final name = drawingNames[index];
              final data = collection.get(name) as Map;
              final thumbnail = data['thumbnail'] as Uint8List;
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () { openDrawing(name); },
                    child: Card (
                      elevation: 4,
                      child: Column (
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Image.memory(
                              thumbnail,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding (
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle (
                                fontSize: 16,
                                fontWeight: FontWeight.bold
                              ),
                            )
                          )
                        ]
                      )
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: () { deleteDrawing.call(name); },
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary),
                    )
                  ),
                ]
              );
            }
          );
        }
      },
    );
  }
}