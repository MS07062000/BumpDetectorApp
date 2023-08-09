import 'dart:async';
import 'package:bump_detector_app/bump_data_table_source.dart';
import 'package:bump_detector_app/google_sheets.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:bump_detector_app/chart_sample_data.dart';

class BumpDetectorPage extends StatefulWidget {
  const BumpDetectorPage({Key? key}) : super(key: key);

  @override
  State<BumpDetectorPage> createState() => _BumpDetectorPageState();
}

class _BumpDetectorPageState extends State<BumpDetectorPage> {
  List<ChartSampleData> chartData = [];
  String bumpValue = '';
  List<String> bumpEvents = [];
  List<List> bumpData = [];
  late TrackballBehavior _trackballBehavior;
  Gsheets gsheet = Gsheets();
  var dateFormat = DateFormat('MM/dd/yyyy HH:mm:ss');
  LocationData? location;
  late BumpDataTableSource bumpTable;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    bumpTable = BumpDataTableSource(bumpData);
    _trackballBehavior = TrackballBehavior(
        // Enables the trackball
        enable: true,
        tooltipSettings:
            const InteractiveTooltip(enable: true, color: Colors.green),
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints);
    gsheet.initializegsheets().then((value) {
      _streamSubscriptions.addAll(
        [
          Location().onLocationChanged.listen((locationData) {
            location = locationData;
          }),
          userAccelerometerEvents.listen(
            (UserAccelerometerEvent event) {
              setState(() {
                _updateChartData(
                    DateTime.now(), event.x, event.y, event.z, location!);
              });
            },
            onError: (e) {
              showDialog(
                  context: context,
                  builder: (context) {
                    return const AlertDialog(
                      title: Text("Sensor Not Found"),
                      content: Text(
                          "It seems that your device doesn't support Accelerometer Sensor"),
                    );
                  });
            },
            cancelOnError: true,
          )
        ],
      );
    }, onError: (error) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(error.toString()),
            );
          });
    });

    super.initState();
  }

  void _updateChartData(DateTime dateTime, double xValue, double yValue,
      double zValue, LocationData locationData) async {
    chartData.add(ChartSampleData(dateTime, xValue, yValue, zValue));
    if (chartData.length > 100) {
      chartData.removeAt(0);
    }
    if (zValue > 5.0) {
      // bumpValue =
      //     '$xValue $yValue $zValue latitude :${locationData.latitude} longitude :${locationData.longitude}';
      // bumpEvents.add('Bump Detected: $bumpValue');
      bumpData.add([
        xValue,
        yValue,
        zValue,
        '${locationData.latitude},${locationData.longitude}',
        dateFormat.format(dateTime),
      ]);
      bumpTable.updateData(bumpData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bump Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () {
              _dialogBuilder(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SfCartesianChart(
              trackballBehavior: _trackballBehavior,
              primaryXAxis: DateTimeAxis(
                title: AxisTitle(text: 'Time'),
              ),
              primaryYAxis: NumericAxis(
                minimum: -100, // Set the minimum value for the Y-axis
                maximum: 100, // Set the maximum value for the Y-axis
                title: AxisTitle(text: 'Accelerometer Values'),
              ),
              series: <ChartSeries<ChartSampleData, DateTime>>[
                SplineSeries<ChartSampleData, DateTime>(
                    dataSource: chartData,
                    xValueMapper: (ChartSampleData data, _) => data.time,
                    yValueMapper: (ChartSampleData data, _) =>
                        num.parse(data.xValue.toStringAsFixed(2)),
                    name: 'Accelerometer X',
                    color: Colors.red[900]),
                SplineSeries<ChartSampleData, DateTime>(
                    dataSource: chartData,
                    xValueMapper: (ChartSampleData data, _) => data.time,
                    yValueMapper: (ChartSampleData data, _) =>
                        num.parse(data.yValue.toStringAsFixed(2)),
                    name: 'Accelerometer Y',
                    color: Colors.green[900]),
                SplineSeries<ChartSampleData, DateTime>(
                    dataSource: chartData,
                    xValueMapper: (ChartSampleData data, _) => data.time,
                    yValueMapper: (ChartSampleData data, _) =>
                        num.parse(data.zValue.toStringAsFixed(2)),
                    name: 'Accelerometer Z',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.blue[900]),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  header: const Text('Bump Data Table'), // Add your header here
                  rowsPerPage: 3, // Number of rows per page
                  columnSpacing: 25,
                  columns: const [
                    DataColumn(label: Text('Sr.No.')),
                    DataColumn(label: Text('x')),
                    DataColumn(label: Text('y')),
                    DataColumn(label: Text('z')),
                    DataColumn(label: Text('Location Coordinates')),
                  ],
                  source: BumpDataTableSource(
                      bumpData), // Use the custom DataTableSource
                ),
              ),
            )
            // Expanded(
            //   child: ListView.builder(
            //     itemCount: bumpEvents.length,
            //     itemBuilder: (context, index) {
            //       return Text(
            //         bumpEvents[index],
            //       );
            //     },
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text(
            'Are you sure you want to push the data to google sheets?',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Yes'),
              onPressed: () {
                gsheet.addAll(bumpData).then((value) {
                  bumpData.clear();
                  Navigator.of(context).pop();
                });
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
