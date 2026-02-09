# ⚡ CHEATSHEET EXAMEN ANSIBLE (30 segundos!)

## CUANDO TE DAN UNA MÁQUINA NUEVA

### 1️⃣ EN LA NUEVA VM (Una sola vez)

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@IP_NUEVA
# Pone tu llave PÚBLICA en authorized_keys de la VM
```

### 2️⃣ EN TU PC (Actualiza el inventario)

```bash
# Edita: ansible/inventories/production.yml
# Cambia:
#   ansible_host: IP_NUEVA
#   ansible_user: usuario (el de la VM)

nano ansible/inventories/production.yml
```

### 3️⃣ PRUEBA RÁPIDA

```bash
ssh usuario@IP_NUEVA
# ← Si entra sin pedir password: ✅
# ← Si pide password: ❌ Repite paso 1

# O usa Ansible para probar:
ansible -i inventories/production.yml web1 -m ping
```

### 4️⃣ EJECUTA

```bash
cd ansible
ansible-playbook -i inventories/production.yml playbooks/deploy.yml -v
```

---

## GITHUB ACTIONS (Si lo pide en examen)

### Setup en GitHub (Una sola vez)

1. Copia tu llave privada:

```bash
cat ~/.ssh/id_ed25519
```

2. En GitHub:
   - Settings → Secrets → New secret
   - Nombre: `SSH_PRIVATE_KEY`
   - Valor: Lo que copiaste

3. Push:

```bash
git push
```

→ GitHub Actions se ejecuta automáticamente

---

## ERRORES Y FIXES

| Error                     | Fix                                               |
| ------------------------- | ------------------------------------------------- |
| `Permission denied`       | `ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@IP` |
| `Host unreachable`        | Verifica IP con `ip add` en la VM                 |
| `pide password`           | `ssh` no configurado sin password                 |
| `ansible_user incorrecto` | Verifica que coincide en production.yml           |

---

## COMANDOS IMPORTANTES

```bash
# Ver IP de la VM
ip add

# Generar claves (si no las tienes)
ssh-keygen -t ed25519

# Copiar llave al cliente
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@IP

# Probar SSH
ssh usuario@IP

# Probar Ansible
ansible -i inventories/production.yml web1 -m ping

# Ejecutar playbook
ansible-playbook -i inventories/production.yml playbooks/deploy.yml -v

# Ver logs si falla
git log --oneline
```

---

## ARCHIVOS CLAVE (No olvides cuáles cambiar)

```
✅ CAMBIAR:
   └─ ansible/inventories/production.yml
      ├─ ansible_host: IP_NUEVA
      └─ ansible_user: usuario

❌ NO CAMBIAR:
   ├─ ansible/playbooks/deploy.yml
   ├─ ansible/roles/*
   ├─ .github/workflows/ci-cd.yml
   └─ app/
```

---

## TEST FINAL

```bash
# ¿Mi SSH funciona?
ssh usuario@IP
# → Entra sin pwd: ✅

# ¿Mi Ansible ve la máquina?
ansible -i inventories/production.yml all -m ping
# → Say pong: ✅

# ¿Todo el playbook?
ansible-playbook -i inventories/production.yml playbooks/deploy.yml
# → Sin errores: ✅
```

---

## SI NO SABES QUÉ PASÓ

```bash
# Ver el contenido del inventario
cat ansible/inventories/production.yml

# Ver si tienes llaves SSH
ls -la ~/.ssh/

# Probar conexión SSH con verbosidad
ssh -vv usuario@IP

# Ejecutar Ansible con más detalles
ansible-playbook -i inventories/production.yml playbooks/deploy.yml -vvv

# Ver si GitHub tiene el Secret
# (Ve a Settings → Secrets en tu repo)
```

---

## TIMELINE RECOMENDADO EXAMEN

⏱️ **5 min:** Setup SSH (`ssh-keygen`, `ssh-copy-id`)
⏱️ **2 min:** Editar `production.yml`
⏱️ **2 min:** Prueba (`ansible -m ping`)
⏱️ **5 min:** Ejecutar playbook
⏱️ **1 min:** Verificar que funciona

= 15 minutos máximo ⚡

---

## 🚀 IMPORTANTE

```
TU MÁQUINA:         GitHub:           VM CLIENTE:
- id_ed25519        - SSH_PRIVATE_KEY - authorized_keys
  (privada)           (privada)        (pública)

REGLA DE ORO:
❌ Nunca hagas ssh-copy-id de la PRIVADA
✅ Solo copia la PÚBLICA al cliente
```

---

**Luck! 🍀**
