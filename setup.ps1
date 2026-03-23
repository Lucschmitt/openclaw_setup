# ╔══════════════════════════════════════════════════════════════╗
# ║         OpenClaw Setup — Script d'installation Windows       ║
# ╚══════════════════════════════════════════════════════════════╝

$ErrorActionPreference = "Stop"

# ── Couleurs ──────────────────────────────────────────────────
function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║    🦞  OpenClaw Setup — Installation         ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step($num, $total, $msg) {
    Write-Host "  [$num/$total] $msg" -ForegroundColor Yellow
}

function Write-OK($msg)   { Write-Host "    ✅ $msg" -ForegroundColor Green }
function Write-ERR($msg)  { Write-Host "    ❌ $msg" -ForegroundColor Red }
function Write-INFO($msg) { Write-Host "    ℹ️  $msg" -ForegroundColor Cyan }
function Write-WARN($msg) { Write-Host "    ⚠️  $msg" -ForegroundColor Yellow }

function Prompt-Required($label, $placeholder) {
    do {
        Write-Host "    → $label" -ForegroundColor White -NoNewline
        if ($placeholder) { Write-Host " ($placeholder)" -ForegroundColor DarkGray -NoNewline }
        Write-Host " : " -NoNewline
        $value = Read-Host
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-ERR "Ce champ est obligatoire."
        }
    } while ([string]::IsNullOrWhiteSpace($value))
    return $value
}

function Prompt-Optional($label, $default) {
    Write-Host "    → $label" -ForegroundColor White -NoNewline
    if ($default) { Write-Host " [$default]" -ForegroundColor DarkGray -NoNewline }
    Write-Host " : " -NoNewline
    $value = Read-Host
    if ([string]::IsNullOrWhiteSpace($value) -and $default) { return $default }
    return $value
}

function Prompt-YesNo($label, $default = "N") {
    Write-Host "    → $label [o/N] : " -ForegroundColor White -NoNewline
    $value = Read-Host
    if ([string]::IsNullOrWhiteSpace($value)) { $value = $default }
    return $value -match "^[oOyY]"
}

# ══════════════════════════════════════════════════════════════
Write-Header

# ── ÉTAPE 1 — Prérequis ───────────────────────────────────────
Write-Step 1 5 "Vérification des prérequis..."
Write-Host ""

# Docker
try {
    $dockerVersion = docker --version 2>&1
    Write-OK "Docker détecté : $dockerVersion"
} catch {
    Write-ERR "Docker non trouvé. Installez Docker Desktop : https://www.docker.com/products/docker-desktop"
    exit 1
}

# Docker en cours
try {
    docker ps > $null 2>&1
    Write-OK "Docker Desktop est démarré"
} catch {
    Write-ERR "Docker Desktop n'est pas démarré. Lancez-le et relancez ce script."
    exit 1
}

# Git
try {
    $gitVersion = git --version 2>&1
    Write-OK "Git détecté : $gitVersion"
} catch {
    Write-WARN "Git non trouvé (optionnel). Installez depuis https://git-scm.com"
}

# RAM disponible
$freeRAM = [math]::Round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)
if ($freeRAM -lt 4) {
    Write-WARN "RAM libre : ${freeRAM}GB (minimum recommandé : 4GB)"
} else {
    Write-OK "RAM libre : ${freeRAM}GB"
}

Write-Host ""

# ── ÉTAPE 2 — Tailscale ──────────────────────────────────────
Write-Step 2 5 "Configuration Tailscale"
Write-Host ""
Write-INFO "Obtenez votre clé sur : https://login.tailscale.com/admin/settings/keys"
Write-INFO "Cochez : Reusable + Pre-authorized"
Write-Host ""

$TS_AUTHKEY  = Prompt-Required "Clé Auth Tailscale" "tskey-auth-..."
$TS_HOSTNAME = Prompt-Optional "Nom du device dans votre tailnet" "openclaw-gateway"
Write-Host ""

# ── ÉTAPE 3 — Anthropic ──────────────────────────────────────
Write-Step 3 5 "Configuration Anthropic"
Write-Host ""
Write-INFO "Obtenez votre clé sur : https://console.anthropic.com/settings/keys"
Write-Host ""

