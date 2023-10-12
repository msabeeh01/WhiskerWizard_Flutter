import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_app/main.dart';
import 'package:first_app/providers/petModelProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class Album extends ConsumerStatefulWidget {
  const Album({Key? key}) : super(key: key);

  @override
  _Album createState() => _Album();
}

class _Album extends ConsumerState<Album> {
  final user = supabase.auth.currentUser?.id;

  late String petID;

  _getFromGallery () async {
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    //upload image to supabase
    await ref.read(uploadPetImage(image));
  }


  @override
  void initState() {
    super.initState();
    //get pet ID from riverpod
    petID = ref.read(petIDProvider);
    ref.refresh(fetchImagesByPetID(petID));
  }

  @override
  Widget build(BuildContext context) {
    //watch riverpod providers
    final AsyncValue<List<dynamic>> petImages = ref.watch(fetchImagesByPetID(petID));
    return Scaffold(
        appBar: AppBar(
          title: const Text('Album'),
          backgroundColor: Colors.orange[200],
          flexibleSpace: null,
        ),
        body: 
            switch (petImages) {
              AsyncData(:final value) => value != null ?
                  //create a cachednetworkimage for each image
                  GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: value[index],
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    );
                  }
                  )
                  : 
                  const Center(child: Text('This Pet Has No Images')),
              AsyncError() => const Text('Error'),
              _ => const Text('Loading'),
            }
            ,
        floatingActionButton:Row(
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
                _getFromGallery();
              }
            )
          ],
        )
            
        );
  }
}
