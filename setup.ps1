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

function Write-Step($num, $total, $msg) { Write-Host "  [$num/$total] $msg" -ForegroundColor Yellow }
function Write-OK($msg)   { Write-Host "    ✅ $msg" -ForegroundColor Green }
function Write-ERR($msg)  { Write-Host "    ❌ $msg" -ForegroundColor Red }
function Write-INFO($msg) { Write-Host "    ℹ️  $msg" -ForegroundColor Cyan }
function Write-WARN($msg) { Write-Host "    ⚠️  $msg" -ForegroundColor Yellow }
function Write-SEP()      { Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray }

function Prompt-Required($label, $placeholder) {
    do {
        Write-Host "    → $label" -ForegroundColor White -NoNewline
        if ($placeholder) { Write-Host " ($placeholder)" -ForegroundColor DarkGray -NoNewline }
        Write-Host " : " -NoNewline
        $value = Read-Host
        if ([string]::IsNullOrWhiteSpace($value)) { Write-ERR "Ce champ est obligatoire." }
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

# ── Fonction pairing Signal ───────────────────────────────────
function Invoke-SignalPairing($botNumber, $ownerNumber) {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║        📱  Pairing Signal                    ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-INFO "Depuis votre application Signal sur votre téléphone :"
    Write-Host ""
    Write-Host "    Envoyez n'importe quel message" -ForegroundColor White
    Write-Host "    DE  : $ownerNumber  (votre numéro personnel)" -ForegroundColor Yellow
    Write-Host "    AU  : $botNumber    (le numéro du bot)" -ForegroundColor Yellow
    Write-Host ""
    Write-WARN "En attente du message... (Ctrl+C pour annuler)"
    Write-Host ""

    $found = $false
    $attempts = 0
    $maxAttempts = 60

    while (-not $found -and $attempts -lt $maxAttempts) {
        Start-Sleep -Seconds 5
        $attempts++
        $pairings = docker compose run --rm openclaw-cli pairing list signal 2>&1
        if ($pairings -match "([A-Z]{8})") {
            $code = $matches[1]
            $found = $true
            Write-Host ""
            Write-OK "Demande de pairing reçue !"
            Write-Host ""
            Write-Host "    Code   : $code" -ForegroundColor Cyan
            Write-Host "    De     : $ownerNumber" -ForegroundColor White
            Write-Host ""
            if (Prompt-YesNo "Confirmer et approuver le pairing pour $ownerNumber") {
                docker compose run --rm openclaw-cli pairing approve signal $code | Out-Null
                Write-OK "Pairing approuvé ! Le bot répondra désormais à vos messages."
            } else {
                Write-WARN "Pairing refusé. Relancez avec : .\setup.ps1 --signal"
            }
        } else {
            Write-Host "    ⏳ Attente... ($($attempts * 5)s / 300s)" -ForegroundColor DarkGray
        }
    }

    if (-not $found) {
        Write-WARN "Aucune demande reçue après 5 minutes."
        Write-INFO "Relancez le pairing avec : .\setup.ps1 --signal"
    }
}

# ── Sous-commandes ────────────────────────────────────────────
if ($args -contains "--help") {
    Write-Header
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║              Menu d'aide                     ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Commandes disponibles :" -ForegroundColor Yellow
    Write-Host "    .\setup.ps1              → Installation complète" -ForegroundColor White
    Write-Host "    .\setup.ps1 --help       → Ce menu" -ForegroundColor White
    Write-Host "    .\setup.ps1 --status     → État des conteneurs" -ForegroundColor White
    Write-Host "    .\setup.ps1 --signal     → Pairing Signal interactif" -ForegroundColor White
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
    exit 0
}

if ($args -contains "--status") {
    docker compose ps
    Write-Host ""
    docker exec openclaw-tailscale-1 tailscale status
    exit 0
}

if ($args -contains "--dashboard") {
    docker compose run --rm openclaw-cli dashboard --no-open
    exit 0
}

if ($args -contains "--signal") {
    if (Test-Path ".\.env") {
        Get-Content ".\.env" | Where-Object { $_ -match "^SIGNAL_" } | ForEach-Object {
            $parts = $_ -split "=", 2
            Set-Variable -Name $parts[0] -Value $parts[1]
        }
    }
    $botNumber   = if ($SIGNAL_BOT_NUMBER)   { $SIGNAL_BOT_NUMBER }   else { Prompt-Required "Numéro du bot Signal" "+33XXXXXXXXX" }
    $ownerNumber = if ($SIGNAL_OWNER_NUMBER) { $SIGNAL_OWNER_NUMBER } else { Prompt-Required "Votre numéro personnel" "+33XXXXXXXXX" }
    Invoke-SignalPairing $botNumber $ownerNumber
    exit 0
}

if ($args -contains "--stop")   { docker compose down ; Write-OK "OpenClaw arrêté" ; exit 0 }
if ($args -contains "--start")  { docker compose up -d ; Write-OK "OpenClaw démarré" ; exit 0 }
if ($args -contains "--logs")   { docker compose logs -f ; exit 0 }
if ($args -contains "--update") {
    docker compose pull ; docker compose up -d ; Write-OK "OpenClaw mis à jour" ; exit 0
}

# ══════════════════════════════════════════════════════════════
# ── INSTALLATION PRINCIPALE ───────────────────────────────────
# ══════════════════════════════════════════════════════════════
Write-Header

# ── ÉTAPE 1 — Prérequis ───────────────────────────────────────
Write-Step 1 6 "Vérification des prérequis..."
Write-Host ""

try { $v = docker --version 2>&1 ; Write-OK "Docker : $v" }
catch { Write-ERR "Docker non trouvé : https://www.docker.com/products/docker-desktop" ; exit 1 }

try { docker ps > $null 2>&1 ; Write-OK "Docker Desktop démarré" }
catch { Write-ERR "Docker Desktop n'est pas démarré." ; exit 1 }

try { Write-OK "Git : $(git --version 2>&1)" } catch { Write-WARN "Git non trouvé (optionnel)" }

$freeRAM = [math]::Round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)
if ($freeRAM -lt 4) { Write-WARN "RAM libre : ${freeRAM}GB (min 4GB recommandé)" }
else { Write-OK "RAM libre : ${freeRAM}GB" }
Write-Host ""

# ── ÉTAPE 2 — Tailscale ──────────────────────────────────────
Write-Step 2 6 "Configuration Tailscale"
Write-Host ""
Write-INFO "Obtenez votre clé sur : https://login.tailscale.com/admin/settings/keys"
Write-INFO "Cochez : Reusable + Pre-authorized"
Write-Host ""
$TS_AUTHKEY  = Prompt-Required "Clé Auth Tailscale" "tskey-auth-..."
$TS_HOSTNAME = Prompt-Optional "Nom du device dans votre tailnet" "openclaw-gateway"
Write-Host ""

# ── ÉTAPE 3 — Anthropic ──────────────────────────────────────
Write-Step 3 6 "Configuration Anthropic"
Write-Host ""
Write-INFO "Obtenez votre clé sur : https://console.anthropic.com/settings/keys"
Write-Host ""
$ANTHROPIC_KEY = Prompt-Required "Clé API Anthropic" "sk-ant-..."
Write-Host ""

# ── ÉTAPE 4 — Signal ─────────────────────────────────────────
Write-Step 4 6 "Configuration Signal"
Write-Host ""
Write-SEP
Write-INFO "Signal nécessite un numéro DÉDIÉ pour le bot (pas votre numéro personnel)."
Write-INFO "Utilisez une SIM secondaire ou un numéro virtuel (ex: Twilio, Vonage)."
Write-INFO "Format international : +33612345678"
Write-SEP
Write-Host ""
$SIGNAL_BOT = Prompt-Required "Numéro dédié au bot Signal" "+33XXXXXXXXX"
Write-Host ""
Write-INFO "Entrez le ou les numéros autorisés à parler au bot."
Write-INFO "Plusieurs numéros : séparez-les par des virgules (+336xxx,+336yyy)"
$SIGNAL_OWNERS_RAW = Prompt-Required "Numéro(s) autorisé(s)" "+33XXXXXXXXX"
$SIGNAL_OWNERS = $SIGNAL_OWNERS_RAW -split "," | ForEach-Object { $_.Trim() }
$SIGNAL_OWNER  = $SIGNAL_OWNERS[0]
Write-Host ""

# ── Options ───────────────────────────────────────────────────
Write-Host "  Options supplémentaires :" -ForegroundColor Yellow
Write-Host ""
$BRAVE_KEY = Prompt-Optional "Clé API Brave Search (optionnel)" ""
Write-Host ""
$ENABLE_OLLAMA = Prompt-YesNo "Activer Ollama (LLM local, nécessite GPU NVIDIA)"
$OLLAMA_MODEL = "qwen2.5:7b"
if ($ENABLE_OLLAMA) {
    Write-Host ""
    Write-INFO "6GB VRAM → qwen2.5:7b | 8GB → mistral:7b | 16GB → qwen2.5:14b"
    $OLLAMA_MODEL = Prompt-Optional "Modèle Ollama" "qwen2.5:7b"
}
Write-Host ""

# ── ÉTAPE 5 — Config + lancement ─────────────────────────────
Write-Step 5 6 "Création de la configuration et lancement..."
Write-Host ""

New-Item -ItemType Directory -Force -Path ".\data\.openclaw\workspace" | Out-Null
Write-OK "Dossiers de données créés"

@"
TS_AUTHKEY=$TS_AUTHKEY
TS_HOSTNAME=$TS_HOSTNAME
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
SIGNAL_BOT_NUMBER=$SIGNAL_BOT
SIGNAL_OWNER_NUMBER=$SIGNAL_OWNER
BRAVE_API_KEY=$BRAVE_KEY
ENABLE_OLLAMA=$($ENABLE_OLLAMA.ToString().ToLower())
OLLAMA_MODEL=$OLLAMA_MODEL
OPENCLAW_CONFIG_DIR=./data/.openclaw
OPENCLAW_WORKSPACE_DIR=./data/.openclaw/workspace
OPENCLAW_TZ=Europe/Paris
OPENCLAW_GATEWAY_TOKEN=
"@ | Out-File -FilePath ".\.env" -Encoding UTF8
Write-OK "Fichier .env créé"

Write-Host ""
if ($ENABLE_OLLAMA) { docker compose --profile ollama up -d }
else { docker compose up -d }
Start-Sleep -Seconds 5
Write-OK "Conteneurs démarrés"

# ── Onboarding OpenClaw ───────────────────────────────────────
Write-Host ""
Write-WARN "Lancement de l'assistant de configuration OpenClaw..."
Write-WARN "Choisissez votre modèle IA, langue, etc."
Write-WARN "Pour Signal : choisissez 'skip' si demandé — on le configure juste après."
Write-Host ""
Start-Sleep -Seconds 2
docker compose run --rm openclaw-cli onboard

# ── Correction config Signal ──────────────────────────────────
$configPath = ".\data\.openclaw\openclaw.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    if ($config.channels -and $config.channels.signal) {
        $config.channels.signal.cliPath = "/usr/local/bin/signal-cli"
        $config.channels.signal | Add-Member -NotePropertyName "allowFrom" -NotePropertyValue $SIGNAL_OWNERS -Force
        $config | ConvertTo-Json -Depth 20 | Out-File $configPath -Encoding UTF8
        Write-OK "Config Signal corrigée"
    }
}

