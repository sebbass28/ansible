const express = require("express");
const app = express();
const port = 3000;

app.get("/", (req, res) => {
  res.send("¡Hola desde Ansible y GitHub Actions!");
});

app.listen(port, () => {
  console.log(`App escuchando en el puerto ${port}`);
});
