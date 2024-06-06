const express = require("express");
const router = express.Router();

// Assuming you have some user controller methods predefined
const userController = require("../controllers/userController"),
  getAllUsers = require("../controllers/getAllUsers");
const auth = require("../middleware/auth");

// Middleware to parse JSON bodies
router.use(express.json());

// Register user
router.post("/register", userController.register);

// Login user
router.post("/login", userController.login);

// Get user details
// router.get("/:userId", auth.verifyToken, userController.getUser);

// Update user details
router.put("/update/:userId", userController.updateUser);

// Delete user
router.delete("/delete/:userId", userController.deleteUser);

router.get("/users", userController.getAllUsers);

module.exports = router;
