import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minha localização',
      home: const LocalizacaoPage(),
    );
  }
}

class LocalizacaoPage extends StatefulWidget {
  const LocalizacaoPage({super.key});

  @override
  State<LocalizacaoPage> createState() => _LocalizacaoPageState();
}

class _LocalizacaoPageState extends State<LocalizacaoPage> {
  double latitude = 0;
  double longitude = 0;
  double latitudeCasa = -21.481503703408066;
  double longitudeCasa = -47.006311094724865;
  double distancia = 0.0;


  Future<void> buscarLocalizacao() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.deniedForever ||
        permissao == LocationPermission.denied) {
      return;
    }
    Position posicao = await Geolocator.getCurrentPosition();

    setState(() {
      latitude = posicao.latitude;
      longitude = posicao.longitude;
    });

    print('Latitude: $latitude');
    print('Longitude: $longitude');

    if (latitude == 0 || longitude == 0){
      distancia = 0.0;
    } else{
      distancia = Geolocator.distanceBetween(latitude, longitude, latitudeCasa, longitudeCasa);
    }
    print('Distancia: $distancia');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha localização')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(  
                child:
                Column(
                  children: [
                    Icon(Icons.house, size: 100, color: Colors.blue),
                    const SizedBox(height: 35),
                    const Text(
                    'Distancia entre a minha casa e a escola',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ],
                )
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text('Distancia até minha casa: ${Geolocator.distanceBetween(latitude, longitude, latitudeCasa, longitudeCasa).toStringAsFixed(2)} metros'),
                  ],
                )
              ),
              const SizedBox(height:25 ),
              Center(
                child: ElevatedButton(
                  onPressed: buscarLocalizacao,
                  child: const Text('Calcular distancia até minha casa'),                
                ),  
              ),
            ],
          ),
        ),
      ),
    );
  }
}
