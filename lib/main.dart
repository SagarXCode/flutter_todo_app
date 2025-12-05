import 'dart:convert'; // Used for converting Task objects to text (JSON) for storage
import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Allows using custom Google Fonts
import 'package:shared_preferences/shared_preferences.dart'; // Local storage for saving tasks

void main() => runApp(const MinimalistTodoApp());

// ==============================================================================
// APP CONFIGURATION & THEME ENGINE
// Handles global setup and switching between Dark/Light modes.
// ==============================================================================
class MinimalistTodoApp extends StatelessWidget {
  const MinimalistTodoApp({super.key});

  // Global state for the Theme (Light/Dark).
  // ValueNotifier is a lightweight way to listen for changes without a complex state management package.
  static final themeNotifier = ValueNotifier(ThemeMode.dark);

  // Helper method to build themes.
  // This ensures both Light and Dark modes share the same structure and fonts,
  // only changing specific colors.
  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Define base colors based on the mode
    final baseColor = isDark ? Colors.white : Colors.black; // Text/Icon color
    final bgColor = isDark ? Colors.black : Colors.white; // Background color

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      // ColorScheme defines the semantic colors (surface, error, primary, etc.) used by widgets
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
        surface: bgColor,
        onSurface: baseColor,
      ),
      // Apply the 'Poppins' font globally to all text in the app
      fontFamily: GoogleFonts.poppins().fontFamily,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listens to 'themeNotifier'. Whenever .value changes, this builder runs again.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner:
        false, // Hides the "Debug" banner in top right
        title: 'Todo',
        themeMode: mode,
        theme: _buildTheme(Brightness.light), // Configuration for Light Mode
        darkTheme: _buildTheme(Brightness.dark), // Configuration for Dark Mode
        home: const TodoScreen(),
      ),
    );
  }
}

// ==============================================================================
// DATA MODEL
// Defines the structure of a single Task and handles data conversion.
// ==============================================================================
class Task {
  String id; // Unique identifier for finding/deleting specific tasks
  String content; // The actual text of the todo item
  bool isCompleted; // Status: checked or unchecked

  Task({required this.id, required this.content, this.isCompleted = false});

  // Converts the Task object into a Map (JSON format) so it can be saved as a string.
  // Shared Preferences can only save simple data types like Strings, not custom Objects.
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isCompleted': isCompleted,
  };

  // Converts a Map (JSON) back into a Task object when loading data from storage.
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    content: json['content'],
    isCompleted: json['isCompleted'],
  );
}

