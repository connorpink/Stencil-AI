/*
Waiting room is a place to load mini games or reading material for users to interact with while they wait for oeno to create there stencils
*/

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:go_router/go_router.dart';

class WaitingRoomScreen extends StatefulWidget {
  final Future<ArtworkEntity> artworkPromise;
  
  const WaitingRoomScreen({
    super.key,
    required this.artworkPromise,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  @override
  void initState() {
    super.initState();
    _waitForArtwork();
  }

  // wait for the artwork promise to be resolved before loading the artwork page
  Future<void> _waitForArtwork() async {
    try {
      final artwork = await widget.artworkPromise;
      if (mounted) {
        context.replace('/draw', extra: artwork); 
      }
    } catch (error) {
      // Handle error - maybe show a dialog or navigate to error screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate artwork: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Oeno is generating some stencils for you to draw with, in the mean time please enjoy [insert reading material or fun game later in development] while we set things up for you.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}