import 'package:first_app/loginPage.dart';
import 'package:first_app/profile.dart';
import 'package:flutter/material.dart';
import 'package:first_app/petCards.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

void main() async {
  await dotenv.load(fileName: ".env"); 

  //keys
  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final key = dotenv.env['SUPABASE_KEY'] ?? '';

  await Supabase.initialize(
      url: url,
      anonKey: key);

  
  runApp(const ProviderScope(child: MyApp()));

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: supabase.auth.currentUser == null
            ? LoginPage()
            : const MyHomePage(title: 'Pets'),
        routes: {
          '/home': (context) => const MyHomePage(title: 'Pets'),
          '/login': (context) => LoginPage(),
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.orange[200],
        flexibleSpace: null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const <Widget>[PetCard(), Profile()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
