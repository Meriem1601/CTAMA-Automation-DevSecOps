const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const userController = require("./controllers/userController");
const authenticateToken = require("./middleware/auth");
const { connection } = require("./config/database");
require("dotenv").config();

const app = express();
const port = process.env.PORT || 8000; // Ensure this is set to 8000

// Use CORS middleware
app.use(
  cors({
    origin: "http://localhost:3000",
    methods: "GET,HEAD,PUT,PATCH,POST,DELETE",
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

//app .use to log all requests
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

app.use(bodyParser.json());

// User routes
app.post("/api/register", userController.register);
app.post("/api/login", userController.login);
app.get("/api/users/:userId", authenticateToken, userController.getUser);
app.put("/api/users/:userId", authenticateToken, userController.updateUser);
app.delete("/api/users/:userId", authenticateToken, userController.deleteUser);
app.get("/api/users", authenticateToken, userController.getAllUsers);
app.get("/api/roles", authenticateToken, userController.getRoles);
app.get("/api/permissions", authenticateToken, userController.getPermissions);
app.get("/api/agencies", authenticateToken, userController.getAgencies);
app.get(
  "/api/current-user-permissions",
  authenticateToken,
  userController.getCurrentUserPermissions
);

connection()
  .then(() => {
    app.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });
  })
  .catch((err) => {
    console.error("Failed to connect to database:", err);
  });
