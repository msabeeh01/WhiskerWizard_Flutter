import 'package:first_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fetchAllPets = FutureProvider((ref) async {
  final res = await supabase
      .from('pets')
      .select()
      .eq('user_id', supabase.auth.currentUser?.id);
  return res as List<dynamic>;
});

final deleteByID = FutureProvider.family((ref, id) async {
  await supabase.from('pets').delete().eq('id', id);
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

final fetchImagesByPetID = FutureProvider.family((ref, id) async {
  final userID = supabase.auth.currentUser?.id;
  final res =
      await supabase.storage.from('petImages').list(path: '$userID/$id');
  //print full path for one
  for (var file in res) {
    //create signedURL for all
    final signedURL = await supabase.storage
        .from('petImages')
        .createSignedUrl('$userID/$id/${file.name}', 60);
    return signedURL;
  }
  //return res as List<dynamic>;
});

class Reminder {
  final int petID;
  final String reminder;
  final String phone;
  final DateTime send_time;

  Reminder({
    required this.petID,
    required this.reminder,
    required this.phone,
    required this.send_time,
  });

  Map<String, dynamic> toJson() => {
    'petID': petID,
    'reminder': reminder,
    'phone': phone,
    'send_time': send_time.toIso8601String(),
  };
}


//provider to store reminder
final addReminderByPetID =
    FutureProvider.family<dynamic, Reminder>((_, reminder) async {
  try {
    final timeString = DateFormat('HH:mm:ss').format(reminder.send_time);
    final res = await supabase.from('reminders').insert({
      'petID': reminder.petID,
      'reminder': reminder.reminder,
      'phone': reminder.phone,
      'send_time': timeString
    });
    //refresh reminders
    _.refresh(fetchReminderByID(reminder.petID));
    print(res);
    return res;
  } catch (e) {
    print(e);
  }
});

//provider to store petID
final petIDProvider = StateProvider((ref) => '');
