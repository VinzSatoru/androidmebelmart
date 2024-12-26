const bcrypt = require('bcrypt');
const mongoose = require('mongoose');

mongoose.connect('mongodb://127.0.0.1:27017/mebelmart_flut', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

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

const User = mongoose.model('User', userSchema);

async function createAdmin() {
  try {
    const hashedPassword = await bcrypt.hash('admin123', 10);
    const admin = new User({
      username: "admin",
      email: "admin@mebelmart.com",
      password: hashedPassword,
      role: "admin",
      fullName: "Admin MebelMart",
      phoneNumber: "081234567890",
      address: "Jl. Admin No. 1"
    });

    await admin.save();
    console.log('Admin berhasil dibuat');
    process.exit(0);
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
}

createAdmin(); 