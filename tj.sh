#!/usr/bin/env bash

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

mkdir -p "$DESTINATION"
log "sauvegarde dans $DESTINATION (rétention $RETENTION jours)"

for entree in "${PORTAILS[@]}"; do
  sauvegarde_un "${entree%%:*}" "${entree#*:}"
done

for entree in "${PORTAILS[@]}"; do
  purger "${entree%%:*}"
done

log "terminé"
