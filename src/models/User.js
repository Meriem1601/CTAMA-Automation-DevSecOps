// models/User.js
const { EntitySchema } = require("typeorm");

module.exports = new EntitySchema({
  name: "User",
  tableName: "user",
  columns: {
    userId: {
      type: "bigint",
      primary: true,
      generated: true,
    },
    username: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    password: {
      type: "varchar",
      length: 255,
      nullable: false,
    },
    email: {
      type: "varchar",
      length: 255,
      nullable: false,
      unique: true,
    },
    roleId: {
      type: "int",
      nullable: false,
    },
  },
});
