# ansible — Despliegue de una app Node.js en AWS EC2 con Ansible y GitHub Actions

Proyecto de prácticas de despliegue automatizado: cada `push` a `main` lanza un workflow de
GitHub Actions que se conecta por SSH a una instancia **AWS EC2 (Ubuntu)** y ejecuta un
playbook de **Ansible** que instala dependencias, descarga la app y la deja corriendo como
servicio **systemd**.

## Qué hace

1. **GitHub Actions** (`.github/workflows/deploy.yml`)
   - Recupera la clave SSH privada desde el secreto `AWS_SSH_KEY` (nunca se guarda en el repo).
   - Comprueba conectividad al puerto 22 y añade el host a `known_hosts`.
   - Instala Ansible y ejecuta el playbook.
2. **Ansible** (rol `node_app`)
   - Instala `git`, `nodejs`, `npm` y Docker (repositorio oficial de Docker).
   - Clona este repositorio en `~/apps/myapp` del servidor.
   - Ejecuta `npm install --production` en `app/`.
   - Crea el servicio `myapp` (systemd) a partir de una plantilla Jinja2 y lo arranca.
3. **App** (`app/index.js`): servidor Express mínimo en el puerto **3000**.

## Estructura

```
.
├── .github/workflows/
│   ├── deploy.yml          # CI/CD: SSH + Ansible contra EC2
│   └── gitleaks.yml        # Escaneo de secretos en push/PR
├── ansible.cfg
├── ansible/
│   ├── inventories/production.yml   # Host, usuario y ruta de la clave
│   ├── playbooks/deploy.yml         # Playbook principal (rol node_app)
│   └── roles/node_app/
│       ├── tasks/main.yml           # Paquetes del sistema y Docker
│       ├── tasks/deploy.yml         # Clonado, npm install y servicio
│       ├── templates/node-app.service.j2
│       └── handlers/main.yml
└── app/                    # App Node.js (Express)
```

## Cómo usarlo

### Requisitos
- Una instancia EC2 Ubuntu con el puerto 22 abierto (y el 3000 si quieres ver la app).
- La clave privada `.pem` de la instancia.

### Despliegue automático (recomendado)
1. En **Settings → Secrets and variables → Actions** crea el secreto `AWS_SSH_KEY` con el contenido de la clave `.pem`.
2. Pon la IP de tu instancia en `ansible/inventories/production.yml` y en `.github/workflows/deploy.yml`.
3. Haz `push` a `main` y revisa la pestaña **Actions**.

### Despliegue manual desde tu equipo
```bash
pip install ansible
cp /ruta/a/tu-clave.pem ansible/key.pem && chmod 600 ansible/key.pem   # ignorado por .gitignore
cd ansible
ansible -i inventories/production.yml all -m ping
ansible-playbook -i inventories/production.yml playbooks/deploy.yml
```

Comprueba el resultado con `curl http://<IP>:3000` o `sudo systemctl status myapp` en el servidor.

## Seguridad
- Las claves (`*.pem`, `*.key`) y los `.env` están en `.gitignore`; la clave solo vive en GitHub Secrets.
- Workflow de **gitleaks** que analiza el historial completo en cada push y pull request.

## Más documentación
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- [GITHUB_ACTIONS_EXPLAINED.md](GITHUB_ACTIONS_EXPLAINED.md)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- [EXAM_CHECKLIST.md](EXAM_CHECKLIST.md)
