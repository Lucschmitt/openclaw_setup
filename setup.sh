#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         OpenClaw Setup — Script d'installation Linux/Mac    ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# ── Couleurs ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; GRAY='\033[0;37m'; NC='\033[0m'

header() {
    clear
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║    🦞  OpenClaw Setup — Installation         ║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

step()    { echo -e "  ${YELLOW}[$1/$2] $3${NC}"; echo ""; }
ok()      { echo -e "    ${GREEN}✅ $1${NC}"; }
err()     { echo -e "    ${RED}❌ $1${NC}"; }
info()    { echo -e "    ${CYAN}ℹ️  $1${NC}"; }
warn()    { echo -e "    ${YELLOW}⚠️  $1${NC}"; }

prompt_required() {
    local label=$1 placeholder=$2 value=""
    while [[ -z "$value" ]]; do
        printf "    → %s" "$label"
        [[ -n "$placeholder" ]] && printf " \033[0;37m(%s)\033[0m" "$placeholder"
        printf " : "
        read -r value
        [[ -z "$value" ]] && err "Ce champ est obligatoire."
    done
    echo "$value"
}

prompt_optional() {
    local label=$1 default=$2
    printf "    → %s" "$label"
    [[ -n "$default" ]] && printf " \033[0;37m[%s]\033[0m" "$default"
    printf " : "
    read -r value
    echo "${value:-$default}"
}

prompt_yesno() {
    printf "    → %s [o/N] : " "$1"
    read -r value
    [[ "$value" =~ ^[oOyY]$ ]]
}

# ── Menu d'aide ───────────────────────────────────────────────
show_help() {
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║              Menu d'aide                     ║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}Commandes disponibles :${NC}"
    echo -e "    ${WHITE}./setup.sh              ${NC}→ Installation complète"
    echo -e "    ${WHITE}./setup.sh --help       ${NC}→ Ce menu"
    echo -e "    ${WHITE}./setup.sh --status     ${NC}→ État des conteneurs"
    echo -e "    ${WHITE}./setup.sh --signal     ${NC}→ Configurer Signal"
    echo -e "    ${WHITE}./setup.sh --dashboard  ${NC}→ Obtenir l'URL du dashboard"
    echo -e "    ${WHITE}./setup.sh --stop       ${NC}→ Arrêter OpenClaw"
    echo -e "    ${WHITE}./setup.sh --start      ${NC}→ Démarrer OpenClaw"
    echo -e "    ${WHITE}./setup.sh --logs       ${NC}→ Voir les logs en direct"
    echo -e "    ${WHITE}./setup.sh --update     ${NC}→ Mettre à jour OpenClaw"
    echo ""
    echo -e "  ${YELLOW}Liens utiles :${NC}"
    echo -e "    ${CYAN}Docs OpenClaw  : https://docs.openclaw.ai${NC}"
    echo -e "    ${CYAN}Tailscale      : https://login.tailscale.com/admin/machines${NC}"
    echo -e "    ${CYAN}Anthropic      : https://console.anthropic.com${NC}"
    echo -e "    ${CYAN}Brave Search   : https://api.search.brave.com${NC}"
    echo ""
    exit 0
}

# ── Sous-commandes ────────────────────────────────────────────
case "${1:-}" in
    --help)     show_help ;;
    --status)
        echo -e "\n  ${YELLOW}État des conteneurs :${NC}"
        docker compose ps
        echo -e "\n  ${YELLOW}État Tailscale :${NC}"
        docker exec openclaw-tailscale-1 tailscale status
        exit 0 ;;
    --dashboard)
        docker compose run --rm --profile cli openclaw-cli dashboard --no-open
        exit 0 ;;
    --signal)
        echo -e "\n  ${YELLOW}Pairings Signal en attente :${NC}"
        docker compose run --rm --profile cli openclaw-cli pairing list signal
        exit 0 ;;
    --stop)
        docker compose down && ok "OpenClaw arrêté" ; exit 0 ;;
    --start)
        docker compose up -d && ok "OpenClaw démarré" ; exit 0 ;;
    --logs)
        docker compose logs -f ; exit 0 ;;
    --update)
        echo -e "  ${YELLOW}Mise à jour...${NC}"
        docker compose pull && docker compose up -d && ok "OpenClaw mis à jour"
        exit 0 ;;
esac

# ══════════════════════════════════════════════════════════════
header

# ── ÉTAPE 1 — Prérequis ───────────────────────────────────────
step 1 5 "Vérification des prérequis..."

if command -v docker &>/dev/null; then
    ok "Docker détecté : $(docker --version)"
else
    err "Docker non trouvé. Installez Docker : https://docs.docker.com/get-docker/"
    exit 1
fi

if docker ps &>/dev/null; then
    ok "Docker est démarré"
else
    err "Docker n'est pas démarré."
    exit 1
fi

command -v git &>/dev/null && ok "Git détecté" || warn "Git non trouvé (optionnel)"

echo ""

# ── ÉTAPE 2 — Tailscale ──────────────────────────────────────
step 2 5 "Configuration Tailscale"
info "Obtenez votre clé sur : https://login.tailscale.com/admin/settings/keys"
info "Cochez : Reusable + Pre-authorized"
echo ""

TS_AUTHKEY=$(prompt_required "Clé Auth Tailscale" "tskey-auth-...")
TS_HOSTNAME=$(prompt_optional "Nom du device dans votre tailnet" "openclaw-gateway")
echo ""

