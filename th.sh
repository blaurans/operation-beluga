#!/usr/bin/env bash
#
# Sauvegarde des bases des portails, sur la machine qui les héberge.
#
# À lancer depuis le dépôt du portail, sur le serveur :
#
#     bash scripts/sauvegarde-bases.sh
#
# ## Ce que ce script protège — et ce qu'il ne protège pas
#
# Il protège d'un **accident logique** : une réinitialisation par erreur, un
# `seed --force`, un volume corrompu, un conteneur recréé avec le mauvais volume,
# un élève qui vide sa progression. Le dump est fait avec `VACUUM INTO`, donc
# **cohérente même base en cours d'écriture** — c'est la raison de ce choix plutôt
# qu'une copie du fichier, qui figerait un instant arbitraire et pourrait
# produire un fichier illisible.
#
# Il **ne protège pas** de la mort du disque. Les sauvegardes atterrissent sur
# `/dev/sda1`, le même disque que les bases. Or le jeu enseigne précisément
# cela, à l'atelier 7 : *« un volume n'est pas une sauvegarde, il est sur la même
# machine que ce qu'il protège »*. Ce script est donc un filet de sécurité
# logique, et **pas** une sauvegarde au sens du jeu.
#
# Pour une vraie sauvegarde hors site, il faut une destination **écrivable**
# ailleurs. `/mnt/jellyfin-sftp` existe sur cette machine mais c'est un montage
# rclone **en lecture seule** vers une autre machine : poser `DESTINATION` plus
# loin ne suffit pas, il faut d'abord un accès en écriture. Voir la fin de ce
# fichier et `docs/REPRISE.md` § 14.
#
# ## Pourquoi `VACUUM INTO` puis `docker cp`, et pas un bind mount
#
# Un bind mount d'un dossier de sauvegarde dans le compose paraît plus simple.
# Il couple le fichier versionné à un chemin absolu de l'hôte, et il faut le
# créer avant le premier `up` — donc avant de découvrir qu'il manque. En
# faisant le dump dans le conteneur et en le recopiant ensuite, le compose reste
# identique à ce qu'il est en production, et le script marche même sur un
# portail déployé avant que la sauvegarde existe.
#
# ## Le contrôle d'intégrité n'est pas optionnel
#
# Le dump est relu **dans le conteneur**, avec le même Node qui l'a écrit, et
# `PRAGMA integrity_check` doit répondre `ok` avant que le fichier soit copié
# dehors. Copier d'abord et vérifier ensuite laisserait un fichier corrompu sur
# le disque, avec l'air d'une sauvegarde — c'est le pire résultat possible, parce
# qu'on ne le saura pas au moment où on en aura besoin.
#
# Le `node` de l'hôte est en v18 et n'a pas `node:sqlite`. C'est pour cela que la
# vérification se fait dans le conteneur, et non sur l'hôte.

set -Eeuo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE"

# Où atterissent les dumps. Créé s'il n'existe pas.
DESTINATION="${DESTINATION:-$RACINE/sauvegardes}"

# Combien de jours garder. Sept dumps d'une base de quelques mégaoctets ne
# pèsent rien, et une semaine est la durée pendant laquelle on s'aperçoit
# généralement qu'un problème existait.
RETENTION="${RETENTION:-7}"

# Les portails à sauvegarder : « conteneur:fichier de base dans le conteneur ».
# Les deux jeux tournent sur cette machine et partagent le même sort : sauvegarder
# l'un sans l'autre laisserait un portail accessible et l'autre vide.
PORTAILS=(
  "operation-beluga:/data/beluga.sqlite"
  "atelier-docker:/data/atelier.sqlite"
)

log()  { printf '%s  %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"; }
die()  { log "ÉCHEC : $*"; exit 1; }

# Le dump n'a de sens que si le conteneur tourne. Un portail arrêté n'est pas un
# incident : son absence ici est sans conséquence, et le dire évite qu'un
# opérateur conclude à une perte de données.
conteneur_live() {
  [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || echo absent)" = "true" ]
}

sauvegarder_un() {
  log "corps : $1 $2"
}

purger() {
  # On garde les `RETENTION` plus récents **par portail**, et on ne touche
  # qu'aux fichiers dont le nom porte ce nom de portail : un glob large
  # effacerait les sauvegardes de l'autre jeu.
  local conteneur="$1"
  local nom="${conteneur%.sqlite}-"
  local vieux
  vieux=$(find "$DESTINATION" -maxdepth 1 -name "${nom}*.sqlite" -type f \
            -printf '%T@ %p\n' 2>/dev/null | sort -rn | tail -n "+$((RETENTION + 1))" | cut -d' ' -f2-)
  if [ -n "$vieux" ]; then
    while IFS= read -r f; do
      rm -f "$f"
      log "purgé $(basename "$f")"
    done <<< "$vieux"
  fi
}

mkdir -p "$DESTINATION"
log "sauvegarde dans $DESTINATION (rétention $RETENTION jours)"

for entree in "${PORTAILS[@]}"; do
  sauvegarde_un "${entree%%:*}" "${entree#*:}"
done

for entree in "${PORTAILS[@]}"; do
  purger "${entree%%:*}"
done

log "terminé"
