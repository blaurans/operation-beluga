#!/usr/bin/env bash
#
# Restaure un dump de sauvegarde **à la place** de la base d'un portail.
#
#     sudo bash scripts/restaure-base.sh operation-beluga            # le plus récent
#     sudo bash scripts/restaure-base.sh operation-beluga <fichier>  # un dump précis
#     sudo bash scripts/restaure-base.sh --verifier-seulement        # sans rien écrire
#     sudo bash scripts/restaure-base.sh --lister                    # les dumps disponibles
#
# ## Pourquoi c'est un script séparé, et pas une option de la sauvegarde
#
# Restaurer est plus dangereux que sauvegarder : un dump du mauvais jour efface
# une journée de travail des élèves. Les deux opérations ne doivent donc pas
# partager un chemin de code — il suffit d'un mot mal tapé pour que la
# restauration devienne l'écrasement.
#
# ## Ce que le script refuse de faire
#
# Il ne restaure **jamais** sans que l'opérateur nomme le portail **et** un
# fichier. Avec `--verifier-seulement` il n'écrit rien du tout. Une restauration
# n'a pas d'urgence : le temps de regarder ce qu'on va écraser est une
# caractéristique, pas un retard.
#
# ## Le conteneur est arrêté, et ce n'est pas une précaution de style
#
# Le serveur écrit en WAL, dans `beluga.sqlite-wal`. Si ce fichier survit au
# remplacement de `beluga.sqlite`, SQLite le rejoue sur la base neuve — et
# re-applique donc les suppressions qui s'y trouvent encore.
#
# Le premier jet de ce script faisait exactement cela. Il annonçait
# « restauré », son contrôle d'intégrité disait « ok », et le joueur que je
# venais de restaurer **avait disparu** — parce que sa suppression était
# encore dans le WAL, que le nouveau fichier ne remplaçait pas.
#
# C'est le pire mode de défaillance possible pour une sauvegarde, parce
# qu'il n'en a l'air d'aucun. C'est aussi pour cela que la fin du script
# **recompte** les joueurs après redémarrage et compare au dump : « le script a
# dit que c'était bon » ne vaut rien, puisque c'est lui qui l'a dit.
#
# L'arrêt coûte une dizaine de secondes d'indisponibilité. C'est le prix, payé
# à un moment choisi : une restauration n'a jamais d'urgence.

set -Eeuo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${DESTINATION:-$RACINE/sauvegardes}"

# conteneur:base dans le conteneur
PORTAILS=(
  "operation-beluga:/data/beluga.sqlite"
  "atelier-docker:/data/atelier.sqlite"
)

log() { printf '%s  %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"; }

# Le conteneur jetant tourne en **root** (`--user 0:0`) : c'est lui qui remet le
# fichier à l'utilisateur du portail. L'image est `node:24-alpine`, dont
# l'utilisateur par défaut est `node` — et un `chown` lancé par `node` sur un
# fichier de `arena` échoue.
#
# Ce n'est pas une.detail : quand le `chown` a échoué, le fichier restauré est
# resté à `root`, et le serveur s'est mis en boucle de redémarrage sur
# `attempt to write a readonly database`. Le portail est resté indisponible
# presque deux minutes. Le script s'en est aperçu — il s'est arrêté sur le
# `chown` — mais le conteneur, lui, était resté arrêté, et c'est ce downtime
# qui a été long.
#
# D'où deux choses : `--user 0:0`, et un `trap` qui redémarre le conteneur même
# en cas de sortie en erreur.
#
# L'image **du conteneur**, pas son nom.
#
# `docker run operation-beluga` cherche une image qui s'appelle
# `operation-beluga:latest` — et l'image du portail est taguée
# `operation-beluga:0.3`, sans alias. Le conteneur et son image ne portent donc
# pas le même tag, et le premier jet échouait sur « repository does not exist ».
#
# Le conteneur étant arrêté pendant la restauration, `docker exec` ne passe plus :
# il faut bien un conteneur jetant pour lire le volume. D'où cette résolution.
IMAGE=""
image_du_conteneur() {
  if [ -z "$IMAGE" ]; then
    IMAGE=$(docker inspect -f '{{.Image}}' "$portail" 2>/dev/null || echo "")
    [ -n "$IMAGE" ] || die "impossible de résoudre l'image du conteneur $portail"
  fi
  printf '%s' "$IMAGE"
}
die() { printf 'ÉCHEC : %s\n' "$*" >&2; exit 1; }

verifier_seulement=0
lister=0
fichier=""
portail=""

while [ $# -gt 0 ]; do
  case "$1" in
    --verifier-seulement) verifier_seulement=1; shift ;;
    --lister)             lister=1; shift ;;
    -h|--help)            sed -n '2,45p' "$0"; exit 0 ;;
    -*)                    die "option inconnue : $1" ;;
    *)                     [ -z "$portail" ] && portail="$1" || fichier="$1"; shift ;;
  esac
