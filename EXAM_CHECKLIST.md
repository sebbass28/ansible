# Checklist Examen Ansible - Cliente Nuevo

## PARTE 1: En tu Máquina (El Controlador)

### ✅ Paso 1: Generar las claves SSH (Si no las tienes)

```bash
ssh-keygen -t ed25519 -C "examen_ansible"
# Presiona ENTER en todo (no pongas contraseña)
# Resultado: ~/.ssh/id_ed25519 (PRIVADA) y ~/.ssh/id_ed25519.pub (PÚBLICA)
```

### ✅ Paso 2: Enviar la LLAVE PÚBLICA al cliente

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@IP_DEL_CLIENTE
# Te pide la contraseña del usuario 'deploy' en la VM
# Después: Ansible entrar sin pedir contraseña
```

### ✅ Paso 3: Probar conexión SSH

```bash
ssh deploy@IP_DEL_CLIENTE
# Si entra sin contraseña: ✅ Bien configurado
# Si pide contraseña: ❌ Algo falló en el ssh-copy-id
```

---

## PARTE 2: En GitHub (Si usas Actions)

### ✅ Paso 4: Subir la LLAVE PRIVADA a Secrets

1. En tu máquina, copia el contenido de tu llave privada:

```bash
cat ~/.ssh/id_ed25519
# Copia TODO el texto (desde -----BEGIN hasta -----END)
```

2. En GitHub:
   - Ve a tu repositorio: `https://github.com/TU_USUARIO/ansible`
   - Haz clic en **Settings** (⚙️)
   - En la barra lateral: **Secrets and variables** → **Actions**
   - Haz clic en **New repository secret**
   - **Nombre:** `SSH_PRIVATE_KEY`
   - **Valor:** Pega aquí lo que copiaste (todo incluyendo -----BEGIN-----END)
   - Haz clic en **Add secret**

### ✅ Paso 5: Subir known_hosts (Opcional pero recomendado)

```bash
# Escaneamos el servidor para agregar a known_hosts
ssh-keyscan -H IP_DEL_CLIENTE
```

Si quieres guardarlo como Secret también:

- Nombre: `SSH_KNOWN_HOSTS`
- Valor: El resultado del comando anterior

---

## PARTE 3: En tu Código (El Inventario)

### ✅ Paso 6: Editar el archivo de inventario

Abre: `ansible/inventories/production.yml`

Cambia la IP y el usuario según lo que te dé el profesor:

```yaml
all:
  hosts:
    web1:
      ansible_host: 192.168.X.X # ← LA IP DEL CLIENTE NUEVO
      ansible_user: deploy # ← EL USUARIO DEL CLIENTE
      ansible_python_interpreter: /usr/bin/python3
```

**IMPORTANTE:**

- ❌ NO dejes `ansible_connection: local`
- ✅ Asegúrate de que `ansible_user` sea el mismo al que le enviaste la llave en Paso 2

### ✅ Paso 7: Hacer commit y push

```bash
git add ansible/inventories/production.yml
git commit -m "Update inventory for new client: IP_DEL_CLIENTE"
git push
```

---

## PARTE 4: Verificación

### ✅ Paso 8: Confirmar que funcionó

**Opción A: Desde tu PC**

```bash
# Entra en la carpeta del proyecto
cd ansible

# Prueba rápida de ping
ansible -i inventories/production.yml web1 -m ping

# Si sale SUCCESS en verde: ✅ Funciona
# Si sale ERROR: ❌ Algo falló
```

**Opción B: Usando GitHub Actions**

- Haz push de los cambios (Paso 7)
- Ve a tu repositorio en GitHub
- Pestaña **Actions**
- Mira el último workflow ejecutarse
- Si está verde: ✅ GitHub entró a la máquina
- Si está rojo: ❌ Revisa los logs

---

## Cheatsheet: Quién tiene qué

| Elemento       | Llave                      | Ubicación                           | Función                                     |
| -------------- | -------------------------- | ----------------------------------- | ------------------------------------------- |
| **Tu PC**      | Privada (`id_ed25519`)     | `~/.ssh/id_ed25519`                 | Para identificarte ante la VM               |
| **GitHub**     | Privada (si usas Actions)  | `Secrets > SSH_PRIVATE_KEY`         | Para que GitHub se identifique ante la VM   |
| **VM Cliente** | Pública (`id_ed25519.pub`) | `/home/deploy/.ssh/authorized_keys` | Para aceptar conexiones de la llave privada |

---

## Errores comunes de examen

❌ **"Permission denied (publickey)"**

- La llave pública no está en la VM
- Solución: Vuelve a hacer `ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@IP`

❌ **"Host unreachable"**

- La IP es incorrecta o la VM no está en Adaptador Puente
- Solución: Verifica `ip add` en la VM y la configuración de red

❌ **Ansible pide contraseña**

- El SSH no está configurado sin contraseña
- Solución: Comprueba que `ssh deploy@IP` no pide contraseña

❌ **GitHub Actions falla en SSH**

- El Secret `SSH_PRIVATE_KEY` está vacío o mal configurado
- Solución: Verifica que copied correctamente TODO el contenido del archivo

---

## Resumen rápido si te da pánico en el examen

1. **Generar:** `ssh-keygen -t ed25519`
2. **Enviar llave pública:** `ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@IP`
3. **Editar:** `ansible/inventories/production.yml` con la IP nueva
4. **Probar:** `ansible -i inventories/production.yml web1 -m ping`
5. **Ejecutar:** `ansible-playbook -i inventories/production.yml playbooks/deploy.yml`

¡Éxito! 🚀
