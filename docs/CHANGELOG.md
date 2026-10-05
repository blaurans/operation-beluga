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
- **L'en-tête de `/admin` affichait encore « ATELIER DOCKER »**, alors que le
  formulaire de connexion portait déjà le nouveau nom. Le changement avait été
  fait au `<div>` du formulaire ; l'en-tête de la classe, qui n'apparaît qu'une
  fois connecté, avait été oublié. Trouvé en ouvrant `/admin` dans un vrai
  navigateur — aucun test ne le voyait. Un test lit maintenant les deux pages
  servies.

### Vérifications

215 tests, la validation du contenu, la construction de l'image, un conteneur qui
démarre et sert le programme, et la recette dans un vrai Chromium
(`verifie-jeu.mjs`) sur les ateliers 1, 2 et 3.

### Limites connues

1. **Le contenu est incohérent avant la v1.0.** Les intros racontent le vol
   Beluga, les quêtes des ateliers 2 à 7 racontent encore la librairie Verdi.
   L'URL n'est pas annoncée : elle sert à l'enseignant pendant la construction.
   → **corrigé en v0.2.0.**
2. **L'atelier 8 n'existe pas.** Pas de manœuvre finale, donc la ligne
   « Atterrissage » du carnet de bord ne s'allume jamais.
3. **Aucune sauvegarde.** Le volume est sur le seul disque du serveur, à 86 %.
   Hors périmètre pour l'instant.
4. **`LINEAR_PROGRESSION` n'est pas une contrainte serveur**, comme avant.

---

## [0.2.0] — 2026-10-05

Les 27 quêtes basculent sur l'intrigue du vol Beluga. **Le jeu est cohérent de
bout en bout** : les sept ateliers racontent le même vol, du diagnostic à la
carte de bord.

Le renommage est passé par `outils/passe-becane.py` plutôt qu'à la main. Les
noms reviennent des dizaines de fois par fichier — `verdi` seul en apparaissait
114 fois dans l'atelier 6 — et une réécriture manuelle laisse toujours un
oubli. Un grep, lui, ne laisse rien.

| avant | après |
|---|---|
| conteneur `verdi` | `cabine` |
| base `verdi-db` | `cabine-db` |
| réseau `reseau-verdi` | `reseau-cabine` |
| image `verdi-site:1.0` | `service-cabine:1.0` |
| `NOM_DU_SITE` | `NOM_DU_SERVICE` |
| flags `VERDI_*` | `CABINE_*` |
| « le stock de la librairie » | les plateaux du service de restauration |

**Les commandes sont renommées dans le même passage que les énoncés.** Elles
sont ce que l'élève tape : si le texte change et pas la commande, la correction
ne correspond plus à ce qu'il a fait. C'est la contrainte qui a dicté l'ordre
des substitutions.

### Défauts trouvés au passage

- **`grep -i cabine` ne trouvait rien.** La substitution avait porté le motif
  du `grep` sur le nom du conteneur, alors que la page affiche « Restauration
  Beluga ». Six commandes promises dans les énoncés et leurs corrections
  échouaient, et l'élève lisait un échec sans comprendre pourquoi. C'est le
  piège d'un renommage par motif : le motif a suivi le nom, pas ce que la
  commande cherche réellement.
- **L'accord avait sauté.** « librairie » est féminin, « service » est masculin :
  « le service n'est pas **seule** derrière son firewall », « le service n'est
  pas **terminée** ». Le nom change, la grammaire doit suivre.
- **Une explication était en anglais**, au milieu d'un jeu entièrement français.
- Une question portait `MON_SITE`, incohérent avec la variable de l'énoncé.
- « Le premier serveur de la librairie » était devenu « Le premier serveur de
  **le** service de restauration » : la substitution ne connaît pas le genre de
  l'article qui la suit.

### Deux tests sur le fond

Aucun test ne vérifiait que le **contenu** racontait la bonne histoire. C'est
ajouté maintenant, après coup — parce que le nom du produit a déjà changé deux
fois sans que ce contrôle existe :

- aucune quête ne parle plus de l'ancienne intrigue : ni énoncé, ni titre, ni
  flag, ni question, ni réflexe ;
- **le fil rouge ne porte jamais une question de compréhension**. Un élève qui
  répond « parce qu'il faut garder Beluga en vie » n'a rien appris du Docker,
  et le jeu ne doit pas lui faire croire le contraire. C'est une règle de
  rédaction, pas de forme : le validateur de contenu ne peut pas la vérifier.

Le second test ignore le texte entre accents graves, parce que `cabine-db` et
`reseau-cabine` sont des **noms de ressources** et non du récit. Sans cette
distinction, il échouait sur la première question réseau — et il aurait été
écarté au lieu d'être corrigé.

217 tests.

---

## [0.3.0] — 2026-10-05

**L'atelier 8 — la manœuvre finale.** Le jeu est complet : 8 ateliers, 28
quêtes, et un fil rouge cohérent du diagnostic à l'atterrissage.

