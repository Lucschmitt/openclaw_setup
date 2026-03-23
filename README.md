# 🦞 OpenClaw Setup

Installation clé en main d'OpenClaw avec Tailscale, Signal et Ollama (optionnel).

## Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installé et démarré
- Un compte [Tailscale](https://tailscale.com) (gratuit)
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
- ✅ Tailscale (accès sécurisé via VPN)
- ✅ Anthropic (modèle IA)
- ✅ Signal (messagerie)
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
  ./setup.sh --signal     → Voir les pairings Signal en attente
  ./setup.sh --dashboard  → Obtenir l'URL du dashboard
  ./setup.sh --stop       → Arrêter OpenClaw
  ./setup.sh --start      → Démarrer OpenClaw
  ./setup.sh --logs       → Voir les logs en direct
  ./setup.sh --update     → Mettre à jour OpenClaw
```

## Configuration manuelle

Si vous préférez configurer manuellement :

```bash
cp .env.example .env
# Éditez .env avec vos clés
docker compose up -d
```

## Après l'installation

### 1. Accéder au dashboard

```bash
./setup.sh --dashboard
```

Ouvrez l'URL affichée dans votre navigateur (format `https://openclaw-gateway.votre-tailnet.ts.net/?token=...`).

### 2. Configurer Signal

Envoyez un message depuis votre Signal au numéro du bot, puis :

```bash
./setup.sh --signal
# Notez le code de pairing affiché
docker compose run --rm --profile cli openclaw-cli pairing approve signal CODE
```

### 3. Vérifier que tout fonctionne

```bash
./setup.sh --status
```

## Structure du projet

```
openclaw-setup/
├── docker-compose.yml    ← Stack Docker complète
├── .env.example          ← Template de configuration
├── .env                  ← Votre configuration (créé par setup.sh)
├── setup.ps1             ← Script Windows
├── setup.sh              ← Script Linux/Mac
├── data/
│   └── .openclaw/        ← Données OpenClaw (config, workspace)
└── README.md             ← Ce fichier
```

## Liens utiles

- 📚 [Docs OpenClaw](https://docs.openclaw.ai)
- 🔑 [Console Anthropic](https://console.anthropic.com)
- 🔒 [Admin Tailscale](https://login.tailscale.com/admin/machines)
- 🔍 [Brave Search API](https://api.search.brave.com)
- 🤖 [Modèles Ollama](https://ollama.com/library)

## Dépannage

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
docker compose run --rm --profile cli openclaw-cli dashboard --no-open
```

**Signal ne répond pas**
```bash
docker compose run --rm --profile cli openclaw-cli channels status --probe
docker compose run --rm --profile cli openclaw-cli doctor
```
