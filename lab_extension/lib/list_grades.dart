import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import 'grades_model.dart';
import 'grade.dart';
import 'grade_chart.dart';
import 'grade_form.dart';

class ListGrades extends StatefulWidget {
  final String title;

  const ListGrades({Key? key, required this.title}) : super(key: key);
  @override
  _ListGradesState createState() => _ListGradesState();
}

enum SortOption { sidAsc, sidDesc, gradeAsc, gradeDesc }

class _ListGradesState extends State<ListGrades> {
  List<Grade> testGrades = []; // All grades
  List<Grade> displayedGrades = []; // Displayed grades
  String _searchQuery = '';
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _getGrades();
  }

  void _filterGrades(String query) {
    final filteredGrades = testGrades.where((grade) {
      return grade.sid.contains(query);
    }).toList();

    setState(() {
      _searchQuery = query;
      testGrades = filteredGrades;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // remembering the selection
    });
  }

  // Fetch grades from the database
  void _getGrades() async {
    var fetchedGrades = await GradesModel.instance.getAllGrades();
    setState(() {
      testGrades = fetchedGrades;
      displayedGrades = fetchedGrades; // Initially display all grades
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Triggering data fetch when the dependencies of this State object change.
    // This is called immediately after initState, and also when the widget is rebuilt with different dependencies.
    _getGrades();
  }

  // Navigate to GradeForm and wait for a result to add a grade
  void _addGrade() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GradeForm()),
    ).then((newGrade) {
      if (newGrade != null && newGrade is Grade) {
        GradesModel.instance.insertGrade(newGrade).then((_) {
          // Fetch the grades again from the database after a new grade is added.
          // This ensures the list on the homepage is updated and displays the newly added item.
          _getGrades();
        });
      }
    });
  }

  void _editGrade(Grade selectedGrade) async {
    var editedGrade = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GradeForm(grade: selectedGrade)),
    );
    if (editedGrade != null) {
      setState(() {
        int index = testGrades.indexWhere((grade) => grade.id == editedGrade.id);
        if (index != -1) {
          testGrades[index] = editedGrade as Grade;
          // Update displayedGrades if it's being used for searching or filtering
          int displayIndex = displayedGrades.indexWhere((grade) => grade.id == editedGrade.id);
          if (displayIndex != -1) {
            displayedGrades[displayIndex] = editedGrade as Grade;
          }
        }
      });
      await GradesModel.instance.updateGrade(editedGrade);
      _getGrades();
    }
  }

  void _sortGrades(SortOption option) {
    setState(() {
      switch (option) {
        case SortOption.sidAsc:
          testGrades.sort((a, b) => a.sid.compareTo(b.sid));
          break;
        case SortOption.sidDesc:
          testGrades.sort((a, b) => b.sid.compareTo(a.sid));
          break;
        case SortOption.gradeAsc:
          testGrades.sort((a, b) => a.grade.compareTo(b.grade));
          break;
        case SortOption.gradeDesc:
          testGrades.sort((a, b) => b.grade.compareTo(a.grade));
          break;
      }
    });
  }

  void _importCsv() async {
    final csvData = await rootBundle.loadString('lib/test.csv');
    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvData);

    for (final row in rowsAsListOfValues) {
      if (row[0] == 'sid') {
        continue;
      }
      final grade = Grade(
        sid: row[0].toString(),
        grade: row[1].toString(),
      );
      await GradesModel.instance.insertGrade(grade);
    }
    _getGrades(); // Refresh the list after importing
  }

  void _exportGradesToCsv() async {
    List<List<String>> csvData = [
      ['sid', 'grade'],
      ...testGrades.map((grade) => [grade.sid, grade.grade]),
    ];
    String csvString = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory(); // Correct path
    final path = '${directory.path}/grades_export.csv';
    final file = File(path);

    await file.writeAsString(csvString);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grades exported to grades_export.csv'), backgroundColor: Colors.green,),
    );
  }

  // Function to perform the search
  void _performSearch() {
    if (_searchQuery.isNotEmpty) {
      final filteredGrades = testGrades.where((grade) {
        return grade.sid.contains(_searchQuery);
      }).toList();

      setState(() {
        displayedGrades = filteredGrades;
      });
    }
  }

  void _resetSearch() {
    setState(() {
      _searchQuery = '';
      displayedGrades = testGrades; // Reset to show all grades
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton<SortOption>(
            onSelected: _sortGrades,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.sidAsc,
                child: Text('Sort by SID Ascending'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.sidDesc,
                child: Text('Sort by SID Descending'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.gradeAsc,
                child: Text('Sort by Grade Ascending'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.gradeDesc,
                child: Text('Sort by Grade Descending'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              // Navigate to the GradesChart page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GradesChart(grades: testGrades)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _importCsv, // Call the _importCsv function here
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _exportGradesToCsv,
          ),
        ],
      ),
      body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => _searchQuery = value,
                      decoration: InputDecoration(
                        labelText: 'Search by Student ID',
                        // prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _performSearch,
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _resetSearch,
                  ),
                ],
              ),
            ),
        Expanded(
          child: ListView.builder(
              itemCount: testGrades.length,
              itemBuilder: (context, index) {
                if (index < displayedGrades.length) {
                  var grade = displayedGrades[index];
                  return Dismissible(
                    key: Key(grade.id.toString()),
                    onDismissed: (direction) {
                      GradesModel.instance.deleteGradeById(grade.id!).then((_) {
                        _getGrades(); // Refresh the list after deletion
                      });
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    child: GestureDetector(
                      onLongPress: () => _editGrade(grade),
                      onTap: () => _onItemTapped(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedIndex == index ? Colors.blue[100] : null,
                          ),
                          child: ListTile(
                            title: Text(grade.sid),
                            subtitle: Text(grade.grade),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container(); // Return an empty container for safety
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addGrade,
          tooltip: 'Add Grade',
          child: const Icon(Icons.add),
      ),
    );
  }
}
