// ignore_for_file: unnecessary_null_comparison, prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class Todo {
  String id;
  final String title;
  final String body;
  final DateTime date;

  Todo({
    this.id ='',
    required this.title,
    required this.body,
    required this.date
  });

  Map<String,dynamic> toJson() => {
    'id' : id,
    'title' : title,
    'body' : body,
    'date' : date
  };

  static Todo fromJson(Map<String, dynamic> json ) => Todo(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    date: (json['date'] as Timestamp).toDate(),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/MainPage',
        routes: {
        '/MainPage' : (context) => const MainPage(),
          '/AddTodoPage' : (context) => const TodoCreatePage()
        },
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final controller = TextEditingController();
  @override
  Widget build(BuildContext context) =>Scaffold(
    appBar: AppBar(
      title: Text("My Todo App ")
    ),
    floatingActionButton: FloatingActionButton(onPressed:
    () {
      Navigator.pushNamed(context,'/AddTodoPage');
    },
      child:  Icon(Icons.add)
    ),
    body: StreamBuilder<List<Todo>>(
      stream: readTodo(),
      builder: (context, snapshot) {
        if(snapshot.hasError) {
          return Text('Something went wrong! ${snapshot.error}');
        } else if (snapshot.hasData) {
          final todos = snapshot.data!;
          return ListView(
            children: todos.map(buildTodo).toList(),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
    ),
  );
  Widget buildTodo(Todo todo) => Dismissible(
    key: Key(todo.id),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: 
      BorderRadius.circular(8)),
      child: ListTile(
        title: Text(todo.title),
        subtitle: Text(todo.date.toIso8601String()),
      ),
    ),
  );
}


Stream<List<Todo>> readTodo() => FirebaseFirestore.instance.collection('Todos')
.snapshots()
.map((snapshot) =>
snapshot.docs.map((doc) => Todo.fromJson(doc.data())).toList());

class TodoCreatePage extends StatefulWidget {
  const TodoCreatePage({Key? key}) : super(key: key);
  @override
  State<TodoCreatePage> createState() => _TodoCreatePageState();
}

class _TodoCreatePageState extends State<TodoCreatePage> {
  DateTime dateTime = DateTime.now();
  final controllerTitle = TextEditingController();
  final controllerBody = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(onPressed: () {
        Navigator.pop(context);
      },
          icon: const Icon(Icons.arrow_back)),
      title: Text('Add new task'),
    ),
    body: ListView(
      padding:  EdgeInsets.all(16),
      children: <Widget>[
        TextField(
          controller: controllerTitle,
          decoration: InputDecoration(
            hintText: 'Title'
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controllerBody,
          decoration: InputDecoration(
            hintText: 'Description'
          ),
        ),
        const SizedBox(height:24),
        ElevatedButton(
            onPressed: () async {
              final date = await pickDate();
              if (date == null) return;
              setState(() => dateTime = date);
            },
            child: Text('${dateTime.year}/'
            '${dateTime.month}/'
            '${dateTime.day}')
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 80,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle:  TextStyle(fontSize: 19),
                backgroundColor: Colors.greenAccent,
               shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)
              ),
            ),
              onPressed: () {
                final todo = Todo(
                    title: controllerTitle.text,
                    body: controllerBody.text,
                    date: dateTime
                );
                createTodo(todo);
                Navigator.pop(context);
          }, child: Text('Create')
          ),
        )
      ],
    ),
  );

  Future createTodo(Todo todo) async {
    final docTodo = FirebaseFirestore.instance.collection('Todos').doc();
    todo.id = docTodo.id;
    final json = todo.toJson();
    await docTodo.set(json);
  }

  Future<DateTime?> pickDate() => showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100)
  );
}



