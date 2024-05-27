import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  runApp(RecipeBookApp());
}

class RecipeBookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Book',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: SplashScreen(),
    );
  }
}

class InMemoryStorage {
  static Map<String, String> _storage = {};

  static String? getItem(String key) {
    return _storage[key];
  }

  static void setItem(String key, String value) {
    _storage[key] = value;
  }

  static void removeItem(String key) {
    _storage.remove(key);
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
                'https://m.media-amazon.com/images/I/71b786dimUL._AC_UF1000,1000_QL80_.jpg'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Continue to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if ((username == 'admin' && password == 'admin') ||
        (username == 'user' && password == 'user')) {
      InMemoryStorage.setItem('role', username == 'admin' ? 'admin' : 'user');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeBookScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SplashScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeBookScreen extends StatefulWidget {
  @override
  _RecipeBookScreenState createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends State<RecipeBookScreen> {
  List<RecipeItem> _recipeItems = [];
  bool _sortAscending = true;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadRole();
  }

  void _loadRecipes() {
    final recipes = InMemoryStorage.getItem('recipes') ?? '[]';
    setState(() {
      _recipeItems = (json.decode(recipes) as List)
          .map((data) => RecipeItem.fromJson(data))
          .toList();
    });
  }

  void _saveRecipes() {
    final recipes =
        json.encode(_recipeItems.map((item) => item.toJson()).toList());
    InMemoryStorage.setItem('recipes', recipes);
  }

  void _loadRole() {
    setState(() {
      _role = InMemoryStorage.getItem('role') ?? 'user';
    });
  }

  Future<void> _addRecipe() async {
    if (_role != 'admin') return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String recipeName = '';
        List<String> ingredients = [];
        List<String> instructions = [];
        String imageUrl = '';

        final TextEditingController ingredientController =
            TextEditingController();
        final TextEditingController instructionController =
            TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Recipe'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Recipe Name'),
                      onChanged: (value) {
                        recipeName = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Image URL'),
                      onChanged: (value) {
                        imageUrl = value;
                      },
                    ),
                    TextField(
                      controller: ingredientController,
                      decoration: InputDecoration(labelText: 'Ingredient'),
                      onSubmitted: (value) {
                        setState(() {
                          ingredients.add(value);
                          ingredientController.clear();
                        });
                      },
                    ),
                    Wrap(
                      children: ingredients.map((ingredient) {
                        return Chip(
                          label: Text(ingredient),
                          onDeleted: () {
                            setState(() {
                              ingredients.remove(ingredient);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: instructionController,
                      decoration: InputDecoration(labelText: 'Instruction'),
                      onSubmitted: (value) {
                        setState(() {
                          instructions.add(value);
                          instructionController.clear();
                        });
                      },
                    ),
                    Column(
                      children: List.generate(
                        instructions.length,
                        (index) => ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(instructions[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                instructions.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      final newRecipe = RecipeItem(
                        recipeName: recipeName,
                        ingredients: ingredients,
                        instructions: instructions,
                        imageUrl: imageUrl,
                      );
                      _recipeItems.add(newRecipe);
                      _saveRecipes();
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editRecipe(int index) async {
    if (_role != 'admin') return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String editedRecipeName = _recipeItems[index].recipeName;
        List<String> editedIngredients =
            List.from(_recipeItems[index].ingredients);
        List<String> editedInstructions =
            List.from(_recipeItems[index].instructions);
        String editedImageUrl = _recipeItems[index].imageUrl;

        final TextEditingController ingredientController =
            TextEditingController();
        final TextEditingController instructionController =
            TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Recipe'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Recipe Name'),
                      onChanged: (value) {
                        editedRecipeName = value;
                      },
                      controller: TextEditingController(text: editedRecipeName),
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Image URL'),
                      onChanged: (value) {
                        editedImageUrl = value;
                      },
                      controller: TextEditingController(text: editedImageUrl),
                    ),
                    TextField(
                      controller: ingredientController,
                      decoration: InputDecoration(labelText: 'Ingredient'),
                      onSubmitted: (value) {
                        setState(() {
                          editedIngredients.add(value);
                          ingredientController.clear();
                        });
                      },
                    ),
                    Wrap(
                      children: editedIngredients.map((ingredient) {
                        return Chip(
                          label: Text(ingredient),
                          onDeleted: () {
                            setState(() {
                              editedIngredients.remove(ingredient);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: instructionController,
                      decoration: InputDecoration(labelText: 'Instruction'),
                      onSubmitted: (value) {
                        setState(() {
                          editedInstructions.add(value);
                          instructionController.clear();
                        });
                      },
                    ),
                    Column(
                      children: List.generate(
                        editedInstructions.length,
                        (index) => ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(editedInstructions[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                editedInstructions.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recipeItems[index].recipeName = editedRecipeName;
                      _recipeItems[index].ingredients = editedIngredients;
                      _recipeItems[index].instructions = editedInstructions;
                      _recipeItems[index].imageUrl = editedImageUrl;
                      _saveRecipes();
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRecipe(int index) async {
    setState(() {
      _recipeItems.removeAt(index);
      _saveRecipes();
    });
  }

  void _toggleSort() {
    setState(() {
      _sortAscending = !_sortAscending;
      _recipeItems.sort((a, b) => _sortAscending
          ? a.recipeName.compareTo(b.recipeName)
          : b.recipeName.compareTo(a.recipeName));
    });
  }

  @override
  Widget build(BuildContext context) {
    List<RecipeItem> _filteredRecipeItems = _recipeItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Book'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _toggleSort,
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: RecipeSearchDelegate(_recipeItems),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredRecipeItems.length,
        itemBuilder: (BuildContext context, int index) {
          return Dismissible(
            key: Key(_filteredRecipeItems[index].recipeName),
            onDismissed: (direction) {
              if (_role == 'admin') _deleteRecipe(index);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(
                      recipe: _filteredRecipeItems[index],
                    ),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    Image.network(
                      _filteredRecipeItems[index].imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    ListTile(
                      title: Text(
                        _filteredRecipeItems[index].recipeName,
                        style: TextStyle(fontSize: 20),
                      ),
                      trailing: _role == 'admin'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    _editRecipe(index);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteRecipe(index);
                                  },
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _role == 'admin'
          ? FloatingActionButton(
              onPressed: _addRecipe,
              child: Icon(Icons.add),
            )
          : null,
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_role == 'admin' ? 'Admin' : 'User'),
              accountEmail: Text('email@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _role == 'admin' ? 'A' : 'U',
                  style: TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                InMemoryStorage.removeItem('role');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailScreen extends StatefulWidget {
  final RecipeItem recipe;

  RecipeDetailScreen({required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  List<bool> _checkedIngredients = [];

  @override
  void initState() {
    super.initState();
    _checkedIngredients =
        List<bool>.filled(widget.recipe.ingredients.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.recipeName),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.network(
              widget.recipe.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16.0),
            Text(
              'Ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...widget.recipe.ingredients.asMap().entries.map((entry) {
              int index = entry.key;
              String ingredient = entry.value;
              return CheckboxListTile(
                title: Text(ingredient),
                value: _checkedIngredients[index],
                onChanged: (bool? value) {
                  setState(() {
                    _checkedIngredients[index] = value ?? false;
                  });
                },
              );
            }).toList(),
            SizedBox(height: 16.0),
            Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Column(
              children: List.generate(
                widget.recipe.instructions.length,
                (index) => ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(widget.recipe.instructions[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeSearchDelegate extends SearchDelegate {
  final List<RecipeItem> _recipeItems;

  RecipeSearchDelegate(this._recipeItems);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<RecipeItem> _filteredRecipeItems = _recipeItems.where((recipe) {
      return recipe.recipeName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: _filteredRecipeItems.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(_filteredRecipeItems[index].recipeName),
          subtitle: Text(_filteredRecipeItems[index].ingredients.join(", ")),
          onTap: () {
            close(context, _filteredRecipeItems[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<RecipeItem> _suggestions = _recipeItems.where((recipe) {
      return recipe.recipeName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(_suggestions[index].recipeName),
          onTap: () {
            query = _suggestions[index].recipeName;
            showResults(context);
          },
        );
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _nameController.text = 'User';
    _emailController.text = 'email@example.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              readOnly: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile Updated')),
                );
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeItem {
  String recipeName;
  List<String> ingredients;
  List<String> instructions;
  String imageUrl;

  RecipeItem({
    required this.recipeName,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    return RecipeItem(
      recipeName: json['recipeName'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: List<String>.from(json['instructions']),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'recipeName': recipeName,
        'ingredients': ingredients,
        'instructions': instructions,
        'imageUrl': imageUrl,
      };
}
