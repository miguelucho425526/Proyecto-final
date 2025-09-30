import 'dart:convert';

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final String steps;
  final String imageUrl;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.imageUrl,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '0',
      title: json['title']?.toString() ?? 'Sin título',
      description: json['description']?.toString() ?? 'Sin descripción',
      ingredients: _parseIngredients(json['ingredients']),
      steps: json['steps']?.toString() ?? 'Sin pasos',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  static List<String> _parseIngredients(dynamic ingredients) {
    if (ingredients is List) {
      return List<String>.from(ingredients);
    }
    if (ingredients is String) {
      return ingredients.split(',').map((e) => e.trim()).toList();
    }
    return ['Sin ingredientes'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? ingredients,
    String? steps,
    String? imageUrl,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}