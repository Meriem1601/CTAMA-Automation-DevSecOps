const mysql = require("mysql2/promise");

const DB_HOST = "localhost";
const DB_PORT = "3306";
const DB_USERNAME = "root";
const DB_PASSWORD = "root";
const DB_DATABASE = "mydatabase";

const pool = mysql.createPool({
  host: DB_HOST,
  port: DB_PORT,
  user: DB_USERNAME,
  password: DB_PASSWORD,
  database: DB_DATABASE,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

const connection = async () => {
  try {
    const conn = await pool.getConnection();
    conn.release();
  } catch (error) {
    console.error("Database connection failed:", error);
    process.exit(1);
  }
};

module.exports = {
  pool,
  connection,
};
