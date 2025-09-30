import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final recipes = await ApiService.getRecetas();
      final recipe = recipes.firstWhere(
        (r) => r.id == widget.recipeId,
        orElse: () => throw Exception('Receta no encontrada'),
      );
      
      setState(() {
        _recipe = recipe;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar receta: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Receta'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _recipe == null
                  ? Center(child: Text('Receta no encontrada'))
                  : _buildRecipeDetail(_recipe!),
    );
  }

  Widget _buildRecipeDetail(Recipe recipe) {
    // Convertir string de pasos a lista
    final stepsList = recipe.steps.split('\n').where((step) => step.trim().isNotEmpty).toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la receta
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade200,
              image: recipe.imageUrl.isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage(recipe.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: recipe.imageUrl.isEmpty
                ? Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade400)
                : null,
          ),
          SizedBox(height: 20),

          // Título y descripción
          Text(
            recipe.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            recipe.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 20),

          // Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(recipe.ingredients.length, 'Ingredientes'),
              _buildStatItem(stepsList.length, 'Pasos'), // 👈 Usar stepsList.length
            ],
          ),
          SizedBox(height: 30),

          // Ingredientes
          Text(
            'Ingredientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...recipe.ingredients.map((ingredient) => 
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(child: Text(ingredient)),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),

          // Pasos de preparación
          Text(
            'Preparación',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...stepsList.asMap().entries.map((entry) => // 👈 Usar stepsList
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}