// Script untuk meng-hash semua password yang belum di-hash
db.users.find().forEach(async function(user) {
  if (!user.password.startsWith('$2b$')) {
    const hashedPassword = "$2b$10$" + require('bcrypt').hashSync(user.password, 10);
    db.users.updateOne(
      { _id: user._id },
      { $set: { password: hashedPassword } }
    );
  }
}); 