# ── Tailscale Serve ──────────────────────────────────────────
Start-Sleep -Seconds 3
docker exec openclaw-tailscale-1 tailscale serve --bg 18789 2>&1 | Out-Null
$dnsName = (docker exec openclaw-tailscale-1 tailscale status --json 2>&1 | ConvertFrom-Json).Self.DNSName.TrimEnd('.')
Write-OK "Tailscale Serve activé : https://$dnsName"

# ── ÉTAPE 6 — Enregistrement Signal ──────────────────────────
Write-Step 6 6 "Enregistrement du bot Signal et pairing..."
Write-Host ""
Write-SEP
Write-INFO "Signal nécessite un captcha pour enregistrer un nouveau numéro."
Write-INFO "Vous recevrez ensuite un SMS de vérification sur $SIGNAL_BOT"
Write-SEP
Write-Host ""

# Captcha
Write-Host "  [1/3] Captcha Signal" -ForegroundColor Yellow
Write-Host ""
Write-INFO "1. Ouvrez ce lien dans votre navigateur :"
Write-Host ""
Write-Host "       https://signalcaptchas.org/registration/generate.html" -ForegroundColor Cyan
Write-Host ""
Write-INFO "2. Résolvez le captcha"
Write-INFO "3. CLIC DROIT sur 'Open Signal' → 'Copier le lien'"
Write-INFO "4. Collez-le ci-dessous (commence par signalcaptcha://...)"
Write-Host ""