### Ce qu'est l'atelier 8

Il ne construit presque rien de neuf. Il **assemble**, et il exige la preuve.

C'est le point de conception du projet, et il mérite d'être dit : l'atelier 7
dit explicitement que `depends_on` décrit un **ordre de démarrage**, et pas une
disponibilité. C'est vrai, et c'est le dernier défaut du vol. L'atelier 8 le
ferme avec deux notions employées ensemble :

- un **`healthcheck`** — le service dit lui-même s'il est prêt ;
- **`condition: service_healthy`** — le service dépendant attend ce verdict, au
  lieu d'attendre que le conteneur existe ;
- et **`profiles`**, qui permet d'avoir dans le **même** fichier un contrôle de
  vol qui ne démarre jamais avec la pile.

Une pile où le site est monté avant sa base n'est pas une pile en panne : c'est
une pile qui *semble* marcher. Le site répondra, la base ne sera pas prête, et
personne ne le verra tant que rien ne l'appellera.

### La preuve est négative

L'énoncé demande de faire tomber la pile, de voir le contrôle le dire, puis de
le relever. C'est le parti pris central de l'atelier : **faire tourner la pile ne
prouve rien** — ça ne prouve rien de plus que les sept ateliers précédents. Un
test qui n'a jamais échoué n'a pas été exécuté.

La question de compréhension porte sur le **code de sortie**, pas sur la ligne
affichée : un contrôle qui réussit pendant la panne ne contrôle rien.

### La borne des points passe de 600 à 800

`points` est un vestige, plus rien ne le lit. Mais la borne haute à 600 rendait
**l'atelier 8 impossible à écrire** : un module doit avoir un total multiple de
100 strictement croissant, m7 finissait à 700, et une quête unique plafonnée à
600 ne pouvait pas le dépasser.

C'est le genre de borne qui paraît arbitraire jusqu'à ce qu'un atelier la bute.
Le commentaire dans le validateur dit maintenant pourquoi elle vaut 800, et quoi
vérifier avant de la redescendre.

### Un test qui ne vérifiait rien

`outils/navigateur/verifie-jeu.mjs` annonçait « 3/3 répondues » **quelle que soit
la réalité**. Deux défauts successifs, tous deux dans la boucle qui répond aux
questions de compréhension :

1. Elle lisait le texte d'un nœud **détaché**. Après un clic, le client
   remplace la carte, donc la référence gardée en mémoire ne changeait plus
   jamais. La recette concluait « juste » dès qu'un bouton était désactivé —
   ce qui est vrai après n'importe quel clic.
2. Une fois la lecture corrigée, elle retombait sur le **premier** bouton à
   chaque tour, et cliquait « Vrai » cinq fois sans jamais essayer « Faux ». Le
   client réactive tous les boutons tant que la réponse est fausse, il fallait
   donc mémoriser les choix déjà tentés.

La recette prouvait donc **moins qu'elle ne le semblait, pendant toute la
construction de la v0.2.0**. C'est le piège énoncé dans `docs/REPRISE.md` § 11,
mais à l'envers : elle croyait que l'élève avait juste parce que le bouton était
mort. Le server et la recette sont maintenant d'accord, et la recette distingue
« répondu » de « juste ».

### Le script de renommage, testé

`passe-becane.py` avait corrompu **« verdict » en « cabinect »** : le nom de
conteneur `verdi` est une sous-chaîne du mot français, et la substitution n'avait
pas de frontière de mot. Il ne signalait rien — `--verifier` annonçait un
contenu propre.

Il avait aussi une seconde fragilité : il ne fonctionnait qu'en étant lancé
**deux fois**, parce qu'une règle rattrapait un état intermédiaire du texte
(« de le service de restauration »). Le cas général absorbe désormais les cas
particuliers, et le script est **idempotent**.

`outils/test-passe-becane.py` verrouille les douze cas, dont les trois pièges. Il
tourne dans la CI : un script de migration sans test est un script dont on ne
peut pas vérifier qu'il a fini sa tâche.

### Deux tests de contenu refusent la faute

- une question de compréhension de l'atelier 8 citait le verdict d'atterrissage,
  et **le test l'a refusée** : le fil rouge ne porte jamais une question, sinon
  un élève y répond par intuition et n'a rien appris du Docker ;
- l'énoncé d'un test vérifiait encore « 7 modules » en dur, et un autre
  attendait `0/27`. Le total vient maintenant du contenu, ce qui est le seul
  moyen que ces tests survivent à l'ajout d'un atelier.

217 tests, plus la vérification du script de renommage.

---

## [0.4.0] — 2026-10-05

**La sauvegarde quotidienne des deux bases**, avec restauration vérifiée.

### Ce qui est en place

`scripts/sauvegarde-bases.sh` dump les bases de `operation-beluga` **et**
`atelier-docker` — les deux jeux partagent le même sort, et sauvegarder l'un
sans l'autre laisserait un portail accessible et l'autre vide.

