# Opération Beluga — v0.1.0

Première version d'**Opération Beluga**. Le squelette est jouable de bout en
bout ; **le contenu des ateliers 2 à 7 est encore celui d'`Atelier Docker`**, et
seul l'atelier 1 est réécrit sur le nouveau fil rouge.

**L'URL n'est pas annoncée.** Elle sert à l'enseignant pendant la construction.
Ne pas diffuser avant la v1.0.0.

---

## Ce que c'est

Un serious game d'apprentissage de Docker, sous la forme d'un vol à tenir.

Onze mille mètres, au-dessus de l'océan. Le vol Beluga vient de traverser une
zone de turbulence ; le capitaine a coupé le pilote automatique ; **Beluga**, le
copilote, ne répond plus. Vous êtes le seul ingénieur de bord, et **le serveur de
bord est la machine devant vous**.

Pour des étudiants qui n'ont jamais tapé une commande Docker. Chaque élève a sa
propre VM Ubuntu Server vierge, travaille **seul**, et tape ses commandes dans son
propre terminal. Le portail ne fait que **valider** : il ne se connecte jamais au
Docker des élèves, et n'exécute aucune commande à leur place.

**7 ateliers · 27 quêtes · ~7 h de contenu indicatif · 215 tests.**

---

## Le fil rouge, et où il est

Le cadre est posé **une fois**, dans l'intro de l'atelier 1. Chaque atelier est
ensuite **un état de plus qu'on stabilise**, et chaque système d'avion est l'objet
du travail :

| # | système d'avion | atelier | les quêtes |
|---|---|---|---|
| 1 | 🩺 **Évaluation** | Évaluer le patient | diagnostiquer la machine, installer l'outillage, le vérifier |
| 2 | 📦 **Approvisionnement** | Ramener les pièces | récupérer une image, la lancer, la jeter, le serveur de catalogue |
| 3 | ⚙️ **Mise en service** | Régler en service | ports et variables, cycle de vie, isolation |
| 4 | 🌐 **Liaisons de bord** | Brancher les systèmes | réseau privé, port publié, résolution par nom |
| 5 | 📄 **Certification** | Certifier les pièces | `commit` et Dockerfile, CMD/ENTRYPOINT, image reproductible |
| 6 | 💾 **Sauvegarde** | Sauvegarder les données | ce qui survit à la mort du conteneur |
| 7 | 📚 **Carte de bord** | Documenter la carte | toute la pile dans un fichier, puis la piloter |
| 8 | 🛬 **Atterrissage** | *à écrire* | la pile complète, assemblée et prouvée |

Le récit est **entièrement porté par les énoncés**, plus une introduction par
atelier. Il n'emporte **jamais** une question de compréhension : c'est une règle
de conception, pas une préférence. Un élève qui répond « parce qu'il faut garder
Beluga en vie » n'a rien appris du Docker, et le jeu ne doit pas lui faire croire
le contraire.

---

## Ce que cette version ajoute

### `meta.story` — le fil rouge devient une donnée

L'introduction narrative de chaque atelier, premier élément de données du fil
rouge. **Obligatoire** : le serveur refuse de démarrer sans.

```js
meta: {
  slug, module, title, tagline, icon,
  story: `# Titre\n\nDeux à quatre paragraphes.`,
}
```

Elle s'affiche au-dessus de la **première** quête du module, et seulement
celle-là. Elle passe par le même mini-renderer que `brief`, et donc par les mêmes
garde-fous : un seul titre `# `, pas de tableau, pas d'HTML, pas d'image. Une
règle non supportée disparaît **en silence** — c'est pour ça que `verifierProse()`
sert aux deux, plutôt que d'être écrit deux fois.

`story` sort par `/api/quests`, avec la même substitution que `brief` et
`fetchHint`. `modules[].quests[].order` sort aussi : le client en a besoin pour
savoir s'il ouvre une première quête. `number` ne le dit pas — la quête 5 peut
être la première de l'atelier 2.

### Le carnet de bord

