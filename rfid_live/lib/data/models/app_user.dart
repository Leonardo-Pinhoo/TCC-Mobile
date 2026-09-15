import 'package:flutter/material.dart';

@immutable
class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    this.role = 'Operacao',
    this.plant = 'Planta Industrial - Unidade 1',
  });

  final String name;
  final String email;
  final String role;
  final String plant;

  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Map<String, String> toJson() => <String, String>{
        'name': name,
        'email': email,
        'role': role,
        'plant': plant,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        name: (json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        role: (json['role'] ?? 'Operacao') as String,
        plant: (json['plant'] ?? 'Planta Industrial - Unidade 1') as String,
      );
}
