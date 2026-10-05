# Reprendre ce projet

Ce document est écrit pour une IA (ou un humain) qui reprend le projet **sans
aucun autre contexte** : ni historique de conversation, ni familiarité avec le
domaine, ni mémoire des décisions prises. Tout ce qu'il faut savoir est ici ou
dans le code.

L'ordre de lecture utile :

1. **ce document**, pour savoir quoi lire ensuite ;
2. `README.md`, le mode d'emploi complet ;
3. `docs/CONTRACTS.md`, la source de vérité du schéma de quêtes et de l'API ;
4. `docs/CHANGELOG.md`, ce qui a changé et ce qu'il reste à faire ;
5. `docs/RELEASE-v0.1.0.md`, ce que la version courante a décidé.

**Si tu n'as lu qu'une chose, lis le § 2.** Ce projet n'est pas terminé, et la
liste de ce qui reste est courte.

---

## 1. Ce qu'est le produit, en une page

**Opération Beluga** est un serious game d'apprentissage de Docker, destiné à
des étudiants qui n'ont jamais tapé une commande Docker.

**Le cadre** : un vol Beluga au-dessus de l'océan, dégradé par une turbulence.
Le capitaine a coupé le pilote automatique, **Beluga** — le copilote — ne
répond plus. Vous êtes l'ingénieur de bord, et **le serveur de bord est la
machine de l'élève**. Le patient est le copilote ; l'outillage est Docker.

**Le contexte pédagogique** (à respecter dans toute évolution) :

- Chaque élève a **sa propre VM Ubuntu Server vierge**. Il travaille **seul**.
  L'enseignant débloque en personne, il n'y a pas d'assistant numérique.
- Le portail ne fait que **valider**. Il ne se connecte jamais au Docker des
  élèves et n'exécute aucune commande à leur place. Tout se tape dans le
  terminal de l'élève, sur sa VM.
- **7 ateliers de cours**, un atelier = un bloc de cours. Cible 60 min, borne
  dure 90. Le huitième est la manœuvre finale : une seule quête, qui n'a pas à
  tenir une heure.
- **28 quêtes**, ~7 h de contenu indicatif.

**La conséquence de rédaction qui compte** : le fil rouge **n'emporte jamais une
question de compréhension**. Un élève qui répond « parce qu'il faut garder Beluga
en vie » n'a rien appris du Docker, et le jeu ne doit pas lui faire croire le
contraire. Le récit est dans les `brief` et dans `meta.story`, nulle part dans
les QCM.

**Les deux modes**, choisis à l'inscription :

- `competitive` → affiché **« Turbulence »** : les deux premiers indices
  coûtent de l'autonomie.
- `normal` → affiché **« Calme »** : tous les indices sont gratuits.

Les deux modes sont **identiques** — mêmes quêtes, mêmes questions, mêmes
indices. La seule différence est le prix de l'aide. Les valeurs d'API sont un
contrat ; les libellés sont ce que l'élève lit (`MODE_LABELS`,
`src/config.js`).

**Pas de score, pas de classement, pas de podium.** Trois mesures qui ne se
comparent qu'à soi-même : progression, autonomie, compréhension. Voir § 5.

**Origine** : ce dépôt est le successeur de `blaurans/atelierdocker` (« Atelier
Docker », gelé sur `v1.0.0` et toujours en production), lui-même successeur de
`blaurans/seriousdocker` (« Docker Ops Race », gelé sur `v1.0.0`). Une partie
du vocabulaire `arena` a survécu aux deux changements de nom — voir § 9.

---

## 2. **Ce qu'il reste à faire** — à lire en premier

Le projet est **jouable mais pas terminé**. Ne le présente pas comme fini.

| # | quoi | où | coût |
|---|---|---|---|
| 1 | **Une sauvegarde** du volume | hors dépôt | petit, à faire avant un vrai cours |
| 2 | Nettoyer le CSS mort, `inject-fetchhint.js` | `public/style.css`, `scripts/` | cosmétique |

**Le jeu est complet** : 8 ateliers, 28 quêtes, cohérents de bout en bout. Il
reste la sauvegarde, qui n'est pas une question de contenu.

**Le jeu est complet.** Les huit ateliers racontent le vol : leurs intros, leurs
énoncés, leurs questions et leurs flags ont été basculés de l'ancienne intrigue
vers celle-ci par `outils/passe-becane.py`.

**L'atelier 8 est la manœuvre finale** : une seule quête, qui assemble tout ce
que les ateliers 4 à 7 ont construit et l'exige **prouvé**. Elle porte 800
points — m7 finit à 700, et un module doit croître — et comme elle est seule
dans son module, elle est forcément sa quête phare. C'est aussi pour cela que la
borne des points est passée de 600 à 800 : à 600, l'atelier 8 était **impossible
à écrire**. Voir § 8.

### Comment réécrire un atelier

1. `python3 outils/intro-modules.py` — si l'intro du module manque ou est encore
   sur l'ancienne intrigue, le script s'en charge (table unique en tête de
   fichier).
