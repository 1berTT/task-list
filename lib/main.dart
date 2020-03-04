import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final tarefaController = TextEditingController();
  List _tarefas = [];
  Map<String, dynamic> _ultimoRemovido;
  int _posRemovido;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _tarefas = json.decode(data);
      });
    });
  }

  void addTarefa(){
    setState(() {
      Map<String, dynamic> novaTarefa = Map();
      novaTarefa["title"] = tarefaController.text;
      tarefaController.text = "";
      novaTarefa["ok"] = false;
      _tarefas.add(novaTarefa);
      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _tarefas.sort((a, b){
        if(a["ok"] && !b["ok"]){
          return 1;
        }else if(!a["ok"] && b["ok"]){
          return -1;
        }else{
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: tarefaController,
                    decoration: InputDecoration(
                          labelText: "Nova tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("Add"),
                  textColor: Colors.white,
                  onPressed: addTarefa,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh, child:
            ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _tarefas.length,
              itemBuilder: buildItem,
            ),),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_tarefas[index]["title"]),
        value: _tarefas[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_tarefas[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c){
          setState(() {
            _tarefas[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _ultimoRemovido = Map.from(_tarefas[index]);
          _posRemovido = index;
          _tarefas.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_ultimoRemovido["title"]} removida"),
            action: SnackBarAction(label: "Desfazer", onPressed: (){
              setState(() {
                _tarefas.insert(_posRemovido, _ultimoRemovido);
                _saveData();
              });
            },),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }


  Future<File> _getFile() async{
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_tarefas);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }

}