// ==============================================================================
// MAIN SCREEN
// Contains App State (Variables), Business Logic, and UI Layout.
// ==============================================================================
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  // Controller allows us to read/clear the text inside the input field
  final _controller = TextEditingController();

  // FocusNode allows us to control the keyboard focus (e.g., keep keyboard open after adding a task)
  final FocusNode _inputFocusNode = FocusNode();

  // The main list that holds all our Task objects
  List<Task> _tasks = [];

  // initState runs once when the widget is first built
  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load saved data immediately

    // This block waits until the first visual frame is drawn, then requests focus.
    // Without 'addPostFrameCallback', asking for focus too early might fail.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  // dispose runs when the widget is destroyed. Important for cleaning up memory.
  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ==============================================================================
  // LOCAL STORAGE & LOGIC SECTION
  // ==============================================================================

  // Central function to update the UI and save to disk.
  // 1. Sorts the list (Active tasks at top, Completed at bottom).
  // 2. Encodes the list to JSON string.
  // 3. Saves it to the phone's persistent storage.
  void _updateAndSave() {
    setState(() {
      _tasks.sort((a, b) {
        // Primary Sort: Completion status (Incomplete items come first)
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        // Secondary Sort: Creation time (Newer items come first based on ID comparison)
        return b.id.compareTo(a.id);
      });
    });

    // SharedPreferences is asynchronous (returns a Future), so we use .then()
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('saved_tasks', jsonEncode(_tasks));
    });
  }

  // Loads data from storage when app starts
  void _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_tasks');

    if (data != null) {
      // jsonDecode turns the String back into a List of Maps.
      // .map(...) iterates over them and converts each Map back into a Task object.
      setState(() {
        _tasks = (jsonDecode(data) as List)
            .map((i) => Task.fromJson(i))
            .toList();
        _updateAndSave(); // Re-sort immediately upon loading
      });
    }
  }

  // ==============================================================================
  // TASK OPERATIONS (Add, Toggle, Delete)
  // ==============================================================================

  void _addTask() {
    // Validation: prevent adding empty tasks
    if (_controller.text.trim().isEmpty) return;

    _tasks.add(
      Task(
        // Use current time in milliseconds as a simple unique ID
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _controller.text.trim(),
      ),
    );

    _controller.clear(); // Clear input field
    _inputFocusNode.requestFocus(); // Keep keyboard open for rapid entry
    _updateAndSave(); // Save changes
  }

  void _toggleTask(Task task) {
    task.isCompleted = !task.isCompleted; // Flip the boolean
    _updateAndSave(); // Save and re-sort (completed item moves to bottom)
  }

  // Handles deletion with "Undo" functionality
  void _deleteTask(Task task) {
    final deletedTask = task; // 1. Create a backup of the task

    _tasks.removeWhere((t) => t.id == task.id); // 2. Remove it from list
    _updateAndSave();

    // 3. Show a SnackBar (popup at bottom)
    ScaffoldMessenger.of(context).clearSnackBars(); // Remove any old snack bars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        content: Text(
          "Task deleted",
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 3), // Popup stays for 3 seconds
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.blueAccent,
          onPressed: () {
            // 4. Restore the backup if user clicks UNDO
            setState(() {
              _tasks.add(deletedTask);
              _updateAndSave();
            });
          },
        ),
      ),
    );
  }

  // ==============================================================================
  // UI BUILDER
  // ==============================================================================
  @override
  Widget build(BuildContext context) {
    // Helper shortcuts to access theme data easily
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Top Navigation Bar
      appBar: AppBar(
        backgroundColor: colors.surface,
        centerTitle: true,
        title: Text(
          "TODO",
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: colors.onSurface,
          ),
        ),
        actions: [
          // Button to toggle Light/Dark mode
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: colors.onSurface,
            ),
            onPressed: () => MinimalistTodoApp.themeNotifier.value = isDark
                ? ThemeMode.light
                : ThemeMode.dark,
          ),
        ],
      ),

      // Main Body Layout
      body: Column(
        children: [
          // Section 1: The List of Tasks
          // Expanded ensures this takes up all available space above the input box
          Expanded(
            child: _tasks.isEmpty
            // Show message if list is empty
                ? Center(
              child: Text(
                "NO ACTIVE TASKS",
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 2,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _tasks.length,
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemBuilder: (ctx, i) {
                final task = _tasks[i];

                // Dismissible adds Swipe-to-Delete functionality
                return Dismissible(
                  key: Key(
                    task.id,
                  ), // Unique key required for Dismissible
                  onDismissed: (_) =>
                      _deleteTask(task), // Trigger delete when swiped
                  // Background shows the "DELETE" text behind the item while swiping
                  background: Container(
                    color: colors.onSurface,
                    alignment: Alignment.center,
                    child: Text(
                      "DELETE",
                      style: TextStyle(
                        color: colors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // GestureDetector detects taps for completing tasks
                  child: GestureDetector(
                    onTap: () => _toggleTask(task),

                    // AnimatedContainer enables smooth transition animations for colors/sizing
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: colors.onSurface),
                      ),
                      child: Row(
                        children: [
                          // Checkbox Icon
                          Icon(
                            task.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: colors.onSurface,
                          ),
                          const SizedBox(width: 15),

                          // Task Text
                          Expanded(
                            child: Text(
                              task.content,
                              style: TextStyle(
                                // Reduce opacity if completed
                                color: colors.onSurface.withValues(
                                  alpha: task.isCompleted ? 0.5 : 1.0,
                                ),
                                // Add strikethrough if completed
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Section 2: Input Area at the bottom
          Container(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _inputFocusNode, // Attaches our focus controller
                    style: TextStyle(color: colors.onSurface),
                    onSubmitted: (_) =>
                        _addTask(), // Triggers add when pressing "Enter"
                    decoration: InputDecoration(
                      hintText: 'ADD NEW TASK...',
                      hintStyle: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colors.onSurface,
                          width: 2,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.onSurface),
                      ),
                    ),
                  ),
                ),
                // Plus Icon Button
                IconButton(
                  onPressed: _addTask,
                  icon: Icon(Icons.add, color: colors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
