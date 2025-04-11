// Importing packages from flutter and firebase
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

// Main page of the app that displays the tasks
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Firestore instance to manage the tasks
  final FirebaseFirestore db =
      FirebaseFirestore.instance; // New firestore instance

  // Controller for the text field or task name input
  final TextEditingController nameController =
      TextEditingController(); //captures textform input

  // List of fetched tasks from Firestore to hold
  final List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks(); // Fetch tasks when the app starts
  }

  //Fetches tasks from the firestore and update local task list
  Future<void> fetchTasks() async {
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear();
      tasks.addAll(
        snapshot.docs.map(
          (doc) => {
            'id': doc.id,
            'name': doc.get('name'),
            'completed': doc.get('completed') ?? false,
          },
        ),
      );
    });
  }

  // Function that adds new tasks to local state & firestore database
  Future<void> addTask() async {
    final taskName = nameController.text.trim();

    // Check if the task name is not empty
    // Add the task to Firestore if it's not empty
    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      //docRef gives us the insertion id of the task from the database
      final docRef = await db.collection('tasks').add(newTask);

      //Adding tasks locally
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });
      nameController.clear(); // Used to clear the input field
    }
  }

  //Updates the completion status of the task in Firestore & locally
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index];

    // Updating the task in Firestore
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    // Updating the task locally
    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  // It deletes the task locally & in the Firestore
  Future<void> removeTasks(int index) async {
    final task = tasks[index];

    // Deleting the task from Firestore
    await db.collection('tasks').doc(task['id']).delete();

    // Removing the task locally
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI of the home page like appbar, calendar, task list & add task section
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),
            const Text(
              'Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Main Area of Content of the app
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar Widget to show current month
                  TableCalendar(
                    calendarFormat: CalendarFormat.month,
                    focusedDay: DateTime.now(),
                    firstDay: DateTime(2025),
                    lastDay: DateTime(2026),
                  ),
                  // Display the tasks list
                  buildTaskList(tasks, removeTasks, updateTask),
                ],
              ),
            ),
          ),
          // Section for adding tasks
          buildAddTaskSection(nameController, addTask),
        ],
      ),
      drawer: Drawer(), //Navigation Drawer
    );
  }
}

// Build the section for adding tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    decoration: const BoxDecoration(color: Colors.white),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Input field for adding task names
          Expanded(
            child: Container(
              child: TextField(
                maxLength: 32,
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Add Task',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // Button to add tasks
          ElevatedButton(
            onPressed: addTask, //Adds tasks when pressed
            child: Text('Add Task'),
          ),
        ],
      ),
    ),
  );
}

// Widget that displays the task item on the UI
// Builds the scrollable list of tasks
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap: true, // Makes the list scrollable
    physics: const NeverScrollableScrollPhysics(), // Disables scrolling
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      final isEven = index % 2 == 0;

      return Padding(
        padding: EdgeInsets.all(1.0),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: isEven ? Colors.blue : Colors.green,
          leading: Icon(
            task['completed']
                ? Icons.check_circle
                : Icons.circle_outlined, // Icon based on completion status
            color: task['completed'] ? Colors.green : Colors.white,
          ),
          title: Text(
            task['name'],
            style: TextStyle(
              decoration: task['completed'] ? TextDecoration.lineThrough : null,
              fontSize: 22,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Click on checkbox to mark tasks as completed in Firestore
              Checkbox(
                value: task['completed'],
                onChanged:
                    (value) => updateTask(
                      index,
                      value!,
                    ), // Updates the task status when clicked the checkbox
              ),
              // Button to delete tasks
              IconButton(
                icon: Icon(Icons.delete),
                onPressed:
                    () => removeTasks(index), // Removes the task when pressed
              ),
            ],
          ),
        ),
      );
    },
  );
}
