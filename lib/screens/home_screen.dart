import 'package:flutter/material.dart';
import 'dart:async';
import '../models/recipe.dart';
import '../models/user.dart';
import '../widgets/recipe_card.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Future<void> Function() toggleTheme;
  final int userId;
  
  const HomeScreen({
    Key? key, 
    required this.toggleTheme,
    required this.userId,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Recipe> _recipes = [];
  bool _loading = true;
  String _error = '';
  Timer? _refreshTimer;
  late AnimationController _refreshController;
  bool _isRefreshing = false;
  bool _isLoading = false;
  User? _currentUser;
  bool _userLoading = true;

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    Future.delayed(Duration(milliseconds: 100), () {
      _loadRecipesFromBackend();
      _loadUserData();
    });

    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted && !_isLoading) {
        print('🔄 Actualización automática de recetas...');
        _loadRecipesFromBackend(silent: true);
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = await UserService.getUserById(widget.userId);
      setState(() {
        _currentUser = user;
        _userLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando datos del usuario: $e');
      setState(() {
        _userLoading = false;
      });
    }
  }

  Future<void> _loadRecipesFromBackend({bool silent = false}) async {
    if (_isLoading) {
      print('⏳ Ya se está cargando, ignorando llamada...');
      return;
    }

    try {
      _isLoading = true;
      print("🏠 HomeScreen: Iniciando carga de recetas...");

      if (!silent && mounted) {
        setState(() {
          _loading = true;
          _error = '';
        });
      }

      final recipes = await ApiService.getRecetas().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('La conexión tardó demasiado (10 segundos)');
        },
      );

      print("🏠 HomeScreen: Recetas cargadas: ${recipes.length}");

      if (!mounted) return;

      for (var recipe in recipes) {
        print(
          "🍳 Receta: ${recipe.title} - ${recipe.ingredients.length} ingredientes",
        );
      }

      if (mounted) {
        setState(() {
          _recipes = recipes;
          _loading = false;
          _error = '';
        });
      }

      print("🏠 HomeScreen: Estado actualizado");
    } on TimeoutException catch (e) {
      print("⏰ HomeScreen: TIMEOUT: $e");
      if (!mounted) return;

      setState(() {
        _error = 'Tiempo de espera agotado. Verifica tu conexión.';
        _loading = false;
      });

      if (!silent) {
        _showSnackBar(
          'Error: El servidor no respondió a tiempo',
          Colors.orange,
        );
      }
    } catch (e) {
      print("❌ HomeScreen: ERROR: $e");

      if (!mounted) return;

      setState(() {
        _error = 'Error al cargar recetas: ${e.toString()}';
        _loading = false;
      });

      if (!silent) {
        _showSnackBar('Error al cargar recetas', Colors.red);
      }
    } finally {
      _isLoading = false;
    }
  }

  bool _hasChanges(List<Recipe> oldRecipes, List<Recipe> newRecipes) {
    if (oldRecipes.length != newRecipes.length) return true;

    for (int i = 0; i < oldRecipes.length; i++) {
      if (oldRecipes[i].id != newRecipes[i].id ||
          oldRecipes[i].title != newRecipes[i].title) {
        return true;
      }
    }
    return false;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addRecipe() async {
    final newRecipe = await Navigator.of(
      context,
    ).push<Recipe>(MaterialPageRoute(builder: (_) => AddRecipeScreen()));

    if (newRecipe != null && mounted) {
      try {
        setState(() {
          _loading = true;
        });

        final createdRecipe = await ApiService.crearReceta(
          newRecipe,
        ).timeout(Duration(seconds: 10));

        if (mounted) {
          setState(() {
            _recipes.insert(0, createdRecipe);
            _loading = false;
          });
        }

        _showSnackBar('Receta creada exitosamente', Colors.green);
        _loadRecipesFromBackend(silent: true);
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        _showSnackBar('Error al crear receta: $e', Colors.red);
      }
    }
  }

  void _toggleFavorite(String recipeId) {
    if (!mounted) return;

    setState(() {
      _recipes = _recipes.map((recipe) {
        if (recipe.id == recipeId) {
          return recipe.copyWith(isFavorite: !recipe.isFavorite);
        }
        return recipe;
      }).toList();
    });
  }

  Future<bool> _deleteRecipe(int index) async {
    final recipe = _recipes[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Eliminar receta',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Eliminar "${recipe.title}"?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ApiService.eliminarReceta(
          recipe.id,
        ).timeout(Duration(seconds: 10));

        if (mounted) {
          setState(() {
            _recipes.removeAt(index);
          });
        }

        _showSnackBar('Receta eliminada', Colors.orange);
        _loadRecipesFromBackend(silent: true);
        return true;
      } catch (e) {
        _showSnackBar('Error al eliminar: $e', Colors.red);
        return false;
      }
    }

    return false;
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing || _isLoading) return;

    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    _refreshController.repeat();

    await _loadRecipesFromBackend();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
    _refreshController.stop();
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.userId),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(fontFamily: 'Poppins')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout();
              },
              child: Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    _showSnackBar('Sesión cerrada exitosamente', Colors.green);

    print('🔐 Sesión cerrada - Usuario desconectado');

    Future.delayed(Duration(milliseconds: 1500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Mis Recetas',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: RotationTransition(
                  turns: Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(_refreshController),
                  child: Icon(Icons.refresh_rounded),
                ),
                onPressed: _isLoading ? null : _manualRefresh,
                tooltip: 'Actualizar recetas',
              ),
              if (_isRefreshing)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.brightness_6_rounded),
            onPressed: () => widget.toggleTheme(),
            tooltip: 'Cambiar tema',
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(
              Icons.autorenew_rounded,
              size: 18,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecipe,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add_rounded, size: 28),
        tooltip: 'Agregar receta',
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _userLoading 
                      ? 'Cargando...' 
                      : _currentUser?.username ?? 'Mi Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _userLoading 
                      ? '' 
                      : _currentUser?.email ?? 'Usuario',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      ),
                      child: Text(
                        'Ver Perfil',
                        style: TextStyle(
                          fontSize: 12, 
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Inicio',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Mi Perfil',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToProfile();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_circle_rounded,
                    title: 'Agregar receta',
                    onTap: () {
                      Navigator.pop(context);
                      _addRecipe();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_rounded,
                    title: 'Favoritos',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Funcionalidad en desarrollo', Colors.blue);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Configuración',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Configuración en desarrollo', Colors.blue);
                    },
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.grey.shade300),
                  ),

                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar Sesión',
                    color: Colors.red.shade600,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Actualización automática cada 15 segundos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.green.shade700;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: itemColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: itemColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.green.shade700,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Cargando recetas...',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Oops! Algo salió mal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _manualRefresh,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'No hay recetas disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Comienza agregando tu primera receta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addRecipe,
                icon: Icon(Icons.add_rounded),
                label: Text('Agregar primera receta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _isLoading ? () async {} : _manualRefresh,
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: Colors.green.shade700,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.green.shade100, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.autorenew_rounded,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                SizedBox(width: 8),
                Text(
                  'Actualización automática activa',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${_recipes.length} recetas',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(recipe.id),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.delete_rounded,
                        color: Colors.red.shade600,
                      ),
                    ),
                    direction: DismissDirection.startToEnd,
                    confirmDismiss: (direction) async {
                      return await _deleteRecipe(index);
                    },
                    child: RecipeCard(
                      recipe: recipe,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetailScreen(recipeId: recipe.id),
                          ),
                        );
                        _loadRecipesFromBackend(silent: true);
                      },
                      onFavorite: () {
                        _toggleFavorite(recipe.id);
                      },
                      onDelete: () {
                        _deleteRecipe(index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}