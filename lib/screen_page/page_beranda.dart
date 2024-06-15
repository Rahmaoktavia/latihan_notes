import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:project_notes/model/model_notes.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Datum> notes = [];

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    try {
      final response =
      await http.get(Uri.parse('http://192.168.156.142/notes/getNotes.php'));
      if (response.statusCode == 200) {
        final ModelNotes notesResponse = modelNotesFromJson(response.body);
        if (notesResponse.isSuccess) {
          setState(() {
            notes = notesResponse.data;
          });
        } else {
          _showErrorSnackBar('Failed to load notes: ${notesResponse.message}');
        }
      } else {
        _showErrorSnackBar('Failed to load notes');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load notes: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void addNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: 'Title'),
              ),
              TextField(
                controller: contentController,
                maxLines: 5, // Limit the number of lines displayed
                decoration: InputDecoration(hintText: 'Content'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                final title = titleController.text;
                final content = contentController.text;
                if (title.isEmpty || content.isEmpty) {
                  _showErrorSnackBar('Title and Content are required');
                  return;
                }
                try {
                  final response = await http.post(
                    Uri.parse('http://192.168.156.142/notes/addNote.php'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'judul_note': title, 'isi_note': content}),
                  );
                  if (response.statusCode == 200) {
                    fetchNotes(); // Refresh notes list after adding
                    Navigator.pop(context);
                  } else {
                    _showErrorSnackBar('Failed to add note');
                  }
                } catch (e) {
                  _showErrorSnackBar('Failed to add note: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void editNoteDialog(Datum note) {
    final titleController = TextEditingController(text: note.judulNote);
    final contentController = TextEditingController(text: note.isiNote);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: 'Title'),
              ),
              TextField(
                controller: contentController,
                maxLines: 5, // Limit the number of lines displayed
                decoration: InputDecoration(hintText: 'Content'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final title = titleController.text;
                final content = contentController.text;
                if (title.isEmpty || content.isEmpty) {
                  _showErrorSnackBar('Title and Content are required');
                  return;
                }
                try {
                  final response = await http.put(
                    Uri.parse(
                        'http://192.168.156.142/notes/editNote.php?id=${note.id}'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'judul_note': title, 'isi_note': content}),
                  );
                  if (response.statusCode == 200) {
                    fetchNotes(); // Refresh notes list after editing
                    Navigator.pop(context);
                  } else {
                    _showErrorSnackBar('Failed to edit note');
                  }
                } catch (e) {
                  _showErrorSnackBar('Failed to edit note: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void deleteNoteDialog(Datum note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Note'),
          content: Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                try {
                  final response = await http.delete(
                    Uri.parse(
                        'http://192.168.156.142/notes/deleteNote.php?id=${note.id}'),
                  );
                  if (response.statusCode == 200) {
                    fetchNotes(); // Refresh notes list after deleting
                    Navigator.pop(context);
                  } else {
                    _showErrorSnackBar('Failed to delete note');
                  }
                } catch (e) {
                  _showErrorSnackBar('Failed to delete note: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showDetailScreen(Datum note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailNoteScreen(note: note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(note.judulNote),
              subtitle: Text(
                note.isiNote.length > 50
                    ? '${note.isiNote.substring(0, 50)}...'
                    : note.isiNote,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => editNoteDialog(note),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteNoteDialog(note),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_red_eye),
                    onPressed: () => showDetailScreen(note),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: addNoteDialog,
      ),
    );
  }
}

class DetailNoteScreen extends StatelessWidget {
  final Datum note;

  DetailNoteScreen({required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.judulNote,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              note.isiNote,
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
