import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notekeeper_app/screens/note_list.dart';
import 'dart:async';
import 'package:notekeeper_app/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:notekeeper_app/models/note.dart';

class NoteDetail extends StatefulWidget {
  final String appBarTitle;
  final Note note;

  NoteDetail(this.note, this.appBarTitle);

  @override
  State<StatefulWidget> createState() {
    return NoteDetailState(this.note, this.appBarTitle);
  }
}

class NoteDetailState extends State<NoteDetail> {

  static var _priorities = ["High", "Low"];

  DatabaseHelper helper = DatabaseHelper();

  String appBarTitle;
  Note note;
  NoteDetailState(this.note, this.appBarTitle);


  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.headline6;

    titleController.text = note.title;
    descriptionController.text = note.description;

    return WillPopScope(
        onWillPop: (){
          moveToLastScreen();
          return Future(() => false);
        },
        // Navigator.pop(context, false);

        child:  Scaffold(
          appBar: AppBar(
          title: Text(appBarTitle),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              moveToLastScreen();
            },
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
          child: ListView(
            children: <Widget>[
              //First Element
              ListTile(
                title: DropdownButton<String>(
                items: _priorities.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                style: textStyle,
                value: getPriorityAsString(note.priority),
                onChanged: (valueSelectedByUser) {
                  setState(() {
                    debugPrint(" Value Selected $valueSelectedByUser");
                    updatePriorityAsInt(valueSelectedByUser);
                  });
                },
              ),
            ),

            //Second Element
            Padding(
              padding: EdgeInsets.only(
                top: 15.0,
                bottom: 15.0,
              ),
              child: TextFormField(
                style: textStyle,
                controller: titleController,
                onChanged: (value) {
                  debugPrint("Some changed in TextFiled 1");
                  updateTitle();
                },
                decoration: InputDecoration(
                  labelText: "Title",
                  labelStyle: textStyle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.indigo,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),

            //Third Element
            Padding(
              padding: EdgeInsets.only(
                top: 15.0,
                bottom: 15.0,
              ),
              child: TextFormField(
                style: textStyle,
                controller: descriptionController,
                onChanged: (value) {
                  debugPrint("Some changed in TextFiled 2");
                  updateDescription();
                },
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: textStyle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.indigo,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),

            //Fourth Element
            Padding(
              padding: EdgeInsets.only(
                top: 15.0,
                bottom: 15.0,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).primaryColorDark),
                        textStyle: MaterialStateProperty.all(TextStyle(
                            color: Theme.of(context).primaryColorLight)),
                      ),
                      child: Text(
                        "Save",
                        textScaleFactor: 1.3,
                      ),
                      onPressed: () {
                        setState(() {
                          debugPrint("Save button clicked");
                          _save();
                        });
                      },
                    ),
                  ),
                  Container(
                    width: 5.0,
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).primaryColorDark),
                        textStyle: MaterialStateProperty.all(TextStyle(
                            color: Theme.of(context).primaryColorLight)),
                      ),
                      child: Text(
                        "Delete",
                        textScaleFactor: 1.3,
                      ),
                      onPressed: () {
                        setState(() {
                          debugPrint("Delete Button Clicked");
                          _delete();
                        });
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }
  void moveToLastScreen(){
    Navigator.pop(context, true);
  }

  //Convert the string priority in the form of integer before saving it to the database
  void updatePriorityAsInt(String value){
    switch(value){
      case 'High':
        note.priority = 1;
        break;
      case 'Low':
        note.priority = 2;
        break;
    }
  }
  //Convert the int priority to string priority and display it to ser in dropdown
  String getPriorityAsString(int value){
    String priority;
    switch(value){
      case 1:
        return _priorities[0]; //high
        break;
      case 2:
        return _priorities[1];  //low
        break;
    }
  }

  //update the title of note object
  void updateTitle(){
    note.title = titleController.text;
  }

  //update the description of note object
  void updateDescription(){
    note.description = descriptionController.text;
  }

  void _save() async{

    moveToLastScreen();
    note.date = DateFormat.yMMMd().format(DateTime.now()); 
    int result;
    if(note.id != null){
      //Case 1 : update operation
      result = await helper.updateNote(note);
    }
    else{
      //case 2: insert operation
      result = await helper.insertNote(note);
    }

    if(result != 0){
      //Success
      _showAlertDialog('Status','Note Saved Successfully');
    }
    else{
      //failure
      _showAlertDialog('Status','Problem Saving Note');
    }
  }

  void _delete() async{

    moveToLastScreen();
    // Case 1 - If user is trying to delete NEW NOTE ,i.e, he has come to the detail page by pressing the FAB of NoteList page.
    if(note.id == null){
      _showAlertDialog('Status', 'No Note was Deleted');
      return;
    }
    //Case 2 - User is trying to delete the old note that already has a valid ID.
    int result = await helper.deleteNote(note.id);
    if(result != 0){
      _showAlertDialog('Status', 'Note Deleted Successfully');
    }
    else{
      _showAlertDialog('Status', 'Error  Occurred while Deleting Note');
    }
  }

  void _showAlertDialog(String title, String message){

    AlertDialog alertDialog = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(
      context: context,
      builder: (_) => alertDialog,
    );
  }
}
