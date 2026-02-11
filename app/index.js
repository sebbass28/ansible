const express = require("express");
const app = express();
const port = 3000;

app.get("/", (req, res) => {
  res.send("Examen DAW Despliegue inicial");
});

app.listen(port, () => {
  console.log(`App escuchando en el puerto ${port}`);
});
