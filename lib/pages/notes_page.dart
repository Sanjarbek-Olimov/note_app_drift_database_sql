import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../services/database.dart';
import '../services/hive_service.dart';
import 'package:drift/drift.dart' as dr;

class NotesPage extends StatefulWidget {
  static const String id = "notes_page";

  const NotesPage({Key? key}) : super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late AppDatabase database;
  bool isLoading = true;
  List<Note> noteList = [];
  List<Note> listofNotestoDelete = [];
  TextEditingController noteController = TextEditingController();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  // #first_alert_dialog
  void _androidDialog() {
    showGeneralDialog(
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                contentPadding:
                    const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 10.0),
                title: Text("new note".tr()),
                content: TextField(
                  maxLines: 10,
                  controller: noteController..clear(),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: "enter note".tr(),
                      border: const OutlineInputBorder(
                          borderSide: BorderSide.none)),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "cancel".tr(),
                        style:
                            const TextStyle(fontSize: 16),
                      )),
                  TextButton(
                      onPressed: () {
                        final note = NotesCompanion(
                            content:
                                dr.Value(noteController.text.toString().trim()),
                            date: dr.Value(DateTime.now().toString()),
                            isSelected: const dr.Value(false));
                        database.insertNote(note);
                        setState(() {});
                        Navigator.pop(context);
                        noteController.clear();
                      },
                      child: Text(
                        "save".tr(),
                        style:
                            const TextStyle(fontSize: 16),
                      )),
                ],
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return const SizedBox();
        });
  }

  // #delete_alert_dialog
  void _androidDialogToDelete(void Function() function) {
    showGeneralDialog(
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                contentPadding:
                    const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 10.0),
                title: Text("confirm delete".tr(args: [selected.toString()])),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "cancelDelete".tr(),
                        style:
                            const TextStyle(fontSize: 16),
                      )),
                  TextButton(
                      onPressed: function,
                      child: Text(
                        "delete".tr(),
                        style:
                            const TextStyle(fontSize: 16),
                      )),
                ],
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return const SizedBox();
        });
  }

  @override
  Widget build(BuildContext context) {
    database = Provider.of<AppDatabase>(context);
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          title: Text(
            "appbar".tr(),
          ),
          actions: [
            // #language_picker
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                  color: Theme.of(context).backgroundColor,
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: DropdownButton<String>(
                alignment: Alignment.centerRight,
                underline: Container(),
                isDense: true,
                value: HiveDB.loadLang(),
                items: <String>[
                  'EN',
                  'РУ',
                  'O\'Z',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Center(child: Text(value)),
                  );
                }).toList(),
                onChanged: (String? value) async {
                  setState(() {
                    HiveDB.storeLang(value!);
                    if (value == "EN") {
                      context.setLocale(const Locale('en', 'US'));
                    } else if (value == "РУ") {
                      context.setLocale(const Locale('ru', 'RU'));
                    } else {
                      context.setLocale(const Locale('uz', 'UZ'));
                    }
                  });
                },
              ),
            ),
            const SizedBox(
              width: 10,
            ),

            // #theme_mode_changer
            IconButton(
                onPressed: () {
                  HiveDB.storeMode(!HiveDB.loadMode());
                },
                icon: Icon(
                    HiveDB.loadMode() ? Icons.dark_mode : Icons.light_mode
                )),
          ],
        ),
        body: FutureBuilder<List<Note>>(
          future: _getNoteFromDatabase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              snapshot.data!.sort((a, b) => b.date.compareTo(a.date));
              noteList = snapshot.data!;
              if (noteList.isEmpty) {
                return Center(
                  child: Text(
                    "center".tr(),
                    style: const TextStyle(fontSize: 20),
                  ),
                );
              } else {
                return ListView.builder(
                    itemCount: noteList.length,
                    itemBuilder: (context, index) {
                      return _notes(context, noteList[index]);
                    });
              }
            } else if (snapshot.hasError) {
              return Center(
                  child: Text(
                snapshot.error.toString(),
                style: Theme.of(context).textTheme.bodyText2,
              ));
            }
            return Center(
              child: isLoading
                  ? const CircularProgressIndicator.adaptive()
                  : Text(
                      "center".tr(),
                      style: const TextStyle(fontSize: 20),
                    ),
            );
          },
        ),
        floatingActionButton: isLongPressed?const SizedBox.shrink():FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          onPressed: _androidDialog,
          child: const Icon(
            Icons.add,
            size: 35,
            color: Colors.white,
          ),
        ),


        // #select_counter_remover
        bottomNavigationBar: isLongPressed?BottomAppBar(
          color: Theme.of(context).primaryColor,
          shape: const CircularNotchedRectangle(),
          child: Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.centerLeft,
            child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "selected".tr(args: [selected.toString()]),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 25),
                      ),
                      IconButton(
                          onPressed: () {
                            if (selected != 0) {
                              _androidDialogToDelete(() {
                                listofNotestoDelete = noteList
                                    .where((element) => element.isSelected)
                                    .toList();
                                for (int i = 0;
                                    i < listofNotestoDelete.length;
                                    i++) {
                                  database.deleteNote(listofNotestoDelete[i]);
                                }
                                enabled = true;
                                isLongPressed = false;
                                selected = 0;
                                setState(() {});
                                Navigator.pop(context);
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ))
                    ],
                  )
          ),
        ):const SizedBox.shrink());
  }

  Future<List<Note>> _getNoteFromDatabase() async {
    return await database.getNoteList();
  }

  int selected = 0;
  bool enabled = true;
  bool isLongPressed = false;

  // #notes_item
  Widget _notes(BuildContext context, Note itemNote) {
    return InkWell(
      onTap: () {
        if (isLongPressed) {
          setState(() {
            database.updateNote(Note(
              id: itemNote.id,
              content: itemNote.content,
              date: itemNote.date,
              isSelected: !itemNote.isSelected,
            ));
            !itemNote.isSelected ? selected++ : selected--;
          });
        } else {
          showGeneralDialog(
              barrierDismissible: true,
              barrierLabel: '',
              context: context,
              transitionBuilder: (context, a1, a2, widget) {
                return Transform.scale(
                  scale: a1.value,
                  child: Opacity(
                    opacity: a1.value,
                    child: AlertDialog(
                      contentPadding: const EdgeInsets.fromLTRB(
                          24.0, 10.0, 24.0, 10.0),
                      title: Text("edit note".tr()),
                      content: TextField(
                        maxLines: 10,
                        controller: noteController
                          ..text = itemNote.content,
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            hintText: "Enter your note!",
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none)),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "cancel".tr(),
                              style: const TextStyle(fontSize: 16),
                            )),
                        TextButton(
                            onPressed: () {
                              database
                                  .updateNote(Note(
                                id: itemNote.id,
                                content: noteController.text.trim(),
                                date: DateTime.now().toString(),
                                isSelected: false,
                              ))
                                  .then((value) =>
                                  Navigator.pop(context, true));
                              setState(() {});
                              noteController.clear();
                            },
                            child: Text(
                              "save".tr(),
                              style: const TextStyle(fontSize: 16),
                            )),
                      ],
                    ),
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 200),
              pageBuilder: (BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation) {
                return const SizedBox();
              });
        }
      },
      onLongPress: () {
        HapticFeedback.vibrate();
        if(!isLongPressed){
          setState(() {
            enabled = false;
            isLongPressed = true;
            database.updateNote(Note(
              id: itemNote.id,
              content: itemNote.content,
              date: itemNote.date,
              isSelected: true,
            ));
            selected = 1;
          });
        }
      },
      child: Slidable(
        enabled: enabled,

        // #delete_note
        startActionPane: ActionPane(
          extentRatio: 0.3,
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              backgroundColor: Colors.redAccent,
              label: "delete".tr(),
              onPressed: (BuildContext context) {
                setState(() {
                  selected = 1;
                });
                _androidDialogToDelete(() {
                  database.deleteNote(itemNote);
                  Navigator.pop(this.context);
                  setState(() {});
                });
              },
              icon: Icons.delete,
            ),
          ],
        ),

        // #note_view_and_selector
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          margin: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
          child: WillPopScope(
            onWillPop: () async {
              if (isLongPressed) {
                setState(() {
                  enabled = true;
                  isLongPressed = false;
                  selected = 0;
                  for (int i = 0; i < noteList.length; i++) {
                    database.updateNote(Note(
                        id: noteList[i].id,
                        content: noteList[i].content,
                        date: noteList[i].date,
                        isSelected: false));
                  }
                });
                return false;
              } else {
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else {
                  exit(0);
                }
                return false;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 12,
                      color: Colors.transparent,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      itemNote.date.substring(0, 16)
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 25,
                      child: Icon(
                        Icons.circle,
                        size: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: Text(
                      itemNote.content,
                      style: const TextStyle(
                          fontSize: 20),
                    )),
                    isLongPressed
                        ? Icon(
                            itemNote.isSelected
                                ? Icons.check_circle_outline
                                : Icons.circle_outlined,
                            size: 20,
                          )
                        : Container()
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
