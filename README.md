# 🦞 OpenClaw Setup

Installation clé en main d'OpenClaw avec Tailscale, Signal et Ollama (optionnel).

## Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installé et démarré
- Un compte [Tailscale](https://tailscale.com) (gratuit) avec **HTTPS activé** (admin.tailscale.com → DNS → HTTPS Certificates)
- Une clé API [Anthropic](https://console.anthropic.com) avec des crédits
- Un numéro de téléphone dédié pour le bot Signal

## Installation rapide

### Windows (PowerShell)

```powershell
git clone https://github.com/VOTRE-REPO/openclaw-setup.git
cd openclaw-setup
.\setup.ps1
```

### Linux / Mac

```bash
git clone https://github.com/VOTRE-REPO/openclaw-setup.git
cd openclaw-setup
chmod +x setup.sh
./setup.sh
```

Le script vous guidera pas à pas pour configurer :
- ✅ Tailscale (accès sécurisé HTTPS via VPN)
- ✅ Anthropic (modèle IA)
- ✅ Signal (messagerie — enregistrement + pairing automatiques)
- ✅ Brave Search (recherche web, optionnel)
- ✅ Ollama / Qwen (LLM local, optionnel)

## Menu d'aide

```powershell
# Windows
.\setup.ps1 --help

# Linux/Mac
./setup.sh --help
```

```
Commandes disponibles :
  ./setup.sh              → Installation complète
  ./setup.sh --help       → Ce menu
  ./setup.sh --status     → État des conteneurs
  ./setup.sh --signal     → Pairing Signal interactif
  ./setup.sh --dashboard  → Obtenir l'URL du dashboard
  ./setup.sh --stop       → Arrêter OpenClaw
  ./setup.sh --start      → Démarrer OpenClaw
  ./setup.sh --logs       → Voir les logs en direct
  ./setup.sh --update     → Mettre à jour OpenClaw
```

## Après l'installation

### 1. Accéder au dashboard

```bash
./setup.sh --dashboard
```

Ouvrez l'URL affichée dans votre navigateur (format `https://openclaw-gateway.votre-tailnet.ts.net/?token=...`).

> ⚠️ Le token dans l'URL est obligatoire — sans lui vous verrez "unauthorized".

### 2. Si vous perdez l'accès au dashboard

Cela peut arriver après un redémarrage. Voici la procédure complète :

**Étape 1 — Récupérer l'URL avec token :**
```bash
./setup.sh --dashboard
```

**Étape 2 — Ouvrir l'URL dans votre navigateur**

Vous verrez peut-être "pairing required" — c'est normal, votre navigateur doit être approuvé.

**Étape 3 — Approuver votre device :**
```bash
# Lister les devices en attente
docker compose run --rm openclaw-cli devices list

# Approuver avec l'ID affiché
docker compose run --rm openclaw-cli devices approve <ID>
```

**Étape 4 — Rafraîchir la page**

Le dashboard est de nouveau accessible.

> 💡 Tailscale Serve est configuré pour démarrer automatiquement — vous n'avez pas à relancer `tailscale serve` manuellement.

### 3. Configurer Signal

Envoyez un message depuis votre Signal au numéro du bot, puis :

```bash
./setup.sh --signal
```

### 4. Vérifier que tout fonctionne

```bash
./setup.sh --status
```

## Structure du projet

```
openclaw-setup/
├── docker-compose.yml        ← Stack Docker complète
├── tailscale-serve.json      ← Config Tailscale Serve (HTTPS auto)
├── .env.example              ← Template de configuration
├── .env                      ← Votre configuration (créé par setup.sh)
├── setup.ps1                 ← Script Windows
├── setup.sh                  ← Script Linux/Mac
├── data/
│   └── .openclaw/            ← Données OpenClaw (config, workspace)
└── README.md                 ← Ce fichier
```

## Liens utiles

- 📚 [Docs OpenClaw](https://docs.openclaw.ai)
- 🔑 [Console Anthropic](https://console.anthropic.com)
- 🔒 [Admin Tailscale](https://login.tailscale.com/admin/machines)
- 🔍 [Brave Search API](https://api.search.brave.com)
- 🤖 [Modèles Ollama](https://ollama.com/library)

## Dépannage

**Dashboard inaccessible après redémarrage**
```bash
./setup.sh --dashboard   # Récupérer l'URL avec token
docker compose run --rm openclaw-cli devices list
docker compose run --rm openclaw-cli devices approve <ID>
```

**OpenClaw ne démarre pas**
```bash
./setup.sh --logs
```

**Tailscale non connecté**
```bash
docker exec openclaw-tailscale-1 tailscale status
```

**Token OpenClaw invalide**
```bash
docker compose run --rm openclaw-cli dashboard --no-open
```

**Signal ne répond pas**
```bash
docker compose run --rm openclaw-cli channels status --probe
docker compose run --rm openclaw-cli doctor
```
