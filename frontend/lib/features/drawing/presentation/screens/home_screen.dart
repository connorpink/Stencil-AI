import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter_frontend/features/drawing/presentation/widgets/thumbnail.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final ArtworkRepositoryInterface artworkRepository;

  const HomeScreen({
    super.key,
    required this.artworkRepository,
  });
  
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
      body: _DrawingCollection(artworkRepository: artworkRepository),
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
  final ArtworkRepositoryInterface artworkRepository;

  const _DrawingCollection({
    required this.artworkRepository,
  });

  @override
  State<_DrawingCollection> createState() => _DrawingCollectionState();
}

// Widget for displaying a collection of drawings in a dynamic grid layout
class _DrawingCollectionState extends State<_DrawingCollection> {

  late final ArtworkRepositoryInterface _artworkRepository;

  @override
  void initState() { 
    super.initState();
    _artworkRepository = widget.artworkRepository;  
  }

  void _openDrawing(String id) async {
    final Future<ArtworkEntity> artworkPromise =  _artworkRepository.fetchArtwork(id);
    context.push('/waitingRoom', extra: artworkPromise);
  }

  void _deleteDrawing(ArtworkEntity artwork) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Drawing"),
        content: Text('Are you sure you want to delete ${artwork.title}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ]
      )
    );

    if (confirm == true) {
      _artworkRepository.deleteArtwork(artwork);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drawing ${artwork.title} deleted!'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // Listen for changes inside hive and rebuild the drawing gallery when changes happen
    return AnimatedBuilder(
      animation: _artworkRepository.listenable,
      builder: (context, staticChild) {

        final List<ArtworkEntity> artworkList = _artworkRepository.fetchAllArtworks();

        // Handle empty state
        if (artworkList.isEmpty) {
          return const Center(child: Text('No drawings yet'));
        }

        // Calculate thumbnail size
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = (screenWidth / 2) - 16;
        final thumbnailSize = (cardWidth * 2).toInt();
        
        // Build the art gallery grid
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
                    onPressed: () { _deleteDrawing.call(artwork); },
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary),
                  )
                ),
                
              ]
            );
          }
        );
      }
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