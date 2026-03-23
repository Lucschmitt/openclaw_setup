#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         OpenClaw Setup — Script d'installation Linux/Mac    ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

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

step()  { echo -e "  ${YELLOW}[$1/$2] $3${NC}"; echo ""; }
ok()    { echo -e "    ${GREEN}✅ $1${NC}"; }
err()   { echo -e "    ${RED}❌ $1${NC}"; }
info()  { echo -e "    ${CYAN}ℹ️  $1${NC}"; }
warn()  { echo -e "    ${YELLOW}⚠️  $1${NC}"; }
sep()   { echo -e "  ${GRAY}─────────────────────────────────────────────${NC}"; }

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

# ── Fonction pairing Signal ───────────────────────────────────
signal_pairing() {
    local bot_number=$1 owner_number=$2
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║        📱  Pairing Signal                    ║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    info "Depuis votre application Signal sur votre téléphone :"
    echo ""
    echo -e "    ${WHITE}Envoyez n'importe quel message${NC}"
    echo -e "    ${YELLOW}DE  : $owner_number  (votre numéro personnel)${NC}"
    echo -e "    ${YELLOW}AU  : $bot_number    (le numéro du bot)${NC}"
    echo ""
    warn "En attente du message... (Ctrl+C pour annuler)"
    echo ""

    local found=false attempts=0 max_attempts=60
    while [[ "$found" == "false" && $attempts -lt $max_attempts ]]; do
        sleep 5
        ((attempts++))
        local pairings
        pairings=$(docker compose run --rm openclaw-cli pairing list signal 2>&1)
        if echo "$pairings" | grep -qE "[A-Z]{8}"; then
            local code
            code=$(echo "$pairings" | grep -oE "[A-Z]{8}" | head -1)
            found=true
            echo ""
            ok "Demande de pairing reçue !"
            echo ""
            echo -e "    ${CYAN}Code   : $code${NC}"
            echo -e "    ${WHITE}De     : $owner_number${NC}"
            echo ""
            if prompt_yesno "Confirmer et approuver le pairing pour $owner_number"; then
                docker compose run --rm openclaw-cli pairing approve signal "$code" > /dev/null 2>&1
                ok "Pairing approuvé ! Le bot répondra désormais à vos messages."
            else
                warn "Pairing refusé. Relancez avec : ./setup.sh --signal"
            fi
        else
            echo -e "    ${GRAY}⏳ Attente... ($((attempts * 5))s / 300s)${NC}"
        fi
    done

    if [[ "$found" == "false" ]]; then
        warn "Aucune demande reçue après 5 minutes."
        info "Relancez le pairing avec : ./setup.sh --signal"
    fi
}

# ── Sous-commandes ────────────────────────────────────────────
show_help() {
    header
    echo -e "  ${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║              Menu d'aide                     ║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}Commandes disponibles :${NC}"
    echo -e "    ${WHITE}./setup.sh              ${NC}→ Installation complète"
    echo -e "    ${WHITE}./setup.sh --help       ${NC}→ Ce menu"
    echo -e "    ${WHITE}./setup.sh --status     ${NC}→ État des conteneurs"
    echo -e "    ${WHITE}./setup.sh --signal     ${NC}→ Pairing Signal interactif"
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

case "${1:-}" in
    --help)     show_help ;;
    --status)
        docker compose ps
        echo ""
        docker exec openclaw-tailscale-1 tailscale status
        exit 0 ;;
    --dashboard)
        docker compose run --rm openclaw-cli dashboard --no-open
        exit 0 ;;
    --signal)
        BOT_NUMBER="" OWNER_NUMBER=""
        [[ -f ".env" ]] && { BOT_NUMBER=$(grep SIGNAL_BOT_NUMBER .env | cut -d= -f2); OWNER_NUMBER=$(grep SIGNAL_OWNER_NUMBER .env | cut -d= -f2); }
        [[ -z "$BOT_NUMBER" ]]   && BOT_NUMBER=$(prompt_required "Numéro du bot Signal" "+33XXXXXXXXX")
        [[ -z "$OWNER_NUMBER" ]] && OWNER_NUMBER=$(prompt_required "Votre numéro personnel" "+33XXXXXXXXX")
        signal_pairing "$BOT_NUMBER" "$OWNER_NUMBER"
        exit 0 ;;
    --stop)   docker compose down && ok "OpenClaw arrêté" ; exit 0 ;;
    --start)  docker compose up -d && ok "OpenClaw démarré" ; exit 0 ;;
    --logs)   docker compose logs -f ; exit 0 ;;
    --update) docker compose pull && docker compose up -d && ok "OpenClaw mis à jour" ; exit 0 ;;
