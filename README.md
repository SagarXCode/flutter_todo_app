# Flutter Todo App

> A sleek, distraction-free task manager built with Flutter. Designed for efficiency, this app combines a monochromatic aesthetic with smooth gesture interactions and persistent local storage.

---

## ✨ Key Features

- **🌗 Adaptive Theming:** Seamlessly switch between Dark Mode and Light Mode with a global theme engine.
- **💾 Persistent Storage:** Tasks are automatically saved to the device using `shared_preferences`—never lose your data.
- **⚡ Rapid Entry:** The keyboard automatically focuses on the input field upon launch and after adding tasks for speed.
- **👋 Gesture Control:** Swipe any task left or right to delete it instantly.
- **↩️ Undo Capability:** Accidentally deleted a task? An "Undo" snackbar appears for 3 seconds to restore it.
- **🧠 Smart Sorting:** Active tasks float to the top, while completed tasks sink to the bottom.

---

## 📱 Screenshots

| Light Mode | Dark Mode |
|:---:|:---:|
| ![Light Mode](path/to/light-mode.png) | ![Dark Mode](path/to/dark-mode.png) |

*> Note: Replace the placeholder links above with actual screenshots of your app running on an emulator or device.*

---

## 🛠️ Tech Stack

- **Framework:** Flutter (3.x)
- **Language:** Dart
- **Typography:** Google Fonts (Poppins)
- **State Management:** Native `setState` and `ValueNotifier`
- **Local Storage:** Shared Preferences

---

## 📂 Project Structure

The project follows a clean, single-file architecture for simplicity (`lib/main.dart`), organized into five clear sections:

* **App Configuration:** Theme logic and routing.
* **Data Model:** The `Task` class with JSON serialization.
* **State Logic:** Functions for sorting, saving, and updating state.
* **Task Operations:** CRUD methods (`_addTask`, `_deleteTask`).
* **UI Builder:** The visual widget tree.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
