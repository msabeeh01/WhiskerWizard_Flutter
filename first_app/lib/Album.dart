import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_app/main.dart';
import 'package:first_app/providers/petModelProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Album extends ConsumerStatefulWidget {
  const Album({Key? key}) : super(key: key);

  @override
  _Album createState() => _Album();
}

class _Album extends ConsumerState<Album> {
  final user = supabase.auth.currentUser?.id;

  late String petID;

  @override
  void initState() {
    super.initState();
    //get pet ID from riverpod
    petID = ref.read(petIDProvider);
  }

  @override
  Widget build(BuildContext context) {
    //watch riverpod providers
    final AsyncValue petImages = ref.watch(fetchImagesByPetID(petID));
    return Scaffold(
        appBar: AppBar(
          title: const Text('Album'),
          backgroundColor: Colors.orange[200],
          flexibleSpace: null,
        ),
        body: GridView.count(
          crossAxisCount: 3,
          children: [
            switch (petImages) {
              AsyncData(:final value) => value != null ?
                  Center(
                      child: ClipRRect(
                          child: CachedNetworkImage(
                    imageUrl: value,
                    fit: BoxFit.cover,
                  ))) : const Center(child: Text('This Pet Has No Images')),
              AsyncError() => const Text('Error'),
              _ => const Text('Loading'),
            }
          ],
        ),
        floatingActionButton:
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded),
              onPressed: () {
              }
            ),
            IconButton(
              icon: const Icon(Icons.photo_album),
              onPressed: () {

              }
            )
          ],
        )
            
        );
  }
}
