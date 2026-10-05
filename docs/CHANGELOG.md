# Journal des versions

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versions sémantiques. Les tags Git et les GitHub Releases suivent ce fichier.

Le projet est en **0.x** : le format du contenu — le schéma d'une quête, le
nombre d'ateliers, la façon dont le fil rouge est porté — n'est pas encore figé,
et une réécriture d'un atelier est une opération normale. Le passage en 1.x
marquera le gel.

---

## [0.1.0] — 2026-10-05

Première version d'**Opération Beluga**. Le squelette est jouable de bout en
bout ; **le contenu des ateliers 2 à 7 est encore celui d'`Atelier Docker`**, et
seul l'atelier 1 a été réécrit sur le nouveau fil rouge. C'est le jalon suivant
qui rend le jeu cohérent de bout en bout.

### Le fil rouge

Le cadre est posé une fois, dans l'intro de l'atelier 1 : vol Beluga au-dessus
de l'océan, turbulence, pilote automatique coupé, copilote inconscient. Vous
êtes le seul ingénieur de bord, et **le serveur de bord est la machine devant
vous**.

Chaque atelier est un **système de l'avion** qu'on remet en état :

| # | système | atelier | quêtes |
|---|---|---|---|
| 1 | 🩺 | Évaluer le patient | 4 |
| 2 | 📦 | Ramener les pièces | 4 |
| 3 | ⚙️ | Régler en service | 4 |
| 4 | 🌐 | Brancher les systèmes | 4 |
| 5 | 📄 | Certifier les pièces | 4 |
| 6 | 💾 | Sauvegarder les données | 4 |
| 7 | 📚 | Documenter la carte | 3 |
| 8 | 🛬 | **L'atterrissage** | 1 — *à écrire* |

L'atelier 8 n'existe pas encore : c'est lui qui portera la manœuvre finale, la
pile complète. Il est écrit en dernier, une fois les sept autres en place, parce
qu'il dépend d'eux.

### Le mot de passe est le soldat, pas Docker

C'est un choix de conception, et il a une conséquence sur la rédaction.

`Atelier Docker` racontait une librairie qui migre : Docker était le héros, et
le fil rouge était le client. Ici, **le patient est le copilote et l'outillage
est Docker**. La conséquence : le fil rouge n'emporte **jamais** une question de
compréhension. Un élève qui répond « parce qu'il faut garder Beluga en vie » n'a
rien appris du Docker, et le jeu ne doit pas le laisser croire le contraire.

Le geste technique est repris tel quel. Ce qui change, c'est le cadre.

### Ce que cette version ajoute

- **`meta.story`** : l'introduction narrative de chaque atelier, premier élément
  de données du fil rouge. **Obligatoire** — le serveur refuse de démarrer sans
  (`src/questpack.js`). Elle est rendue par le même mini-renderer que `brief`,
  et passe donc par les mêmes garde-fous Markdown.
- **Le carnet de bord** : sept lignes dans la colonne de gauche, une par système
  d'avion, plus une huitième pour l'atterrissage. Une ligne s'allume quand son
  atelier est entièrement validé. C'est du **décor narratif** : il ne mesure
  rien, n'entre dans aucun ratio, et se dérive entièrement de ce que le serveur
  renvoie déjà. Aucune requête supplémentaire.
- **L'intro d'atelier à l'écran** : elle apparaît au-dessus de la première quête
  du module, et seulement celle-là. C'est le seul endroit du jeu où le récit est
  une donnée plutôt qu'un texte.
- **`order` dans `/api/quests`** : le rang dans le module, dont le client a besoin
  pour savoir s'il ouvre une première quête. `number` ne le dit pas — la quête 5
  peut être la première de l'atelier 2.

### Ce que cette version renomme

| avant | après |
|---|---|
| Atelier Docker | Opération Beluga |
| Challenge | **Turbulence** 🌀 |
| Sans stress | **Calme** ☁️ |
| Debout dans le conteneur | **Éveillé** |
| Ça tourne | **Moteur en marche** |
| Autonome | **Aux commandes** |
| Geste sûr | **Vol stable** |
| Maîtrise | **Atterrissage** |

Les **valeurs d'API ne changent pas** : `competitive` et `normal` restent, parce
qu'elles sont un contrat — les élèves s'inscrivent en ligne de commande avec
`{"mode":"competitive"}`, et les consignes déjà données continueraient de
fonctionner. Seuls les libellés lus à l'écran changent.

