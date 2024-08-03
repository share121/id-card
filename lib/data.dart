import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'addr_code.dart';

enum Gender { male, female, unknown }

class Controller extends GetxController {
  final idCard = ''.obs;
  final gender = Gender.unknown.obs;
  final idTextBoxKey = GlobalKey<FormState>();
  final list = <String>[].obs;
  final cache = <String, List<String>>{};

  @override
  void onInit() {
    super.onInit();
    everAll([idCard, gender], (_) {
      list.clear();
      completion();
      cache[idCard().toUpperCase() + gender().name] =
          list.toList(growable: false);
    });
  }

  void completion() {
    if (idCard.isEmpty) return;
    final key = idCard().toUpperCase() + gender().name;
    if (cache.containsKey(key)) return list.addAll(cache[key]!);
    final a = idCard
        .split('')
        .map((e) => e == 'X' || e == 'x' ? 10 : int.tryParse(e))
        .toList();
    final nullPos =
        a.indexed.where((e) => e.$2 == null).map((e) => e.$1).toList();
    if (nullPos.isEmpty) {
      if (isIdCard(a.cast(), gender())) {
        list.add(idCard());
      } else {
        return;
      }
    }
    final hasCheckCode = a[17] != null;

    void t(List<int> nullPos) {
      if (nullPos.length > 1) {
        final v = nullPos[0], list = nullPos.sublist(1);
        for (var i = 0; i < 10; i++) {
          a[v] = i;
          t(list);
        }
      } else if (nullPos.length == 1) {
        if (hasCheckCode) {
          final v = nullPos[0];
          for (var i = 0; i < 10; i++) {
            a[v] = i;
            if (isIdCard(a.cast(), gender())) {
              list.add(a.map((e) => e == 10 ? 'X' : '$e').join());
            }
          }
        } else {
          a[17] = genCheckCode(a.take(17).toList().cast());
          if (isIdCard(a.cast(), gender(), false)) {
            list.add(a.map((e) => e == 10 ? 'X' : '$e').join());
          }
        }
      }
    }

    t(nullPos);
  }

  int genCheckCode(List<int> a) {
    const W = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    const c = [1, 0, 10, 9, 8, 7, 6, 5, 4, 3, 2];
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      sum += a[i] * W[i];
    }
    return c[sum % 11];
  }

  bool isIdCard(List<int> a, Gender gender, [needCompute = true]) {
    if (gender == Gender.male && a[16] % 2 == 0 ||
        gender == Gender.female && a[16] % 2 == 1) return false;
    final addr = a[0] * 100000 +
        a[1] * 10000 +
        a[2] * 1000 +
        a[3] * 100 +
        a[4] * 10 +
        a[5];
    if (!addrCode.contains(addr)) return false;
    final year = a[6] * 1000 + a[7] * 100 + a[8] * 10 + a[9];
    var yearNow = DateTime.now().year;
    if (year > yearNow || year < yearNow - 150) return false;
    final month = a[10] * 10 + a[11];
    if (month < 1 || month > 12) return false;
    final day = a[12] * 10 + a[13];
    final maxDay = [
      31,
      year % 4 == 0 && year % 100 != 0 || year % 400 == 0 ? 29 : 28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31
    ];
    if (day < 1 || day > maxDay[month - 1]) return false;
    if (!needCompute) return true;
    const W = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2, 1];
    var sum = 0;
    for (var i = 0; i < 18; i++) {
      sum += a[i] * W[i];
    }
    return sum % 11 == 1;
  }
}

extension Use<V> on V? {
  T? use<T>(T Function(V value) fn) => this == null ? null : fn(this as V);
}

extension Num2Duration on num {
  Duration get microseconds => Duration(microseconds: toInt());
  Duration get ms => (this * 1000).microseconds;
  Duration get s => (this * 1000).ms;
  Duration get min => (this * 60).s;
  Duration get hour => (this * 60).min;
  Duration get day => (this * 24).hour;
  Duration get week => (this * 7).day;
}
