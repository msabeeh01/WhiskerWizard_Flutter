import 'package:first_app/model/PetModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Reminders extends StatefulWidget {
  const Reminders({Key? key}) : super(key: key);

  @override
  State<Reminders> createState() => _Reminders();
}

class _Reminders extends State<Reminders> {
  String? petId;
  late PetModel petModel;

  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    petModel = Provider.of<PetModel>(context, listen: false);
    petId = petModel.petId;
    print('BEFORE FETCHING REMINDERS: ${petModel.isLoading}');
    petModel
        .fetchDataReminders(petId!)
        .then((_) => print('AFTER FETCHING REMINDERS: ${petModel.isLoading}'));
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
      body: Consumer<PetModel>(builder: (context, petModel, child) {
        if (petModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: context
                    .watch<PetModel>()
                    .reminders
                    .map((reminder) => ReminderComponent(
                          pet_id: petId!,
                          phone: reminder['phone'],
                          reminder: reminder['reminder'],
                        ))
                    .toList(),
              ));
        }
      }),
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
    );
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

class AddReminderComponent extends StatefulWidget {
  const AddReminderComponent({Key? key, required this.petId}) : super(key: key);

  final String? petId;

  @override
  _AddReminderComponent createState() => _AddReminderComponent();
}

class _AddReminderComponent extends State<AddReminderComponent> {
  //form stuff
  final _formKey = GlobalKey<FormState>();
  final _reminderController = TextEditingController();
  final _phoneController = TextEditingController();

  //set petModel = this
  late PetModel petModel;

  @override
  void initState() {
    super.initState();
    petModel = Provider.of<PetModel>(context, listen: false);
  }

  //submit reponse
  void submitResponse(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      await petModel.addReminder(
          _reminderController.text, _phoneController.text, widget.petId!, _time);
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
                            }, child: newTime == null
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
