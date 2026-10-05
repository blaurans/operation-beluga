#!/usr/bin/env bash
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
  local conteneur="$1" base="$2"
  local nom horodatage dump_interne dump_final

  if ! conteneur_live "$conteneur"; then
    log "$conteneur : arrêté, non sauvegardé"
    return 0
  fi

  nom="${conteneur}.sqlite"
  horodatage="$(date -u '+%Y%m%dT%H%M%SZ')"
  dump_interne="/data/.sauvegarde-${horodatage}.sqlite"
  dump_final="$DESTINATION/${nom%.sqlite}-${horodatage}.sqlite"

  # Le dump et son contrôle, en un seul passage dans le conteneur. `VACUUM INTO`
  # échoue si le fichier existe déjà : on le retire d'abord, sinon une seconde
  # exécution à la même seconde échouerait.
  docker exec "$conteneur" sh -c 'rm -f "$1"' sh "$dump_interne"

  # Le script Node passe par un heredoc, jamais entre apostrophes bash.
  #
  # Il contient forcément des apostrophes — le littéral SQL de `VACUUM INTO` en
  # demande une — et une apostrophe ferme la chaîne bash. C'est arrivé : le
  # premier jet ne parsait pas, et le message ne parlait pas de SQL.
  #
  # Un heredoc `<<'NODE'` ne fait aucune substitution : le code Node peut
  # contenir ce qu'il veut.
  #
  # `VACUUM INTO '...'` et **jamais** `"..."` : SQLite reconnaît un littéral entre
  # guillemets doubles comme un identifiant, c'est-à-dire un nom de colonne, et
  # refuse l'instruction en disant `no such column`. Ce message ne désigne ni les
  # guillemets ni le chemin, et c'est ce qui a coûté le plus de temps ici.
  set +e
  docker exec -i "$conteneur" node --input-type=module - "$base" "$dump_interne" <<'NODE'
    import { DatabaseSync } from "node:sqlite";
    const [source, sortie] = process.argv.slice(2);
    const litteral = sortie.replaceAll("'", "''");
    const db = new DatabaseSync(source, { readOnly: true });
    db.exec(`VACUUM INTO '${litteral}'`);
    db.close();

    // Contrôle immédiat, sur le fichier qui va être copié dehors. Un dump
    // corrompu ne doit jamais atteindre le dossier de sauvegarde : on ne le
    // verrait qu'au moment d'en avoir besoin.
    const copie = new DatabaseSync(sortie, { readOnly: true });
    const verdict = copie.prepare("PRAGMA integrity_check").get().integrity_check;
    const taille = copie.prepare("SELECT count(*) AS n FROM players").get().n;
    copie.close();
    if (verdict !== "ok") {
      console.error(`intégrité : ${verdict}`);
      process.exit(2);
    }
    console.log(`intégrité ok, ${taille} joueur(s)`);
NODE
  local statut=$?
  set -e
  if [ "$statut" -ne 0 ]; then
    docker exec "$conteneur" sh -c 'rm -f "$1"' sh "$dump_interne" || true
    die "$conteneur : le dump a échoué (code $statut), rien n'a été copié"
  fi

  docker cp "$conteneur:$dump_interne" "$dump_final" >/dev/null
  docker exec "$conteneur" sh -c 'rm -f "$1"' sh "$dump_interne"

  # `VACUUM INTO` produit un fichier lisible par n'importe quel SQLite, et
  # lisible par rien d'autre. On le vérifie donc une seconde fois, avec
  # l'outillage de l'hôte — le contrôle de l'étape précédente tourne dans le
  # conteneur, sur le même runtime que l'écriture. Deux vérifications par deux
  # outils distincts, sur le fichier **copié**, pas sur l'original.
  python3 - "$dump_final" <<'PY'
import sqlite3, sys
chemin = sys.argv[1]
connexion = sqlite3.connect(f"file:{chemin}?mode=ro", uri=True)
verdict = connexion.execute("PRAGMA integrity_check").fetchone()[0]
connexion.close()
if verdict != "ok":
    print(f"intégrité du fichier copié : {verdict}")
    sys.exit(3)
PY

  log "$conteneur → $(basename "$dump_final") ($(du -h "$dump_final" | cut -f1))"
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

log "terminé"
