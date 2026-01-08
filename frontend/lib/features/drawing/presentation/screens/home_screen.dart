import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter_frontend/features/drawing/presentation/widgets/drawing_gallery.dart';
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
      body: DrawingGallery(artworkRepository: artworkRepository),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/createPrompt');
        },
        child: const Icon(Icons.draw),
      ),
    );
  }
}
