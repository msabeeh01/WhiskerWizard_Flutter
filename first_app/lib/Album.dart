import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_app/main.dart';
import 'package:first_app/model/PetModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Album extends StatefulWidget {
  const Album({Key? key}) : super(key: key);


  @override
  State<Album> createState() => _Album();
}

class _Album extends State<Album> {
  final user = supabase.auth.currentUser?.id;

  late PetModel petModel;

  late String petID;

  @override
  void initState() {
    super.initState();
    petModel = Provider.of<PetModel>(context, listen: false);
    petID = petModel.petId;
    //MY PET ID
    print('MY PETS ID IS $petID');
    petModel.fetchPetImages(petID);
    // fetchImage();
  }

  // Future<void> fetchImage() async {
  //   try {
  //     // Get all images from storage and create private signed URL and store in _images
  //     final response =
  //         await supabase.storage.from('petImages').list(path: '$user/');
  // Now create a signed URL for each image and store in _images
  //     for (var element in response) {
  //       if (!element.name.endsWith('/')) {
  //         var path = '$user/${element.name}';
  //         var signedUrl = await supabase.storage
  //             .from('petImages')
  //             .createSignedUrl(path, 60);
  //         if (!petModel.images.contains(signedUrl)) {
  //           petModel.images.add(signedUrl);
  //         }
  //         print(petModel.images);
  //       } else {
  //         print(element.name);
  //       }
  //     }
  //   } catch (e) {
  //     print('e: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Album'),
          backgroundColor: Colors.orange[200],
          flexibleSpace: null,
        ),
        body: GridView.count(
          crossAxisCount: 3,
          children: [
            for (var image in context.watch<PetModel>().petImages)
              Center(
                  child: ClipRRect(
                      child: CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
              )))
          ],
        ));
  }
}
