const { pool } = require("../config/database");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");

// Utility function to get roles and permissions for a user
const getRolesAndPermissions = async (userId) => {
  const [roles] = await pool.query(
    `
    SELECT r.roleName 
    FROM role r
    INNER JOIN user_roles ur ON r.roleId = ur.roleId
    WHERE ur.userId = ?
  `,
    [userId]
  );

  const [permissions] = await pool.query(
    `
    SELECT p.permissionName 
    FROM permission p
    INNER JOIN user_permissions up ON p.permissionId = up.permissionId
    WHERE up.userId = ?
  `,
    [userId]
  );

  return {
    roles: roles.map((role) => role.roleName),
    permissions: permissions.map((permission) => permission.permissionName),
  };
};

// Register a new user
exports.register = async (req, res) => {
  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    const hashedPassword = await bcrypt.hash(req.body.password, 10);
    const { username, email, phone, status, roles, permissions, agencyId } =
      req.body;

    const [result] = await connection.query(
      `INSERT INTO user (username, password, email, phone, status, agencyId) VALUES (?, ?, ?, ?, ?, ?)`,
      [username, hashedPassword, email, phone, status, agencyId]
    );

    const userId = result.insertId;

    // Insert roles
    for (const roleId of roles) {
      await connection.query(
        `INSERT INTO user_roles (userId, roleId) VALUES (?, ?)`,
        [userId, roleId]
      );
    }

    // Insert permissions
    for (const permissionId of permissions) {
      await connection.query(
        `INSERT INTO user_permissions (userId, permissionId) VALUES (?, ?)`,
        [userId, permissionId]
      );
    }

    await connection.commit();
    res.status(201).send({
      userId,
      username,
      email,
      phone,
      status,
      roles,
      permissions,
      agencyId,
    });
  } catch (error) {
    await connection.rollback();
    res.status(400).send(error);
  } finally {
    connection.release();
  }
};

// Login a user
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const [users] = await pool.query(`SELECT * FROM user WHERE email = ?`, [
      email,
    ]);

    if (users.length === 0) {
      return res.status(404).send("User not found");
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).send("Invalid credentials");
    }

    const payload = {
      userId: user.userId,
      email: user.email,
    };

    const token = jwt.sign(payload, "secret", {
      expiresIn: "24h",
    });

    res.send({ token });
  } catch (error) {
    console.log(error);
    res.status(500).send(error);
  }
};

// Get all users
exports.getAllUsers = async (req, res) => {
  try {
    const [users] = await pool.query(`
      SELECT u.userId, u.username, u.email, u.phone, u.createdAt, u.status, a.agencyName
      FROM user u
      LEFT JOIN agency a ON u.agencyId = a.agencyId
    `);

    for (const user of users) {
      const { roles, permissions } = await getRolesAndPermissions(user.userId);
      user.roles = roles;
      user.permissions = permissions;
    }

    res.send(users);
  } catch (error) {
    res.status(500).send(error);
  }
};

// Get a single user by ID
exports.getUser = async (req, res) => {
  try {
    const userId = req.params.userId;
    const [users] = await pool.query(
      `
      SELECT u.userId, u.username, u.email, u.phone, u.createdAt, u.status, a.agencyName
      FROM user u
      LEFT JOIN agency a ON u.agencyId = a.agencyId
      WHERE u.userId = ?
    `,
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).send("User not found");
    }

    const user = users[0];
    const { roles, permissions } = await getRolesAndPermissions(userId);
    user.roles = roles;
    user.permissions = permissions;

    res.send(user);
  } catch (error) {
    res.status(500).send(error);
  }
};

// Update a user
exports.updateUser = async (req, res) => {
  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    const userId = req.params.userId;
    const { username, email, phone, status, roles, permissions, agencyId } =
      req.body;

    await connection.query(
      `UPDATE user SET username = ?, email = ?, phone = ?, status = ?, agencyId = ? WHERE userId = ?`,
      [username, email, phone, status, agencyId, userId]
    );

    // Update roles
    await connection.query(`DELETE FROM user_roles WHERE userId = ?`, [userId]);
    for (const roleId of roles) {
      await connection.query(
        `INSERT INTO user_roles (userId, roleId) VALUES (?, ?)`,
        [userId, roleId]
      );
    }

    // Update permissions
    await connection.query(`DELETE FROM user_permissions WHERE userId = ?`, [
      userId,
    ]);
    for (const permissionId of permissions) {
      await connection.query(
        `INSERT INTO user_permissions (userId, permissionId) VALUES (?, ?)`,
        [userId, permissionId]
      );
    }

    await connection.commit();
    res.send("User updated successfully");
  } catch (error) {
    await connection.rollback();
    res.status(400).send(error);
  } finally {
    connection.release();
  }
};

// Delete a user
exports.deleteUser = async (req, res) => {
  try {
    const userId = req.params.userId;
    await pool.query(`DELETE FROM user WHERE userId = ?`, [userId]);
    res.send("User deleted successfully");
  } catch (error) {
    res.status(500).send(error);
  }
};

// Get all roles
exports.getRoles = async (req, res) => {
  try {
    const [roles] = await pool.query(`SELECT * FROM role`);
    res.send(roles);
  } catch (error) {
    res.status(500).send(error);
  }
};

// Get all permissions
exports.getPermissions = async (req, res) => {
  try {
    const [permissions] = await pool.query(`SELECT * FROM permission`);
    res.send(permissions);
  } catch (error) {
    res.status(500).send(error);
  }
};

// Get all agencies
exports.getAgencies = async (req, res) => {
  try {
    const [agencies] = await pool.query(`SELECT * FROM agency`);
    res.send(agencies);
  } catch (error) {
    res.status(500).send(error);
  }
};

const getRolesAndPermissionsUserId = async (userId) => {
  const [roles] = await pool.query(
    `
    SELECT r.roleName 
    FROM role r
    INNER JOIN user_roles ur ON r.roleId = ur.roleId
    WHERE ur.userId = ?
  `,
    [userId]
  );

  const [permissions] = await pool.query(
    `
    SELECT p.permissionName 
    FROM permission p
    INNER JOIN user_permissions up ON p.permissionId = up.permissionId
    WHERE up.userId = ?
  `,
    [userId]
  );

  return {
    roles: roles.map((role) => role.roleName),
    permissions: permissions.map((permission) => permission.permissionName),
  };
};

// Get current user permissions
exports.getCurrentUserPermissions = async (req, res) => {
  try {
    const { userId } = req.user;
    const { roles, permissions } = await getRolesAndPermissionsUserId(userId);
    res.send({ roles, permissions });
  } catch (error) {
    res.status(500).send(error);
  }
};
