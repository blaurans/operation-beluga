// Atelier 8 — L'atterrissage
//
// Le dernier atelier, et le seul qui ne fasse pas qu'apprendre une notion : il
// **prouve**. Les sept précédents ont construit, un par un, les morceaux du vol.
// Celui-ci les assemble et exige une preuve que tout le monde répond.
//
// Ce qui rend la manœuvre possible, et que l'atelier 7 a explicitement laissé
// ouvert : l'atelier 7 dit que `depends_on` décrit un **ordre de démarrage**, et
// pas une disponibilité. C'est vrai, et c'est le dernier défaut du vol. Ici on
// le ferme avec deux notions qu'il ne reste qu'à employer ensemble :
//
//   • un `healthcheck` — le service dit lui-même s'il est prêt ;
//   • `condition: service_healthy` — le dependent attend ce verdict, au lieu
//     d'attendre que le conteneur existe.
//
// Et une troisième, plus courte : `profiles`, qui permet d'avoir dans le
// **même** fichier un service qui ne démarre jamais avec la pile. C'est ce qui
// donne la preuve : le contrôle de vol est dans le fichier de production, et il
// ne se lance que quand on le demande.
//
// Deux partis pris.
//
//   1. **Une seule quête, et c'est la phare.** C'est un module d'un seul tenant :
//     on ne « manœuvre pas d'atterrissage ». Le fichier se lit d'un bout à
//     l'autre, donc l'énoncé aussi.
//
//   2. **La preuve est négative.** Faire tourner la pile ne prouve rien — ça ne
//      prouve rien de plus que les ateliers précédents. Ce qui compte est de la
//      faire tomber, de voir le contrôle échouer, puis de la relever. Un test
//      qui n'a jamais échoué n'a pas été exécuté.
export default {
  meta: {
    slug: 'm8-atterrissage',
    module: 8,
    title: 'L\'atterrissage',
    tagline: 'Assembler la pile, et exiger la preuve que tout le monde répond',
    icon: '🛬',
    story: `# Avant d'atterrir, il faut que tout le monde le dise

Le vol Beluga descend. Il reste quatre mille pieds, et une chose manque encore :
**la preuve**.

Le capitaine ne décidera pas d'atterrir parce que ça a l'air d'aller. Il lui
faut que chaque système se présente, qu'il réponde, et que quelqu'un **ait
vérifié**. Le travail des sept ateliers précédents a produit tout ce qu'il faut
pour cette vérification — un réseau où les services se trouvent par leur nom, une
image versionnée, un volume qui survit, un fichier qui décrit la pile. Il n'a
produit **rien qui dise que la pile est saine**.

C'est le dernier défaut du vol, et il est plus grave qu'il n'en a l'air. Une
pile où le site est monté avant sa base n'est pas une pile en panne : elle est
une pile qui *semble* marcher. Le site répondra, la base ne sera pas prête, et
personne ne le verra tant que rien ne l'appellera.

Cet atelier ne construit presque rien de nouveau. Il assemble, et il exige la
preuve — y compris quand la preuve est un échec.
`,
  },

  quests: [
    {
      id: 'm8-01-atterrissage',
      order: 1,
      title: 'La manœuvre finale',
      points: 800,
      flag: 'FLAG{ATTERRISSAGE_CONTROLE_PREUVE_ET_REUSSI}',
      estMinutes: 25,
      brief: `# La manœuvre finale

Il faut tenir quatre mille pieds. Tu as le site, la base, le réseau, l'image
versionnée, le volume, et le fichier qui décrit la pile. Ce qui manque est
l'unique chose que le capitaine demande, et qu'aucun des ateliers précédents
ne fournit : **la preuve que tous les systèmes répondent.**

Tu vas assembler la pile complète dans un seul fichier, y ajouter un contrôle
de vol, et le faire échouer avant de le faire réussir.

**Ta mission**

1. Écris le fichier final. Il reprend la pile de l'atelier 7, et ajoute deux
   choses : un contrôle de santé sur la base, et une condition d'attente sur le
   site. La clé \`healthcheck\` dit au moteur **comment tester** ; la clé
   \`interval\` dit **à quelle fréquence**.

\`\`\`bash
mkdir -p ~/cabine-final && cd ~/cabine-final
cat > compose.yaml <<'EOF'
services:
  db:
    image: redis:alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  cabine:
    image: service-cabine:1.0
    ports:
      - "8080:80"
    depends_on:
      db:
        condition: service_healthy

  controle:
    image: redis:alpine
    profiles: ["vol"]
    entrypoint: ["/bin/sh", "-c"]
    command: >
      redis-cli -h db ping &&
      wget -qO- http://cabine/ >/dev/null &&
      echo "SYSTEMES VERIFIES - ATTERRISSAGE AUTORISE"
EOF
\`\`\`

Trois détails, et ils sont tout l'atelier :

- \`condition: service_healthy\` remplace un \`depends_on\` ordinaire. Sans lui,
  Compose attend que le conteneur **existe**. Avec lui, Compose attend que la
  base **réponde**.
- \`profiles: ["vol"]\` met le contrôle **hors du trajet normal**. Un service
  qui porte un profil ne démarre jamais avec \`docker compose up\` : il faut le
  nommer. Le contrôle est donc dans le fichier de production, et il ne coûte
  rien tant qu'on ne le demande pas.
- Le \`command\` se termine par \`&&\` : si un seul des deux tests échoue, la
  chaîne s'arrête là, et le service sort **en erreur**. C'est ce qui fera
  échouer la manœuvre tout à l'heure.

2. Vérifie le fichier, monte la pile, et regarde l'état de santé :

\`\`\`bash
docker compose config --quiet && echo "valide"
docker compose up -d
docker compose ps
\`\`\`

Le contrôle **n'est pas** dans la liste. C'est attendu : il porte un profil.

3. Attends la santé de la base, sans rien mettre sur un délai fixe. La boucle
   attend une **condition**, elle ne suppose pas un temps :

\`\`\`bash
until [ "$(docker inspect --format '{{.State.Health.Status}}' cabine-final-db-1)" = "healthy" ]; do
  echo "en attente…"
  sleep 2
done
docker compose ps
\`\`\`

4. **La manœuvre.** Demande le contrôle de vol :

\`\`\`bash
docker compose run --rm controle
\`\`\`

\`\`\`
PONG
SYSTEMES VERIFIES - ATTERRISSAGE AUTORISE
\`\`\`

C'est le mot que le capitaine attendait. Mais **ça ne prouve encore rien** : une
pile qui n'a jamais échoué n'a pas été testée.

5. **Casse la pile, et regarde le contrôle le dire.** Arrête la base en cours de
   vol, et redemande le contrôle :

\`\`\`bash
docker compose stop db
docker compose run --rm controle; echo "code de sortie : $?"
\`\`\`

Le site répond toujours. La base ne répond plus. Le contrôle doit le dire, et il
doit **sortir en erreur**. Un contrôle qui réussit quand la panne est là ne
contrôle rien.

6. **Relève la manœuvre.** Remets la base, et recommence :

\`\`\`bash
docker compose up -d
until [ "$(docker inspect --format '{{.State.Health.Status}}' cabine-final-db-1)" = "healthy" ]; do sleep 2; done
docker compose run --rm controle; echo "code de sortie : $?"
\`\`\`

**Ce que tu observes**

- \`docker compose ps\` porte une colonne de plus qu'à l'atelier 7 : la
  **santé**. \`healthy\` et \`starting\` sont deux états qu'un simple
  \`Up\` ne distingue pas.
- \`run\` démarre le service demandé **et ses dépendances**, puis s'arrête. C'est
  pourquoi \`controle\` trouve la base, même après un \`stop\` : \`depends_on\`
  s'applique aussi à \`run\`.
- Étape 5 : le site répond toujours, et c'est le pire symptôme possible. Une
  panne invisible dans un service qui a l'air sain.
- Étape 6 : le code de sortie revient à \`0\`. C'est **lui** que le capitaine
  lit, pas la ligne affichée.

**Bon à retenir**

Un déploiement qui n'a jamais été cassé n'a pas été déployé. Et un contrôle qui
ne sait pas échouer ne contrôle rien.

**Ton mot de passe**

Le mot de passe sort du journal d'un service à usage unique — celui qui affiche
le verdict. C'est la technique de l'atelier 7, appliquée à la manœuvre :

\`\`\`bash
export ARENA_TOKEN='dq_xxxxxxxxxxxxxxxx'
mkdir -p /tmp/atelier-m8 && cd /tmp/atelier-m8 && printf '%s\\n' 'services:' '  journal:' '    image: alpine' "    command: wget -qO- https://SERVER_IP/api/secret/m8-01-atterrissage/raw?token=$ARENA_TOKEN" > compose.yaml
docker compose up journal; docker compose logs journal; docker compose down
\`\`\``,
      hints: [
        "Un `depends_on` sans `condition` attend que le conteneur **existe**, pas qu'il soit prêt. C'est la limite que l'atelier 7 avait signalée, et c'est ce que le `healthcheck` vient lever.",
        "`docker compose run` prend le nom d'un **service** du fichier, pas un nom de conteneur. Et un service qui porte un `profiles` ne démarre pas avec `up` : c'est tout l'intérêt.",
        "Un `&&` dans un `command` s'arrête au premier échec, et le conteneur sort alors avec le code du sous-processus. C'est ce qui distingue un contrôle qui échoue d'un contrôle qui ne sait pas échouer.",
      ],
      charge: { perHint: 1, autonomy: [1, 1, 0] },
      check: [
        {
          id: 'm8-01-depends-on',
          kind: 'mcq',
          prompt: 'Que garantit exactement un `depends_on` écrit sans `condition` ?',
          choices: [
            'Rien de plus que l\'ordre de démarrage : le site peut parler à une base qui n\'écoute pas encore',
            'Que le service dépendant attend que le service demandé soit prêt à répondre',
            'Que le service dépendant est relancé si le service demandé tombe',
            'Que la pile entière démarre avant le moindre conteneur',
          ],
          answer: 0,
          explanation: "C'est la limite signalée à l'atelier 7, et le cœur de celui-ci : par défaut `depends_on` décrit un ordre, pas une disponibilité. `condition: service_healthy` est ce qui transforme l'ordre en attente réelle.",
          required: true,
        },
        {
          id: 'm8-01-profiles',
          kind: 'mcq',
          prompt: 'Un service qui porte `profiles: ["vol"]` se lance…',
          choices: [
            'Uniquement quand on le nomme, par exemple `docker compose run controle`',
            'Jamais, quelle que soit la commande',
            'En même temps que les autres, après eux',
            'Seulement au premier `docker compose up` de la journée',
          ],
          answer: 0,
          explanation: "Le profil sort le service du trajet normal : il est dans le fichier, il est versionné avec le reste, et il ne coûte rien tant qu'on ne le demande pas. C'est ce qui permet d'avoir un contrôle de vol dans un fichier de production.",
          required: true,
        },
        {
          id: 'm8-01-code-sortie',
          kind: 'boolean',
          prompt: 'Un contrôle qui affiche un verdict favorable et qui sort en code 0, alors que la base est arrêtée, fonctionne correctement.',
          answer: false,
          explanation: "Faux, et c'est le point de la quête : un contrôle qui réussit pendant la panne ne contrôle rien. C'est le **code de sortie** que l'automatisation lit, pas la ligne affichée.",
          required: true,
        },
      ],
      solution: `\`\`\`bash
cd ~/cabine-final

docker compose config --quiet && echo "valide"
# -> valide

docker compose up -d
docker compose ps
# -> NAME               IMAGE              STATUS              PORTS
# -> cabine-final-db-1   redis:alpine       Up (healthy) 3s
# -> cabine-final-cabine-1   service-cabine:1.0   Up 4s        0.0.0.0:8080->80/tcp
# -> (controle est absent : il porte un profil)

until [ "$(docker inspect --format '{{.State.Health.Status}}' cabine-final-db-1)" = "healthy" ]; do
  echo "en attente…"
  sleep 2
done
docker compose ps
# -> db : Up (healthy) — le site n'a attendu que le verdict, pas le conteneur

docker compose run --rm controle
# -> PONG
# -> SYSTEMES VERIFIES - ATTERRISSAGE AUTORISE

# ── la preuve est négative ──
docker compose stop db
docker compose run --rm controle; echo "code de sortie : $?"
# -> Could not connect to db:6379
# -> code de sortie : 1

# ── et on relève ──
docker compose up -d
until [ "$(docker inspect --format '{{.State.Health.Status}}' cabine-final-db-1)" = "healthy" ]; do sleep 2; done
docker compose run --rm controle; echo "code de sortie : $?"
# -> PONG
# -> SYSTEMES VERIFIES - ATTERRISSAGE AUTORISE
# -> code de sortie : 0

docker compose down
\`\`\`

La manœuvre est réussie quand le contrôle **sort en erreur** pendant la panne,
et en \`0\` après. L'inverse n'aurait rien prouvé.`,
      teaches: ['healthcheck', 'depends_on condition service_healthy', 'profiles', 'code de sortie', 'docker compose run'],
      fetchHint: `export ARENA_TOKEN='dq_xxxxxxxxxxxxxxxx'
mkdir -p /tmp/atelier-m8 && cd /tmp/atelier-m8 && printf '%s\\n' 'services:' '  journal:' '    image: alpine' "    command: wget -qO- https://SERVER_IP/api/secret/m8-01-atterrissage/raw?token=$ARENA_TOKEN" > compose.yaml
docker compose up journal; docker compose logs journal; docker compose down`,
      checkpoint: "Tu as compris quand tu sais faire tomber la pile, montrer que le contrôle le dit, et le relever — et que sans l'étape 5, l'étape 4 n'aurait rien prouvé.",
    },
  ],
};
