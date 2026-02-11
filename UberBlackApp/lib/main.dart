import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(UberBlackHourlyFlowApp());

class RegionHourlyData {
  final String region;
  final int startHour;
  final int endHour;
  final double avgValue;
  final double blackMovement;
  final double returnChance;
  final LatLng center;

  RegionHourlyData({
    required this.region,
    required this.startHour,
    required this.endHour,
    required this.avgValue,
    required this.blackMovement,
    required this.returnChance,
    required this.center,
  });
}

class UberBlackHourlyFlowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber Black Hourly Flow',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MapHourlyFlowPage(),
    );
  }
}

class MapHourlyFlowPage extends StatefulWidget {
  @override
  _MapHourlyFlowPageState createState() => _MapHourlyFlowPageState();
}

class _MapHourlyFlowPageState extends State<MapHourlyFlowPage> {
  late GoogleMapController _mapController;
  double kmPerLiter = 5.5;
  double fuelPrice = 4.39;
  double fixedCostPerRide = 7.0;
  double lastDistanceKm = 10;
  double lastValue = 38;
  double profit = 0;
  String alert = '';
  String? selectedRegion;

  List<RegionHourlyData> regions = [
    RegionHourlyData(
      region: 'Tatuapé',
      startHour: 6,
      endHour: 9,
      avgValue: 38,
      blackMovement: 0.8,
      returnChance: 0.7,
      center: LatLng(-23.545, -46.573),
    ),
    RegionHourlyData(
      region: 'Tatuapé',
      startHour: 17,
      endHour: 20,
      avgValue: 42,
      blackMovement: 0.9,
      returnChance: 0.6,
      center: LatLng(-23.545, -46.573),
    ),
    RegionHourlyData(
      region: 'Mooca',
      startHour: 6,
      endHour: 9,
      avgValue: 36,
      blackMovement: 0.6,
      returnChance: 0.65,
      center: LatLng(-23.565, -46.605),
    ),
    RegionHourlyData(
      region: 'Mooca',
      startHour: 17,
      endHour: 20,
      avgValue: 40,
      blackMovement: 0.7,
      returnChance: 0.7,
      center: LatLng(-23.565, -46.605),
    ),
  ];

  void _onRegionTapped(RegionHourlyData regionData) {
    selectedRegion = regionData.region;
    double fuelCost = (lastDistanceKm / kmPerLiter) * fuelPrice;
    profit = regionData.avgValue - fuelCost - fixedCostPerRide;

    if (profit >= 25 && regionData.blackMovement >= 0.7 && regionData.returnChance >= 0.6) {
      alert = 'VERDE: Vale a pena ir!';
    } else if (profit >= 15 && regionData.blackMovement >= 0.5 && regionData.returnChance >= 0.5) {
      alert = 'AMARELO: Pode arriscar';
    } else {
      alert = 'VERMELHO: Não vale a pena';
    }

    setState(() {});
  }

  RegionHourlyData? getNextRegionSuggestion() {
    int hour = DateTime.now().hour;
    RegionHourlyData? best;
    double maxScore = 0;
    for (var r in regions) {
      if (r.startHour <= hour && r.endHour >= hour && r.region != selectedRegion) {
        double score = r.avgValue * r.blackMovement * r.returnChance;
        if (score > maxScore) {
          maxScore = score;
          best = r;
        }
      }
    }
    return best;
  }

  void openWaze(String regionName) async {
    String url = 'waze://?q=$regionName&navigate=yes';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível abrir Waze')));
    }
  }

  @override
  Widget build(BuildContext context) {
    RegionHourlyData? nextRegion = getNextRegionSuggestion();

    return Scaffold(
      appBar: AppBar(title: Text('Uber Black Hourly Flow')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: LatLng(-23.55, -46.60), zoom: 12),
              polygons: regions.map((r) => Polygon(
                polygonId: PolygonId(r.region + r.startHour.toString()),
                points: [
                  LatLng(r.center.latitude + 0.005, r.center.longitude + 0.005),
                  LatLng(r.center.latitude + 0.005, r.center.longitude - 0.005),
                  LatLng(r.center.latitude - 0.005, r.center.longitude - 0.005),
                  LatLng(r.center.latitude - 0.005, r.center.longitude + 0.005),
                ],
                fillColor: Colors.green.withOpacity(0.4),
                strokeColor: Colors.green,
                strokeWidth: 2,
              )).toSet(),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (LatLng pos) {
                for (var r in regions) {
                  if ((pos.latitude - r.center.latitude).abs() < 0.005 && (pos.longitude - r.center.longitude).abs() < 0.005) {
                    _onRegionTapped(r);
                  }
                }
              },
            ),
          ),
          if (selectedRegion != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Região atual: $selectedRegion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Lucro líquido estimado: R\$${profit.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                  Text(alert, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ElevatedButton(onPressed: () => openWaze(selectedRegion!), child: Text('Abrir Waze para região')), 
                  if (nextRegion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Próxima região sugerida: ${nextRegion.region}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
