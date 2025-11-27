import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter_frontend/features/drawing/presentation/widgets/thumbnail.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Art Gallery'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: _DrawingCollection(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/createPrompt');
        },
        child: const Icon(Icons.draw),
      ),
    );
  }
}


class _DrawingCollection extends StatefulWidget {

  @override
  State<_DrawingCollection> createState() => _DrawingCollectionState();
}

// Widget for displaying a collection of drawings in a dynamic grid layout
class _DrawingCollectionState extends State<_DrawingCollection> {

  late ArtworkRepositoryInterface _artworkRepository;

  @override
  void initState() { 
    super.initState();
    _artworkRepository = context.read<ArtworkRepositoryInterface>();    
  }

  void _openDrawing(String id) async {
    context.push('/draw', extra: id);
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
      await _artworkRepository.deleteArtwork(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drawing $name deleted!'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // listen for changes inside hive and rebuild the drawing gallery when changes happen
    return AnimatedBuilder(
      animation: _artworkRepository.listenable,

      // build the drawing gallery
      builder: (context, staticChild) {
        final artworkList = _artworkRepository.fetchAllArtworks();

        // return default text if no drawings exist
        if (artworkList.isEmpty) { return const Center(child: Text('No drawings yet')); }

        // calculate the size of each thumbnail
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = (screenWidth / 2) - 16;
        final thumbnailSize = (cardWidth * 2).toInt();
        
        // else return a grid of all items inside the hive box (gallery)
        return GridView.builder(
          padding: const EdgeInsets.all(8),

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),

          itemCount: artworkList.length,

          itemBuilder: (context, index) {
            final artwork = artworkList[index];

            // return the object actually being displayed in the gallery
            return Stack(
              children: [

                GestureDetector(
                  onTap: () { _openDrawing(artwork.id); },
                  
                  // visual part of the drawing icon
                  child: _DrawingCard(
                    artwork: artwork,
                    thumbnailSize: thumbnailSize
                  ),
                ),

                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: () { _deleteDrawing.call(artwork.id); },
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary),
                  )
                ),
                
              ]
            );
          }
        );
      },
    );
  }
}

class _DrawingCard extends StatelessWidget {
  final ArtworkEntity artwork;
  final int thumbnailSize;

  const _DrawingCard ({
    required this.artwork,
    required this.thumbnailSize
  });

  @override
  Widget build(BuildContext context) {
    return Card (
      elevation: 4,
      child: Column (
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FutureBuilder<Uint8List>(

              // create the thumbnail image
              future: generateThumbnail(
                artwork.strokeList,
                thumbnailSize.toDouble(),
                thumbnailSize.toDouble()
              ),

              // display the thumbnail image once generated
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover
                  );
                }
                else if (snapshot.hasError) {
                  return const Center(child: Icon(Icons.error));
                }
                else {
                  return const Center(child: CircularProgressIndicator());
                }
              }
            ),
          ),
          Padding (
            padding: const EdgeInsets.all(5),
            child: Text(
              artwork.title,
              textAlign: TextAlign.center,
              style: TextStyle (
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),
            )
          )
        ]
      )
    );
  }
  
}