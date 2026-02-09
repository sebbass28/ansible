# 🔧 TROUBLESHOOTING ANSIBLE - Guía de Emergencia Examen

## Cuando TODO se rompe

---

## ❌ Error: `Permission denied (publickey)`

**Síntoma:**

```
fatal: [192.168.82.165]: UNREACHABLE! => {
    "msg": "Failed to connect to the host via ssh: Permission denied (publickey)."
}
```

**Causas posibles (en orden de probabilidad):**

### 1. No enviaste la llave pública al cliente

```bash
# Solución:
ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@192.168.82.165
# Te pide la contraseña del usuario 'deploy' (última vez que la pides)
```

### 2. El usuario es incorrecto

```bash
# Verifica qué usuario existe en la VM:
ssh -v deploy@192.168.82.165
# Si dice "No such user", cambia 'deploy' por el usuario correcto

# Ejemplo:
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@192.168.82.165
# O cámbialo en ansible/inventories/production.yml
```

### 3. No tienes las claves SSH

```bash
# Verifica:
ls -la ~/.ssh/

# Si no ves id_ed25519, generalas:
ssh-keygen -t ed25519
# (Presiona ENTER en todo)
```

### 4. La carpeta .ssh tiene permisos incorrectos

```bash
# Arregla:
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

---

## ❌ Error: `Host unreachable` o `No route to host`

**Síntoma:**

```
[192.168.82.165]: UNREACHABLE! => {
    "msg": "ssh: connect to host 192.168.82.165 port 22: No route to host"
}
```

**Causas posibles:**

### 1. IP incorrecta

```bash
# En la VM, verifica la IP real:
ip add
# Busca algo como: inet 192.168.x.x (NO es 127.0.0.1)

# Actualiza el inventario:
nano ansible/inventories/production.yml
# Cambia ansible_host: por la IP correcta
```

### 2. La VM no está en red Bridged (VirtualBox)

```bash
# En VirtualBox:
1. Apaga la VM
2. Click derecho en la VM → Settings
3. Network → Adapter
4. Cambia "NAT" por "Bridged Adapter"
5. Enciende la VM
6. De nuevo: ip add
```

### 3. SSH no está iniciado en la VM

```bash
# En la máquina cliente (VM), ve si SSH está corriendo:
sudo systemctl status ssh

# Si no está:
sudo systemctl start ssh
sudo systemctl enable ssh  # Para que inicie al boot
```

### 4. Firewall bloquea SSH

```bash
# En la VM, abre el puerto SSH:
sudo ufw allow 22/tcp
```

### 5. Simplemente no tienes ping a la IP

```bash
# Desde tu PC, prueba:
ping 192.168.82.165

# Si no hay respuesta, es un problema de red, no de Ansible
# Revisa configuración de VirtualBox como se explicó en punto 2
```

---

## ❌ Error: `Unable to parse as an inventory source`

**Síntoma:**

```
Unable to parse ansible/inventories/production.yml as an inventory source
```

**Causa:** Sintaxis YAML incorrecta

```bash
# Solución: Verifica el archivo
cat -A ansible/inventories/production.yml
# Busca caracteres raros

# Mejor: Valida el YAML
python3 -c "import yaml; yaml.safe_load(open('ansible/inventories/production.yml'))"
# Si no dice nada: ✅ Está bien
# Si sale error: ❌ Hay problema de sintaxis
```

**Errores comunes en YAML:**

- ❌ Mezclar espacios con tabulaciones (Usar SOLO espacios)
- ❌ Falta de indentación
- ❌ Comillas mal colocadas

**Arreglalo:** Abre el archivo y verifica que todas las líneas estén bien indentadas (4 espacios por nivel)

---

## ❌ Error: `Failed to connect to the server ssh: No such file or directory`

**Síntoma:**

```
ssh: Could not resolve hostname ansible_host: Name or service not known
```

**Causa:** Ansible no encuentra el binario SSH

```bash
# Solución: Instala SSH client
sudo apt install openssh-client
```

---

## ❌ Error: `ansible_user not found`

**Síntoma:**

```
[192.168.82.165]: UNREACHABLE! => {
    "msg": "Failed to connect to the host via ssh... No such user"
}
```

**Solución:**

1. Verifica qué usuarios existen en la VM:

```bash
ssh root@192.168.82.165
cat /etc/passwd | grep -v nologin
# O:
who
```

2. Usa el usuario correcto en el inventario:

```bash
# Edita:
nano ansible/inventories/production.yml

