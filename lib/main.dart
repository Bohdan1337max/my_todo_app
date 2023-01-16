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
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
      home: MainPage(),
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
      Navigator.push(context,
      MaterialPageRoute(builder: (context) => const TodoCreatePage()));
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
    onDismissed: (direction) {deleteTodo(todo);},
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: 
      BorderRadius.circular(8)),
      child: ListTile(
        trailing: IconButton(icon: Icon(Icons.delete), color: Colors.red ,
        onPressed: () {
          deleteTodo(todo);
        },),
        onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (context) => AlertDialogHandler(todo: todo))),
        title: Text(todo.title),
        subtitle: Text(todo.date.toIso8601String()),
      ),
    ),
  );
  Future deleteTodo (Todo todo) async {
    final docTodo = FirebaseFirestore.instance.collection('Todos').doc(todo.id);
    await docTodo.delete();
  }
}

class AlertDialogHandler extends StatefulWidget {
  const AlertDialogHandler({super.key, required this.todo});
  final Todo todo;
  @override
  State<AlertDialogHandler> createState() => _AlertDialogHandlerState();
}

class _AlertDialogHandlerState extends State<AlertDialogHandler> {

  DateTime dateTime = DateTime.now();
  final controllerTitle = TextEditingController();
  final controllerBody = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showAlertDialog(context),
    );
  }
  
  Future<DateTime?> pickDate() => showDatePicker(
      context: context,
      initialDate: widget.todo.date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100)
  );

    showAlertDialog(BuildContext context){
    AlertDialog alert = AlertDialog(
      title: TextField(
        controller: controllerTitle,
        style: TextStyle(fontSize: 30),
        decoration: InputDecoration(
            border:  InputBorder.none,
            hintText: widget.todo.title,
            hintStyle: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.bold,
            )
        ) ,
      ),
      content: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child:
          Column(
            children: [
              TextField(
                controller: controllerBody,
                decoration: InputDecoration(
                  hintText: widget.todo.body,
                    border: InputBorder.none,
                   ),
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),

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
            ],
          ),
        ),
      ),

      actions: [
        FloatingActionButton(onPressed: () {
          final docTodo =
          FirebaseFirestore.instance.collection('Todos').doc(widget.todo.id);
          docTodo.update({'date' : dateTime});
          if(controllerTitle.text.isNotEmpty )
            {
              docTodo.update({'title' : controllerTitle.text} );
            } else if (widget.todo.body != controllerBody.text
              && controllerBody.text.isNotEmpty){
            docTodo.update({'body' : controllerBody.text});
          }

          Navigator.push(context, 
          MaterialPageRoute(builder: (context) => const MainPage() ));
        },
          child: Icon(Icons.save),
        )
      ],
    );

     Future.delayed(Duration.zero, () {
       showDialog(context: context, builder: (BuildContext context) => alert);
     });
  }
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





