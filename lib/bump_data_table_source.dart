import 'package:flutter/material.dart';

class BumpDataTableSource extends DataTableSource {
  List<List> _bumpData;

  BumpDataTableSource(this._bumpData);

  @override
  DataRow? getRow(int index) {
    if (index >= _bumpData.length) {
      return null;
    }

    final rowData = _bumpData[index];
    return DataRow(cells: [
      DataCell(Text(index.toString())),
      DataCell(Text(rowData[0].toStringAsFixed(2))),
      DataCell(Text(rowData[1].toStringAsFixed(2))),
      DataCell(Text(rowData[2].toStringAsFixed(2))),
      DataCell(Text(rowData[3], softWrap: true)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _bumpData.length;

  @override
  int get selectedRowCount => 0;

  void updateData(List<List> newData) {
    _bumpData = newData;
    notifyListeners(); // Notify the data source about the update
  }
}
