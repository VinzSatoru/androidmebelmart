// Buat collections
db.createCollection("products")
db.createCollection("categories")
db.createCollection("users")
db.createCollection("orders")
db.createCollection("cart")

// Contoh insert data kategori
db.categories.insertMany([
  { name: "Kursi", icon: "chair" },
  { name: "Meja", icon: "table" },
  { name: "Lemari", icon: "cabinet" },
  { name: "Tempat Tidur", icon: "bed" },
  { name: "Sofa", icon: "sofa" }
])

// Contoh insert data produk
db.products.insertMany([
  {
    name: "Kursi Makan Minimalis",
    category: "Kursi",
    price: 750000,
    description: "Kursi makan modern dengan bahan kayu jati",
    image: "kursi_makan.jpg",
    stock: 10
  },
  {
    name: "Meja Kerja",
    category: "Meja",
    price: 1200000,
    description: "Meja kerja ergonomis dengan laci",
    image: "meja_kerja.jpg",
    stock: 5
  }
])

// Tambahkan index untuk performa query
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "username": 1 }, { unique: true })
db.orders.createIndex({ "orderId": 1 }, { unique: true })
db.orders.createIndex({ "userId": 1 })
db.cart.createIndex({ "userId": 1 })

// Reset cart collection and create proper index
db.cart.drop()
db.createCollection("cart")
db.cart.createIndex({ "userId": 1 })