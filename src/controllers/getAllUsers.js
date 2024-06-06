const User = require("../models/User");

exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.findAll();
    res.send(users);
  } catch (error) {
    res.status(500).send(error);
  }
};
