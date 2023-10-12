import 'package:first_app/main.dart';
import 'package:first_app/providers/petModelProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

class Reminders extends ConsumerStatefulWidget {
  const Reminders({Key? key}) : super(key: key);

  @override
  _Reminders createState() => _Reminders();
}

class _Reminders extends ConsumerState<Reminders> {
  String? petId;

  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    //get PETID from riverpod
    petId = ref.read(petIDProvider);
    ref.refresh(fetchImagesByPetID(petId));

    //set scroll listener
    _scrollController.addListener(() {
      _scrollListener();
    });
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
    final AsyncValue<List<dynamic>> petReminders =
        ref.watch(fetchReminderByID(petId));
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: SizedBox(
                          child: Wrap(
                            children: <Widget>[
                              //reminder component
                              AddReminderComponent(petId: petId)
                            ],
                          ),
                        ),
                      );
                    });
              },
            )
          ],
        ),
        floatingActionButton: _showFab
            ? FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn);
                },
                backgroundColor: Colors.orange[200],
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              )
            : Container(),
        body: SingleChildScrollView(
          child: switch (petReminders) {
            AsyncData(:final value) => Column(
                  children: value.map((reminder) {
                return (ReminderComponent(
                  pet_id: reminder['petID'].toString(),
                  phone: reminder['phone'],
                  reminder: reminder['reminder'],
                ));
              }).toList()),
            AsyncError(:final error) => Text(error.toString()),
            _ => const CircularProgressIndicator(),
          },
        ));
  }
}

class ReminderComponent extends StatefulWidget {
  const ReminderComponent(
      {Key? key,
      required this.pet_id,
      required this.phone,
      required this.reminder})
      : super(key: key);
  //reminder vars
  final String reminder;
  final String phone;
  final String pet_id;

  @override
  _ReminderComponent createState() => _ReminderComponent();
}

class _ReminderComponent extends State<ReminderComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Center(
          child: Card(
        color: Colors.orange[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 10,
        child: Stack(
          children: [
            SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        margin: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Text(widget.reminder,
                                style: const TextStyle(fontSize: 30)),
                            Text(widget.phone),
                          ],
                        ))
                  ],
                )),
            Positioned(
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 20),
                      child: Row(
                        children: [
                          IconButton(
                            splashColor: Colors.red,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[300],
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            splashColor: Colors.red,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Colors.red[300],
                            ),
                            onPressed: () {},
                          ),
                        ],
                      )),
                ))
          ],
        ),
      )),
    );
  }
}

class AddReminderComponent extends ConsumerStatefulWidget {
  const AddReminderComponent({Key? key, required this.petId}) : super(key: key);

  final String? petId;

  @override
  _AddReminderComponent createState() => _AddReminderComponent();
}

class _AddReminderComponent extends ConsumerState<AddReminderComponent> {
  //form stuff
  final _formKey = GlobalKey<FormState>();
  final _reminderController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  //submit reponse
  void submitResponse(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      //create reminder object with form data, make sure to convert TimeOfDay to time var acceptable by supabase
      //convert TimeOfDay to to DateTime
      final timeAsDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _time.hour,
        _time.minute,
      );
      final reminder = Reminder(
        user_id: supabase.auth.currentUser!.id,
        petID: int.parse(widget.petId!),
        reminder: _reminderController.text,
        phone: _phoneController.text,
        send_time: timeAsDateTime,
      );
      //add reminder to pet using riverpod
      ref.read(addReminderByPetID(reminder));

      ref.refresh(fetchReminderByID(widget.petId!));

      Navigator.of(context).pop();
    }
  }

  var newTime;
  TimeOfDay _time = const TimeOfDay(hour: 13, minute: 15);

  void _selectTime() async {
    newTime = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() {
        _time = newTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextFormField(
                  controller: _reminderController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a reminder'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Reminder',
                  ),
                ),
                TextFormField(
                  controller: _phoneController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a phone number'
                      : null,
                  //make this a number field and enforce it
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                  ),
                ),
                Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              _selectTime();
                            },
                            child: newTime == null
                                ? const Text('Choose Time')
                                : Text(newTime.format(context))),
                        ElevatedButton(
                            onPressed: () {
                              submitResponse(context);

                            },
                            child: const Text('Add'))
                      ],
                    ))
              ],
            )));
  }
}