$ANTHROPIC_KEY = Prompt-Required "Clé API Anthropic" "sk-ant-..."
Write-Host ""

# ── ÉTAPE 4 — Signal ─────────────────────────────────────────
Write-Step 4 5 "Configuration Signal"
Write-Host ""
Write-INFO "Utilisez un numéro DÉDIÉ pour le bot (pas votre numéro personnel)"
Write-INFO "Format international : +33612345678"
Write-Host ""

$SIGNAL_BOT   = Prompt-Required "Numéro du bot Signal" "+33XXXXXXXXX"
$SIGNAL_OWNER = Prompt-Required "Votre numéro personnel Signal" "+33XXXXXXXXX"
Write-Host ""

# ── ÉTAPE 4b — Options ───────────────────────────────────────
Write-Host "  Options supplémentaires :" -ForegroundColor Yellow
Write-Host ""

$BRAVE_KEY = Prompt-Optional "Clé API Brave Search (optionnel, api.search.brave.com)" ""
Write-Host ""

$ENABLE_OLLAMA = Prompt-YesNo "Activer Ollama (LLM local, nécessite un GPU NVIDIA)"
$OLLAMA_MODEL = "qwen2.5:7b"
if ($ENABLE_OLLAMA) {
    Write-Host ""
    Write-INFO "Modèles recommandés selon votre GPU :"
    Write-INFO "  6GB VRAM  → qwen2.5:7b (recommandé)"
    Write-INFO "  8GB VRAM  → mistral:7b"
    Write-INFO "  16GB VRAM → qwen2.5:14b"
    $OLLAMA_MODEL = Prompt-Optional "Modèle Ollama" "qwen2.5:7b"
}
Write-Host ""

# ── ÉTAPE 5 — Génération .env ────────────────────────────────
Write-Step 5 5 "Création de la configuration..."
Write-Host ""

# Créer les dossiers de données
New-Item -ItemType Directory -Force -Path ".\data\.openclaw\workspace" | Out-Null
Write-OK "Dossiers de données créés"

# Générer .env
$envContent = @"
# OpenClaw — Configuration générée le $(Get-Date -Format "dd/MM/yyyy HH:mm")

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
ENABLE_OLLAMA=$($ENABLE_OLLAMA.ToString().ToLower())
OLLAMA_MODEL=$OLLAMA_MODEL

# ── CHEMINS ───────────────────────────────────────────────────
OPENCLAW_CONFIG_DIR=./data/.openclaw
OPENCLAW_WORKSPACE_DIR=./data/.openclaw/workspace
OPENCLAW_TZ=Europe/Paris
OPENCLAW_GATEWAY_TOKEN=
"@

$envContent | Out-File -FilePath ".\.env" -Encoding UTF8
Write-OK "Fichier .env créé"

# ── Lancement ────────────────────────────────────────────────
Write-Host ""
Write-Host "  Démarrage des conteneurs..." -ForegroundColor Yellow
Write-Host ""

if ($ENABLE_OLLAMA) {
    docker compose --profile ollama up -d
} else {
    docker compose up -d
}

Write-Host ""
Start-Sleep -Seconds 3

# ── Onboarding ───────────────────────────────────────────────
Write-Host ""
Write-WARN "Lancement de l'assistant de configuration OpenClaw..."
Write-WARN "Suivez les instructions à l'écran."
Write-Host ""
Start-Sleep -Seconds 2

docker compose run --rm --profile cli openclaw-cli onboard

# ── Tailscale Serve ──────────────────────────────────────────
Write-Host ""
Write-Host "  Activation de Tailscale Serve (HTTPS)..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
docker exec openclaw-tailscale-1 tailscale serve --bg 18789 2>&1 | Out-Null

# ── URL Dashboard ────────────────────────────────────────────
$tailscaleStatus = docker exec openclaw-tailscale-1 tailscale status --json 2>&1 | ConvertFrom-Json
$dnsName = $tailscaleStatus.Self.DNSName.TrimEnd('.')