2. Réécrire les `brief`, en gardant **la commande de récupération du mot de
   passe** : chaque module a une technique, et elle est alignée sur ce qu'il
   enseigne. Voir la table dans `README.md` § « Comment la validation
   fonctionne ».
3. `node scripts/check-content.js && npm test` — le validateur juge la forme, les
   tests jugent le contrat.
4. `node outils/navigateur/verifie-jeu.mjs <url> <équipe> 1,5,9,13,17,21,25,27` —
   et **regarder les captures**. Voir § 10.

---

## 3. Déploiement en production

| | |
|---|---|
| URL publique | `https://operation-beluga.laurans.org` |
| Machine | `ssh ociuc` — aarch64 (Ampere A1), Ubuntu 24.04.5 |
| Dépôt du serveur | `/app/operation-beluga` (clone du dépôt GitHub) |
| Caddy | conteneur `caddy`, Caddyfile monté depuis `/app/headscale/Caddyfile` |
| Réseau Docker | `headscale_default` (externe, partagé avec Caddy) |
| Volume de données | `operation-beluga-data` |
| Bloc Caddy | `reverse_proxy operation-beluga:8000` |
| Disque | 121 Go, **86 % utilisés** — surveiller |

### Déployer

```bash
ssh ociuc
cd /app/operation-beluga
git fetch && git reset --hard origin/main
docker compose up -d --build
```

Puis vérifier :

```bash
curl -sS https://operation-beluga.laurans.org/healthz
docker ps --filter name=operation-beluga --format '{{.Status}}'
```

### Les deux portails cohabitent

`Atelier Docker` **reste en production** sur `atelierdocker.laurans.org`. Les
deux tournent en parallèle sur la même machine, derrière le même Caddy, sur le
même réseau Docker. Il n'y a **rien de partagé** :

| | Atelier Docker | Opération Beluga |
|---|---|---|
| domaine | `atelierdocker.laurans.org` | `operation-beluga.laurans.org` |
| service compose | `atelier` | `beluga` |
| conteneur | `atelier-docker` | `operation-beluga` |
| volume | `atelier-docker-data` | `operation-beluga-data` |
| base | `atelier.sqlite` | `beluga.sqlite` |
| clé d'administration | `ATELIER_ADMIN_KEY` | `BELUGA_ADMIN_KEY` |
| sel de dérivation | `atelier-docker-v2` | `operation-beluga-v1` |
| image | `atelier-docker:1.0` | `operation-beluga:0.1` |

**Une seule de ces valeurs partagés est un incident.** Deux pièges concrets :

- Le **bloc Caddy** du nouveau portail doit dire `operation-beluga:8000`. Un
  `reverse_proxy atelier-docker:8000` qui traîne ne se voit pas : le portail
  répond, avec le contenu de l'autre jeu.
- `check-fetchhints.js` et `nettoie-verif.js` ont une **URL par défaut**. Lancer
  `npm run check-fetchhints` sans argument teste le portail d'`Atelier Docker` et
  valide donc l'autre jeu. La CI passe l'URL en argument (`$PORTAIL`) ;
  en local, passe-la aussi.

### Le mot de passe d'administration

```bash
ssh ociuc 'grep BELUGA_ADMIN_KEY /app/operation-beluga/.env'
```

Obligatoire : le serveur refuse de démarrer sans (`src/server.js`,
`verifierAdmin()`). `docker-compose.yml` échoue aussi, sur
`${BELUGA_ADMIN_KEY:?…}`.

Le secret GitHub **`BELUGA_ADMIN_KEY`** est configuré sur ce dépôt. C'est ce que
`Atelier Docker` n'a jamais eu, et ce qui y laissait un joueur `Verif_*` à
chaque exécution de la CI : sans clé, `nettoie-verif` sort en 0 en disant
qu'il n'a rien à nettoyer.

### La fenêtre de 502

Le déploiement coupe le service pendant ~10 s. Caddy renvoie alors `502 Bad
Gateway` à toute requête — y compris aux commandes de récupération de mot de
passe des élèves. **C'est la cause la plus fréquente d'échec du job
`commandes`**, et elle n'a rien à voir avec le contenu. Voir § 13.

---

## 4. Lancer en local

```bash
npm install          # une seule dépendance : express (+ linkedom en dev)
npm test             # 217 tests
npm start            # http://localhost:8000
```

`npm start` sans `ADMIN_KEY` **refuse de démarrer**. En local :

```bash
ADMIN_KEY=mdp npm start
```

Si le portail est derrière un proxy (Caddy en production, `TRUST_PROXY=1`),
sinon non. Un `TRUST_PROXY` activé sans proxy fait reconstruire les commandes
de récupération en `https://` vers le port 443, où rien n'écoute.

Conteneur de recette, avec publication de port :

