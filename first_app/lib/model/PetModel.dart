
import 'dart:convert';

import 'package:first_app/main.dart';
import 'package:flutter/material.dart';

class PetModel extends ChangeNotifier {
  String _petId;
  List<dynamic>? _pets = [];
  List<dynamic>? _reminders = [];
  List<dynamic>? _image = [{}];
  List<dynamic>? _petImages = [];
  bool _isLoading = false;

  //userID
  String? user = supabase.auth.currentUser?.id;

  PetModel({String petId = ''}) : _petId = petId;

  //fetch pets from supabase
  Future<void> fetchData() async {
    _isLoading = true;
    final response = await supabase
        .from('pets')
        .select()
        .eq('user_id', supabase.auth.currentUser?.id);
    _pets = response;
    for(var pet in response){
      fetchPetSplashImage(pet['pet_name']);
    }
    _isLoading = false;
    notifyListeners();
  }

  //Delete pet based on id
  Future<void> deletePet(String petId) async {
    _isLoading = true;
    await supabase.from('pets').delete().eq('id', petId);
    fetchData();
    _isLoading = false;
    notifyListeners();

  }

  //Reminder functions
  //fetch reminders from supabase
  Future<void> fetchDataReminders(String petID) async {
    _isLoading = true;
    print('MY LOADING STATE in function: $_isLoading');
    final response =
        await supabase.from('reminders').select().eq("petID", petID);
    _reminders = response;
    _isLoading = false;
    print('MY LOADING STATE in function: $_isLoading');
    notifyListeners();
  }

  Future<void> addReminder(String reminder, String phone, String petID, TimeOfDay time) async {
    _isLoading = true;
    print("TIME RECEIVED: ${time}");
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
     await supabase.from('reminders').insert([
      {'petID': petID, 'phone': phone, 'reminder': reminder, 'send_time': timeString}
    ]);
    fetchDataReminders(petID);
        _isLoading = false;
    notifyListeners();

  }

  //images functions
  Future<void> fetchPetImages(String petID) async {
    try {
      //clear images
      _petImages = [];
      _isLoading = true;
      // Get all images from storage and create private signed URL and store in _images
      final response =
          await supabase.storage.from('petImages').list(path: '${user}/');
      // Now create a signed URL for each image and store in _images
      for (var element in response) {
        if (!element.name.endsWith('/')) {
          var path = '$user/${element.name}';
          var signedUrl = await supabase.storage
              .from('petImages')
              .createSignedUrl(path, 60);
          if (!_petImages!.contains(signedUrl)) {
            _petImages?.add(signedUrl);
          }
        } else {
          print(element.name);
        }
      }
    } catch (e) {
      print('e: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPetSplashImage(String pet_name) async {
    _isLoading = true;
    try {
      _image = [];
      final response =
          await supabase.storage.from('petImages').list(path: '${user}/');


      //if there is a FileObject in the reponse, add it to _images
      for (var element in response) {
        if (element.name.endsWith(pet_name)) {
          var path = '$user/${element.name}';
          var signedUrl = await supabase.storage
              .from('petImages')
              .createSignedUrl(path, 60);
          if (!_image!.contains(signedUrl)) {
            //add url to _image with the pet_name as key
              _image?.add({'pet_name': pet_name, 'signedUrl': signedUrl});
          }
        }
      }
    } catch (e) {
      print('e: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  String get petId => _petId;
  set petId(String petId) {
    _petId = petId;
    notifyListeners();
  }

  List<dynamic> get pets => _pets ?? [];
  set pets(List<dynamic> pets) {
    _pets = pets;
    notifyListeners();
  }

  List<dynamic> get reminders => _reminders ?? [];
  set reminders(List<dynamic> reminders) {
    _reminders = reminders;
    notifyListeners();
  }

  List<dynamic> get images => _image ?? [];
  set images(List<dynamic> images) {
    _image = images;
    notifyListeners();
  }

  List<dynamic> get petImages => _petImages ?? [];
  set petImages(List<dynamic> images) {
    _petImages = petImages;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  set isLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}
