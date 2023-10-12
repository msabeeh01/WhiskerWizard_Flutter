import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:first_app/Album.dart";
import "package:first_app/Reminders.dart";
import "package:first_app/main.dart";
import "package:first_app/providers/petModelProvider.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";

class PetCard extends ConsumerStatefulWidget {
  const PetCard({Key? key}) : super(key: key);

  @override
  _PetCard createState() => _PetCard();
}

class _PetCard extends ConsumerState<PetCard> {
  final user = supabase.auth.currentUser?.id;
  String _searchQuery = '';

  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollListener();
    });
    ref.refresh(fetchAllPets);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

//scrolling rules
  void _scrollListener() {
    if (_scrollController.offset > 5 && !_showFab) {
      setState(() {
        _showFab = true;
      });
    } else if (_scrollController.offset <= 5 && _showFab) {
      setState(() {
        _showFab = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //watch riverpod providers
    final AsyncValue<List<dynamic>> allPets = ref.watch(fetchAllPets);

    return Scaffold(
        body: Column(children: [
          Container(
            color: Colors.orange[200],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Search pets',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: () async {
              ref.refresh(fetchAllPets);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //show image, if no image, show text
                    switch (allPets) {
                      AsyncData(:final value) => Column(
                            children: value.map((pet) {
                          return PetCardComponent(
                              name: pet['pet_name'],
                              pet_id: pet['id'].toString(),
                              desc: pet['pet_desc']);
                        }).toList()),
                      //generate pet card for each pet
                      AsyncError(:final error, :final stackTrace) =>
                        Text(error.toString()),
                      _ => const CircularProgressIndicator(),
                    }
                  ]),
            ),
          )),
        ]),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                supabase.auth.signOut();
                //direct to /login route and not page without ability to go back
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Icon(Icons.logout),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                //
                showDialog(
                    context: context, builder: (context) => AddPetComponent());
              },
              child: const Icon(Icons.add, color: Colors.black),
            ),
            const SizedBox(width: 10),
            _showFab
                ? FloatingActionButton(
                    onPressed: () {
                      _scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut);
                    },
                    backgroundColor: Colors.orange[200],
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  )
                : const SizedBox(width: 0, height: 0),
          ],
        ));
  }
}

class PetCardComponent extends StatefulWidget {
  const PetCardComponent(
      {Key? key, required this.name, required this.pet_id, required this.desc})
      : super(key: key);

  final String name;
  final String desc;
  final String pet_id;

  @override
  State<PetCardComponent> createState() => _PetCardComponentState();
}

class _PetCardComponentState extends State<PetCardComponent> {
  bool? _showIcons = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    //create a card for each name that will have an image in one row, with 3 icons in the next
    return GestureDetector(
        onLongPress: () {
          setState(() {
            _showIcons = !_showIcons!;
          });
        },
        child: Stack(
          children: [
            Container(
                margin: const EdgeInsets.all(8.0),
                child: Center(
                  child: Card(
                    color: Colors.orange[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: SizedBox(
                        width: screenWidth * 0.9,
                        child: Row(
                          children: [
                            Expanded(
                                child: SizedBox(
                                    width: double.maxFinite,
                                    height: 230,
                                    child: Stack(
                                        children: _showIcons == true
                                            ? [
                                                FlippedCard(
                                                  pet_id: widget.pet_id,
                                                  pet_name: widget.name,
                                                )
                                              ]
                                            : [
                                                ImageAndText(
                                                    name: widget.name,
                                                    desc: widget.desc),
                                              ]))),
                            CardIconBar(pet_id: widget.pet_id)
                          ],
                        )),
                  ),
                )),
          ],
        ));
  }
}

class ImageAndText extends ConsumerWidget {
  const ImageAndText({Key? key, required this.name, required this.desc})
      : super(key: key);

  final String name;
  final String desc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue image = ref.watch(fetchImageByName(name));

    return Stack(fit: StackFit.expand, children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(15),
          //wait for data
          child: switch (image) {
            AsyncData(:final value) => value != null ? CachedNetworkImage(
                imageUrl: value,
                fit: BoxFit.cover,
              ) : Text('NO IMAGE'),
            AsyncError(:final error, :final stackTrace) =>
              Text(error.toString()),
            _ => const CircularProgressIndicator(),
          }),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            color: Colors.orange.withOpacity(0.3),
            padding: const EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    )),
                Text(desc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ))
              ],
            ),
          ))
    ]);
  }
}

class CardIconBar extends ConsumerWidget {
  const CardIconBar({Key? key, required this.pet_id}) : super(key: key);

  final pet_id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petIDState = ref.watch(petIDProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: IconButton(
              icon: const Icon(
                Icons.padding_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                //set petID
                ref.read(petIDProvider.notifier).state = pet_id;
                // Provider.of<PetModel>(context, listen: false).petId = pet_id;
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Reminders()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: IconButton(
              icon: const Icon(Icons.photo_album),
              color: Colors.white,
              onPressed: () {
                //set petID and print after
                ref.read(petIDProvider.notifier).state = pet_id;
                // Provider.of<PetModel>(context, listen: false).petId = pet_id;
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Album()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: IconButton(
              icon: const Icon(Icons.vaccines),
              color: Colors.white,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class FlippedCard extends ConsumerWidget {
  const FlippedCard({Key? key, required this.pet_id, required this.pet_name}) : super(key: key);

  final pet_id;
  final pet_name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: IconButton(
              onPressed: () {
                //delete pet by calling riverpod async func
                final pet = deleteParams(
                    id: pet_id,
                    name: pet_name);
                ref.read(deleteByID(pet));
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              icon: const Icon(Icons.delete_forever_outlined),
              color: Colors.red,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: IconButton(
              onPressed: () {},
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              icon: const Icon(
                Icons.mode_edit_outline_outlined,
                color: Colors.black,
              ),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class AddPetComponent extends ConsumerStatefulWidget {
  const AddPetComponent({Key? key}) : super(key: key);

  @override
  _AddPetComponent createState() => _AddPetComponent();
}

class _AddPetComponent extends ConsumerState<AddPetComponent> {
  final petNameController = TextEditingController();
  final descController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  //image picker variables
  XFile? imageFile;

  //user vars
  var user =  supabase.auth.currentUser?.id;

  //function submit form data to supabase
  void submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      await supabase.from('pets').insert([
        {
          'user_id': supabase.auth.currentUser?.id,
          'pet_name': petNameController.text,
          'pet_desc': descController.text
        }
      ]);

      //insert image into supabase
      if (imageFile != null) {
        final bytes = await File(imageFile!.path).readAsBytes();
        await supabase.storage.from('petImages').uploadBinary(
              '$user/$user${petNameController.text}',
              bytes,
            );
      }

      ref.refresh(fetchAllPets);
      

      Navigator.of(context).pop();
      //refetch pets data
    }
  }

  _getFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Wrap(children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: petNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a pet name';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Pet Name',
                ),
              ),
              TextFormField(
                controller: descController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a pet name';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(children: [
                    //display picked iage
                    imageFile == null
                        ? Container()
                        : //display picked image
                        SizedBox(
                            height: 200,
                            width: 200,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  File(imageFile!.path),
                                  fit: BoxFit.cover,
                                )),
                          ),

                    ElevatedButton(
                        onPressed: () {
                          _getFromGallery();
                        },
                        child: const Text('Choose Photo')),
                    ElevatedButton(
                        onPressed: () {
                          submitForm(context);
                        },
                        child: const Text('Add'))
                  ]))
            ],
          ),
        )
      ]),
    );
  }
}