```bash
docker build -t operation-beluga:test .
docker run -d --name beluga-recette -p 127.0.0.1:8095:8000 \
  -e ADMIN_KEY=mdp -e RATE_LIMIT=off -e QUIET=1 operation-beluga:test
```

`RATE_LIMIT=off` : sinon les tests automatisés, qui enchaînent les appels depuis
une seule adresse, se heurtent aux plafonds. `QUIET=1` coupe les logs.

> **Le port 8095, pas 8094.** Le conteneur de recette d'`Atelier Docker` tourne
> peut-être encore en local sur 8094. Le réutiliser fait tester l'autre jeu.

---

## 5. Architecture

### Pile

- **Runtime** : Node ≥ 22.5 (l'image est `node:24-alpine`), ESM partout
  (`"type": "module"`).
- **Serveur** : Express 4. L'unique dépendance de production.
- **Base** : `node:sqlite`, le module **natif** de Node. Pas `better-sqlite3`,
  écarté parce qu'il demande une compilation native (`python3`, `make`, `g++`)
  dans l'image. Conséquence : le code tourne sur Node 22 à 26, et `docker build`
  n'a besoin que de Docker et de npm.
- **Front** : vanilla. Zéro dépendance, zéro CDN, zéro framework, zéro webfont.
  Le jeu doit fonctionner sur un réseau de TP coupé d'Internet.
- **Markdown** : mini-renderer maison (`public/md.js`), rendu par construction
  DOM. Le contenu pédagogique n'est **jamais** interprété comme du HTML.

### Carte des fichiers

```
content/quests/m*.js    les quêtes — données pures, aucune logique
src/
  server.js             createApp() + start() ; montage des routes, statique, erreurs
  config.js             configuration d'environnement, MODES, MODE_LABELS
  db.js                 node:sqlite + migrations « j'ajoute une colonne »
  schema.sql            tables, lues au démarrage
  questpack.js          chargement + VALIDATION du contenu (échec au démarrage)
  mastery.js            les trois ratios, les cinq paliers, la synthèse de cohorte
  progress.js           validation d'une quête : écrit des faits, jamais des cumuls
  portal.js             état de la classe + flux SSE (derrière le mot de passe)
  admin_session.js      mot de passe → jeton HMAC → cookie HttpOnly
  auth.js               HttpError, identification du joueur, requirePlayer
  secret.js             dérivation du mot de passe d'une quête (HMAC)
  ratelimit.js          plafonds par IP, clientIp(), lecture de X-Forwarded-For
  events.js             bus d'événements interne (SSE)
  routes/api.js         le parcours de l'élève
  routes/atelier.js     indice, compréhension, réflexe
  routes/admin.js       tout ce qui est fermé + la vue de classe
  repo/arena.js         accès SQLite : joueurs, validations, journal
  repo/progress_repo.js indices consommés, tentatives de compréhension
public/
  index.html + app.js   l'écran des élèves, servi sur `/`
  admin.html + admin.js l'écran de l'enseignant, servi sur `/admin`
  md.js                 mini-renderer Markdown
  style.css             une feuille pour les deux écrans
outils/
  navigateur/           recette dans un vrai Chromium (CDP) — § 10
  intro-modules.py      réécrit le bloc `meta` des huit ateliers
  passe-becane.py       bascule le vocabulaire d'une intrigue vers l'autre
  test-passe-becane.py  vérifie que le script ne corrompt rien
test/                   217 tests
docs/
  CONTRACTS.md          source de vérité : schéma de quête + contrat d'API
  REPRISE.md            ce document
  CHANGELOG.md          ce qui change à chaque version
  RELEASE-v0.1.0.md     notes de version
scripts/
  check-content.js      le contenu est-il chargeable ?
  # (les deux outils de renommage sont dans `outils/`, avec le contenu :
  #  ils agissent sur `content/quests/`, pas sur le serveur)
  check-fetchhints.js   REJOUE les commandes de récupération — demande Docker
  nettoie-verif.js      purge les joueurs de vérification
  smoke.js              joue toutes les quêtes, affiche la maîtrise
  seed.js               réinitialise la base
  inject-fetchhint.js   migration de contenu (utilisé une fois, conservé)
```

### L'ordre de montage, dans `server.js`

```js
app.get('/healthz', …)
app.use('/api', admin);      // AVANT api
app.use('/api', atelier);
app.use('/api', api);
app.get('/admin', …)         // servie sans mot de passe : c'est le formulaire
app.use(express.static(publicDir))
app.use(GET inconnu → index.html)
```

`admin` **avant** `api` : `/api/overview` et `/api/stats` vivent dans `admin`
et doivent rester derrière le mot de passe. Montées dans l'autre ordre, `api`
les redéfinirait et personne ne le verrait.

> `src/routes/admin.js` importe `modeLabel` depuis `./api.js`. C'est le seul
> import **entre** les deux fichiers de routes, et il est sans cycle : `api.js`
> n'importe rien de `admin.js`. Ne le déplace pas dans `admin.js` sans vérifier
> que le cycle ne se forme pas — `server.js` monte `admin` avant `api`, et
> c'est cette ordre qui protège les routes fermées.

---

## 6. Le modèle de mesure

C'est le cœur du produit. Le remplacer par un score serait une régression.

### Trois ratios, sur un seul élève

| ratio | formule | source |
|---|---|---|
| progression | validées / `totalQuests` | `src/mastery.js` |
| autonomie | validées **sans indice payé** / validées | idem |
| compréhension | validées avec QCM réussis / validées | idem |

Le dénominateur de la progression est **le jeu entier**, jamais le nombre de
quêtes faites. Un élève à 5/27 est à 19 %, pas à 100 %.

### Cinq paliers, deux seuils chacun

```js
LEVELS = [
  { key: 'debout',      name: 'Éveillé',           min: 0,    minProgress: 0    },
  { key: 'ranim',       name: 'Moteur en marche',  min: 0.10, minProgress: 0.05 },
  { key: 'autonome',    name: 'Aux commandes',     min: 0.50, minProgress: 0.25 },
  { key: 'travailleur',  name: 'Vol stable',        min: 0.75, minProgress: 0.50 },
  { key: 'maitre',      name: 'Atterrissage',      min: 0.90, minProgress: 0.80 },
];
```

**Les deux seuils sont obligatoires.** Sans `minProgress`, un élève qui réussit
sa première quête sans indice a 100 % d'autonomie et verrait « Atterrissage »
s'afficher à 4 % du jeu.

**Les noms sont aéronautiques** et les seuils ne sont pas ceux du thème : un
palier n'est pas un pourcentage de vol, c'est une étape atteinte. Le
renommage des libellés est vérifié par `test/contract.test.js`.

### Les deux compteurs d'indices

| champ | ce que c'est | qui l'utilise |
|---|---|---|
| `hints_used` | indices **demandés** | l'enseignant, pour voir où ça coince |
| `hints_charged` | indices **payés** | **l'autonomie, et rien d'autre** |

En mode Calme, `charged` est 0 (annulation côté serveur) alors que `hints_used`
compte. Compter la consommation aurait annulé le prix sans annuler la
conséquence : l'élève verrait sa maîtrise chuter sans avoir rien payé.

`src/mastery.js` retombe sur `hints_used` quand `hints_charged` est absent —
pour les lignes antérieures. `src/progress.js` écrit les deux.

### Le carnet de bord n'en est pas un

Le carnet de bord de l'écran des élèves est **du décor narratif**. Il ne mesure
rien et n'entre dans aucun ratio : il affiche, module par module, un fait que le
serveur connaît déjà — « toutes les quêtes de cet atelier sont validées ».

Il se dérive de `state.pack.modules`, donc **aucune requête supplémentaire** et
rien à invalider côté serveur. S'il entrait dans la maîtrise, le décompte
« 7 systèmes sur 7 » aurait le poids d'une note, et il n'en est pas une.

---

## 7. Le contrat d'API

Le détail est dans `docs/CONTRACTS.md`. L'essentiel :

### Routes de l'élève — ouvertes

| route | rôle |
|---|---|
| `POST /api/register` | inscription ; `201` créé, `200` existe, `409` secret faux, `400` invalide |
| `GET /api/quests` | le programme — **sans** les indices, **sans** les réponses |
| `GET /api/me` | maîtrise et historique du joueur |
| `POST /api/submit` | soumission d'un mot de passe |
| `GET /api/secret/:questId` | le mot de passe, en JSON |
| `GET /api/secret/:questId/raw` | le mot de passe, en texte brut (pour `wget`) |
| `GET /api/commands` | mémento des commandes |
| `POST /api/quests/:id/hint` | rend **un** indice, l'enregistre, renvoie ce qu'il a coûté |
| `POST /api/quests/:id/check` | vérifie une réponse de compréhension |
| `POST /api/quests/:id/recall` | vérifie le réflexe ; renvoie l'aide si faux |
| `GET /api/quests/:id/attempts` | ce que l'élève a déjà répondu |

### Routes d'enseignant — fermées

`/api/overview`, `/api/live`, `/api/stats`, `/api/admin/*` (session, reset,
delete, mode, attest, pending, seed, qui). Toutes derrière `requireAdmin`.

**`GET /admin` est publique** : la page *est* le formulaire. Ce qui est protégé,
c'est ce qu'elle affiche.

### `meta.story` sort par `/api/quests`

`GET /api/quests` renvoie `modules[].story`. Elle passe par `jouable()`, comme
`brief` et `fetchHint` : les trois substitutions (`SERVER_IP`, `dq_…`,
`$ARENA_TOKEN`) s'appliquent. Une substitution limitée à `fetchHint` a produit un
`401` sur la commande de l'énoncé — un élève copiait une commande morte, juste au
dessus de la bonne. Le point est acquis ; ne le reintroduis pas.

`modules[].quests[].order` sort aussi. Le client en a besoin pour savoir s'il
ouvre la **première** quête d'un atelier, donc s'il doit afficher l'intro.
`number` ne le dit pas : la quête 5 peut être la première de l'atelier 2.

### Deux règles d'API à ne jamais casser

1. **Ce qui est montré au client a été demandé au serveur.** Les indices vivent
   dans `pack.hintsByQuest`, **hors** du graphe d'objets que sérialise
   `/api/quests`. La fuite est impossible par oubli : il faudrait un accès
   explicite à cette table. `check[].answer`, `check[].explanation`,
   `recall[].accept`, `recall[].hint` et `hints` ne sortent jamais (les
   explications et aides, seulement après une bonne / mauvaise réponse).

2. **Le mot de passe n'apparaît dans aucun énoncé.** Il est dérivé par HMAC du
   jeton du joueur (`src/secret.js`), donc unique par couple joueur × quête.
   Chaque mission fournit la commande qui va le chercher, et cette commande
   utilise la technique que le module enseigne.

### Substitution des commandes

`jouable()` dans `src/routes/api.js` remplace, **partout** :

- `https://SERVER_IP` / `http://SERVER_IP` → l'origine vue par l'élève ;
- `dq_xxxxxxxxxxxxxxxx` et `$ARENA_TOKEN` → le jeton du joueur.

### Authentification

- **Joueur** : `X-Arena-Token`, `Authorization: Bearer`, `?token=`, `?t=`, ou
  `{team, secret}` dans le corps.
- **Administration** : cookie `dq_admin` signé HMAC-SHA256 (`HttpOnly`,
  `SameSite=Strict`, `Secure` si HTTPS), ou `X-Arena-Admin` qui accepte **le mot
  de passe en clair** pour `curl` et les scripts.

---

## 8. Le contenu

Écrire une quête impose de respecter `docs/CONTRACTS.md` § 1. Le validateur
(`src/questpack.js`) **fait échouer le serveur au démarrage** si quelque chose
manque, et nomme le fichier et la quête. C'est délibéré : un contenu invalide
découvert par un élève devant trente collègues est pire qu'un portail qui ne
démarre pas le matin.

| # | système d'avion | atelier | slug | quêtes |
|---|---|---|---|---|
| 1 | 🩺 Évaluation | Évaluer le patient | `m1-evaluer-le-patient` | 4 |
| 2 | 📦 Approvisionnement | Ramener les pièces | `m2-ramener-les-pieces` | 4 |
| 3 | ⚙️ Mise en service | Régler en service | `m3-regler-en-service` | 4 |
| 4 | 🌐 Liaisons de bord | Brancher les systèmes | `m4-brancher-les-systemes` | 4 |
| 5 | 📄 Certification | Certifier les pièces | `m5-certifier-les-pieces` | 4 |
| 6 | 💾 Sauvegarde | Sauvegarder les données | `m6-sauvegarder-les-donnees` | 4 |
| 7 | 📚 Carte de bord | Documenter la carte | `m7-documenter-la-carte` | 3 |
| 8 | 🛬 Atterrissage | L'atterrissage | `m8-atterrissage` | 1 |

Le module 8 est le seul à n'avoir qu'une quête : c'est un module d'un seul
tenant, on ne manœuvre pas d'atterrissage par morceaux. Il porte 800 points,
et la borne des points du validateur a été remontée à 800 pour cette raison —
voir § 8.

**Les ateliers 1 à 7 racontent le vol de bout en bout.** Le renommage a été
fait par `outils/passe-becane.py`, un script, et non à la main — les noms
revenaient des dizaines de fois par fichier, et une réécriture manuelle laisse
toujours un oubli. Le script applique des motifs, il ne réécrit pas de prose.

`python3 outils/passe-becane.py --verifier` compte ce qui reste à faire et signale
toute ligne qui porte encore l'ancienne intrigue. **Le test qui l'interdit est
`test/content.test.js`** — il porte sur les énoncés, les titres, les flags, les
questions et les réflexes, ce qu'un script ne peut pas garantir.

Deux pièges que le renommage a produits, et qui sont instructifs :

- **Un motif suit le nom, pas l'intention.** `grep -i verdi` est devenu
  `grep -i cabine` — mais la page affiche « Restauration Beluga », et la
  commande ne trouvait plus rien. Six énoncés promettaient un résultat que la
  commande ne pouvait pas produire.
- **Le genre change avec le nom.** « librairie » est féminin, « service » est
  masculin. « Le service n'est pas **seule** » s'est glissé dans trois phrases
  sans qu'aucun test ne le voie : la faute est dans la prose, pas dans la
  structure.

Chaque fichier `content/quests/m<N>.js` exporte **un objet** `{ meta, quests }`
en ESM.

### `meta.story`

```js
meta: {
  slug, module, title, tagline, icon,
  story: `# Titre\n\nDeux à quatre paragraphes.`,
}
```

**Obligatoire**, au moins 200 caractères, **un seul** titre `# `, et le même
sous-ensemble Markdown que `brief` — les mêmes garde-fous s'appliquent
(`verifierProse` dans `src/questpack.js`).