Le vocabulaire `arena` est **conservé** : `X-Arena-Token`, `routes/atelier.js`,
`ARENA_*`, `repo/arena.js`. C'est documenté dans `docs/REPRISE.md` § 9, et le
nettoyage a déjà été tenté une fois puis annulé.

### Déploiement

Les deux portails tournent **en parallèle** sur `ociuc`, derrière le même Caddy :

| | Atelier Docker | Opération Beluga |
|---|---|---|
| domaine | `atelierdocker.laurans.org` | `operation-beluga.laurans.org` |
| conteneur | `atelier-docker` | `operation-beluga` |
| volume | `atelier-docker-data` | `operation-beluga-data` |
| clé d'administration | `ATELIER_ADMIN_KEY` | `BELUGA_ADMIN_KEY` |
| sel de dérivation | `atelier-docker-v2` | `operation-beluga-v1` |
| image | `atelier-docker:1.0` | `operation-beluga:0.1` |

Rien n'est partagé. C'est délibéré : une clé d'administration ou un sel commun
ouvrirait l'administration d'un portail sur l'autre, ou ferait valider une quête
avec le mot de passe de l'autre jeu.

La clé d'administration est **nouvelle et dédiée**, générée sur le serveur, et le
secret GitHub `BELUGA_ADMIN_KEY` est configuré — ce que le dépôt
d'`Atelier Docker` n'a jamais eu, et qui y laissait un joueur de vérification à
chaque exécution de la CI.

### Corrections

Elles sont dans le code et dans les tests ; cette liste est pour le lecteur,
pas pour l'historique ligne à ligne.

- **`.env.example` était ignoré par `.gitignore`.** Le motif `.env.*` l'avalait, et
  le fichier n'était versionné que parce qu'il était dans l'index depuis
  toujours. Dans un dépôt neuf, le premier `git add -A` l'aurait laissé tomber en
  silence — et le test qui vérifie ce point aurait échoué sans que rien n'ait eu
  l'air de changer. Ajouté : `!.env.example`.
- **`admin.js` avait quatre libellés de mode en dur**, que le test de cohérence
  ne couvrait pas. Renommer `MODE_LABELS` laissait `/admin` afficher l'ancienne
  nomenclature sans qu'aucun test ne le voie. Le test couvre maintenant `admin.js`.
- **`/api/admin/mode` renvoyait la valeur d'API dans son message.** L'enseignant
  lisait `passe en normal` au lieu de `passe en Calme`. Le message et le journal
  de l'événement utilisent maintenant `modeLabel`.
- **`outils/navigateur/verifie-jeu.mjs` échouait en `ENOENT`** si le répertoire de
  captures n'existait pas. Le créer dans le script : un mode d'emploi à lire avant
  de lancer la recette est un document de trop, et l'oubli se paie après plusieurs
  minutes de jeu, ce qui fait croire à un bug.
- **Trois fichiers contenaient des caractères CJK** introduits par accident
  (`docker-compose.yml`, `test/admin.test.js`, `test/format.test.js`) : des
  traductions faites à la main dans un commentaire. Corrigés.

### Vérifications

214 tests, la validation du contenu, la construction de l'image, un conteneur qui
démarre et sert le programme, et la recette dans un vrai Chromium
(`verifie-jeu.mjs`) sur les ateliers 1, 2 et 3.

### Limites connues

1. **Le contenu est incohérent avant la v1.0.** Les intros racontent le vol
   Beluga, les quêtes des ateliers 2 à 7 racontent encore la librairie Verdi.
   L'URL n'est pas annoncée : elle sert à l'enseignant pendant la construction.
2. **L'atelier 8 n'existe pas.** Pas de manœuvre finale, donc pas d'atterrissage
   dans le carnet de bord.
3. **Aucune sauvegarde.** Le volume est sur le seul disque du serveur, à 86 %.
   Hors périmètre pour l'instant.
4. **`LINEAR_PROGRESSION` n'est pas une contrainte serveur**, comme avant.

---

## [1.0.0] — à venir

Le gel. Il conditionne : les 28 quêtes réécrites, la manœuvre finale écrite et
validée par `check-fetchhints`, et un contenu cohérent de bout en bout.
