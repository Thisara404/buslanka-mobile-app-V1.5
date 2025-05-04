// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:to_do/config/config.dart';
// import 'package:to_do/screens/auth/login_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<Task> _tasks = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchTasks();
//   }

//   Future<void> _fetchTasks() async {
//     // To be implemented later with actual API calls
//     setState(() {
//       _isLoading = false;
//       // Sample tasks for UI demo
//       _tasks = [
//         Task(id: '1', title: 'Learn Flutter', completed: true),
//         Task(id: '2', title: 'Build Todo App', completed: false),
//         Task(id: '3', title: 'Connect to MongoDB backend', completed: false),
//       ];
//     });
//   }

//   Future<void> _logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(ApiConfig.tokenKey);
//     await prefs.remove(ApiConfig.userIdKey);

//     if (!mounted) return;

//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => const LoginScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Tasks'),
//         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _tasks.isEmpty
//               ? const Center(child: Text('No tasks yet. Add one!'))
//               : ListView.builder(
//                   padding: const EdgeInsets.all(8),
//                   itemCount: _tasks.length,
//                   itemBuilder: (context, index) {
//                     final task = _tasks[index];
//                     return Card(
//                       elevation: 2,
//                       margin: const EdgeInsets.symmetric(vertical: 5),
//                       child: ListTile(
//                         leading: Checkbox(
//                           value: task.completed,
//                           onChanged: (value) {
//                             setState(() {
//                               _tasks[index].completed = value ?? false;
//                             });
//                             // Update task in backend (to be implemented)
//                           },
//                         ),
//                         title: Text(
//                           task.title,
//                           style: TextStyle(
//                             decoration: task.completed
//                                 ? TextDecoration.lineThrough
//                                 : TextDecoration.none,
//                             color: task.completed ? Colors.grey : Colors.black,
//                           ),
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete),
//                           onPressed: () {
//                             setState(() {
//                               _tasks.removeAt(index);
//                             });
//                             // Delete from backend (to be implemented)
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _showAddTaskDialog();
//         },
//         backgroundColor: Colors.deepPurple,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }

//   void _showAddTaskDialog() {
//     final textController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Add New Task'),
//           content: TextField(
//             controller: textController,
//             autofocus: true,
//             decoration: const InputDecoration(
//               hintText: 'Enter task title',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('CANCEL'),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (textController.text.trim().isNotEmpty) {
//                   setState(() {
//                     _tasks.add(Task(
//                       id: DateTime.now().toString(),
//                       title: textController.text.trim(),
//                       completed: false,
//                     ));
//                   });
//                   // Add task to backend (to be implemented)
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text('ADD'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class Task {
//   final String id;
//   final String title;
//   bool completed;

//   Task({
//     required this.id,
//     required this.title,
//     required this.completed,
//   });

//   // Methods for JSON conversion will be added when implementing API
// }