Elle s'affiche au-dessus de la **première** quête du module, et seulement
celle-là. `paintQuest` ne dépend que de la quête ouverte, pas de l'historique
de navigation : rejouer l'intro à chaque visite la rendrait illisible, et ne la
montrer qu'à la première ouverture la ferait manquer à qui commence par une
quête du milieu. Le premier cas est le pire — c'est celui où le récit porte le
jeu.

**Le fil rouge n'emporte jamais un QCM.** Le validateur interdit à `story` de
demander une réponse écrite ; il n'interdit pas le récit dans les choix d'un
`check`, parce que c'est une règle de rédaction, pas de forme. C'est à toi de
l'appliquer.

### Les invariants qui comptent

- `flag` : `FLAG{MAJUSCULES_ET_TIRETS_BAS}`, unique dans tout le jeu, **jamais
  dans le `brief`**.
- `charge.autonomy` : autant d'entrées que `hints`, **et le dernier vaut 0** —
  un élève bloqué n'a jamais le droit de rester coincé.
- `check[].explanation` : obligatoire, ≥ 15 caractères, et **ne doit pas figurer
  mot pour mot dans le `brief`**.
- `recall.hint` : obligatoire, et ne contient **jamais** un mot de `accept`.
- `fetchHint` : ≥ 20 caractères, vise `/api/secret/<id>/raw`, et cible
  `SERVER_IP` ou `127.0.0.1` **avec** `--network host`.
