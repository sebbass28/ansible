# Entendiendo el Workflow de GitHub Actions para Ansible

## ¿Qué es el workflow?

El archivo `.github/workflows/ci-cd.yml` es un conjunto de **instrucciones automáticas** que GitHub ejecuta cada vez que haces `push` a la rama `main`. Es como un robot que:

1. Descarga tu código
2. Prueba la aplicación
3. Configura SSH
4. Ejecuta Ansible contra la VM del cliente

---

## Desglose del flujo paso a paso

### 🔵 Trigger (Cuándo se ejecuta)

```yaml
on:
  push:
    branches: [main]
  workflow_dispatch: # Permite Click manual en GitHub
```

**¿Qué significa?**

- Se ejecuta automáticamente cuando haces `push` a `main`
- También puedes ejecutarlo manualmente desde GitHub

---

### 🟢 Job 1: `test` (Probar la app)

```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: "18"

    - name: Install deps & run tests
      run: |
        cd app
        npm ci
        npm test
```

**¿Qué hace?**

1. Descarga tu código del repositorio
2. Prepara Node.js 18
3. Instala dependencias y ejecuta tests de la aplicación

**Si falla aquí:** No va al siguiente paso (protección)

---

### 🟡 Job 2: `deploy` (Desplegar con Ansible)

Este job solo se ejecuta si `test` pasó correctamente.

#### Paso 1: `Setup SSH Key`

```yaml
- name: Setup SSH Key (Llave Privada)
  run: |
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519
```

**¿Qué pasa aquí?**

1. **Crear carpeta:** `mkdir -p ~/.ssh` → Crea la carpeta segura
2. **Recuperar Secret:** `${{ secrets.SSH_PRIVATE_KEY }}` → GitHub va a `Settings > Secrets` y trae tu llave privada
3. **Guardar archivo:** `echo ... > ~/.ssh/id_ed25519` → Escribe la llave en un archivo
4. **Proteger archivo:** `chmod 600` → Solo GitHub puede leer ese archivo (permisos rw-------)

**Es como si dijera:** "Aquí está tu llave privada, úsala para entrar"

---

#### Paso 2: `Install Ansible`

```yaml
- name: Install Ansible
  run: |
    sudo apt update
    sudo apt install -y python3-pip
    python3 -m pip install --upgrade pip
    pip3 install ansible
```

**¿Qué pasa aquí?**

- Prepara el entorno de GitHub (que es Ubuntu limpio)
- Instala Ansible y sus dependencias

---

#### Paso 3: `Run Ansible Playbook`

```yaml
- name: Run Ansible Playbook (deploy)
  env:
    GIT_REF: ${{ github.ref_name }}
    ANSIBLE_HOST_KEY_CHECKING: False
  run: |
    cd ansible
    ansible-playbook playbooks/deploy.yml \
      -i inventories/production.yml \
      -v
```

**¿Qué pasa aquí?**

1. **Entra en la carpeta:** `cd ansible`
2. **Ejecuta el playbook:** `ansible-playbook` usa:
   - `playbooks/deploy.yml` → Las tareas a ejecutar
   - `inventories/production.yml` → La IP de la VM (y el usuario)
   - `-v` → Modo verbose (muestra detalles)

**En este momento:**

- Ansible busca en su carpeta `~/.ssh/` la llave privada que preparamos
- Usa esa llave para conectarse a la IP en `production.yml`
- Ejecuta las tareas del playbook

---

## El flujo de seguridad

### 🔐 Cómo se genera confianza

```
Tu PC genera:
  ├─ id_ed25519 (PRIVADA) ← Guardas en tu PC y subes a GitHub Secrets
  └─ id_ed25519.pub (PÚBLICA) ← Envías a la VM del cliente

GitHub Actions hace:
  1. Lee la PRIVADA de Secrets
  2. La coloca en ~/.ssh/id_ed25519
  3. Ansible la usa para conectarse a la VM

La VM hace:
  1. Recibe una conexión SSH
  2. Says: "¿Quién eres?"
  3. Chequea su archivo authorized_keys
  4. Ve tu llave PÚBLICA allí
  5. Dice: "¡Vale, eres tú!"
  6. Abre la puerta (conexión SSH establecida)
  7. Ansible entra y ejecuta las tareas
```

---

## Cambiar a un "Cliente Nuevo" (Para el examen)

Si te dan una máquina nueva en el examen, estos son los cambios:

### ❌ Lo que NO cambias en GitHub

- Los Secrets (`SSH_PRIVATE_KEY`) permanecen igual
- El workflow permanece igual
- El playbook permanece igual

### ✅ Lo que SÍ cambias

**1. En la VM nueva:**

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub nuevo_usuario@NUEVA_IP
```

**2. En el archivo:** `ansible/inventories/production.yml`

```yaml
all:
  hosts:
    web1:
      ansible_host: NUEVA_IP # ← Cambiar
      ansible_user: nuevo_usuario # ← Cambiar
      ansible_python_interpreter: /usr/bin/python3
```

**3. Hacer push:**

```bash
git add ansible/inventories/production.yml
git commit -m "Update for new client"
git push
```

**¡Listo!** El workflow automáticamente:

- Se ejecuta
- Lee la llave privada de Secrets
- Se conecta a la NUEVA_IP
- Ejecuta Ansible

---

## Variables útiles en GitHub Actions

| Variable                         | Significado                             |
| -------------------------------- | --------------------------------------- |
| `${{ secrets.SSH_PRIVATE_KEY }}` | Tu llave privada desde Secrets          |
| `${{ github.ref_name }}`         | Rama actual (main, develop, etc)        |
| `${{ github.run_number }}`       | Número de ejecución del workflow        |
| `${{ runner.os }}`               | Sistema operativo (Linux, Windows, Mac) |

---

## Debugging si falla

### 1. El test falla

- Revisa `npm test` en la carpeta `app`
- El workflow se detiene aquí

### 2. SSH falla

- Verifica que `SSH_PRIVATE_KEY` está en Secrets
- Verifica que no tiene espacios o saltos de línea adicionales

### 3. Ansible falla

- Revisa los logs del workflow en GitHub
- Prueba localmente: `ansible -i inventories/production.yml web1 -m ping`
- Verifica que la IP en `production.yml` es correcta
- Verifica que `ansible_user` coincide con el usuario que tiene la llave pública

---

## Checklist de configuración

- [ ] ¿Generaste las claves SSH? (`ssh-keygen -t ed25519`)
- [ ] ¿Enviaste la llave pública a la VM? (`ssh-copy-id`)
- [ ] ¿Probaste SSH sin contraseña? (`ssh deploy@IP`)
- [ ] ¿Copiaste la llave privada a Secrets? (`cat ~/.ssh/id_ed25519`)
- [ ] ¿Editaste `production.yml` con la IP correcta?
- [ ] ¿Hiciste push? (`git push`)
- [ ] ¿El workflow se ejecutó en GitHub?

¡Si todos los checks están ✅, tu Ansible está listo para producción!

---

## Analogía final para recordar

```
Tu PC = 🔑 (tiene la llave maestra)
GitHub = 🚗 (el vehículo autónomo)
VM Cliente = 🏠 (la casa a proteger)

Proceso:
1. 🔑 genera un par de llaves (privada+pública)
2. 🏠 instala la pública en su cerradura
3. 🚗 agarra la privada de 🔑
4. 🚗 usa la privada para abrir 🏠
5. 🚗 entra a 🏠 y ejecuta Ansible
```

¡Simple! 🚀
