import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:bakery_app/models/product_models.dart';
import 'package:bakery_app/models/customer_models.dart';
import 'package:bakery_app/models/order_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bakery_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        imageUrl TEXT NOT NULL,
        category TEXT NOT NULL,
        isAvailable INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create Customers table
    await db.execute('''
      CREATE TABLE customers(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create Orders table
    await db.execute('''
      CREATE TABLE orders(
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        orderDate TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        estimatedDelivery TEXT,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Create Order Items table
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId TEXT NOT NULL,
        productId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (orderId) REFERENCES orders (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Create Cart Items table (for persistent cart)
    await db.execute('''
      CREATE TABLE cart_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        notes TEXT,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Insert default products
    await _insertDefaultProducts(db);
  }

  Future<void> _insertDefaultProducts(Database db) async {
    final defaultProducts = [
      {
        'id': '1',
        'name': 'Roti Tawar Gandum',
        'description':
            'Roti tawar gandum segar dengan tekstur lembut dan bergizi tinggi',
        'price': 15000.0,
        'imageUrl': 'images/gandum.jpeg',
        'category': 'Roti',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Croissant Butter',
        'description':
            'Croissant klasik dengan mentega premium, berlapis dan renyah',
        'price': 8000.0,
        'imageUrl': 'images/croissant.jpeg',
        'category': 'Roti',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'name': 'Kue Blackforest',
        'description': 'Kue coklat lembut dengan cherry segar dan krim whip',
        'price': 85000.0,
        'imageUrl': 'images/blackforest.jpeg',
        'category': 'Kue',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '4',
        'name': 'Donat Glazed',
        'description': 'Donat lembut dengan glazed manis yang menggugah selera',
        'price': 5000.0,
        'imageUrl': 'images/donat.jpeg',
        'category': 'Roti',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '5',
        'name': 'Kue Tiramisu',
        'description':
            'Kue tiramisu dengan rasa kopi yang khas dan tekstur lembut',
        'price': 95000.0,
        'imageUrl': 'images/tiramisu.jpeg',
        'category': 'Kue',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '6',
        'name': 'Roti Coklat',
        'description':
            'Roti manis dengan isian coklat melimpah dan topping coklat',
        'price': 12000.0,
        'imageUrl': 'images/coklat.jpeg',
        'category': 'Roti',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '7',
        'name': 'Red Velvet Cake',
        'description': 'Kue red velvet dengan cream cheese frosting yang lezat',
        'price': 120000.0,
        'imageUrl': 'images/red velvet.jpeg',
        'category': 'Kue',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '8',
        'name': 'Roti Sobek',
        'description': 'Roti sobek lembut dengan tekstur yang mudah disobek',
        'price': 18000.0,
        'imageUrl': 'images/sobek.jpeg',
        'category': 'Roti',
        'isAvailable': 1,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];

    for (var product in defaultProducts) {
      await db.insert('products', product);
    }
  }

  // Product CRUD operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'category': product.category,
      'isAvailable': product.isAvailable ? 1 : 0,
      'createdAt': product.createdAt.toIso8601String(),
    });
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        imageUrl: maps[i]['imageUrl'],
        category: maps[i]['category'],
        isAvailable: maps[i]['isAvailable'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product(
        id: maps[0]['id'],
        name: maps[0]['name'],
        description: maps[0]['description'],
        price: maps[0]['price'],
        imageUrl: maps[0]['imageUrl'],
        category: maps[0]['category'],
        isAvailable: maps[0]['isAvailable'] == 1,
        createdAt: DateTime.parse(maps[0]['createdAt']),
      );
    }
    return null;
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: category.toLowerCase() != 'semua' ? 'category = ?' : null,
      whereArgs: category.toLowerCase() != 'semua' ? [category] : null,
    );

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        imageUrl: maps[i]['imageUrl'],
        category: maps[i]['category'],
        isAvailable: maps[i]['isAvailable'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name LIKE ? OR description LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        imageUrl: maps[i]['imageUrl'],
        category: maps[i]['category'],
        isAvailable: maps[i]['isAvailable'] == 1,
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'isAvailable': product.isAvailable ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Customer CRUD operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', {
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'latitude': customer.latitude,
      'longitude': customer.longitude,
      'createdAt': customer.createdAt.toIso8601String(),
    });
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) {
      return Customer(
        id: maps[i]['id'],
        name: maps[i]['name'],
        phone: maps[i]['phone'],
        address: maps[i]['address'],
        latitude: maps[i]['latitude'],
        longitude: maps[i]['longitude'],
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Customer(
        id: maps[0]['id'],
        name: maps[0]['name'],
        phone: maps[0]['phone'],
        address: maps[0]['address'],
        latitude: maps[0]['latitude'],
        longitude: maps[0]['longitude'],
        createdAt: DateTime.parse(maps[0]['createdAt']),
      );
    }
    return null;
  }

  // Order CRUD operations
  Future<int> insertOrder(Order order) async {
    final db = await database;

    // Insert customer first if not exists
    await insertCustomer(order.customer);

    // Insert order
    await db.insert('orders', {
      'id': order.id,
      'customerId': order.customer.id,
      'totalAmount': order.totalAmount,
      'orderDate': order.orderDate.toIso8601String(),
      'status': order.status.toString(),
      'notes': order.notes,
      'estimatedDelivery': order.estimatedDelivery?.toIso8601String(),
    });

    // Insert order items
    for (var item in order.items) {
      await db.insert('order_items', {
        'orderId': order.id,
        'productId': item.product.id,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'notes': item.notes,
      });
    }

    return 1;
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.rawQuery('''
      SELECT o.*, c.name as customerName, c.phone, c.address, c.latitude, c.longitude, c.createdAt as customerCreatedAt
      FROM orders o
      INNER JOIN customers c ON o.customerId = c.id
      ORDER BY o.orderDate DESC
    ''');

    List<Order> orders = [];

    for (var orderMap in orderMaps) {
      // Get order items
      final List<Map<String, dynamic>> itemMaps = await db.rawQuery(
        '''
        SELECT oi.*, p.name, p.description, p.price, p.imageUrl, p.category, p.isAvailable, p.createdAt
        FROM order_items oi
        INNER JOIN products p ON oi.productId = p.id
        WHERE oi.orderId = ?
      ''',
        [orderMap['id']],
      );

      List<OrderItem> items = itemMaps.map((itemMap) {
        return OrderItem(
          product: Product(
            id: itemMap['productId'],
            name: itemMap['name'],
            description: itemMap['description'],
            price: itemMap['price'],
            imageUrl: itemMap['imageUrl'],
            category: itemMap['category'],
            isAvailable: itemMap['isAvailable'] == 1,
            createdAt: DateTime.parse(itemMap['createdAt']),
          ),
          quantity: itemMap['quantity'],
          unitPrice: itemMap['unitPrice'],
          notes: itemMap['notes'],
        );
      }).toList();

      Customer customer = Customer(
        id: orderMap['customerId'],
        name: orderMap['customerName'],
        phone: orderMap['phone'],
        address: orderMap['address'],
        latitude: orderMap['latitude'],
        longitude: orderMap['longitude'],
        createdAt: DateTime.parse(orderMap['customerCreatedAt']),
      );

      orders.add(
        Order(
          id: orderMap['id'],
          customer: customer,
          items: items,
          totalAmount: orderMap['totalAmount'],
          orderDate: DateTime.parse(orderMap['orderDate']),
          status: OrderStatus.values.firstWhere(
            (e) => e.toString() == orderMap['status'],
          ),
          notes: orderMap['notes'],
          estimatedDelivery: orderMap['estimatedDelivery'] != null
              ? DateTime.parse(orderMap['estimatedDelivery'])
              : null,
        ),
      );
    }

    return orders;
  }

  Future<int> updateOrderStatus(String orderId, OrderStatus status) async {
    final db = await database;
    return await db.update(
      'orders',
      {'status': status.toString()},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Cart operations
  Future<int> insertCartItem(
    String productId,
    int quantity,
    String? notes,
  ) async {
    final db = await database;

    // Check if item already exists
    final existing = await db.query(
      'cart_items',
      where: 'productId = ?',
      whereArgs: [productId],
    );

    if (existing != null && existing.isNotEmpty) {
      // Update quantity
      try {
        return await db.update(
          'cart_items',
          {
            'quantity': (existing[0]['quantity'] as int) + quantity,
            'notes': notes ?? existing[0]['notes'] as String?,
          },
          where: 'id = ?',
          whereArgs: [existing[0]['id']],
        );
      } catch (e) {
        throw Exception('Failed to update cart item: $e');
      }
    } else {
      // Insert new item
      try {
        return await db.insert('cart_items', {
          'productId': productId,
          'quantity': quantity,
          'notes': notes,
          'addedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        throw Exception('Failed to insert cart item: $e');
      }
    }
  }

  Future<List<OrderItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT ci.*, p.name, p.description, p.price, p.imageUrl, p.category, p.isAvailable, p.createdAt
      FROM cart_items ci
      INNER JOIN products p ON ci.productId = p.id
      ORDER BY ci.addedAt DESC
    ''');

    return maps.map((map) {
      return OrderItem(
        product: Product(
          id: map['productId'],
          name: map['name'],
          description: map['description'],
          price: map['price'],
          imageUrl: map['imageUrl'],
          category: map['category'],
          isAvailable: map['isAvailable'] == 1,
          createdAt: DateTime.parse(map['createdAt']),
        ),
        quantity: map['quantity'],
        notes: map['notes'],
      );
    }).toList();
  }

  Future<int> updateCartItemQuantity(String productId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      return await db.delete(
        'cart_items',
        where: 'productId = ?',
        whereArgs: [productId],
      );
    } else {
      return await db.update(
        'cart_items',
        {'quantity': quantity},
        where: 'productId = ?',
        whereArgs: [productId],
      );
    }
  }

  Future<int> removeCartItem(String productId) async {
    final db = await database;
    return await db.delete(
      'cart_items',
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  Future<int> clearCart() async {
    final db = await database;
    return await db.delete('cart_items');
  }

  // Utility methods
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