$token = docker compose run --rm --profile cli openclaw-cli dashboard --no-open 2>&1 | Select-String "token=" | Select-Object -Last 1
$dashboardUrl = "https://$dnsName/?$($token -replace '.*\?', '')"

# ══════════════════════════════════════════════════════════════
# ── Résumé final ─────────────────────────────────────────────
Write-Header
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║        ✅  Installation terminée !           ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  📱 Signal Bot  : $SIGNAL_BOT" -ForegroundColor White
Write-Host "  🌐 Dashboard   : $dashboardUrl" -ForegroundColor Cyan
Write-Host "  📚 Docs        : https://docs.openclaw.ai" -ForegroundColor White
Write-Host ""
Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Prochaines étapes :" -ForegroundColor Yellow
Write-Host "  1. Ouvrez le dashboard ci-dessus dans votre navigateur" -ForegroundColor White
Write-Host "  2. Approuvez le device : .\setup.ps1 --help → option [3]" -ForegroundColor White
Write-Host "  3. Configurez Signal   : .\setup.ps1 --signal" -ForegroundColor White
Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  💡 Aide : .\setup.ps1 --help" -ForegroundColor DarkGray
Write-Host ""

# ── Menu aide si --help ───────────────────────────────────────
if ($args -contains "--help") {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║              Menu d'aide                     ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Commandes disponibles :" -ForegroundColor Yellow
    Write-Host "    .\setup.ps1              → Installation complète" -ForegroundColor White
    Write-Host "    .\setup.ps1 --help       → Ce menu" -ForegroundColor White
    Write-Host "    .\setup.ps1 --status     → État des conteneurs" -ForegroundColor White
    Write-Host "    .\setup.ps1 --signal     → Configurer Signal" -ForegroundColor White
    Write-Host "    .\setup.ps1 --dashboard  → Obtenir l'URL du dashboard" -ForegroundColor White
    Write-Host "    .\setup.ps1 --stop       → Arrêter OpenClaw" -ForegroundColor White
    Write-Host "    .\setup.ps1 --start      → Démarrer OpenClaw" -ForegroundColor White
    Write-Host "    .\setup.ps1 --logs       → Voir les logs en direct" -ForegroundColor White
    Write-Host "    .\setup.ps1 --update     → Mettre à jour OpenClaw" -ForegroundColor White
    Write-Host ""
    Write-Host "  Liens utiles :" -ForegroundColor Yellow
    Write-Host "    Docs OpenClaw  : https://docs.openclaw.ai" -ForegroundColor Cyan
    Write-Host "    Tailscale      : https://login.tailscale.com/admin/machines" -ForegroundColor Cyan
    Write-Host "    Anthropic      : https://console.anthropic.com" -ForegroundColor Cyan
    Write-Host "    Brave Search   : https://api.search.brave.com" -ForegroundColor Cyan
    Write-Host ""
}

if ($args -contains "--status") {
    Write-Host ""
    Write-Host "  État des conteneurs :" -ForegroundColor Yellow
    docker compose ps
    Write-Host ""
    Write-Host "  État Tailscale :" -ForegroundColor Yellow
    docker exec openclaw-tailscale-1 tailscale status
}

if ($args -contains "--dashboard") {
    Write-Host ""
    Write-Host "  URL du dashboard :" -ForegroundColor Yellow
    docker compose run --rm --profile cli openclaw-cli dashboard --no-open
}

if ($args -contains "--signal") {
    Write-Host ""
    Write-Host "  Configuration Signal :" -ForegroundColor Yellow
    Write-Host "  Pairings en attente :" -ForegroundColor White
    docker compose run --rm --profile cli openclaw-cli pairing list signal
}

if ($args -contains "--stop") {
    docker compose down
    Write-OK "OpenClaw arrêté"
}

if ($args -contains "--start") {
    docker compose up -d
    Write-OK "OpenClaw démarré"
}

if ($args -contains "--logs") {
    docker compose logs -f
}

if ($args -contains "--update") {
    Write-Host "  Mise à jour en cours..." -ForegroundColor Yellow
    docker compose pull
    docker compose up -d
    Write-OK "OpenClaw mis à jour"
}