$captcha = Prompt-Required "Lien captcha" "signalcaptcha://..."
Write-Host ""

Write-Host "  [2/3] Envoi de la demande d'enregistrement..." -ForegroundColor Yellow
docker compose exec -u root openclaw-gateway signal-cli -a $SIGNAL_BOT register --captcha $captcha 2>&1 | Out-Null
Write-OK "Demande envoyée ! Vous allez recevoir un SMS sur $SIGNAL_BOT"
Write-Host ""

Write-Host "  [3/3] Vérification par SMS" -ForegroundColor Yellow
Write-Host ""
Write-INFO "Entrez le code à 6 chiffres reçu par SMS sur $SIGNAL_BOT"
Write-Host ""
$smsCode = Prompt-Required "Code SMS" "123456"

docker compose exec -u root openclaw-gateway signal-cli -a $SIGNAL_BOT verify $smsCode 2>&1 | Out-Null
Write-OK "Numéro $SIGNAL_BOT enregistré sur Signal !"

Write-Host ""
Write-Host "  Redémarrage du gateway..." -ForegroundColor Yellow
docker compose restart openclaw-gateway
Start-Sleep -Seconds 8
Write-OK "Gateway redémarré"

# ── Pairing interactif ────────────────────────────────────────
Write-Host ""
Write-SEP
Write-Host ""
Write-Host "  📱 Dernière étape : Pairing Signal" -ForegroundColor Cyan
Write-Host ""
Write-INFO "Depuis votre application Signal :"
Write-Host ""
Write-Host "    Envoyez un message DE $SIGNAL_OWNER AU $SIGNAL_BOT" -ForegroundColor Yellow
Write-Host ""
Write-WARN "En attente... (5 min max — Ctrl+C pour annuler, relancez avec .\setup.ps1 --signal)"
Write-Host ""