- Le `brief` est un **sous-ensemble** de Markdown : `# ` (un seul), paragraphes,
  `- `, `1. `, blocs ```` ```bash ````, `**gras**`, `*italique*`, `` `code` ``,
  liens http(s). **Interdits** : tableaux, images, HTML, listes imbriquées,
  plusieurs titres `#`. Le validateur s'applique à la **prose** seulement, pas
  aux blocs de code.
- Chaque module : un multiple de 100 points, et **une seule** quête phare
  (points multiples de 100), qui doit être la dernière. La somme croît **strictement**
  d'un module à l'autre — le test le verrouille, parce que le validateur
  n'accepterait qu'une non-décroissance.

Le module 8 porte **800 points** : m7 finit à 700, et la somme doit croître.

### Le `brief` est la seule source pédagogique

Aucun `solution` dans le `brief`, aucun indice dedans, et pas de consigne
demandant une réponse écrite sans champ pour la saisir.

### Deux règles de rédaction que le validateur n'impose pas

**Aucune commande de récupération ne doit mettre sur un délai fixe.** Pas de
`sleep 3` entre un lancement et une lecture : c'est une hypothèse sur la vitesse
d'un réseau, alors qu'il suffit d'attendre la fin d'un processus. Les trois
quêtes de l'atelier 7 le faisaient, et la CI les a vues échouer ensemble pendant
que tout fonctionnait. Attends le processus : `docker compose up <service>`
retourne quand le service se termine, en attaché.

