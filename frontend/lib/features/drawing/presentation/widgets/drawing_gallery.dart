import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter_frontend/features/drawing/presentation/widgets/thumbnail.dart';
import 'package:go_router/go_router.dart';

class DrawingGallery extends StatefulWidget {
  final ArtworkRepositoryInterface artworkRepository;
  
  const DrawingGallery({
    super.key,
    required this.artworkRepository,
  });

  @override
  State<DrawingGallery> createState() => _DrawingGalleryState();
}

class _DrawingGalleryState extends State<DrawingGallery> {
  List<ArtworkEntity> _artworkList = [];

  @override
  void initState() {
    super.initState();
  }

  void _openDrawing(String id) {
    final Future<ArtworkEntity> artworkPromise =  widget.artworkRepository.fetchArtwork(id);
    context.push('/waitingRoom', extra: artworkPromise);
  }

  void _deleteArtwork(ArtworkEntity artwork) async {
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
      widget.artworkRepository.deleteArtwork(artwork);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drawing ${artwork.title} deleted!'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // get the size of each displayed screen (screen size / number of rows)
    final int displaySize = (((MediaQuery.of(context).size.width) / 2) - 16).toInt();

    return ValueListenableBuilder(
      valueListenable: widget.artworkRepository.listenable as ValueListenable,
      builder: (context, box, child) {
        // fetch the updated list of artworks
        _artworkList = widget.artworkRepository.fetchAllArtworks();
        // only show the drawing collections if
        if (_artworkList.isEmpty) { return const Center(child: Text('No drawings yet')); }

        return GridView.builder(
          padding:  const EdgeInsets.all(8),

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),

          itemCount: _artworkList.length,

          itemBuilder: (context, index) {
            final artwork = _artworkList[index];

            return Stack(
              children: [
                GestureDetector(
                  onTap: () { _openDrawing(artwork.id); },

                  child: _DrawingGalleryDisplay(
                    artwork: artwork,
                    thumbnailSize: displaySize,
                  ),
                ),

                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: () { _deleteArtwork(artwork); },
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            );
          },
        );
      }
    );
  }
}

class _DrawingGalleryDisplay extends StatelessWidget {
  final ArtworkEntity artwork;
  final int thumbnailSize;

  const _DrawingGalleryDisplay({
    required this.artwork,
    required this.thumbnailSize,
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