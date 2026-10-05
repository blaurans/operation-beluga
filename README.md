# 🐋 Opération Beluga

Serious game d'apprentissage de Docker, sous la forme d'un vol à tenir.

**Le pitch.** Onze mille mètres, au-dessus de l'océan. Le vol Beluga vient de
traverser une zone de turbulence. Le capitaine a coupé le pilote automatique.
**Beluga**, le copilote, ne répond plus. Vous êtes le seul ingénieur de bord.

Il n'y a ni second serveur, ni secours, ni connexion au sol. **Le serveur de
bord, c'est la machine devant vous.** Tout ce que vous ferez pendant les sept
ateliers, vous le faites dessus, dans votre terminal.

L'outillage, c'est Docker. Le soldat, c'est le copilote. Et le jeu ne mesure
jamais votre vitesse.

---

## Ce que c'est, en une page

Pour des étudiants qui **n'ont jamais tapé une commande Docker**. Chaque élève a
sa propre VM Ubuntu Server vierge, travaille **seul**, et tape ses commandes
dans son propre terminal.

Le portail ne fait que **valider**. Il ne se connecte jamais au Docker des
élèves et n'exécute aucune commande à leur place. Tout se tape dans le terminal
de l'élève, sur sa machine.

**7 ateliers, 28 quêtes, ~7 h de contenu indicatif.** Chaque atelier est un
**système de l'avion** qu'on remet en état :

| # | système de l'avion | atelier | quêtes | ce qu'on y fait |
|---|---|---|---|---|
| 1 | 🩺 **Évaluer le patient** | Évaluer le patient | 4 | diagnostiquer la machine, installer l'outillage, vérifier qu'il répond |
| 2 | 📦 **Approvisionnement** | Ramener les pièces | 4 | récupérer une image, la lancer, la jeter, démarrer le serveur de catalogue |
| 3 | ⚙️ **Mise en service** | Régler en service | 4 | ports et variables d'environnement, cycle de vie, isolation |
| 4 | 🌐 **Liaisons de bord** | Brancher les systèmes | 4 | réseaux privés, ports publiés, résolution par nom |
| 5 | 📄 **Certification** | Certifier les pièces | 4 | `commit` et Dockerfile, CMD/ENTRYPOINT, l'image reproductible |
| 6 | 💾 **Sauvegarde** | Sauvegarder les données | 4 | ce qui doit survivre à la mort du conteneur |
| 7 | 📚 **Carte de bord** | Documenter la carte | 3 | toute la pile dans un fichier, puis la piloter |
| 8 | 🛬 **Atterrissage** | La manœuvre finale | 1 | la pile complète, assemblée et prouvée |

**Chaque atelier est introduit par son `meta.story`**, cette introduction
narrative qui est la seule donnée du fil rouge : le reste du récit est porté
par le texte des énoncés. Le champ est **obligatoire** — le serveur refuse de
démarrer sans (voir `docs/CONTRACTS.md` § 1).

Successeur d'**Atelier Docker**, qui reste en production sur
`atelierdocker.laurans.org` et est déployable tel quel (tag `v1.0.0`). Les deux
portails tournent **en parallèle**, sur deux volumes et deux domaines distincts.

---

## Mise en ligne

Le portail est en production sur **https://operation-beluga.laurans.org**, servi
par Caddy (TLS automatique) devant le conteneur.

Trois adresses, et c'est tout :

| adresse | pour qui |
|---|---|
| `https://operation-beluga.laurans.org` | **les élèves.** C'est la page d'accueil : elle ouvre directement l'écran de choix de mode |
| `https://operation-beluga.laurans.org/#/` | les mêmes, par l'ancienne adresse — elle fonctionne encore |
| `https://operation-beluga.laurans.org/admin` | **l'enseignant.** Derrière le mot de passe du `.env` |

```bash
cp .env.example .env
$EDITOR .env          # BELUGA_ADMIN_KEY est obligatoire
docker compose up -d --build
```

Puis, côté reverse proxy, un bloc de plus dans le Caddyfile :

```
operation-beluga.laurans.org {
    reverse_proxy operation-beluga:8000
}
```

Le `docker-compose.yml` **ne publie aucun port** : le portail rejoint le réseau
Docker du reverse proxy (`headscale_default`) et n'est atteignable que par lui.
Sans cette ligne dans le Caddyfile, le portail tourne mais reste injoignable ;
sans `BELUGA_ADMIN_KEY`, le compose refuse de démarrer.