**Un diagnostic montre la cause, pas le ménage.** Docker Compose écrit son
erreur au moment où elle se produit, puis démonte ce qu'il a construit — sur
stderr aussi. Prendre les deux dernières lignes affiche le nom d'un réseau que
le script vient de créer et de supprimer.

### Pour ajouter une quête

1. Éditer `content/quests/m<N>.js`.
2. `node scripts/check-content.js && npm test`.
3. Vérifier au navigateur : `node outils/navigateur/verifie-jeu.mjs <url>`.

Le `brief` passe par `public/md.js`, dont le sous-ensemble supporté est strict.
Une syntaxe non rendue disparaît **silencieusement** : c'est le défaut de rendu
le plus facile à manquer.

---

## 9. Les vérifications

```bash
npm test                      # 217 tests — 10 s
npm run check-content         # le contenu est chargeable
npm run smoke                 # joue toutes les quêtes (demande un portail)
npm run check-fetchhints -- <url>   # REJOUE les commandes — demande Docker
npm run nettoie-verif -- <url>      # purge les joueurs de vérification
```

**Passe l'URL aux deux derniers**, et utilise le port **8095** pour un conteneur
de recette local. Voir § 3.

### La CI

`.github/workflows/verifications.yml`, sur chaque push et chaque PR :

| job | ce qu'il prouve |
|---|---|
| `tests` | les tests, le contenu validable, le script de renommage vérifié, l'image construite, un conteneur qui démarre et sert |
| `commandes` | les commandes de récupération contre le portail de production — **`main` seulement**, en continu |

Le job `commandes` inscrit un joueur en production et le supprime en sortant ;
`nettoie-verif` est le filet pour une exécution interrompue. Il lui faut le
secret GitHub **`BELUGA_ADMIN_KEY`**, configuré sur ce dépôt.

**Ce job échoue pour des raisons qui ne sont pas dans le code.** Voir § 13.

