import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pfc_inventaza/views/piezaDetail.dart';

import '../models/Pieza.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static final navKey = GlobalKey<NavigatorState>();
  const MyApp({super.key, navKey});


  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Pieza>> listadoPiezas;
  final TextEditingController searchController = TextEditingController();

  Future<List<Pieza>> getPiezas() async {
    var url = Uri.parse("http://www.ies-azarquiel.es/paco/apiinventario/pieza");
    final response = await http.get(url);

    List<Pieza> piezas = [];

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);

      final jsonData = jsonDecode(body);

      for (var item in jsonData["piezas"]) {
        piezas.add(Pieza(
          item["CodPropietarioPieza"],
          item["CodPiezaPadre"],
          item["CodPropietario"],
          item["CodPieza"],
          item["CodNIF"],
          item["CodModelo"],
          item["Identificador"],
          item["Prestable"],
          item["Contenedor"],
          item["AltaPieza"],
        ));
      }

      return piezas;
    } else {
      throw Exception("Falló la conexión");
    }
  }

  @override
  void initState() {
    super.initState();
    listadoPiezas = getPiezas();
  }

  List<Pieza> listadoPiezasBuscador = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navKey,
      title: "Material App",
      theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xffc7e8fc)
      ),
      home: Scaffold(
          appBar: AppBar(
              title: const Text("InventAza"),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.topRight,
                        colors: <Color>[Colors.lightBlueAccent, Colors.cyanAccent])),
              )
          ),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FutureBuilder<List<Pieza>>(
                  future: listadoPiezas,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasData) {
                      listadoPiezasBuscador = snapshot.data!;
                      return TextField(
                        onChanged: (value) {
                          setState(() {
                            // Filtrar la lista según el valor de búsqueda
                            listadoPiezasBuscador = snapshot.data!
                                .where((item) => item
                                .toString().toLowerCase()
                                .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Buscar',
                          prefixIcon: Icon(Icons.search),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Text('No hay datos');
                    }
                  },
                ),
              ),
              Expanded(
                child: FutureBuilder(
                    future: listadoPiezas,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return ListView(
                          children: listPiezas(snapshot.data),
                        );
                      } else if (snapshot.hasError) {
                        if (kDebugMode) {
                          print(snapshot.error);
                        }
                        return const Text("Error");
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }),
              ),
            ],
          )
      ),
    );
  }



  List<Widget> listPiezas(List<Pieza>? data) {
    List<Widget> piezas = [];
    final context = MyApp.navKey.currentState?.overlay?.context;

    for (var pieza in data!) {
      piezas.add(Flex(
        direction: Axis.horizontal,
        children: [
          Flexible(
            child: Card(
                margin: EdgeInsets.all(6.0),
                shadowColor: Colors.grey,
                elevation: 10.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  //set border radius more than 50% of height and width to make circle
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Image.network(
                        "http://www.ies-azarquiel.es/paco/apiinventario/resources/photo/${pieza.codModelo.toString()}.jpg",
                      ),
                    ),
                    Expanded(
                        flex: 5,
                        child: Wrap(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(15.0),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 0, bottom: 130.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "PIEZA: ${pieza.codPropietario.toString()}-${pieza.codPiezaPadre.toString()}-${pieza.codNIF.toString()}",
                                          style: const TextStyle(
                                            fontSize: 18.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          pieza.identificador.toString(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Contenedor: ${pieza.codPropietario.toString()}-${pieza.codPropietarioPadre.toString()}",
                                          textScaleFactor: 1.0,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: <Widget>[
                                        TextButton(
                                          onPressed: () => {
                                            if(pieza.contenedor == "true") {
                                              Navigator.push(
                                                context!,
                                                MaterialPageRoute(builder: (context) => PiezaDetail(pieza: pieza)),
                                              )
                                            } else {
                                              showError(context!),
                                            }
                                          },
                                          style: const ButtonStyle(
                                            backgroundColor: MaterialStatePropertyAll(Colors.lightBlueAccent),
                                            elevation: MaterialStatePropertyAll(20.0),
                                            foregroundColor: MaterialStatePropertyAll(Colors.white),
                                          ),
                                          child: const Text(
                                            "Detail",
                                            style: TextStyle(
                                              decorationColor: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ]
                        )
                    ),
                  ],
                )
            ),
          )
        ],
      ));
    }
    return piezas;
  }
}


void showError(BuildContext context) {
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: const Text("Error"),
    content: const Text("Esta pieza no contiene a otras"),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}