> **Attention à la confusion des deux portails.** Les deux jeux tournent sur la
> même machine, derrière le même Caddy, sur le même réseau Docker. Ils ont des
> noms distincts partout — image, conteneur, volume, sel, clé d'administration,
> domaine — et c'est délibéré. Partager une seule de ces valeurs vide la base
> du mauvais jeu ou ouvre l'administration de l'un sur l'autre.

### Portail en local, sans proxy

Pour travailler sur le code, il faut repasser par une publication de port. La
copier dans une `compose.override.yml` — jamais dans le fichier versionné :

```yaml
services:
  beluga:
    ports:
      - "127.0.0.1:8000:8000"
    environment:
      TRUST_PROXY: "0"
```

```bash
docker compose up -d --build
```

Le portail répond alors sur `http://127.0.0.1:8000`, en `http` : `TRUST_PROXY`
vaut `0` parce qu'aucun proxy ne renseigne `X-Forwarded-Proto`. En recouvrant
ce `0` à `1` sans proxy, les commandes de récupération de mot de passe
partiraient en `https` vers le port 443 de la machine locale, où rien n'écoute.

---

## Ce que fait l'étudiant

Il choisit un mode, puis joue les missions sur **son propre Docker**, en tapant
les commandes dans son terminal habituel. Le portail ne fait que valider.

### Aucun verrou, dans les deux modes

Les 28 missions sont accessibles dès la première seconde. Un étudiant bloqué
sur la mission 7 peut lire la 12, consulter une correction antérieure, ou
attaquer directement la manœuvre finale. **Vous validez dans l'ordre que vous
voulez.**

Le bandeau « Par où continuer » au programme propose une suite, mais n'oblige
à rien. **L'ordre de validation ne change rien** à la maîtrise : c'est vérifié
par un test, parce que c'était l'effet du bonus de podium de la V1.