# Ejemplo, si el usuario es 'ubuntu':
ansible_user: ubuntu
```

---

## ❌ Error: `[Errno 2] No such file or directory: 'ansible-playbook'`

**Síntoma:**

```
/bin/bash: ansible-playbook: command not found
```

**Causa:** Ansible no está instalado

```bash
# Solución: Instálalo
sudo apt update
sudo apt install -y python3-pip
pip3 install ansible
```

---

## ❌ Error: `Module not found` o errores en el playbook

**Síntoma:**

```
FAILED! => {
    "msg": "The following modules failed to load: ... Not Found."
}
```

**Solución:**

1. Instala módulos requisitos:

```bash
pip3 install -r /path/to/requirements.txt
# (Si existe el archivo)
```

2. O instala manualmente lo que falta:

```bash
pip3 install jinja2 paramiko netaddr
```

---

## ⚠️ Advertencia: `[WARNING]: No inventory was parsed`

**Síntoma:**

```
[WARNING]: provided hosts list contains a not yet matched group name: web1:
ignoredwarning
```

**Solución:**

Estás usando `ansible all` pero el grupo no existe. Usa el grupo correcto:

```bash
# ❌ Así NO:
ansible all -m ping

# ✅ Así SÍ:
ansible -i inventories/production.yml web1 -m ping
```

---

## GitHub Actions: El workflow falla

### 1. Secret no está configurado

**Error en logs:**

```
${{ secrets.SSH_PRIVATE_KEY }} expands to an empty string
```

**Solución:**

```bash
# Verifica el Secret está en GitHub:
# Settings → Secrets and variables → Actions

# Si no está:
cat ~/.ssh/id_ed25519
# Copia TODO (incluyendo BEGIN y END)
# Settings → New repository secret → SSH_PRIVATE_KEY → Pega
```

### 2. Build pasa pero SSH falla

**Ver los logs:**

1. Ve a tu repositorio en GitHub
2. Pestaña "Actions"
3. Haz click en el workflow que falló
4. Busca el step "Run Ansible Playbook"
5. Expande y lee el error

**Problemas comunes:**

- IP incorrecta en production.yml
- Usuario incorrecto
- La llave no está en la VM

### 3. Todo funciona localmente pero falla en GitHub

**Probable causa:** La llave privada en GitHub no es la misma que usaste localmente

```bash
# Verifica:
cat ~/.ssh/id_ed25519 | head -c 50
# (Esto muestra los primeros 50 caracteres)

# Compara con lo que ves en:
# GitHub → Settings → Secrets → SSH_PRIVATE_KEY → Edit
# (Las primeras líneas deben coincidir)
```

---

## 🆘 Checklist de Emergencia (Cuando no sabes qué pasó)

- [ ] ¿La IP es correcta? (`ip add` en la VM)
- [ ] ¿El usuario es correcto? (`cat /etc/passwd` en la VM)
- [ ] ¿Tienes llaves SSH? (`ls ~/.ssh/`)
- [ ] ¿Enviaste la llave pública? (`ls ~/.ssh/authorized_keys` en la VM)
- [ ] ¿SSH sin password funciona? (`ssh usuario@IP`)
- [ ] ¿Ansible está instalado? (`ansible --version`)
- [ ] ¿El inventario está bien? (`cat ansible/inventories/production.yml`)
- [ ] ¿Hiciste git push? (`git log`)

Si TODOS los checks son ✅, probablemente el problema es en el playbook, no en SSH.

---

## 📞 "No tengo tiempo, dame la solución rápida"

**TOP 3 problemas en examen (99% de casos):**

1. **Permission denied:**

   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@IP
   ```

2. **Host unreachable:**

   ```bash
   # Verifica IP real:
   ip add
   # En VirtualBox: Bridged Adapter
   ```

3. **Inventario mal configurado:**
   ```bash
   # Edita:
   nano ansible/inventories/production.yml
   # Asegúrate de:
   # - ansible_host: IP CORRECTA
   # - ansible_user: usuario CORRECTO
   ```

Si probaste estos 3 y nada funciona, pregunta al profesor 🙋

---

**¡Mucho éxito! Respira, verifica paso a paso, y todo va a funcionar.** 🚀