Sept lignes dans la colonne de gauche, une par système d'avion, plus une
huitième pour l'atterrissage. Une ligne s'allume quand son atelier est
entièrement validé ; on peut cliquer dessus pour ouvrir la première quête non
validée.

**C'est du décor narratif.** Il ne mesure rien et n'entre dans aucun ratio : il
affiche un fait que le serveur connaît déjà. Il se dérive de
`state.pack.modules`, donc **aucune requête supplémentaire** et rien à invalider
côté serveur. S'il entrait dans la maîtrise, « 7 systèmes sur 7 » aurait le
poids d'une note, et il n'en est pas une.

Une ligne stabilisée dit « stabilisé », pas « 4/4 » : le décompte est déjà dans le
plan, la ligne doit apporter autre chose.

---

## Ce que cette version renomme

| avant | après |
|---|---|
| Atelier Docker | Opération Beluga |
| Challenge ⚡ | **Turbulence** 🌀 |
| Sans stress 🧘 | **Calme** ☁️ |
| Debout dans le conteneur | **Éveillé** |
| Ça tourne | **Moteur en marche** |
| Autonome | **Aux commandes** |
| Geste sûr | **Vol stable** |
| Maîtrise | **Atterrissage** |

Les **valeurs d'API ne changent pas** : `competitive` et `normal` restent. Elles
sont un contrat — les élèves s'inscrivent en ligne de commande avec
`{"mode":"competitive"}`, et les consignes déjà données continueraient de
fonctionner. Seuls les libellés lus à l'écran changent.

Le vocabulaire `arena` est **conservé** : `X-Arena-Token`,
`X-Arena-Admin`, `routes/atelier.js`, `ARENA_*`, `repo/arena.js`, `secret.js`.
Il a survécu à deux changements de nom et c'est un contrat d'API ; le
« nettoyer » a déjà été tenté une fois, et le diff a été annulé.

Les **seuils** de maîtrise ne changent pas non plus. Les noms racontent le vol,
les seuils mesurent l'élève.

---

## Le mot de passe n'est jamais dans l'énoncé

Règle structurante du contenu, inchangée. Chaque quête fournit la commande qui va
le chercher, et cette commande utilise **la technique même que l'atelier
enseigne** :

| atelier | comment on récupère le mot de passe |
|---|---|
| 1 | `cat` d'un fichier système dans un conteneur (puis `curl` — l'outillage n'existe pas encore) |
| 2 | la sortie d'un `docker run` |
| 3 | `docker exec` / `docker cp` dans un conteneur en marche |
| 4 | la réponse HTTP d'un port publié |
| 5 | la sortie d'un conteneur construit par ses soins |
| 6 | un volume relu par un second conteneur |
| 7 | les journaux de la pile Compose |
| 8 | l'état de santé de la pile finale |

Le mot de passe est dérivé du jeton du joueur : deux élèves ne l'ont jamais
identique, et se le communiquer ne prouve rien. Le validateur refuse un `brief`
qui contient le flag, qui promet qu'il est affiché, ou qui demande une réponse
écrite sans champ pour la saisir.

---

## Ce qui remplace le score

Trois mesures, sur un seul élève, **aucune comparable à celle d'un camarade** :

| mesure | formule |
|---|---|
| progression | quêtes validées / 27 |
| autonomie | validées sans indice payé / validées |
| compréhension | validées avec QCM réussis / validées |

Le niveau exige **deux seuils** — autonomie *et* avancement. Sans le second, un
élève qui réussit sa première quête sans indice (autonomie 100 %) verrait
« Atterrissage » s'afficher à 4 % du jeu.

**Pas de classement, pas de podium, pas de score.** C'est un choix, et il a un
prix : le portail perd son classement en direct, qui était son effet le plus
spectaculaire. Ce qu'il gagne est une vue qui répond à la seule question utile
pendant une séance — *qui est bloqué, et où*.

---

## Déploiement