Si vous préférez une progression linéaire (dépannage de TP, ou progression
évaluée au fil de l'eau) :

```bash
echo "ARENA_LINEAR=1" >> .env && docker compose up -d
```

À noter : c'est un **guidage d'affichage**, pas une contrainte. Le plan ne
montre que la mission suivante comme ouverte, mais un appel direct à
`/api/submit` validerait quand même n'importe quel flag. C'est volontaire :
un ordre imposé côté serveur punirait l'étudiant qui utilise `curl` comme
documenté, sans rien apporter. Pour une contrainte réelle, c'est
`ARENA_ATTESTATION=1` — chaque flag correct attend alors votre validation.

|  | 🌀 Turbulence | ☁️ Calme |
|---|---|---|
| Temps affiché | oui, par quête | oui |
| Indices | **payants** — coûtent de l'autonomie | gratuits |
| Classement | aucun | aucun |
| Contenu | identique | identique |

**Les deux modes partagent exactement le même contenu et les mêmes mesures.** La
seule différence est le prix des indices. C'est tout.

Un élève en mode Calme n'a donc pas « un mode sans points » : il a le même jeu
que les autres. Ce qui change, c'est qu'il peut demander de l'aide sans que ça
se voie. C'est le mode par défaut quand le professeur est là.

Et aucun mode ne classe les élèves. La seule liste du portail est triée
alphabétiquement.

### Le carnet de bord

La colonne de gauche porte un **carnet de bord** : sept lignes, une par système
d'avion, plus une huitième pour l'atterrissage. Chaque ligne s'allume quand son
atelier est entièrement validé.

C'est du pur décor narratif — il ne dérive d'aucun fait que le serveur ne
connaît déjà. Il est rendu par le client à partir de `state.pack.modules`, donc
**aucune requête supplémentaire** et rien à invalider côté serveur. Il n'a aucun rôle dans la maîtrise : c'est la seule chose de l'écran qui ne mesure
rien.

---

## Le fil rouge

Le cadre est posé une fois, dans l'intro de l'atelier 1 : un vol dégradé, un
copilote qui ne répond plus, un serveur de bord et personne d'autre.

Chaque atelier est ensuite **un état de plus qu'on stabilise**, et chaque
système d'avion est l'objet du travail :

1. **Évaluer le patient** — on diagnostique la machine avant d'y toucher, et on installe l'outillage. Sans les deux, rien de ce qui suit n'est possible.
2. **Ramener les pièces** — la cause du défaut est trouvée : le service de repas est arrêté. On apprend à récupérer, lancer et jeter une pièce.
3. **Régler en service** — la pièce tourne mais ne fait rien de utile. On apprend les conditions de service, et on entre dans un conteneur pour voir.
4. **Brancher les systèmes** — le service est seul, son voisin n'existe pas. On relie, et on apprend que trois machines qui se parlent s'appellent par leur nom.
5. **Certifier les pièces** — ça marche, mais personne ne sait le refaire. On écrit la certification qui rend la pièce reproductible.
6. **Sauvegarder les données** — le service de bord plante et ne sait plus rien. On sépare ce qui survit de ce qui meurt.
7. **Documenter la carte** — tout fonctionne, et c'est écrit nulle part. On écrit la carte, et on apprend à la piloter.
8. **L'atterrissage** — la pile complète, assemblée et prouvée.

Le geste technique est celui d'`Atelier Docker`, à une exception près : le
récit est **entièrement porté par les énoncés**, et jamais par les questions de
compréhension. Une question qui porte le récit, un élève la répond par
intuition et n'a rien appris du Docker.

---

## Comment la validation fonctionne

Le mot de passe d'une mission **n'existe pas comme donnée**. Il n'est dans aucun
énoncé, dans aucune commande, dans le code. Le serveur le calcule à la volée :

```
FLAG{ HMAC_SHA256(sel_du_déploiement, jeton_du_joueur + ":" + id_mission)[:20] }
```

Deux conséquences utiles :

- **Il est unique par couple joueur × mission.** Deux élèves n'ont jamais le
  même, et se le communiquer ne prouve rien.
- **Il n'est pas devinable** à partir du contenu, puisqu'il n'y figure pas.

Chaque mission fournit la commande qui va le chercher — et cette commande
utilise **la technique même que l'atelier enseigne** :

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

Le portail substitue l'adresse du portail et le jeton du joueur à l'exécution :
ce que l'élève copie fonctionne.

---

## La maîtrise

**Pas de score, pas de classement, pas de podium.** C'est un choix pédagogique
assumé : le score mesurait l'inégalité de départ entre élèves, pas leur
progression. Ce qu'il y a à la place ne se compare qu'à soi-même :

| mesure | ce qu'elle compte | formule |
|---|---|---|
| **progression** | où j'en suis | `validées / 28` |
| **autonomie** | ce que j'ai su faire seul | `validées sans indice payé / validées` |
| **compréhension** | ce que j'ai compris | `validées avec QCM réussis / validées` |

Le dénominateur de la progression est **le jeu entier**, jamais le nombre de
quêtes faites : un élève à 5/28 est à 18 %, pas à 100 %.

Le niveau exige **deux seuils** — autonomie *et* avancement. Sans le second, un
élève qui réussit sa première quête sans indice (autonomie 100 %) verrait
« Atterrissage » s'afficher à 4 % du jeu. Cinq paliers :

| Palier | autonomie | avancement |
|---|---|---|
| Éveillé | 0 | 0 |
| Moteur en marche | 10 % | 5 % |
| Aux commandes | 50 % | 25 % |
| Vol stable | 75 % | 50 % |
| Atterrissage | 90 % | 80 % |

Aucun de ces chiffres n'est comparable à celui d'un camarade. C'est le cœur du
choix : la seule comparaison possible est avec soi-même, d'un atelier à l'autre.

### Pourquoi plus de score

Parce que la question « qui a été le plus rapide ? » porte sur la promotion, pas
sur l'élève. Le premier d'une classe lente apprend exactement autant que le
vingtième d'une classe rapide, et l'affichage affirmait le contraire. La course
servait à remotiver, mais elle mesurait l'inégalité de départ au lieu de la
progression.

Ce qu'on y perd : le classement en direct, qui était l'effet le plus
spectaculaire. Ce qu'on y gagne : une vue qui répond à la seule question utile
pendant une séance — *qui est bloqué, et où*.

### Les indices coûtent de l'autonomie

Chaque mission a jusqu'à **trois** indices, du plus flou au plus direct. Les
deux premiers **coûtent de l'autonomie**, le dernier est **toujours gratuit** :
un élève bloqué n'a jamais le droit de rester coincé, et le professeur doit
rester disponible en toutes circonstances.

Le prix est réel et il est mesuré : l'autonomie est la part de quêtes réussies
**sans indice payé**. Prendre de l'aide, c'est savoir moins faire seul — et le
jeu le note.

Le contenu des indices **ne sort pas** par `GET /api/quests`. La réponse ne
porte que `hint_count`, un nombre. Un élève ouvre l'onglet réseau, il voit trois
boutons, et il ne peut pas lire un indice sans le prendre — le prendre l'engage.
Les indices vivent dans `pack.hintsByQuest`, **hors** des objets sérialisés, ce
qui rend la fuite impossible par un oubli.

### La compréhension est vérifiée

Après la validation d'une mission, deux à trois **questions de compréhension**
portent sur ce qui vient d'être fait. Elles ne sont pas notées, mais elles
comptent dans la mesure de compréhension, et **un QCM manqué n'empêche rien** :
la mission est validée, la question est rattrapable.

L'idée est simple : quelqu'un qui a recopié une commande sait la taper, et ne
sait pas ce qu'elle fait. La question de compréhension est le seul endroit du jeu
où l'on peut le voir.

Une question de compréhension **n'emporte jamais le fil rouge**. Elle porte sur
le mécanisme Docker — parce qu'un élève qui répond « parce qu'on doit garder
Beluga en vie » n'a rien appris, et n'a rien à apprendre.

---

## Prérequis côté étudiant

- Une **VM Ubuntu Server** vierge, ou un accès à un serveur Ubuntu 24.04.
- Un compte **avec les droits `sudo`** : l'installation de l'outillage se fait
  au niveau système.
- ~30 Go d'espace disque sur `/`.
- **Un terminal.** Tout le jeu se tape dedans. Le portail ne sert qu'à valider.
- Le portail doit être **joignable** depuis la VM de l'élève — c'est la
  seule condition pour que la récupération des mots de passe fonctionne.

> Le réseau du TP est coupé d'Internet en salle. Le jeu fonctionne : toutes les
> images utilisées sont soit présentes en local, soit récupérées une fois pour
> toutes avant la séance. Le portail, lui, doit rester joignable en `https`.

---

## Guide de l'enseignant

### Ce que voit l'étudiant

Un bandeau en haut avec son pseudo, son mode, son niveau, son autonomie et sa
progression. À gauche, le carnet de bord puis le programme des 28 missions. Au
centre, la mission ouverte, avec son énoncé, ses indices, ses questions de
compréhension et le champ de soumission du mot de passe.

Le portail **ne se connecte jamais** au Docker de l'élève. Il ne peut donc pas
lui dire « ton conteneur n'est pas démarré » : il constate qu'un mot de passe
est correct ou ne l'est pas. Le diagnostic reste dans le terminal de l'élève,
qui est le seul endroit où il peut être juste.

### Valider une mission

1. L'élève lit l'énoncé dans le portail.
2. Il fait le travail **dans son terminal**.
3. Il récupère le mot de passe par la commande donnée dans l'énoncé.
4. Il le colle dans le champ du portail.
5. Le portail valide, affiche la correction, et pose les questions de
   compréhension.

Si le mot de passe est refusé, l'élève a deux erreurs possibles : le travail
n'est pas fait, ou le mot de passe est mal recopié. Le portail ne peut pas
trancher — **demandez-lui de vérifier sa commande**.

### Avant le TP

```bash
# Sur la VM d'un élève, une fois pour toutes :
docker pull nginx:alpine
docker pull alpine
docker pull busybox
```

C'est le seul endroit où Internet est nécessaire. Une fois ces trois images là,
toute la séance se passe hors ligne.

### Deux pièges connus

- **Le mot de passe ne s'affiche jamais dans l'énoncé.** Si un élève ne le
  trouve pas, c'est qu'il n'a pas fait le travail. La commande de récupération
  est dans l'énoncé, en bas.
- **Une commande qui rapporte un `502` sort en `0`.** Elle a bien tourné. Un
  élève qui « n'a pas la bonne réponse » a peut-être un portail qui redémarre.

### Pendant le TP

L'écran de l'enseignant est sur `/admin`, derrière le mot de passe. Il montre
la classe en direct : pseudos, mode, progression, autonomie, adresses IP des
postes, et un journal des événements.

Les quatre actions par joueur : **remettre à zéro**, **changer de mode**,
**supprimer**, **attester**. Toutes demandent confirmation.

Changer de mode **efface le parcours** du joueur : une quête validée en
Turbulence l'a été sous une règle d'autonomie différente, la conserver n'aurait
pas de sens.

### Après le TP

```bash
# Statistiques : où la classe bloque
curl -H "X-Arena-Admin: $MDP" https://operation-beluga.laurans.org/api/stats

# Remettre un joueur à zéro (oubli de jeton, réinscription).
# La confirmation est obligatoire : sans elle le serveur refuse.
curl -X POST -H "X-Arena-Admin: $MDP" -H "Content-Type: application/json" \
  -d '{"confirm":"oui"}' \
  https://operation-beluga.laurans.org/api/admin/reset/MonPseudo

# Supprimer une inscription
curl -X POST -H "X-Arena-Admin: $MDP" \
  https://operation-beluga.laurans.org/api/admin/delete/MonPseudo
```

`$MDP` : `export BELUGA_ADMIN_KEY=$(grep BELUGA_ADMIN_KEY /app/operation-beluga/.env | cut -d= -f2-)`

---

## Attestation : vérifier au lieu de croire

Par défaut, un mot de passe correct valide la mission. Si vous voulez
**vérifier** que le travail a réellement été fait — pour une note, une
évaluation sommative, un public qui triche :

```bash
# dans .env
ARENA_ATTESTATION=1
```

Alors un mot de passe correct laisse la mission **en attente**, et c'est
l'enseignant qui valide dans le tableau de bord. Le portail n'est plus
autonome : il faut être là.

C'est le seul mode où le portail peut réellement juger de la compétence. Tout
le reste est déclaré.

---

## Sécurité — à lire avant d'ouvrir le portail

Trois règles, et aucune n'est facultative.

1. **L'administration est fermée par un mot de passe.** Sans `BELUGA_ADMIN_KEY`,
   le serveur **refuse de démarrer**. Il n'y a pas de mode « lab ouvert » : sur
   une URL publique, une clé vide donnait à quiconque trouve l'adresse la liste
   de la classe et un bouton pour supprimer des inscriptions.

2. **Le mot de passe d'administration n'est jamais stocké.** Il sert à vérifier
   une signature HMAC-SHA256 et à comparer — sur deux **hachés à préfixe
   fixe**, jamais sur les chaînes, pour ne pas laisser de fenêtre de timing.
   La session dure 8 h, le temps d'une journée de cours, dans un cookie
   `HttpOnly; SameSite=Strict`.

3. **Le sel de dérivation est propre à ce portail.** `ARENA_SALT` vaut
   `operation-beluga-v1` par défaut. Sans sel, deux joueurs distincts
   déduiraient le même secret à partir de quêtes identiques. Changer le sel
   **invalide les mots de passe déjà distribués** : à faire après une
   réinitialisation, jamais pendant une séance.

Et pour le mot de passe de l'élève, une seule règle : **il n'est dans aucun
énoncé**. Il est dérivé du jeton du joueur, et chaque mission fournit la
commande qui va le chercher. C'est ce qui distingue le travail réellement fait
d'un copier-coller — et c'est vérifié par le validateur de contenu, qui fait
échouer le serveur au démarrage si un énoncé contient son propre flag.

---

## Vérifications automatiques

```bash
npm test                      # 215 tests — 10 s
npm run check-content         # le contenu est chargeable
npm run smoke                 # joue les 28 quêtes (demande un portail)
npm run check-fetchhints      # REJOUE chaque commande de récupération — demande Docker
npm run nettoie-verif         # purge les joueurs de vérification
```

La CI (`.github/workflows/verifications.yml`) tourne sur chaque push et chaque
PR : les tests, la validation du contenu, la construction de l'image, et le
démarrage d'un conteneur qui doit servir le programme.

Un second job, sur `main` seulement, **rejoue les commandes de récupération
contre la production**. C'est le seul contrôle qui prouve que le jeu marche sur
une vraie machine : les tests unitaires ne lancent pas Docker. Il a attrapé un
bug qu'aucun test ne pouvait voir. Il inscrit un joueur et le supprime en
sortant ; `nettoie-verif` est le filet pour une exécution interrompue. Il lui
faut le secret `BELUGA_ADMIN_KEY` sur le dépôt.

---

## Développement

```bash
npm install          # une seule dépendance de production : express
npm test
npm start            # http://localhost:8000
```

`npm start` sans `ADMIN_KEY` **refuse de démarrer**. En local :

```bash
ADMIN_KEY=mdp npm start
```

Conteneur de recette, avec publication de port :

```bash
docker build -t operation-beluga:test .
docker run -d --name recette -p 127.0.0.1:8094:8000 \
  -e ADMIN_KEY=mdp -e RATE_LIMIT=off -e QUIET=1 operation-beluga:test
```

`RATE_LIMIT=off` : sinon les tests automatisés, qui enchaînent les appels
depuis une seule adresse, se heurtent aux plafonds.

### Ajouter une mission

1. Éditer `content/quests/m<N>.js`.
2. `node scripts/check-content.js && npm test`.
3. Vérifier au navigateur : `node outils/navigateur/verifie-jeu.mjs <url>`.

Le `brief` passe par `public/md.js`, dont le sous-ensemble supporté est
**strict**. Une syntaxe non rendue disparaît **silencieusement** — c'est le
défaut de rendu le plus facile à manquer.

### Structure

```
content/quests/m*.js    les 28 quêtes — données pures, aucune logique
src/
  server.js             createApp() + start()
  config.js             configuration, MODES, MODE_LABELS
  db.js                 node:sqlite + migrations
  questpack.js          chargement + VALIDATION du contenu (échec au démarrage)
  mastery.js            les trois ratios, les cinq paliers
  progress.js           validation d'une quête
  portal.js             état de la classe + flux SSE
  routes/api.js         le parcours de l'élève
  routes/atelier.js     indice, compréhension, réflexe
  routes/admin.js       tout ce qui est fermé + la vue de classe
public/
  index.html + app.js   l'écran des élèves, servi sur `/`
  admin.html + admin.js l'écran de l'enseignant, servi sur `/admin`
  md.js                 mini-renderer Markdown
  style.css             une feuille pour les deux écrans
test/                   215 tests
docs/
  CONTRACTS.md          source de vérité : schéma de quête + contrat d'API
  REPRISE.md            tout ce qu'il faut savoir pour reprendre le projet
  CHANGELOG.md          ce qui change à chaque version
outils/
  navigateur/           recette dans un vrai Chromium (CDP)
  intro-modules.py      réécrit le bloc `meta` des sept ateliers
```

### Choix techniques

- **Node ≥ 22.5, Express 4, `node:sqlite`.** Le module natif de Node, pas
  `better-sqlite3` : celui-ci demande une compilation native dans l'image, et on
  veut que `docker build` n'ait besoin que de Docker et de npm.
- **Front vanilla.** Zéro dépendance, zéro CDN, zéro framework, zéro webfont.
  Le jeu doit fonctionner sur un réseau de TP coupé d'Internet.
- **Markdown rendu par construction DOM.** Le contenu pédagogique n'est jamais
  interprété comme du HTML.
- **Échec au démarrage plutôt qu'incohérence en cours de TP.** Le contenu est
  chargé en `await` au chargement ; une faute de frappe dans un flag empêche le
  serveur de démarrer, avec un message qui nomme le fichier.
- **Le vocabulaire `arena` est conservé** — `X-Arena-Token`, `routes/atelier.js`,
  `ARENA_*`, `repo/arena.js`. C'est un contrat d'API ; le renommer coûterait un
  diff de plusieurs centaines de lignes pour aucun gain. Le nettoyage a déjà été
  tenté une fois, et le diff a été annulé.

---

## Documents

| document | ce qu'il contient |
|---|---|
| [`docs/CONTRACTS.md`](docs/CONTRACTS.md) | la source de vérité : schéma d'une quête, contrat d'API, mesure de la maîtrise |
| [`docs/REPRISE.md`](docs/REPRISE.md) | tout ce qu'il faut savoir pour reprendre le projet **sans aucun autre contexte** |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | ce qui change à chaque version |
| [`docs/RELEASE-v0.1.0.md`](docs/RELEASE-v0.1.0.md) | ce que la v0.1.0 a décidé et où elle s'arrête |

---

## Licence

MIT. Voir [`LICENSE`](LICENSE).

Successeur d'`Atelier Docker` (MIT), lui-même successeur de
[Docker Ops Race](https://github.com/blaurans/seriousdocker) (`v1.0.0`, gelé et
maintenu).