### Pourquoi le job `commandes` existe

C'est le seul contrôle qui prouve que le jeu marche sur une vraie machine : les
tests unitaires ne lancent pas Docker. Il a attrapé un bug qu'aucun test ne
pouvait voir.

---

## 10. Conventions

- **Échec au démarrage plutôt qu'incohérence en cours de TP.** Le contenu est
  chargé en `await` au chargement du module ; une faute de frappe dans un flag
  empêche le serveur de démarrer, avec un message qui nomme le fichier.
- **Une seule dépendance de production.** Toute complication doit être justifiée
  par un coût mesurable.
- **Nommage** : le vocabulaire `arena` a survécu aux changements de nom —
  `X-Arena-Token`, `X-Arena-Admin`, `repo/arena.js`, `ARENA_SALT`,
  `ARENA_LINEAR`, `ARENA_RATE_LIMIT`, `ARENA_ATTESTATION`, `secret.js`, et le
  nom de fichier `routes/atelier.js`. C'est un contrat d'API ; le renommer
  coûterait un diff de plusieurs centaines de lignes pour aucun gain. **Ne le «
  nettoie » pas** : c'est déjà arrivé une fois et le diff a été annulé.
- **Les libellés de mode sont dupliqués** dans `src/config.js`, `index.html`,
  `admin.html` et `admin.js`. Le doublon est toléré parce qu'un test le vérifie
  dans les deux sens — voir `test/contract.test.js`, « les libellés de mode sont
  les mêmes partout ». **Ne le « nettoie » pas** sans ajouter le test.
- **Les erreurs HTTP** : `HttpError` (statut + message écrit pour être lu) pour
  le volontaire, 500 générique pour le reste. Le handler décide sur
  `err instanceof HttpError`, **pas** sur le statut.
- **`points` est un vestige.** Plus rien ne le lit ; les invariants sont
  maintenus pour que le contenu se charge sans réécriture.
- **Les commentaires expliquent le pourquoi**, pas le quoi. C'est la convention
  dominante du dépôt.

---

## 11. La recette dans une vraie navigateur

`outils/navigateur/` — six scripts CDP, aucune dépendance. **C'est le moyen le
plus important de trouver un défaut d'affichage** : cinq des neuf défauts
corrigés avant la v1.0 d'`Atelier Docker` étaient invisibles depuis les tests
unitaires, qui exécutent `public/app.js` contre un DOM de substitution.

Voir `outils/navigateur/LISEZ-MOI.md` pour Chromium, les arguments, et les pièges
déjà payés. Les quatre qui coûtent le plus cher :

1. **Un `confirm` natif bloque le renderer de son onglet.** `Page.enable` n'y
   répond plus jamais. Créez un onglet neuf à chaque exécution.
2. **Naviguer vers la même URL ne recharge pas la page.** Ajoutez `?r=<aléatoire>`.
   Sans ça, le script rapporte fidèlement un bug déjà corrigé.
3. **`Page.captureScreenshot({captureBeyondViewport: true})` ment.** Pour vérifier
   une présence/absence, capturez le **viewport** seul.
4. **Un élément remplacé par `replaceWith` devient un nœud détaché.** Sa
   référence ne change plus. Une recette qui lit `carte.textContent` dans une
   boucle lit du vide et conclut n'importe quoi — en l'occurrence, « juste » dès
   qu'un bouton était désactivé, ce qui est vrai après n'importe quel clic.
   **Relire l'élément dans le DOM à chaque tour.**
5. **Les coupures de code se repaid par `python3`, jamais par numéro de ligne.**
   Un appel de fonction non défini est une erreur d'**exécution**, pas de syntaxe :
   `node --check` ne la voit pas. La première coupe a emporté 368 lignes au lieu
   de 302.

---

## 12. L'administration

### La page

`/admin` : mot de passe → tableau de classe (pseudos, progression, autonomie,
compréhension, niveau, IP du poste, indices), statistiques de cohorte, journal
des événements, flux SSE, et quatre actions par joueur (remettre à zéro, changer
de mode, supprimer, attester). Plus un formulaire d'inscription rapide, avec son
champ secret.

### La session

Un mot de passe, échangé contre un jeton HMAC-SHA256
(`<expiration>.<signature>`), dans un cookie `HttpOnly; SameSite=Strict`,
valable 8 h (une journée de cours). Le mot de passe **n'est jamais stocké** : il
sert à vérifier la signature et à comparer — sur deux **hachés SHA-256 à préfixe
fixe**, jamais sur les chaînes, pour ne pas laisser de fenêtre de timing.

---

## 13. Pièges déjà payés

Liste courte des erreurs récurrentes. Chacune a coûté du temps.