esac

# ══════════════════════════════════════════════════════════════
# ── INSTALLATION PRINCIPALE ───────────────────────────────────
# ══════════════════════════════════════════════════════════════
header

# ── ÉTAPE 1 — Prérequis ───────────────────────────────────────
step 1 6 "Vérification des prérequis..."

command -v docker &>/dev/null && ok "Docker : $(docker --version)" || { err "Docker non trouvé : https://docs.docker.com/get-docker/" ; exit 1; }
docker ps &>/dev/null && ok "Docker démarré" || { err "Docker n'est pas démarré." ; exit 1; }
command -v git &>/dev/null && ok "Git : $(git --version)" || warn "Git non trouvé (optionnel)"
echo ""

# ── ÉTAPE 2 — Tailscale ──────────────────────────────────────
step 2 6 "Configuration Tailscale"
info "Obtenez votre clé sur : https://login.tailscale.com/admin/settings/keys"
info "Cochez : Reusable + Pre-authorized"
echo ""
TS_AUTHKEY=$(prompt_required "Clé Auth Tailscale" "tskey-auth-...")
TS_HOSTNAME=$(prompt_optional "Nom du device dans votre tailnet" "openclaw-gateway")
echo ""

# ── ÉTAPE 3 — Anthropic ──────────────────────────────────────
step 3 6 "Configuration Anthropic"
info "Obtenez votre clé sur : https://console.anthropic.com/settings/keys"
echo ""
ANTHROPIC_KEY=$(prompt_required "Clé API Anthropic" "sk-ant-...")
echo ""

# ── ÉTAPE 4 — Signal ─────────────────────────────────────────
step 4 6 "Configuration Signal"
sep
info "Signal nécessite un numéro DÉDIÉ pour le bot (pas votre numéro personnel)."
info "Utilisez une SIM secondaire ou un numéro virtuel (ex: Twilio, Vonage)."
info "Format international : +33612345678"
sep
echo ""
SIGNAL_BOT=$(prompt_required "Numéro dédié au bot Signal" "+33XXXXXXXXX")
echo ""
info "Entrez le ou les numéros autorisés à parler au bot."
info "Plusieurs numéros : séparez-les par des virgules (+336xxx,+336yyy)"
SIGNAL_OWNERS_RAW=$(prompt_required "Numéro(s) autorisé(s)" "+33XXXXXXXXX")
SIGNAL_OWNER=$(echo "$SIGNAL_OWNERS_RAW" | cut -d',' -f1 | tr -d ' ')
# Construire tableau JSON des owners
SIGNAL_OWNERS_JSON=$(echo "$SIGNAL_OWNERS_RAW" | tr ',' '\n' | tr -d ' ' | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))")
echo ""

# ── Options ───────────────────────────────────────────────────
echo -e "  ${YELLOW}Options supplémentaires :${NC}"; echo ""
BRAVE_KEY=$(prompt_optional "Clé API Brave Search (optionnel)" "")
echo ""
ENABLE_OLLAMA=false; OLLAMA_MODEL="qwen2.5:7b"
if prompt_yesno "Activer Ollama (LLM local, nécessite GPU NVIDIA)"; then
    ENABLE_OLLAMA=true
    echo ""
    info "6GB VRAM → qwen2.5:7b | 8GB → mistral:7b | 16GB → qwen2.5:14b"
    OLLAMA_MODEL=$(prompt_optional "Modèle Ollama" "qwen2.5:7b")
fi
echo ""

# ── ÉTAPE 5 — Config + lancement ─────────────────────────────
step 5 6 "Création de la configuration et lancement..."

mkdir -p ./data/.openclaw/workspace
ok "Dossiers créés"

cat > .env << EOF
TS_AUTHKEY=$TS_AUTHKEY
TS_HOSTNAME=$TS_HOSTNAME
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
SIGNAL_BOT_NUMBER=$SIGNAL_BOT
SIGNAL_OWNER_NUMBER=$SIGNAL_OWNER
BRAVE_API_KEY=$BRAVE_KEY
ENABLE_OLLAMA=$ENABLE_OLLAMA
OLLAMA_MODEL=$OLLAMA_MODEL
OPENCLAW_CONFIG_DIR=./data/.openclaw
OPENCLAW_WORKSPACE_DIR=./data/.openclaw/workspace
OPENCLAW_TZ=Europe/Paris
OPENCLAW_GATEWAY_TOKEN=
EOF
ok "Fichier .env créé"
echo ""

if [[ "$ENABLE_OLLAMA" == "true" ]]; then
    docker compose --profile ollama up -d
else
    docker compose up -d
