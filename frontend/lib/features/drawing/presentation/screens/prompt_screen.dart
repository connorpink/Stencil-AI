/*
basic screen that lets the user write a prompt that the Oeno will use to create some basic sketches
*/

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:go_router/go_router.dart';

class PromptScreen extends StatefulWidget {
  final ArtworkRepositoryInterface artworkRepository;

  const PromptScreen ({
    super.key,
    required this.artworkRepository,
  });

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {

  late final ArtworkRepositoryInterface _artworkRepository;

  final promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _artworkRepository = widget.artworkRepository;
  }

  void _createProject(String prompt) {
    final Future<ArtworkEntity> artworkPromise = _artworkRepository.createArtwork(prompt);
    context.replace('/waitingRoom', extra: artworkPromise);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Describe Your New Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children:[ 
            Expanded(
              child: TextField(
                controller: promptController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Describe what you would like to draw. Oeno (our built in AI) will generate some simple sketches to help get you started.",
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () { _createProject(promptController.text); },
              child: Text('Start Drawing!'),
            )
          ],
        )
      ),
    );
  }
}