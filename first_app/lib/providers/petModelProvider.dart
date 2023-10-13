import 'dart:io';

import 'package:first_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final fetchAllPets = FutureProvider((ref) async {
  final res = await supabase
      .from('pets')
      .select()
      .eq('user_id', supabase.auth.currentUser?.id);
  return res as List<dynamic>;
});

class deleteParams {
  final String id;
  final String name;

  deleteParams({required this.id, required this.name});

}

final deleteByID = FutureProvider.family<dynamic, deleteParams>((ref, del) async {
  //delete from pets table
  await supabase.from('pets').delete().eq('id', del.id);
  //delete from reminders
  await supabase.from('reminders').delete().eq('petID', del.id);

  //delete corresponding images from storage
  final userID = supabase.auth.currentUser?.id;
  await supabase.storage
      .from('petImages')
      .remove(['$userID/${userID}${del.name}']);

  //list then delete corresponding images and folder from storage
  final res = await supabase.storage.from('petImages').list(path: '$userID/${del.id}');
  for (var file in res) {
    await supabase.storage
        .from('petImages')
        .remove(['$userID/${del.id}/${file.name}']);
  }

  await supabase.storage.from('petImages').remove(['$userID/${del.id}/']);

  //invalidate fetch all pets
  ref.refresh(fetchAllPets);
});

final fetchImageByName = FutureProvider.family((ref, name) async {
  final userID = supabase.auth.currentUser?.id;
  final res = await supabase.storage.from('petImages').list(path: '$userID');
  //in the response, create signedURL for one that matches the name

  for (var file in res) {
    if (file.name == '$userID$name') {
      final signedURL = await supabase.storage
          .from('petImages')
          .createSignedUrl('$userID/${file.name}', 60);
      return signedURL;
    }
  }
  // return res as List<dynamic>;
});

final fetchReminderByID = FutureProvider.family((ref, id) async {
  final res = await supabase.from('reminders').select().eq('petID', id);
  return res as List<dynamic>;
});

final deleteReminderByID = FutureProvider.family((ref, id) async {
  await supabase.from('reminders').delete().eq('id', id);
  //refresh all reminders
  final petID = ref.read(petIDProvider);
  ref.refresh(fetchReminderByID(petID));
});

final fetchImagesByPetID = FutureProvider.family((ref, id) async {
  final userID = supabase.auth.currentUser?.id;
  final res =
      await supabase.storage.from('petImages').list(path: '$userID/$id');
  //print full path for one
  List<dynamic> signedURLs = [];
  for (var file in res) {
    //create signedURL for all
    final signedURL = await supabase.storage
        .from('petImages')
        .createSignedUrl('$userID/$id/${file.name}', 60);
    signedURLs.add(signedURL);
  }
  return signedURLs;
});

final uploadPetImage = FutureProvider.family((ref, XFile? file) async{
  final userID = supabase.auth.currentUser?.id;
  final petID = ref.read(petIDProvider);
  final fileName = file!.name;
  //XFILE conversion
  final bytes = await File(file!.path).readAsBytes();
  await supabase.storage.from('petImages').uploadBinary('$userID/$petID/${fileName}', bytes);
  ref.refresh(fetchImagesByPetID(petID));
});

class Reminder {
  final int petID;
  final String reminder;
  final String phone;
  final String user_id;
  final DateTime send_time;

  Reminder({
    required this.petID,
    required this.reminder,
    required this.phone,
    required this.send_time,
    required this.user_id,
  });

  Map<String, dynamic> toJson() => {
    'user_id': user_id,
    'petID': petID,
    'reminder': reminder,
    'phone': phone,
    'send_time': send_time.toIso8601String(),
  };
}

//provider to store reminder
final addReminderByPetID = FutureProvider.family<dynamic, Reminder>((ref, reminder) async {
  try {
    final petID = ref.read(petIDProvider);
    final timeString = DateFormat('HH:mm:ss').format(reminder.send_time);
    await supabase.from('reminders').insert({
      'user_id': reminder.user_id,
      'petID': reminder.petID,
      'reminder': reminder.reminder,
      'phone': reminder.phone,
      'send_time': timeString
    });
    //refresh reminders
    ref.invalidate(fetchReminderByID(petID));
  } catch (e) {
    print(e);
  }
});

//provider to store petID
final petIDProvider = StateProvider((ref) => '');

//provider to store showIcons state
final showIconsProvider = StateProvider((ref) => false);