fi
sleep 5
ok "Conteneurs démarrés"

# ── Onboarding OpenClaw ───────────────────────────────────────
echo ""
warn "Lancement de l'assistant de configuration OpenClaw..."
warn "Choisissez votre modèle IA, langue, etc."
warn "Pour Signal : choisissez 'skip' si demandé — on le configure juste après."
echo ""
sleep 2
docker compose run --rm openclaw-cli onboard

# ── Correction config Signal ──────────────────────────────────
CONFIG_PATH="./data/.openclaw/openclaw.json"
if [[ -f "$CONFIG_PATH" ]]; then
    python3 -c "
import json
with open('$CONFIG_PATH', 'r') as f:
    config = json.load(f)
if 'channels' in config and 'signal' in config['channels']:
    config['channels']['signal']['cliPath'] = '/usr/local/bin/signal-cli'
    config['channels']['signal']['allowFrom'] = $SIGNAL_OWNERS_JSON
    with open('$CONFIG_PATH', 'w') as f:
        json.dump(config, f, indent=2)
    print('OK')
" && ok "Config Signal corrigée (cliPath absolu + allowFrom)"
fi

# ── Tailscale Serve ──────────────────────────────────────────
sleep 3
docker exec openclaw-tailscale-1 tailscale serve --bg 18789 2>/dev/null || true
DNS_NAME=$(docker exec openclaw-tailscale-1 tailscale status --json 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Self']['DNSName'].rstrip('.'))" 2>/dev/null \
    || echo "votre-tailnet.ts.net")
ok "Tailscale Serve activé : https://$DNS_NAME"

# ── ÉTAPE 6 — Enregistrement Signal ──────────────────────────
step 6 6 "Enregistrement du bot Signal et pairing..."
sep
info "Signal nécessite un captcha pour enregistrer un nouveau numéro."
info "Vous recevrez ensuite un SMS de vérification sur $SIGNAL_BOT"
sep
echo ""

# Captcha
echo -e "  ${YELLOW}[1/3] Captcha Signal${NC}"
echo ""
info "1. Ouvrez ce lien dans votre navigateur :"
echo ""
echo -e "       ${CYAN}https://signalcaptchas.org/registration/generate.html${NC}"
echo ""
info "2. Résolvez le captcha"
info "3. CLIC DROIT sur 'Open Signal' → 'Copier le lien'"
info "4. Collez-le ci-dessous (commence par signalcaptcha://...)"
echo ""
CAPTCHA=$(prompt_required "Lien captcha" "signalcaptcha://...")
echo ""

echo -e "  ${YELLOW}[2/3] Envoi de la demande d'enregistrement...${NC}"
docker compose exec -u root openclaw-gateway signal-cli -a "$SIGNAL_BOT" register --captcha "$CAPTCHA" 2>&1 || true
ok "Demande envoyée ! Vous allez recevoir un SMS sur $SIGNAL_BOT"
echo ""

echo -e "  ${YELLOW}[3/3] Vérification par SMS${NC}"
echo ""
info "Entrez le code à 6 chiffres reçu par SMS sur $SIGNAL_BOT"
echo ""
SMS_CODE=$(prompt_required "Code SMS" "123456")

docker compose exec -u root openclaw-gateway signal-cli -a "$SIGNAL_BOT" verify "$SMS_CODE" 2>&1 || true
ok "Numéro $SIGNAL_BOT enregistré sur Signal !"

echo ""
echo -e "  ${YELLOW}Redémarrage du gateway...${NC}"
docker compose restart openclaw-gateway
sleep 8
ok "Gateway redémarré"

# ── Pairing interactif ────────────────────────────────────────
signal_pairing "$SIGNAL_BOT" "$SIGNAL_OWNER"

# ── Résumé final ─────────────────────────────────────────────
header
echo -e "  ${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║        ✅  Installation terminée !           ║${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${WHITE}📱 Bot Signal  : $SIGNAL_BOT${NC}"
echo -e "  ${WHITE}🔑 Autorisé(s) : $SIGNAL_OWNERS_RAW${NC}"
echo -e "  ${CYAN}🌐 Dashboard   : https://$DNS_NAME${NC}"
echo -e "  ${WHITE}📚 Docs        : https://docs.openclaw.ai${NC}"
echo ""
sep
echo -e "  ${YELLOW}Prochaines étapes :${NC}"
echo -e "  ${WHITE}1. Ouvrez le dashboard : ./setup.sh --dashboard${NC}"
echo -e "  ${WHITE}2. Testez en envoyant un message Signal au bot${NC}"
echo -e "  ${WHITE}3. Aide complète : ./setup.sh --help${NC}"
sep
echo ""