Le dump se fait par `VACUUM INTO`, donc **cohérent même base en cours
d'écriture**. Ce n'était pas un détail théorique : pendant les essais, les
élèves d'`Atelier Docker` étaient connectés, et la sauvegarde a pris leurs
progressions sans les interrompre.

Le dump est **contrôlé avant d'être copié dehors** : `PRAGMA integrity_check`
dans le conteneur, puis une seconde vérification sur le fichier copié, avec
l'outillage de l'hôte. Un dump corrompu dans le dossier de sauvegarde ne se
distingue d'un bon que le jour où on en a besoin — c'est le pire moment pour
découvrir la différence.

La rétention est de 7 jours, par portail. Un glob large purgerait les dumps de
l'autre jeu.

L'exécution est portée par un **timer systemd**, à 3 h 12 avec un écart
aléatoire de 15 minutes : un déclencheur à `hh:00` réveille tous les timers de la
machine en même temps. `cron` n'est pas actif sur cette machine, et un timer
survit au redémarrage.

### La restauration se prouve

`scripts/restaure-base.sh` arrête le portail, remplace la base, **retire le
`-wal` de l'ancienne**, remet le fichier au bon propriétaire, redémarre, puis
**recompte les joueurs et compare au dump**. Un écart est un échec, pas un
avertissement.

Le retrait du `-wal` est l'essentiel, et c'est un bug que seul un test de bout
en bout pouvait prendre. Le premier jet annonçait « restauré », son contrôle
d'intégrité disait « ok », et **le joueur restauré avait disparu** : sa
suppression était encore dans le `beluga.sqlite-wal`, que le nouveau fichier ne
remplaçait pas, et SQLite rejouait le WAL par-dessus.

C'est le pire mode de défaillance possible pour une sauvegarde, parce qu'il
n'en a l'air d'aucun. C'est aussi ce que le jeu enseigne aux élèves à
l'atelier 7 — un test qui n'a jamais échoué n'a pas été exécuté — et c'est pour
cela que la restauration se compte elle-même.

### Une indisponibilité de deux minutes

Le `--user 0:0` sur le conteneur jetant manque, et le `chown` a échoué : le
fichier restauré est resté à `root`, et le serveur — qui tourne sous `arena` —
s'est mis en boucle de redémarrage sur `attempt to write a readonly database`.
Le portail est resté indisponible près de deux minutes.

Le script s'en est aperçu : il s'est arrêté sur le `chown`. Le conteneur, lui,
était resté arrêté, et c'est ce downtime qui a été long. Un `trap` qui
redémarre le portail à la sortie existe maintenant, pour que la prochaine erreur
entre l'arrêt et le redémarrage coûte dix secondes et non deux minutes.

### Ce que la sauvegarde ne fait pas

Elle **n'est pas hors site**. Les dumps atterrissent sur le même `/dev/sda1`
que les bases : elle protège d'un accident logique — une réinitialisation, un
volume corrompu — et pas de la mort du disque.

`/mnt/jellyfin-sftp` existe sur la machine, mais c'est un montage rclone **en
lecture seule** vers une autre machine : ce n'est pas une destination
d'écriture. Il faut un accès en écriture ailleurs, et c'est une décision, pas
une ligne de code. Elle est notée au § 2 du REPRISE.

Le dossier `sauvegardes/` est dans `.gitignore` : ce sont des copies des bases,
et les committer exposerait les pseudos, les adresses IP et les jetons des
élèves.

### Les archives de sécurité sont purgées, elles aussi

Chaque restauration laisse dans le volume une copie de la base qu'elle
remplaçait, pour pouvoir revenir en arrière. Rien ne la retirait : le volume en
accumulait une par restauration. C'est le défaut inverse d'une sauvegarde qui ne
purge pas — on ne perd rien, on sature le disque.

Le motif de purge a d'abord été faux deux fois, et **les deux fois le script a
annoncé que tout allait bien** :

- le glob cherchait `beluga.sqlite.avant-restauration-*` alors que les fichiers
  s'appellent `.avant-restauration-*` — un point devant, pour rester hors du
  chemin que le portail connaît. Le décompte final affichait « 0 archive
  restante » : un chiffre juste, sur un motif qui ne trouvait rien ;
- le script du conteneur était passé dans une double chaîne, donc le shell de
  l'appelant développait `$base` et les `$( )` à sa place, et le chemin arrivait
  vide.

C'est le même motif que la recette qui annonçait des questions réussies : un
décompte ou un verdict produit par le code qu'il est censé vérifier. Les
compter ne suffit pas, il faut les **faire venir d'ailleurs** — d'un `ls` dans
le dossier, à la main.

---

## [1.0.0] — à venir

Le gel. Il ne reste plus de contenu à écrire : les 28 quêtes sont là, et la
sauvegarde est en place. Ce qui reste est une relecture du contenu avec un œil
neuf, et la décision sur la destination hors site.
