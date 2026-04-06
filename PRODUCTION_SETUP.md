# CountryBoy — Production Deployment Guide

**Domain:** `countryboy.co.zw`  
**Registrar:** Webzim.co.zw  
**Server:** Contabo VPS (Ubuntu 22.04 LTS)  
**Stack:** React/Vite (frontend) · Express/Node.js/TypeScript (API) · PostgreSQL · Nginx · PM2 · Let's Encrypt SSL

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [DNS Setup at Webzim](#2-dns-setup-at-webzim)
3. [Initial Server Setup](#3-initial-server-setup)
4. [Install Required Software](#4-install-required-software)
5. [PostgreSQL Setup](#5-postgresql-setup)
6. [App Directory & Environment Files](#6-app-directory--environment-files)
7. [Clone & Build the Project](#7-clone--build-the-project)
8. [PM2 — Backend Process Manager](#8-pm2--backend-process-manager)
9. [Nginx Configuration](#9-nginx-configuration)
10. [SSL Certificate with Let's Encrypt](#10-ssl-certificate-with-lets-encrypt)
11. [Firewall (UFW)](#11-firewall-ufw)
12. [Verify Everything is Working](#12-verify-everything-is-working)
13. [Deployment Workflow (How to Update)](#13-deployment-workflow-how-to-update)
14. [Logs & Monitoring](#14-logs--monitoring)
15. [Security Checklist](#15-security-checklist)
16. [Troubleshooting Reference](#16-troubleshooting-reference)

---

## 1. Architecture Overview

```
              Internet
                 │
         countryboy.co.zw
         api.countryboy.co.zw
                 │
         ┌───── Nginx ─────┐
         │                 │
   Static files       Reverse proxy
   /var/www/countryboy   localhost:3000
   (React build)       (Express API)
                             │
                       PostgreSQL
                       (localhost:5432)
```

- `countryboy.co.zw` → Nginx serves the React build (static files)
- `api.countryboy.co.zw` → Nginx proxies to Express backend on port 3000
- PostgreSQL runs locally — never exposed to the internet
- PM2 keeps the Node.js process alive across reboots and restarts it on crashes
- Let's Encrypt provides free HTTPS for both subdomains

---

## 2. DNS Setup at Webzim

Do this **before** anything else. DNS propagation can take up to 24 hours.

### Steps at Webzim.co.zw

1. Log in to your Webzim account → go to **DNS Manager** for `countryboy.co.zw`
2. Find your Contabo VPS IP address from your Contabo account panel
3. Add the following DNS records:

| Type | Name              | Value                  | TTL  |
|------|-------------------|------------------------|------|
| A    | `@`               | `YOUR_CONTABO_IP`      | 3600 |
| A    | `www`             | `YOUR_CONTABO_IP`      | 3600 |
| A    | `api`             | `YOUR_CONTABO_IP`      | 3600 |

Replace `YOUR_CONTABO_IP` with your actual server IP (e.g. `185.x.x.x`).

### Check DNS propagation

Run this from your local machine (or use https://dnschecker.org):

```bash
nslookup countryboy.co.zw
nslookup api.countryboy.co.zw
```

Both should return your Contabo IP before you proceed to Step 10 (SSL).

---

## 3. Initial Server Setup

Connect to your VPS via SSH:

```bash
ssh root@YOUR_CONTABO_IP
```

### 3.1 — Update the system

```bash
apt update && apt upgrade -y
apt install -y curl wget git unzip build-essential software-properties-common
```

### 3.2 — Create a non-root tafadzwa user

Never run your app as root. Create a dedicated user:

```bash
adduser tafadzwa
# Enter a strong password when prompted, press Enter for everything else

# Give sudo access
usermod -aG sudo tafadzwa

# Copy your SSH key so you can log in as tafadzwa
cp -r /root/.ssh /home/tafadzwa/.ssh
chown -R tafadzwa:tafadzwa /home/tafadzwa/.ssh
chmod 700 /home/tafadzwa/.ssh
chmod 600 /home/tafadzwa/.ssh/authorized_keys
```

Switch to the tafadzwa user for all remaining steps:

```bash
su - tafadzwa
```

### 3.3 — Set timezone

```bash
sudo timedatectl set-timezone Africa/Harare
timedatectl   # verify
```

### 3.4 — Set the hostname

```bash
sudo hostnamectl set-hostname countryboy-prod
```

---

## 4. Install Required Software

### 4.1 — Node.js via NVM (Node Version Manager)

NVM lets you easily switch Node versions. Install the latest LTS version:

```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Reload shell
source ~/.bashrc

# Install Node.js 20 LTS
nvm install 20
nvm use 20
nvm alias default 20

# Verify
node -v   # should show v20.x.x
npm -v
```

### 4.2 — Bun (for building the frontend)

```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

# Verify
bun -v
```

### 4.3 — PM2 (process manager for Node.js)

```bash
npm install -g pm2

# Verify
pm2 -v
```

### 4.4 — Nginx

```bash
sudo apt install -y nginx

# Start and enable on boot
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx   # should show "active (running)"
```

### 4.5 — Certbot (Let's Encrypt SSL)

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 4.6 — PostgreSQL

```bash
sudo apt install -y postgresql postgresql-contrib

# Start and enable on boot
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql   # should show "active (running)"
```

---

## 5. PostgreSQL Setup

### 5.1 — Create the database and user

```bash
sudo -u postgres psql
```

Inside the PostgreSQL shell:

```sql
-- Create the application database
CREATE DATABASE countryboy;

-- Create a dedicated user (replace 'STRONG_DB_PASSWORD' with a real password)
CREATE USER cboyuser WITH ENCRYPTED PASSWORD 'STRONG_DB_PASSWORD';

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE countryboy TO cboyuser;

-- Required for Prisma migrations (grants schema creation rights)
\c countryboy
GRANT ALL ON SCHEMA public TO cboyuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO cboyuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO cboyuser;

-- Exit
\q
```

### 5.2 — Test the connection

```bash
psql -U cboyuser -d countryboy -h localhost
# Enter your password when prompted
# If it connects, type \q to exit
```

### 5.3 — Keep PostgreSQL local-only (security)

PostgreSQL is already configured to only listen on localhost by default. Verify this:

```bash
sudo grep -i listen_addresses /etc/postgresql/*/main/postgresql.conf
# Should show: listen_addresses = 'localhost'
```

If it shows `'*'`, change it:

```bash
sudo nano /etc/postgresql/*/main/postgresql.conf
# Change: listen_addresses = 'localhost'
sudo systemctl restart postgresql
```

---

## 6. App Directory & Environment Files

### 6.1 — Create the app directory structure

```bash
sudo mkdir -p /var/www/countryboy
sudo chown -R tafadzwa:tafadzwa /var/www/countryboy
sudo mkdir -p /var/www/countryboy/frontend   # for built React files
sudo mkdir -p /var/www/countryboy/server     # for backend
```

### 6.2 — Backend environment file

```bash
nano /var/www/countryboy/server/.env
```

Paste and fill in ALL values:

```env
# Server
NODE_ENV=production
PORT=3000
HOST=127.0.0.1

# Database — must match what you set in Step 5.1
DATABASE_URL="postgresql://countryboy_user:STRONG_DB_PASSWORD@localhost:5432/countryboy_prod"

# JWT Secrets — generate these with: openssl rand -base64 64
JWT_SECRET=REPLACE_WITH_LONG_RANDOM_SECRET_64_CHARS
JWT_RESET_SECRET=REPLACE_WITH_DIFFERENT_LONG_RANDOM_SECRET

# CORS — frontend origin
CORS_ORIGINS=https://countryboy.co.zw,https://www.countryboy.co.zw

# Email (SMTP) — your email provider credentials
SMTP_HOST=smtp.yourmailprovider.com
SMTP_PORT=587
SMTP_USER=noreply@countryboy.co.zw
SMTP_PASS=YOUR_EMAIL_PASSWORD
SMTP_FROM="CountryBoy <noreply@countryboy.co.zw>"
```

> **Generate secure JWT secrets** on the server:
> ```bash
> openssl rand -base64 64
> # Run twice — one for JWT_SECRET, one for JWT_RESET_SECRET
> ```

Protect the .env file:

```bash
chmod 600 /var/www/countryboy/server/.env
```

---

## 7. Clone & Build the Project

### 7.1 — Clone the repository

```bash
cd /var/www/countryboy

git clone https://github.com/tfeadzwa/countryboy.git .
# If your repo is private you will need to authenticate with a deploy key or PAT
```

> **If your repo is private**, set up a GitHub deploy key:
> ```bash
> ssh-keygen -t ed25519 -C "tafadzwa@countryboy-prod" -f ~/.ssh/github_deploy
> cat ~/.ssh/github_deploy.pub
> # Copy the output and add it as a Deploy Key in GitHub:
> # GitHub repo → Settings → Deploy keys → Add deploy key
>
> # Add to SSH config
> nano ~/.ssh/config
> # Paste:
> # Host github.com
> #   IdentityFile ~/.ssh/github_deploy
> #   StrictHostKeyChecking no
>
> # Now clone with SSH:
> git clone git@github.com:tfeadzwa/countryboy.git .
> ```

### 7.2 — Build the backend

```bash
cd /var/www/countryboy/server

# Install dependencies (production + dev needed for build)
npm install

# Compile TypeScript to JavaScript
npm run build
# Output goes to: server/dist/

# Generate Prisma client
npx prisma generate

# Run database migrations
npx prisma migrate deploy
# This applies all pending migrations in prisma/migrations/ to the production DB

# Verify the build
ls dist/
# You should see index.js and other compiled files
```

### 7.3 — Build the frontend

```bash
cd /var/www/countryboy/frontend

# Install dependencies
bun install

# Set the API URL for production build
# Create a production env file
nano .env.production
```

Paste into `.env.production`:

```env
VITE_API_URL=https://api.countryboy.co.zw
```

> If your frontend uses a different env variable name (e.g. `VITE_API_BASE_URL`), check your `src/lib/api` files and use the correct name.

Now build:

```bash
bun run build
# Output goes to: frontend/dist/

# Copy the built files to the web directory
cp -r dist/. /var/www/countryboy/frontend/
```

### 7.4 — Check the API base URL in the frontend

Before building, verify how your frontend calls the API:

```bash
grep -r "VITE_API" /var/www/countryboy/frontend/src/lib/ | head -20
```

Make sure your `apiClient` (axios instance) is reading from `import.meta.env.VITE_API_URL`.

---

## 8. PM2 — Backend Process Manager

PM2 keeps the backend running, restarts it on crashes, and starts it automatically on server reboot.

### 8.1 — Create PM2 ecosystem config

```bash
nano /var/www/countryboy/server/ecosystem.config.cjs
```

Paste:

```javascript
module.exports = {
  apps: [
    {
      name: 'countryboy-api',
      script: './dist/index.js',
      cwd: '/var/www/countryboy/server',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      // Restart if memory exceeds 500MB
      max_memory_restart: '500M',
      // Log configuration
      out_file: '/var/log/countryboy/api-out.log',
      error_file: '/var/log/countryboy/api-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      // Auto-restart settings
      restart_delay: 3000,
      max_restarts: 10,
    },
  ],
};
```

Create the log directory:

```bash
sudo mkdir -p /var/log/countryboy
sudo chown -R tafadzwa:tafadzwa /var/log/countryboy
```

### 8.2 — Start the backend with PM2

```bash
cd /var/www/countryboy/server

pm2 start ecosystem.config.cjs

# Check it is running
pm2 status
pm2 logs countryboy-api --lines 50

# Test the API responds
curl http://localhost:3000/api
# Should return: {"status":"ok","version":"1.0.0"}
```

### 8.3 — Persist PM2 across reboots

```bash
pm2 save

# Generate and install startup script
pm2 startup
# This prints a command like: sudo env PATH=... pm2 startup systemd -u tafadzwa --hp /home/tafadzwa
# COPY AND RUN that exact command it prints
```

---

## 9. Nginx Configuration

### 9.1 — Remove the default Nginx site

```bash
sudo rm /etc/nginx/sites-enabled/default
```

### 9.2 — Frontend site config

```bash
sudo nano /etc/nginx/sites-available/countryboy-frontend
```

Paste:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name countryboy.co.zw www.countryboy.co.zw;

    root /var/www/countryboy/frontend;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript
               application/rss+xml application/atom+xml image/svg+xml;

    # Cache static assets aggressively (Vite hashes filenames)
    location ~* \.(js|css|woff2?|png|jpg|jpeg|gif|svg|ico|webp)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # React Router — send all routes to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
}
```

### 9.3 — API site config

```bash
sudo nano /etc/nginx/sites-available/countryboy-api
```

Paste:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name api.countryboy.co.zw;

    # Proxy to Node.js backend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Body size limit (for file uploads etc.)
        client_max_body_size 10M;
    }

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
}
```

### 9.4 — Enable both sites

```bash
sudo ln -s /etc/nginx/sites-available/countryboy-frontend /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/countryboy-api /etc/nginx/sites-enabled/

# Test the config
sudo nginx -t
# Should print: configuration file /etc/nginx/nginx.conf test is successful

# Reload Nginx
sudo systemctl reload nginx
```

---

## 10. SSL Certificate with Let's Encrypt

> **DNS must be propagated first** (Step 2). If DNS isn't pointing to your server yet, Certbot will fail.

### 10.1 — Obtain certificates

```bash
sudo certbot --nginx -d countryboy.co.zw -d www.countryboy.co.zw -d api.countryboy.co.zw
```

Follow the prompts:
- Enter your email address (used for renewal reminders)
- Agree to terms: `A`
- Share email with EFF (optional): `N` or `Y`
- Certbot will automatically modify your Nginx configs to add HTTPS

### 10.2 — Test auto-renewal

Certificates expire every 90 days and auto-renew via a system timer. Test the renewal process:

```bash
sudo certbot renew --dry-run
# Should complete with "Congratulations, all simulated renewals succeeded"
```

### 10.3 — Verify the renewal timer is active

```bash
sudo systemctl status certbot.timer
# Should show "active (waiting)"
```

After Certbot runs, your Nginx configs will be automatically updated to redirect HTTP → HTTPS and serve on port 443.

---

## 11. Firewall (UFW)

Restrict what reaches your server. Only allow SSH, HTTP, and HTTPS:

```bash
# Enable UFW
sudo ufw enable

# Allow SSH (critical — do this BEFORE enabling UFW)
sudo ufw allow 22/tcp

# Allow web traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Deny everything else
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Verify rules
sudo ufw status verbose
```

Expected output:

```
Status: active

To                 Action     From
--                 ------     ----
22/tcp             ALLOW IN   Anywhere
80/tcp             ALLOW IN   Anywhere
443/tcp            ALLOW IN   Anywhere
```

> **Important:** Port 3000 (the Node.js API) is NOT open. Traffic only reaches it through Nginx. This is correct.

---

## 12. Verify Everything is Working

Run these checks in order:

```bash
# 1. Is the API running?
pm2 status
curl http://localhost:3000/api
# Expected: {"status":"ok","version":"1.0.0"}

# 2. Is Nginx working?
sudo nginx -t
sudo systemctl status nginx

# 3. Is the database connected?
pm2 logs countryboy-api --lines 30
# Look for "Server listening on" — no DB errors

# 4. Check the frontend is being served
curl -I http://countryboy.co.zw
# After SSL: curl -I https://countryboy.co.zw
# Expected: HTTP 200

# 5. Check the API is reachable through Nginx
curl https://api.countryboy.co.zw/api
# Expected: {"status":"ok","version":"1.0.0"}

# 6. Check SSL certificates
sudo certbot certificates
# Should list both domains with expiry dates
```

Open in a browser:
- `https://countryboy.co.zw` — should show the admin login page
- `https://api.countryboy.co.zw/api` — should return `{"status":"ok"}`

---

## 13. Deployment Workflow (How to Update)

Every time you push new code and want to deploy it to production:

### 13.1 — Create a deploy script

```bash
nano /var/www/countryboy/deploy.sh
```

Paste:

```bash
#!/bin/bash
set -e   # Exit immediately on error

echo "=== [1/6] Pulling latest code ==="
cd /var/www/countryboy
git pull origin main

echo "=== [2/6] Building backend ==="
cd /var/www/countryboy/server
npm install --omit=dev    # skip dev deps in production
npm install               # need TypeScript etc. for build
npm run build
npx prisma generate
npx prisma migrate deploy

echo "=== [3/6] Restarting API ==="
pm2 restart countryboy-api

echo "=== [4/6] Building frontend ==="
cd /var/www/countryboy/frontend
bun install
bun run build

echo "=== [5/6] Deploying frontend ==="
rm -rf /var/www/countryboy/frontend-dist
cp -r dist /var/www/countryboy/frontend-dist
# Swap atomically
rm -rf /var/www/countryboy/frontend-live
mv /var/www/countryboy/frontend-dist /var/www/countryboy/frontend-live

# Update Nginx root if needed — or keep root pointing to frontend-live

echo "=== [6/6] Reload Nginx ==="
sudo nginx -t && sudo systemctl reload nginx

echo ""
echo "=== Deployment complete ==="
pm2 status
```

Make it executable:

```bash
chmod +x /var/www/countryboy/deploy.sh
```

Run a deployment:

```bash
/var/www/countryboy/deploy.sh
```

> **Note:** Update the Nginx `root` directive in `countryboy-frontend` to `/var/www/countryboy/frontend-live` if you use the atomic swap above. Otherwise point it directly at `/var/www/countryboy/frontend/dist`.

### 13.2 — Simple one-liner for quick updates (backend only)

```bash
cd /var/www/countryboy && git pull && cd server && npm run build && pm2 restart countryboy-api
```

---

## 14. Logs & Monitoring

### PM2 logs (backend app logs)

```bash
# Live streaming logs
pm2 logs countryboy-api

# Last 100 lines
pm2 logs countryboy-api --lines 100

# Error log only
tail -f /var/log/countryboy/api-error.log

# Output log (all logs)
tail -f /var/log/countryboy/api-out.log
```

### Nginx logs

```bash
# Access log (every request)
sudo tail -f /var/log/nginx/access.log

# Error log
sudo tail -f /var/log/nginx/error.log
```

### PostgreSQL logs

```bash
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### System resources

```bash
# CPU, memory, processes
htop

# Disk usage
df -h

# Check what's using ports
sudo ss -tlnp | grep -E '80|443|3000|5432'
```

### PM2 monitoring dashboard

```bash
pm2 monit
# Shows CPU/memory per process in real time
```

---

## 15. Security Checklist

After deployment, verify each item:

- [ ] **Root login disabled:** `sudo nano /etc/ssh/sshd_config` → `PermitRootLogin no` → `sudo systemctl restart sshd`
- [ ] **Password SSH disabled (key-only):** `PasswordAuthentication no` in sshd_config
- [ ] **UFW enabled** with only ports 22, 80, 443 open
- [ ] **PostgreSQL not exposed** — only listens on localhost
- [ ] **Port 3000 not exposed** — traffic only via Nginx
- [ ] **.env file permission 600** — `chmod 600 /var/www/countryboy/server/.env`
- [ ] **Strong JWT secrets** — at least 64 random characters each
- [ ] **HTTPS enforced** — HTTP redirects to HTTPS (Certbot does this automatically)
- [ ] **Nginx security headers set** — X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- [ ] **Database user has limited privileges** — app user cannot `DROP DATABASE` or create roles
- [ ] **No dev dependencies in production** for the running app
- [ ] **Certbot auto-renewal working** — `certbot renew --dry-run` passes

---

## 16. Troubleshooting Reference

### Problem: `502 Bad Gateway` on API

The backend isn't running or isn't listening. Check:

```bash
pm2 status
pm2 logs countryboy-api --lines 50
curl http://localhost:3000/api
```

If the process is errored, check for .env issues:

```bash
cat /var/www/countryboy/server/.env
pm2 restart countryboy-api
pm2 logs countryboy-api --lines 20
```

---

### Problem: `404 Not Found` on all frontend routes in production

React Router routes return 404 because Nginx doesn't know about client-side routing. Fix: ensure the `try_files $uri $uri/ /index.html;` line is in your Nginx frontend config (it is in the config above). After editing, run `sudo nginx -t && sudo systemctl reload nginx`.

---

### Problem: Certbot fails — "DNS problem: NXDOMAIN"

DNS hasn't propagated yet. Wait and try again:

```bash
# Check if DNS resolves
nslookup api.countryboy.co.zw 8.8.8.8
```

Only run Certbot once DNS returns your IP.

---

### Problem: Prisma migration fails

```bash
cd /var/www/countryboy/server
npx prisma migrate status   # shows pending migrations
npx prisma migrate deploy   # apply pending
```

If migrations are in a bad state:

```bash
npx prisma migrate resolve --applied "migration_name"
```

---

### Problem: Frontend API calls fail (CORS error)

Check that `CORS_ORIGINS` in the server `.env` exactly matches the frontend domain including protocol:

```env
CORS_ORIGINS=https://countryboy.co.zw,https://www.countryboy.co.zw
```

Restart the backend after changing:

```bash
pm2 restart countryboy-api
```

---

### Problem: PM2 doesn't survive server reboot

```bash
pm2 save
pm2 startup
# Run the exact command it outputs (starts with "sudo env PATH=...")
```

---

### Problem: `ECONNREFUSED` to PostgreSQL

The database isn't running or the credentials are wrong:

```bash
sudo systemctl status postgresql
sudo systemctl start postgresql

# Test connection
psql -U countryboy_user -d countryboy_prod -h localhost
```

---

## Quick Reference — Useful Commands

| Task | Command |
|------|---------|
| Deploy update | `/var/www/countryboy/deploy.sh` |
| Restart API | `pm2 restart countryboy-api` |
| View API logs | `pm2 logs countryboy-api` |
| Reload Nginx | `sudo systemctl reload nginx` |
| Test Nginx config | `sudo nginx -t` |
| Renew SSL | `sudo certbot renew` |
| Check processes | `pm2 status` |
| Check disk | `df -h` |
| Check open ports | `sudo ss -tlnp` |
| Postgres shell | `sudo -u postgres psql` |
| Connect to app DB | `psql -U countryboy_user -d countryboy_prod -h localhost` |

---

*Guide written for CountryBoy v0.1.0 — Ubuntu 22.04 LTS — March 2026*