done

if [ "$lister" = 1 ]; then
  for entree in "${PORTAILS[@]}"; do
    conteneur="${entree%%:*}"
    echo "== $conteneur"
    find "$DESTINATION" -maxdepth 1 -name "${conteneur}-*.sqlite" -type f \
      -printf '  %TY-%Tm-%Td %TH:%TM  %10s  %p\n' 2>/dev/null | sort -r \
      || echo "  (aucun dump)"
  done
  exit 0
fi

[ -n "$portail" ] || die "il faut nommer un portail. Voyez --lister."

base=""
for entree in "${PORTAILS[@]}"; do
  [ "${entree%%:*}" = "$portail" ] && base="${entree#*:}"
done
[ -n "$base" ] || die "portail inconnu : $portail. Attendu : operation-beluga ou atelier-docker."

if [ -z "$fichier" ]; then
  # Le plus récent **par date de modification**, pas par nom : un dump restauré
  # à la main doit gagner, et rien ne garantit que l'horodatage du nom soit
  # cohérent avec celui du fichier.
  fichier=$(find "$DESTINATION" -maxdepth 1 -name "${portail}-*.sqlite" -type f \
            -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  [ -n "$fichier" ] || die "aucun dump pour $portail dans $DESTINATION"
  log "dump le plus récent : $fichier"
fi

[ -f "$fichier" ] || die "fichier introuvable : $fichier"

# ── contrôle du dump, avant toute écriture ──────────────────────────────

log "contrôle du dump"
attendus=$(python3 - "$fichier" <<'PY'
import sqlite3, sys
connexion = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
verdict = connexion.execute("PRAGMA integrity_check").fetchone()[0]
if verdict != "ok":
    print(f"intégrité : {verdict}", file=sys.stderr)
    sys.exit(3)
print(connexion.execute("SELECT count(*) FROM players").fetchone()[0])
PY
) || die "le dump ne s'ouvre pas, ou n'est pas intact. Rien n'a été écrit."

validations=$(python3 -c "
import sqlite3, sys
c = sqlite3.connect('file:' + sys.argv[1] + '?mode=ro', uri=True)
print(c.execute('SELECT count(*) FROM completions').fetchone()[0])
" "$fichier")

log "  $attendus joueur(s), $validations validation(s)"

if [ "$verifier_seulement" = 1 ]; then
  log "vérification seule : rien n'a été écrit"
  exit 0
fi

[ "$(id -u)" -eq 0 ] || die "restaurer exige sudo : le volume appartient à root."

# ── à qui appartient la base ─────────────────────────────────────────────
#
# Un `docker cp` dépose le fichier en `root`. Le serveur tourne sous un autre
# utilisateur : un fichier qu'il ne peut pas écrire transforme la prochaine
# inscription en erreur. On note donc le propriétaire **avant** d'arrêter, tant
# que `docker exec` fonctionne encore.

proprietaire=$(docker exec "$portail" stat -c '%u:%g' "$base" 2>/dev/null || echo "")

# ── arrêt, remplacement, redémarrage ─────────────────────────────────────

horodatage="$(date -u '+%Y%m%dT%H%M%SZ')"
archive="/data/.avant-restauration-${horodatage}.sqlite"

log "arrêt de $portail"
docker stop "$portail" >/dev/null

# Toute sortie en cours de route doit laisser le portail **démarré**. Sans ce
# filet, une erreur entre l'arrêt et le redémarrage — un `chown` refusé, un
# `docker cp` en faute — laissait le conteneur à l'arrêt, et le portail
# indisponible jusqu'à ce qu'un opérateur le remarque. C'est arrivé pendant la
# mise au point de ce script.
redemarrer_en_sortie() {
  local code=$?
  if [ "$code" -ne 0 ] && [ "$(docker inspect -f '{{.State.Running}}' "$portail" 2>/dev/null || echo false)" != "true" ]; then
    printf '\n' >&2
    printf 'ERREUR %s : le portail est arrêté et le redémarrage n\047a pas été fait.\n' "$code" >&2
    printf 'Redémarrage de %s. La base précédente est dans le volume.\n' "$portail" >&2
    docker start "$portail" >/dev/null 2>&1 || true
  fi
  rm -f "${relais:-}" 2>/dev/null || true
}
trap redemarrer_en_sortie EXIT

log "la base actuelle est conservée dans le volume, sous $(basename "$archive")"
# `docker cp` refuse le copie de conteneur à conteneur (« copying between
# containers is not supported »), même pour le même conteneur. On passe donc par
# l'hôte : le conteneur est arrêté, donc le fichier n'est pas en cours
# d'écriture, et le détour n'a pas de risque.
relais="/tmp/.sauvegarde-avant-restauration-$$.sqlite"
docker cp "$portail:$base" "$relais" >/dev/null
docker cp "$relais" "$portail:$archive" >/dev/null
rm -f "$relais"
relais=""
trap - EXIT

provisoire="/data/.restauration-${horodatage}.sqlite"
log "copie du dump dans le volume"
docker cp "$fichier" "$portail:$provisoire" >/dev/null

# Contrôle du dump **dans le volume**, avant mise en place. Le conteneur est
# arrêté, donc `docker exec` ne passe plus : c'est un conteneur jetant qui
# monte le volume. `if !` parce que sous `set -e` un heredoc qui échoue arrête
# le script et laisserait le fichier temporaire derrière lui.
if ! docker run --rm --user 0:0 --volumes-from "$portail" --entrypoint node "$(image_du_conteneur)" \
     --input-type=module - "$provisoire" <<'NODE'
    import { DatabaseSync } from "node:sqlite";
    const [chemin] = process.argv.slice(2);
    const db = new DatabaseSync(chemin, { readOnly: true });
    const verdict = db.prepare("PRAGMA integrity_check").get().integrity_check;
    db.close();
    if (verdict !== "ok") { console.error(`intégrité : ${verdict}`); process.exit(2); }
NODE
then
  docker run --rm --user 0:0 --volumes-from "$portail" --entrypoint sh "$(image_du_conteneur)" -c \
    "rm -f '$provisoire'" >/dev/null 2>&1 || true
  docker start "$portail" >/dev/null
  die "le dump ne s'ouvre pas dans le volume. La base actuelle est intacte, et $portail repart."
fi

log "mise en place — et retrait du WAL de l'ancienne base, qui la rejouerait par-dessus"
docker run --rm --user 0:0 --volumes-from "$portail" --entrypoint sh "$(image_du_conteneur)" -c "
  mv -f '$provisoire' '$base' &&
  rm -f '$base-wal' '$base-shm'
  [ -n '$proprietaire' ] && chown '$proprietaire' '$base'
" >/dev/null

log "démarrage de $portail"
docker start "$portail" >/dev/null

# ── la vérification qui compte ───────────────────────────────────────────
#
# Le compte se fait **après** redémarrage, sur la base en place, et se compare
# au dump. Un écart n'est pas une alerte : c'est un échec, et la restauration
# est déclarée non fiable.

obtenus=0
for _ in $(seq 1 20); do
  if [ "$(docker inspect -f '{{.State.Running}}' "$portail" 2>/dev/null || echo false)" = "true" ]; then
    sleep 2
    obtenu=$(docker exec "$portail" node --input-type=module -e '
      import { DatabaseSync } from "node:sqlite";
      const db = new DatabaseSync(process.argv[1], { readOnly: true });
      process.stdout.write(String(db.prepare("SELECT count(*) AS n FROM players").get().n));
      db.close();
    ' "$base" 2>/dev/null || echo "?")
    [ "$obtenu" != "?" ] && { obtenus="$obtenu"; break; }
  fi
  sleep 1
done

if [ "$obtenus" = "$attendus" ]; then
  log "vérifié : $obtenus joueur(s) dans la base, comme dans le dump"
  log "fait"
else
  printf '\n' >&2
  printf 'ÉCHEC : le dump contient %s joueur(s), la base en contient %s.\n' "$attendus" "$obtenus" >&2
  printf 'La restauration n\047est pas fiable, et le joueur vient peut-être de\n' >&2
  printf 'revenir sans qu\047on le voie. La base précédente est dans le volume,\n' >&2
  printf 'sous %s.\n' "$archive" >&2
  exit 4
fi