# ── ÉTAPE 3 — Anthropic ──────────────────────────────────────
step 3 5 "Configuration Anthropic"
info "Obtenez votre clé sur : https://console.anthropic.com/settings/keys"
echo ""

ANTHROPIC_KEY=$(prompt_required "Clé API Anthropic" "sk-ant-...")
echo ""

# ── ÉTAPE 4 — Signal ─────────────────────────────────────────
step 4 5 "Configuration Signal"
info "Utilisez un numéro DÉDIÉ pour le bot (pas votre numéro personnel)"
info "Format international : +33612345678"
echo ""

SIGNAL_BOT=$(prompt_required "Numéro du bot Signal" "+33XXXXXXXXX")
SIGNAL_OWNER=$(prompt_required "Votre numéro personnel Signal" "+33XXXXXXXXX")
echo ""

# Options
echo -e "  ${YELLOW}Options supplémentaires :${NC}"; echo ""

BRAVE_KEY=$(prompt_optional "Clé API Brave Search (optionnel)" "")
echo ""

ENABLE_OLLAMA=false
OLLAMA_MODEL="qwen2.5:7b"
if prompt_yesno "Activer Ollama (LLM local, nécessite un GPU NVIDIA)"; then
    ENABLE_OLLAMA=true
    echo ""
    info "Modèles recommandés :"
    info "  6GB VRAM  → qwen2.5:7b (recommandé)"
    info "  8GB VRAM  → mistral:7b"
    info "  16GB VRAM → qwen2.5:14b"
    OLLAMA_MODEL=$(prompt_optional "Modèle Ollama" "qwen2.5:7b")
fi
echo ""

# ── ÉTAPE 5 — Génération .env ────────────────────────────────
step 5 5 "Création de la configuration..."

mkdir -p ./data/.openclaw/workspace
ok "Dossiers de données créés"

cat > .env << EOF
# OpenClaw — Configuration générée le $(date '+%d/%m/%Y %H:%M')

# ── TAILSCALE ─────────────────────────────────────────────────
TS_AUTHKEY=$TS_AUTHKEY
TS_HOSTNAME=$TS_HOSTNAME

# ── ANTHROPIC ─────────────────────────────────────────────────
ANTHROPIC_API_KEY=$ANTHROPIC_KEY

# ── SIGNAL ────────────────────────────────────────────────────
SIGNAL_BOT_NUMBER=$SIGNAL_BOT
SIGNAL_OWNER_NUMBER=$SIGNAL_OWNER

# ── BRAVE SEARCH ──────────────────────────────────────────────
BRAVE_API_KEY=$BRAVE_KEY

# ── OLLAMA ────────────────────────────────────────────────────
ENABLE_OLLAMA=$ENABLE_OLLAMA
OLLAMA_MODEL=$OLLAMA_MODEL

# ── CHEMINS ───────────────────────────────────────────────────
OPENCLAW_CONFIG_DIR=./data/.openclaw
OPENCLAW_WORKSPACE_DIR=./data/.openclaw/workspace
OPENCLAW_TZ=Europe/Paris
OPENCLAW_GATEWAY_TOKEN=
EOF

ok "Fichier .env créé"
echo ""

# ── Lancement ────────────────────────────────────────────────
echo -e "  ${YELLOW}Démarrage des conteneurs...${NC}"; echo ""

if [[ "$ENABLE_OLLAMA" == "true" ]]; then
    docker compose --profile ollama up -d
else
    docker compose up -d
fi

sleep 3

# ── Onboarding ───────────────────────────────────────────────
echo ""
warn "Lancement de l'assistant de configuration OpenClaw..."
sleep 2
docker compose run --rm --profile cli openclaw-cli onboard

# ── Tailscale Serve ──────────────────────────────────────────
echo ""
echo -e "  ${YELLOW}Activation de Tailscale Serve (HTTPS)...${NC}"
sleep 5
docker exec openclaw-tailscale-1 tailscale serve --bg 18789 2>/dev/null || true

# ── URL Dashboard ────────────────────────────────────────────
DNS_NAME=$(docker exec openclaw-tailscale-1 tailscale status --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Self']['DNSName'].rstrip('.'))" 2>/dev/null || echo "votre-tailnet.ts.net")

# ── Résumé final ─────────────────────────────────────────────
header
echo -e "  ${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║        ✅  Installation terminée !           ║${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${WHITE}📱 Signal Bot  : $SIGNAL_BOT${NC}"
echo -e "  ${CYAN}🌐 Dashboard   : https://$DNS_NAME${NC}"
echo -e "  ${WHITE}📚 Docs        : https://docs.openclaw.ai${NC}"
echo ""
echo -e "  ${GRAY}─────────────────────────────────────────────${NC}"
echo -e "  ${YELLOW}Prochaines étapes :${NC}"
echo -e "  ${WHITE}1. Ouvrez le dashboard dans votre navigateur${NC}"
echo -e "  ${WHITE}2. Récupérez l'URL avec token : ./setup.sh --dashboard${NC}"
echo -e "  ${WHITE}3. Configurez Signal          : ./setup.sh --signal${NC}"
echo -e "  ${GRAY}─────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${GRAY}💡 Aide : ./setup.sh --help${NC}"
echo ""
