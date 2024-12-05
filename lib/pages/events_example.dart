import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadMemos() async {
    try {
      QuerySnapshot groupSnapshot = await _firestore.collection('groups').get();
      List<Map<String, dynamic>> memos = [];
      for (var groupDoc in groupSnapshot.docs) {
        if (groupDoc.exists) {
          QuerySnapshot memoSnapshot = await groupDoc.reference.collection('memos').get();
          for (var memoDoc in memoSnapshot.docs) {
            if (memoDoc.exists) {
              memos.add({
                'group': groupDoc.id,
                'title': memoDoc['title'],
                'content': memoDoc['content'],
                'id': memoDoc.id
              });
            }
          }
        }
      }
      return memos;
    } catch (e) {
      print('Error loading memos: $e');
      return [];
    }
  }

  Future<List<String>> loadGroups() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('groups').get();
      List<String> groups = [];
      querySnapshot.docs.forEach((doc) {
        if (doc.exists) {
          groups.add(doc.id);
        }
      });
      return groups;
    } catch (e) {
      print('Error loading groups: $e');
      return [];
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: GoogleKeepClone(),
  ));
}

class GoogleKeepClone extends StatefulWidget {
  @override
  _GoogleKeepCloneState createState() => _GoogleKeepCloneState();
}

class _GoogleKeepCloneState extends State<GoogleKeepClone> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> _memos = [];
  List<Map<String, dynamic>> _filteredMemos = [];
  List<String> _groups = [];
  FirebaseService _firebaseService = FirebaseService();
  String _selectedGroup = '전체';

  @override
  void initState() {
    super.initState();
    _loadMemos();
    _loadGroups();
  }

  Future<void> _loadMemos() async {
    List<Map<String, dynamic>> memos = await _firebaseService.loadMemos();
    setState(() {
      _memos = memos;
      _filteredMemos = List.from(memos);
    });
  }

  Future<void> _loadGroups() async {
    List<String> groups = await _firebaseService.loadGroups();
    setState(() {
      _groups = groups;
      _groups.insert(0, '전체');
    });
  }

  void _updateMemo(Map<String, dynamic> memo, String newTitle, String newContent) async {
    setState(() {
      memo['title'] = newTitle;
      memo['content'] = newContent;
    });

    DocumentReference memoRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(memo['group'])
        .collection('memos')
        .doc(memo['id']);
    await memoRef.update({
      'title': newTitle,
      'content': newContent,
    });
  }

  void _editMemo(Map<String, dynamic> memo) {
    String title = memo['title'];
    String content = memo['content'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("메모 수정"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: title),
                onChanged: (value) {
                  title = value;
                },
                decoration: InputDecoration(hintText: "제목을 입력하세요."),
              ),
              TextField(
                controller: TextEditingController(text: content),
                onChanged: (value) {
                  content = value;
                },
                maxLines: null,
                decoration: InputDecoration(hintText: "내용을 입력하세요."),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                if (title.isNotEmpty) {
                  _updateMemo(memo, title, content);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('제목을 입력하세요.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text("저장"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addGroup(String group) async {
    DocumentReference groupRef = FirebaseFirestore.instance.collection('groups').doc(group);
    await groupRef.set({'memos': []});
    setState(() {
      _groups.add(group);
    });
  }

  Future<void> _deleteGroup(String groupName) async {
    await FirebaseFirestore.instance.collection('groups').doc(groupName).delete();
    setState(() {
      _groups.remove(groupName);
      if (_selectedGroup == groupName) {
        _selectedGroup = '전체';
        _filteredMemos = List.from(_memos);
      }
    });
  }

  Future<void> _deleteMemo(String groupId, String memoId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('memos')
        .doc(memoId)
        .delete();
    setState(() {
      _memos.removeWhere((memo) => memo['id'] == memoId);
      _filteredMemos.removeWhere((memo) => memo['id'] == memoId);
    });
  }

  void _showCreateGroupMenu() {
    String newGroup = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("그룹 추가"),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              newGroup = value;
            },
            decoration: InputDecoration(hintText: "그룹명을 입력하세요."),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                if (newGroup.isNotEmpty) {
                  await _addGroup(newGroup);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('그룹명을 입력하세요.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text("추가"),
            ),
          ],
        );
      },
    );
  }

  void _filterMemos(String query) {
    setState(() {
      _filteredMemos = _memos
          .where((memo) =>
      memo['title'].toLowerCase().contains(query.toLowerCase()) ||
          memo['content'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _filterByGroup(String group) {
    setState(() {
      _selectedGroup = group;
      if (group == '전체') {
        _filteredMemos = List.from(_memos);
      } else {
        _filteredMemos = _memos.where((memo) => memo['group'] == group).toList();
      }
    });
  }

  Future<void> _addMemo(String title, String content, String group) async {
    DocumentReference groupRef = FirebaseFirestore.instance.collection('groups').doc(group);
    DocumentReference memoRef = groupRef.collection('memos').doc();
    String memoId = memoRef.id;
    Map<String, dynamic> newMemo = {
      'title': title,
      'content': content,
      'id': memoId
    };
    await memoRef.set(newMemo);
    setState(() {
      _memos.add({
        'group': group,
        'title': title,
        'content': content,
        'id': memoId
      });
      if (_selectedGroup == group || _selectedGroup == '전체') {
        _filteredMemos.add({
          'group': group,
          'title': title,
          'content': content,
          'id': memoId
        });
      }
      _saveMemos();
    });
  }

  void _saveMemos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('memos', jsonEncode(_memos));
  }

  void _showCreateMemoDialog(String group) {
    String title = '';
    String content = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("메모 추가"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: InputDecoration(hintText: "제목을 입력하세요."),
              ),
              TextField(
                onChanged: (value) {
                  content = value;
                },
                maxLines: null,
                decoration: InputDecoration(hintText: "내용을 입력하세요."),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () async {
                if (title.isNotEmpty) {
                  await _addMemo(title, content, group);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('제목을 입력하세요.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text("추가"),
            ),
          ],
        );
      },
    );
  }

  void _showGroupMenu(String group) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.add),
                title: Text('메모 추가'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateMemoDialog(group);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('그룹 수정'),
                onTap: () {
                  Navigator.pop(context);
                  _editGroup(group);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('그룹 삭제'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteGroup(group);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editGroup(String group) {
    String updatedGroup = group;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("그룹 수정"),
          content: TextField(
            onChanged: (value) {
              updatedGroup = value;
            },
            controller: TextEditingController(text: group),
            decoration: InputDecoration(hintText: "새 그룹명을 입력하세요."),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                if (updatedGroup.isNotEmpty) {
                  setState(() {
                    int index = _groups.indexOf(group);
                    _groups[index] = updatedGroup;
                    _memos.forEach((memo) {
                      if (memo['group'] == group) {
                        memo['group'] = updatedGroup;
                      }
                    });
                    _filteredMemos.forEach((memo) {
                      if (memo['group'] == group) {
                        memo['group'] = updatedGroup;
                      }
                    });
                    _saveMemos();
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text("저장"),
            ),
          ],
        );
      },
    );
  }

  void _showMemoDetail(Map<String, dynamic> memo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(memo['title']),
          content: Text(memo['content']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("닫기"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공유 메모장'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _MemoSearch(
                  memos: _memos,
                  showMemoDetail: _showMemoDetail,
                  deleteMemo: _deleteMemo,
                  filteredMemos: _filteredMemos,
                  titleController: _titleController,
                  contentController: _contentController,
                  searchController: _searchController,
                  showGroupMenu: _showGroupMenu,
                  showCreateMemoDialog: _showCreateMemoDialog,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showCreateGroupMenu();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _filterByGroup(_groups[index]);
                  },
                  onLongPress: () {
                    _showGroupMenu(_groups[index]);
                  },
                  child: Chip(
                    label: Text(_groups[index]),
                    backgroundColor: _selectedGroup == _groups[index]
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredMemos.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _filteredMemos[index]['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    _editMemo(_filteredMemos[index]);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteMemo(_filteredMemos[index]['group'], _filteredMemos[index]['id']);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _filteredMemos[index]['content'],
                          style: TextStyle(fontSize: 16),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoSearch extends SearchDelegate<String> {
  final List<Map<String, dynamic>> memos;
  final Function(Map<String, dynamic>) showMemoDetail;
  final Function(String, String) deleteMemo;
  final List<Map<String, dynamic>> filteredMemos;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController searchController;
  final Function(String) showGroupMenu;
  final Function(String) showCreateMemoDialog;

  _MemoSearch({
    required this.memos,
    required this.showMemoDetail,
    required this.deleteMemo,
    required this.filteredMemos,
    required this.titleController,
    required this.contentController,
    required this.searchController,
    required this.showGroupMenu,
    required this.showCreateMemoDialog,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          searchController.clear();
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(query);
  }

  Widget _buildSearchResults(String query) {
    if (query.isEmpty) {
      return SizedBox();
    }

    final List<Map<String, dynamic>> filteredResults = memos.where((memo) =>
    memo['title'].toLowerCase().contains(query.toLowerCase()) ||
        memo['content'].toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(filteredResults[index]['title']),
          onTap: () {
            showMemoDetail(filteredResults[index]);
            close(context, '');
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showMemoDetail(filteredResults[index]);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  deleteMemo(filteredResults[index]['group'], filteredResults[index]['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