Les deux portails tournent **en parallèle** sur `ociuc`, derrière le même Caddy :
`atelierdocker.laurans.org` et `operation-beluga.laurans.org`. **Rien n'est
partagé** — ni volume, ni base, ni clé, ni sel. C'est délibéré, et c'est le
point à ne pas rater.

| | Atelier Docker | Opération Beluga |
|---|---|---|
| domaine | `atelierdocker.laurans.org` | `operation-beluga.laurans.org` |
| conteneur | `atelier-docker` | `operation-beluga` |
| volume | `atelier-docker-data` | `operation-beluga-data` |
| clé | `ATELIER_ADMIN_KEY` | `BELUGA_ADMIN_KEY` |
| sel | `atelier-docker-v2` | `operation-beluga-v1` |

La clé d'administration est **nouvelle et dédiée**, générée sur le serveur, et le
secret GitHub `BELUGA_ADMIN_KEY` est configuré — ce que le dépôt
d'`Atelier Docker` n'a jamais eu, et qui y laissait un joueur `Verif_*` à chaque
exécution de la CI.

```bash
ssh ociuc
cd /app/operation-beluga
git fetch && git reset --hard origin/main
docker compose up -d --build
```

Le bloc Caddy à ajouter :

```
operation-beluga.laurans.org {
    reverse_proxy operation-beluga:8000
}
```

`docker-compose.yml` ne publie **aucun port** : le portail rejoint le réseau
Docker du reverse proxy et n'est atteignable que par lui.

---

## Corrections au passage

Elles sont dans le code et couvertes par les tests ; cette liste est pour le
lecteur.

- **`.env.example` était ignoré par `.gitignore`.** Le motif `.env.*` l'avalait, et
  le fichier n'était versionné que parce qu'il était dans l'index depuis
  toujours. `git check-ignore` considère un fichier **déjà suivi** comme jamais
  ignoré — donc le défaut n'apparaissait que dans un dépôt neuf, où le premier
  `git add -A` l'aurait laissé tomber. Ajouté : `!.env.example`.
- **`admin.js` avait quatre libellés de mode en dur**, hors du test de cohérence.
  Renommer `MODE_LABELS` laissait `/admin` afficher l'ancienne nomenclature sans
  qu'aucun test ne le voie.
- **`/api/admin/mode` renvoyait la valeur d'API dans son message** : l'enseignant
  lisait « passe en normal » au lieu de « passe en Calme ». Le message et le
  journal de l'événement utilisent maintenant `modeLabel`.
- **`verifie-jeu.mjs` échouait en `ENOENT`** si le répertoire de captures n'existait
  pas — après plusieurs minutes de jeu, ce qui fait croire à un bug.
- **Trois fichiers contenaient des caractères CJK** introduits par accident dans
  des commentaires.

---

## Vérifications

215 tests, la validation du contenu, la construction de l'image, un conteneur qui
démarre et sert le programme, et la recette dans un vrai Chromium
(`verifie-jeu.mjs`) sur les ateliers 1, 2 et 3.

---

## Ce que cette version n'est pas

1. **Le contenu est incohérent.** Les intros racontent le vol Beluga, les quêtes
   des ateliers 2 à 7 racontent encore la librairie Verdi. L'URL n'est pas
   annoncée ; elle sert à l'enseignant pendant la construction.
2. **L'atelier 8 n'existe pas.** Pas de manœuvre finale, donc la ligne
   « Atterrissage » du carnet de bord ne s'allume jamais.
3. **Aucune sauvegarde.** Le volume est sur le seul disque du serveur, à 86 %
   utilisés. Hors périmètre pour l'instant, mais c'est le risque le plus élevé du
   déploiement.
4. **`LINEAR_PROGRESSION` n'est pas une contrainte serveur**, comme avant.

---

## La suite

1. Réécrire les quêtes des ateliers 2 à 7.
2. Écrire l'atelier 8 — après, parce qu'il dépend de la pile que les ateliers 4 à
   7 font construire.
3. Configurer une sauvegarde du volume.
4. `v1.0.0`, quand le contenu est cohérent de bout en bout.