$found = $false ; $attempts = 0 ; $maxAttempts = 60
while (-not $found -and $attempts -lt $maxAttempts) {
    Start-Sleep -Seconds 5 ; $attempts++
    $pairings = docker compose run --rm openclaw-cli pairing list signal 2>&1
    if ($pairings -match "([A-Z]{8})") {
        $code = $matches[1] ; $found = $true
        Write-Host ""
        Write-OK "Demande reçue ! Code : $code  |  De : $SIGNAL_OWNER"
        Write-Host ""
        if (Prompt-YesNo "Approuver le pairing pour $SIGNAL_OWNER") {
            docker compose run --rm openclaw-cli pairing approve signal $code | Out-Null
            Write-OK "Pairing approuvé ! Le bot est prêt."
        } else {
            Write-WARN "Refusé. Relancez : .\setup.ps1 --signal"
        }
    } else {
        Write-Host "    ⏳ $($attempts * 5)s / 300s" -ForegroundColor DarkGray
    }
}
if (-not $found) { Write-WARN "Délai dépassé. Relancez : .\setup.ps1 --signal" }

# ── Résumé final ─────────────────────────────────────────────
Write-Header
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║        ✅  Installation terminée !           ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  📱 Bot Signal  : $SIGNAL_BOT" -ForegroundColor White
Write-Host "  🔑 Autorisé(s) : $SIGNAL_OWNERS_RAW" -ForegroundColor White
Write-Host "  🌐 Dashboard   : https://$dnsName" -ForegroundColor Cyan
Write-Host "  📚 Docs        : https://docs.openclaw.ai" -ForegroundColor White
Write-Host ""
Write-SEP
Write-Host "  Prochaines étapes :" -ForegroundColor Yellow
Write-Host "  1. Ouvrez le dashboard : .\setup.ps1 --dashboard" -ForegroundColor White
Write-Host "  2. Testez en envoyant un message Signal au bot" -ForegroundColor White
Write-Host "  3. Aide complète : .\setup.ps1 --help" -ForegroundColor White
Write-SEP
Write-Host ""
