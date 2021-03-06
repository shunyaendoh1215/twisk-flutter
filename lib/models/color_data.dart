import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:sqflite/sqflite.dart';
import 'package:twisk/util/database_helper.dart';
import 'dart:async';
import 'package:twisk/models/color.dart';
import 'package:intl/intl.dart';

class ColorData extends ChangeNotifier {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<ColorSetting> colorList;

  UnmodifiableListView<ColorSetting> get colors {
    return UnmodifiableListView(colorList);
  }

  int get colorListCount {
    if (this.colorList != null) {
      return colorList.length;
    }
    return 0;
  }

  void updateColorList() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) async {
      Future<List<ColorSetting>> colorListFuture =
          databaseHelper.getColorList();
      await colorListFuture.then((colorList) {
        this.colorList = colorList;
        notifyListeners();
      });
    });
  }

  void delete(BuildContext context, ColorSetting color) async {
    int result = await databaseHelper.deleteColorData();
    if (result != 0) {
      updateColorList();
    }
  }

  void updateColor(bool isDark) async {
    DatabaseHelper helper = DatabaseHelper();
    await helper.deleteColorData();
    final date = DateFormat.yMMMd().format(DateTime.now());
    if (isDark) {
      final ColorSetting color = ColorSetting(1, date);
      await helper.insertColorData(color);
    } else {
      final ColorSetting color = ColorSetting(0, date);
      await helper.insertColorData(color);
    }
    this.updateColorList();
  }

  void initializeData(BuildContext context) async {
    if (this.colorList == null) {
      this.updateColorList();
    } else if (this.colorListCount > 1) {
      if (this.colorList[0].colorMode == 0) {
        updateColor(false);
      } else {
        updateColor(true);
      }
    }
  }
}
