/*
basic screen that lets the user write a prompt that the Oeno will use to create some basic sketches
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen ({super.key});

  @override 
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {

  final promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _createProject(String prompt) async {
    context.replace('/draw');
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