| piège | pourquoi il mord |
|---|---|
| couper du code par numéro de ligne | un appel de fonction non défini est une erreur d'**exécution**, pas de syntaxe. **Utiliser un script de coupe à garde-fous.** |
| substituer une globale dans un harnais de test | remplacer `globalThis.confirm` après que `loadClient` l'a capturé ne change rien, et les tests échouent en désignant une cause étrangère. |
| un diagnostic qui n'accuse pas **la** chose | trois fois dans ce projet : `https://https://` au premier commit, « portail injoignable » pour un 401, et vingt-et-une quêtes « cassées » qui fonctionnaient pendant un redéploiement. Un diagnostic doit nommer la subsysteme en cause. |
| lire la sortie d'un shell pour juger une commande | une commande qui reçoit un 502 **sort en 0**. Regarder le statut ne prouve rien. |
| **`sleep N` entre un lancement et une lecture** | Works on my machine. Le runner de CI est plus lent, et les quêtes échouent ensemble pendant que tout fonctionne. |
| **prendre les dernières lignes de stderr** | Docker démonte ce qu'il a construit, sur stderr aussi. L'erreur est en **haut**. |
| `.click()` contre `dispatchEvent` | `.click()` respecte `disabled` ; `dispatchEvent` non. Le premier respecte le comportement réel. |
| `captureBeyondViewport` | laisse des couches peintes là où un élément était masqué. |
| navigation vers la même URL | ne recharge pas — l'app garde son état. |
| `linkedom` n'implémente pas tout | `readOnly` y est `undefined`. Lire l'attribut (`hasAttribute`). |
| `[hidden]` battu par une règle d'auteur | d'où `[hidden] { display: none !important }`. **Ne pas retirer ce `!important`.** |
| `readonly` sur un champ `sr-only` | `display: none` retire l'élément de l'accessibilité. |
| `git check-ignore` et les fichiers suivis | il considère un fichier **déjà suivi** comme jamais ignoré. Un `.gitignore` peut donc laisser passer un fichier que sa propre règle exclut, et le défaut n'apparaît que dans un dépôt neuf. |
| deux portails sur une machine | un `reverse_proxy` pointant sur le mauvais conteneur ne se voit pas : le portail répond, avec le contenu de l'autre jeu. |
| un script avec une URL par défaut | tester le mauvais portail valide l'autre jeu, en silence. |

---

## 14. Limites connues, et la suite logique

1. **Aucune sauvegarde.** Le volume `operation-beluga-data` est sur le seul
   disque du serveur (86 % utilisés). Pas de copie, pas de réplication. C'est le
   risque le plus élevé du déploiement — et le même pour `Atelier Docker`.
2. **`LINEAR_PROGRESSION` n'est pas une contrainte serveur.** `/api/submit`
   n'accepte que le flag, dans les deux cas. Assumé. Pour une vraie contrainte :
   `ARENA_ATTESTATION=1`.
3. **Les quotas sont par IP, pas par jeton.** En salle derrière un NAT, toute la
   promotion partage un compteur : le plafond de 40/min sur `/api/submit` peut
   renvoyer des 429 à tout le monde.
4. **CSS mort** dans `public/style.css` : `.portal-head`, `.portal-body`,
   `.portal-foot`, `.podium`, `.panel-amber`, `.panel-emerald`, `.panel-cyan` —
   des restes du portail supprimé. Cosmétique.
5. **Le `recall` n'est présent que sur 2 quêtes sur 27.** Choix délibéré, à
   reconsidérer si l'enseignant veut plus de mémorisation.
6. **`inject-fetchhint.js`** a servi une fois à migrer le contenu. Conservé par
   prudence, sans raison d'être.
7. **La ligne « Atterrissage » du carnet de bord ne s'allume qu'à la fin.**
   Elle exige les 28 quêtes, pas les 27 de cours : c'est la seule ligne dont
   l'état n'est pas la somme d'un atelier.

---

## 15. Si tu reprends ce projet

**D'abord le § 2.** Le travail qui reste est listé et chiffré : l'atelier 8,
puis une sauvegarde du volume.

**Écrire du contenu.** C'est là que ce projet a le plus de valeur et le moins
d'obstacle. Un atelier = un bloc de cours ; respecter `docs/CONTRACTS.md` § 1 et
laisser le validateur juger. Le validateur est un professeur exigeant : il vaut
mieux.

**Corriger ce qui coince.** Les défauts de `Atelier Docker` ont tous été trouvés
en jouant, pas en lisant le code. Le premier coup est donc de jouer : ouvrir le
contenu, lire les 27 briefs, les questions, les indices, et chercher ce qui ne se
tient pas.

**Améliorer la mesure.** C'est le cœur du projet. Trois questions : l'enseignant
sait-il, pendant la séance, qui est bloqué et où ? L'élève sait-il ce qu'il a
appris ? La mesure reste-t-elle comparable à elle-même d'un atelier à l'autre ?
La réponse à la troisième est la plus difficile, et c'est celle qui compte.

Dans tous les cas : **pousser sur GitHub et sur le serveur d'abord, puis
continuer.** Le portail est en production sur une URL publique ; un changement
non déployé est un changement que personne n'a vu.
