#!/usr/bin/env bash
#
# Installe la sauvegarde quotidienne des bases, et la **restaure** pour de vrai.
#
# À lancer depuis le dépôt du portail, sur le serveur, **une fois** :
#
#     sudo bash scripts/installe-sauvegarde.sh
#
# Ce que ça met en place :
#
#   · un `systemd` *timer* plutôt qu'une entrée cron — `cron` n'est pas actif
#     sur cette machine, et un timer survit au redémarrage sans configuration
#     supplémentaire ;
#   · une exécution quotidienne **à 3 h 12**, heure creuse et décimale. Un
#     déclencheur à `hh:00` sature : tous les timers de la machine et tous les
#     cron du monde se réveillent ensemble. La minute est donc décalée, et
#     `RandomizedDelaySec` ajoute encore de l'écart ;
#   · un `OnBootSec` de 10 minutes, pour qu'un redémarrage de la machine
#     répare aussi les données.
#
# Puis **on restaure**, parce qu'une sauvegarde jamais restaurée n'est pas une
# sauvegarde : on ne sait pas si le fichier s'ouvre, ni si les données y sont.
# C'est la restauration qui le prouve, et c'est aussi le seul moyen de découvrir
# une erreur de schéma avant d'en avoir besoin.

set -Eeuo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$RACINE/scripts/sauvegarde-bases.sh"
HEURE="${HEURE:-3}"
MINUTE="${MINUTE:-12}"
RETENTION="${RETENTION:-7}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script installe des unités systemd : il faut sudo." >&2
  exit 1
fi

for fichier in "$SCRIPT" "$RACINE/scripts/restaure-base.sh"; do
  [ -x "$fichier" ] || { echo "manquant ou non exécutable : $fichier" >&2; exit 1; }
done

log() { printf '%s  %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"; }

# ── les deux unités ──────────────────────────────────────────────────────

cat > /etc/systemd/system/operation-beluga-sauvegarde.service <<UNIT
[Unit]
# Le portail doit répondre pour que la sauvegarde ait un sens : une base taken
# pendant un arrêt ne contient que la moitié de ce qui a été fait.
Description=Sauvegarde des bases des portails Atelier Docker et Opération Beluga
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=$RACINE
Environment=RETENTION=$RETENTION
ExecStart=$SCRIPT
UNIT

cat > /etc/systemd/system/operation-beluga-sauvegarde.timer <<UNIT
[Unit]
Description=Sauvegarde quotidienne des bases des portails

[Timer]
# 3 h 12, et non 3 h 00 : voir l'en-tête du script.
OnCalendar=*-*-* $HEURE:$MINUTE:00
# Au redémarrage aussi, dix minutes après le démarrage du timer. Une machine
# qui redémarre le soir ne doit pas attendre jusqu'au lendemain matin.
OnBootSec=10min
# Au cas où l'heure de la machine bouge, l'exécution est rattrappée.
Persistent=true
# L'écart aléatoire évite que deux timers ne se réveillent ensemble.
RandomizedDelaySec=15min

[Install]
WantedBy=timers.target
UNIT

log "activation"
systemctl daemon-reload
systemctl enable --now operation-beluga-sauvegarde.timer

log "première exécution"
systemctl start operation-beluga-sauvegarde.service || true
systemctl --no-pager --lines=0 status operation-beluga-sauvegarde.service || true

# ── la preuve : restaurer ────────────────────────────────────────────────

# On vérifie le dump **de chaque portail**, pas d'un seul : une sauvegarde qui
# ne s'ouvre que pour l'un des deux jeux n'en est pas une. Et un portail arrêté
# n'a pas de dump — son absence est alors normale, et le dire évite qu'un
# opérateur y voie une perte de données.
for conteneur in operation-beluga atelier-docker; do
  log "vérification du dump de $conteneur"
  if "$RACINE/scripts/restaure-base.sh" "$conteneur" --verifier-seulement; then
    continue
  fi
  if ! docker inspect -f '{{.State.Running}}' "$conteneur" 2>/dev/null | grep -q true; then
    log "  $conteneur est arrêté : pas de dump, ce n'est pas une perte"
  else
    die "le dump de $conteneur ne s'ouvre pas. La sauvegarde est à revoir."
  fi
done

cat <<RESUME

Installation terminée.

  Prochaine exécution : systemctl list-timers operation-beluga-sauvegarde.timer
  Journal             : journalctl -u operation-beluga-sauvegarde
  Forcer une exécution: systemctl start operation-beluga-sauvegarde.service
  Restaurer           : sudo bash scripts/restaure-base.sh operation-beluga

Ce que la sauvegarde ne fait PAS : elle n'est pas hors site. Les dumps
atterrissent sur le même disque que les bases, donc elle protège d'un accident
logique — une réinitialisation, un volume corrompu — et pas de la mort du
disque. Voir l'en-tête de scripts/sauvegarde-bases.sh.

RESUME
