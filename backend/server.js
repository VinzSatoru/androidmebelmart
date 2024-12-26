const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');

app.use(cors());
app.use(express.json());

mongoose.connect('mongodb://127.0.0.1:27017/mebelmart_flut', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

// Schemas
const userSchema = new mongoose.Schema({
  username: { type: String, unique: true },
  email: { type: String, unique: true },
  password: String,
  role: String,
  fullName: String,
  phoneNumber: String,
  address: String,
  createdAt: { type: Date, default: Date.now }
});

const cartSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  items: [{
    productId: String,
    product: {
      _id: String,
      name: String,
      price: Number,
      image: String
    },
    quantity: { type: Number, default: 1 },
    price: { type: Number, default: 0 },
    subtotal: { type: Number, default: 0 }
  }],
  total: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const orderSchema = new mongoose.Schema({
  orderId: { type: String, unique: true },
  userId: String,
  items: [{
    productId: String,
    productName: String,
    quantity: Number,
    price: Number,
    subtotal: Number
  }],
  totalAmount: Number,
  shippingAddress: {
    fullName: String,
    phoneNumber: String,
    address: String,
    city: String,
    postalCode: String
  },
  paymentStatus: String,
  orderStatus: String,
  paymentMethod: String,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Models
const User = mongoose.model('User', userSchema);
const Cart = mongoose.model('Cart', cartSchema);
const Order = mongoose.model('Order', orderSchema);

// User Routes
app.post('/api/users/register', async (req, res) => {
  try {
    console.log('Registration request body:', req.body); // Debug log

    // Validasi data
    const { username, email, password, fullName, phoneNumber, address, role } = req.body;
    
    if (!email || !password || !fullName) {
      return res.status(400).json({ message: 'Data registrasi tidak lengkap' });
    }

    // Cek apakah email sudah terdaftar
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(409).json({ message: 'Email sudah terdaftar' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Buat user baru
    const user = new User({
      username: username.toLowerCase(),
      email: email.toLowerCase(),
      password: hashedPassword,
      fullName,
      phoneNumber: phoneNumber || '',
      address: address || '',
      role: role || 'customer',
    });

    await user.save();
    console.log('User registered successfully:', user.email); // Debug log

    res.status(201).json({ message: 'User registered successfully' });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/users/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log('Login attempt for:', email); // Debug log
    
    if (!email || !password) {
      return res.status(400).json({ 
        message: 'Email dan password harus diisi' 
      });
    }

    const user = await User.findOne({ email });
    console.log('Found user:', user ? 'Yes' : 'No'); // Debug log tanpa expose data sensitif
    
    if (!user) {
      console.log('User not found');
      return res.status(401).json({ message: 'Email atau password salah' });
    }

    const isValidPassword = await bcrypt.compare(password, user.password);
    console.log('Password valid:', isValidPassword); // Debug log

    if (!isValidPassword) {
      console.log('Invalid password');
      return res.status(401).json({ message: 'Email atau password salah' });
    }

    // Buat object response tanpa password
    const userResponse = {
      _id: user._id,
      username: user.username,
      email: user.email,
      role: user.role,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      address: user.address
    };
    
    console.log('Login successful for:', email);
    res.json({ user: userResponse });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      message: 'Terjadi kesalahan pada server',
      error: error.message 
    });
  }
});

// Cart Routes
app.get('/api/carts/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log('Fetching cart for userId:', userId);

    // Try to find existing cart
    let cart = await Cart.findOne({ userId });
    
    if (!cart) {
      console.log('No cart found, creating new cart');
      // Create new cart
      const newCart = {
        userId,
        items: [],
        total: 0
      };
      
      try {
        cart = new Cart(newCart);
        await cart.save();
        console.log('New cart created successfully:', cart);
      } catch (createError) {
        console.error('Error creating new cart:', createError);
        throw createError; // Let the outer catch block handle it
      }
    }

    console.log('Returning cart:', cart);
    return res.json(cart);

  } catch (error) {
    console.error('Cart operation error:', error);
    // Send a more detailed error response
    return res.status(500).json({
      message: 'Error processing cart request',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

app.post('/api/carts', async (req, res) => {
  try {
    const cart = new Cart(req.body);
    await cart.save();
    res.status(201).json(cart);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/carts/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { productId, quantity, price, product } = req.body;

    console.log('Adding to cart for userId:', userId);
    console.log('Product data:', { productId, quantity, price, product });

    // Find or create cart
    let cart = await Cart.findOne({ userId });
    if (!cart) {
      cart = new Cart({
        userId,
        items: [],
        total: 0
      });
    }

    // Check if item already exists
    const existingItemIndex = cart.items.findIndex(
      item => item.productId.toString() === productId.toString()
    );

    if (existingItemIndex !== -1) {
      // Update existing item
      cart.items[existingItemIndex].quantity += quantity;
      cart.items[existingItemIndex].subtotal = 
        cart.items[existingItemIndex].quantity * price;
    } else {
      // Add new item
      cart.items.push({
        productId,
        product: {
          _id: product._id,
          name: product.name,
          price: product.price,
          image: product.image
        },
        quantity,
        price,
        subtotal: quantity * price
      });
    }

    // Calculate total
    cart.total = cart.items.reduce((sum, item) => sum + item.subtotal, 0);
    cart.updatedAt = new Date();

    await cart.save();
    console.log('Cart saved successfully:', cart);
    res.status(200).json(cart);
  } catch (error) {
    console.error('Error adding to cart:', error);
    res.status(500).json({ 
      message: 'Error adding to cart', 
      error: error.message 
    });
  }
});

app.delete('/api/carts/:userId/items/:itemId', async (req, res) => {
  try {
    const { userId, itemId } = req.params;
    console.log('Deleting item from cart - userId:', userId, 'itemId:', itemId);

    const cart = await Cart.findOne({ userId });
    if (!cart) {
      return res.status(404).json({ message: 'Keranjang tidak ditemukan' });
    }

    // Find the item index in the cart
    const itemIndex = cart.items.findIndex(
      item => item._id.toString() === itemId || item.productId.toString() === itemId
    );

    if (itemIndex === -1) {
      return res.status(404).json({ message: 'Item tidak ditemukan dalam keranjang' });
    }

    // Remove the item from the cart
    cart.items.splice(itemIndex, 1);

    // Recalculate total
    cart.total = cart.items.reduce((total, item) => total + item.subtotal, 0);

    // Save the updated cart
    await cart.save();

    res.json({ message: 'Item berhasil dihapus dari keranjang', cart });
  } catch (error) {
    console.error('Error deleting item from cart:', error);
    res.status(500).json({ message: error.message });
  }
});

// Delete entire cart
app.delete('/api/carts/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log('Deleting cart for userId:', userId);

    const result = await Cart.findOneAndDelete({ userId });
    if (!result) {
      return res.status(404).json({ message: 'Keranjang tidak ditemukan' });
    }

    res.json({ message: 'Keranjang berhasil dihapus' });
  } catch (error) {
    console.error('Error deleting cart:', error);
    res.status(500).json({ message: error.message });
  }
});

// Order Routes
app.post('/api/orders', async (req, res) => {
  try {
    console.log('Creating new order with data:', req.body); // Debug log
    const order = new Order(req.body);
    const savedOrder = await order.save();
    console.log('Order created successfully:', savedOrder); // Debug log
    res.status(201).json(savedOrder);
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get all orders (for admin)
app.get('/api/orders/all', async (req, res) => {
  try {
    console.log('Fetching all orders...'); // Debug log
    const orders = await Order.find().sort({ createdAt: -1 });
    console.log('Raw orders from database:', orders); // Debug log
    console.log(`Found ${orders.length} orders`); // Debug log
    
    // Verify each order has required fields
    orders.forEach((order, index) => {
      console.log(`Order ${index + 1}:`, {
        orderId: order.orderId,
        userId: order.userId,
        status: order.orderStatus,
        total: order.totalAmount,
        items: order.items.length
      });
    });
    
    res.json(orders);
  } catch (error) {
    console.error('Error fetching all orders:', error);
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/orders/:userId', async (req, res) => {
  try {
    console.log('Fetching orders for userId:', req.params.userId); // Debug log
    const orders = await Order.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    console.log(`Found ${orders.length} orders for user ${req.params.userId}`); // Debug log
    res.json(orders);
  } catch (error) {
    console.error('Error fetching user orders:', error);
    res.status(500).json({ message: error.message });
  }
});

// Product Schema
const productSchema = new mongoose.Schema({
  name: String,
  category: String,
  price: Number,
  description: String,
  image: String,
  stock: Number
});

const Product = mongoose.model('Product', productSchema);

// Routes
app.get('/api/products', async (req, res) => {
  try {
    const products = await Product.find();
    console.log('Fetched products:', products); // Debug log
    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/products', async (req, res) => {
  try {
    console.log('Received product data:', req.body); // Debug log

    const product = new Product({
      name: req.body.name,
      category: req.body.category,
      price: Number(req.body.price),
      description: req.body.description,
      image: req.body.image,
      stock: Number(req.body.stock)
    });

    const savedProduct = await product.save();
    console.log('Product saved:', savedProduct); // Debug log
    res.status(201).json(savedProduct);
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({ 
      message: 'Error creating product', 
      error: error.message 
    });
  }
});

app.put('/api/products/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.delete('/api/products/:id', async (req, res) => {
  try {
    console.log('Deleting product with id:', req.params.id); // Debug log
    
    const deletedProduct = await Product.findByIdAndDelete(req.params.id);
    
    if (!deletedProduct) {
      console.log('Product not found');
      return res.status(404).json({ message: 'Product not found' });
    }
    
    console.log('Product deleted successfully:', deletedProduct); // Debug log
    res.json({ 
      message: 'Product deleted successfully',
      product: deletedProduct 
    });
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ 
      message: 'Error deleting product',
      error: error.message 
    });
  }
});

// Update order status
app.put('/api/orders/:id/status', async (req, res) => {
  try {
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { orderStatus: req.body.status },
      { new: true }
    );
    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const users = await User.find({}, '-password'); // Exclude password field
    console.log('Fetched users:', users); // Debug log
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: error.message });
  }
});

// Konfigurasi penyimpanan gambar
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/products/') // Buat folder uploads/products
  },
  filename: function (req, file, cb) {
    cb(null, req.params.id + path.extname(file.originalname))
  }
});

const upload = multer({ storage: storage });

// Endpoint untuk upload gambar produk
app.post('/api/products/:id/image', upload.single('image'), async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { image: req.file.filename },
      { new: true }
    );
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Endpoint untuk mengambil gambar produk
app.get('/api/products/:id/image', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (product && product.image) {
      res.sendFile(path.join(__dirname, 'uploads/products', product.image));
    } else {
      res.status(404).send('Image not found');
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Middleware untuk logging requests
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

const PORT = 44800;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
}); 