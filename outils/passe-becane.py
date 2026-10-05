#!/usr/bin/env python3
"""
Bascule le vocabulaire du contenu de l'ancienne intrigue vers celle d'Opération
Beluga.

Ce script fait un **renommage mécanique**, pas une réécriture. Il ne touche
qu'aux noms propres et aux phrases qui les portent ; il ne reformule rien. La
réécriture des énoncés, des indices et des questions reste un travail de
rédaction, et c'est volontaire : un script qui réécrit de la prose produit de la
prose de script.

## Pourquoi un script quand on pourrait éditer à la main

Parce que les noms reviennent des dizaines de fois par fichier, et qu'une
occurrence oubliée se voit tout de suite : un élève lit « Librairie Verdi » au
milieu d'un vol Beluga, et le cadre s'effondre. Une réécriture à la main laisse
toujours un oubli ; un grep ne laisse rien.

## Les invariants que ce script doit respecter

1. **Les flags sont uniques dans le jeu** et ne sont jamais montrés dans un
   énoncé. Les renommer ne casse donc rien côté joueur — le mot de passe est
   dérivé par HMAC du jeton et de l'identifiant de quête, jamais du flag.
2. **Les identifiants de quête** (`m2-04-initial-boot`) sont le reste du nom
   d'un flag dans l'API. Les changer est sans risque ici, le jeu n'a pas
   encore servi d'élèves.
3. **Aucune commande utile ne doit disparaître.** Les noms de conteneur
   (`verdi`, `verdi-db`), de réseau (`reseau-verdi`) et d'image
   (`verdi-site:1.0`) sont ce que l'élève tape : ils sont renommés, et les
   commandes sont mises à jour dans le même passage, sinon la correction ne
   correspond plus à l'énoncé.

Usage :
    python3 outils/passe-becane.py --verifier   # compte, n'écrit rien
    python3 outils/passe-becane.py             # applique
    python3 outils/passe-becane.py --fiche m2.js   # montre le résultat d'un fichier
"""
import io
import os
import re
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUEST = os.path.join(RACINE, 'content', 'quests')

# ── l'ancienne intrigue ──────────────────────────────────────────────────
# Ordre important : le plus long d'abord. `reseau-verdi` contient `verdi`, et
# `verdi-site:1.0` doit être traité avant `verdi` seul. Une substitution dans
# l'ordre inverse produirait `reseau-cabine` puis `verdi` qui ne matcherait
# plus — ici on s'appuie sur le fait que chaque motif est distinct, mais
# l'ordre reste du plus spécifique au plus général, par prudence.
VESTIGES = [
    # Identifiants et noms de ressources : ce que l'élève tape.
    ('reseau-verdi', 'reseau-cabine'),
    ('verdi-db', 'cabine-db'),
    ('verdi-site', 'service-cabine'),
    ('~/verdi-image', '~/service-cabine'),
    ('verdi-image', 'service-cabine'),

    # Flags. Uniques, jamais montrés : le joueur ne voit jamais cette chaîne.
    ('VERDI_BOOT_PERSISTED_AFTER_RESTART', 'CABINE_UP_AFTER_DAEMON_RESTART'),
    ('PORT_9090_ENV_CONFIGURED_VERDI', 'PORT_9090_ENV_CONFIGURED_CABINE'),
    ('RECREATED_AFTER_CONFIG_CHANGE_VERDI', 'RECREATED_AFTER_CONFIG_CHANGE_CABINE'),
    ('PORT_PUBLISHED_VERDI_REACHABLE', 'PORT_PUBLISHED_CABINE_REACHABLE'),
    ('VERDI_STACK_SITE_AND_DB_ISOLATED', 'CABINE_STACK_SITE_AND_DB_ISOLATED'),
    ('VERDI_1_0_REPRODUCIBLE_AND_TAGGED', 'CABINE_1_0_REPRODUCIBLE_AND_TAGGED'),
    ('VERDI_VOLUME_NAMED_DURABLE_AND_LISTED', 'CABINE_VOLUME_NAMED_DURABLE_AND_LISTED'),
    ('VERDI_PILE_RECOVERED_ON_CLEAN_MACHINE', 'CABINE_PILE_RECOVERED_ON_CLEAN_MACHINE'),
    ('FLAG{VERDI_', 'FLAG{CABINE_'),
    ('FLAG{CABINE_BOOT', 'FLAG{CABINE_UP'),

    # Identifiants de quête.
    ('m2-04-initial-boot', 'm2-04-premier-service-de-bord'),
    ('m5-04-la-methode-de-la-librairie', 'm5-04-la-methode-de-la-cabine'),

    # Le nom du conteneur principal, seul.
    #
    # Passé en `regex` avec frontières de mot, et c'est indispensable : sans
    # elles, `verdi` transformait le mot français **verdict** en « cabinect ».
    # Le script ne signalait rien — il corruption un mot parfaitement innocent,
    # dans quatre fichiers, et `--verifier` annonçait unRename propre.
    #
    # C'est le troisième exemplaire du même piège dans ce projet : un motif
    # suit une chaîne, pas une intention. Un `grep -i` transformait le `grep`
    # d'un énoncé en un motif qui ne trouvait plus rien ; ici c'est un mot de la
    # langue française qui disparaît dans un identifiant.
    ('verdi', 'cabine', r'\bverdi\b'),

    # Textes : la librairie Verdi devient le service de restauration.
    # « Le site de la librairie » devient « le service de restauration » par la
    # règle générale, mais cela produit « le site de **le** service », qui n'est
    # pas français. Ces trois-ci reprennent le mot juste après : une substitution
    # par motif ne connaît pas le genre de l'article qui la suit.
    #
    # Elles viennent **avant** la règle générale, et c'est pour ça qu'elles
    # mentionnent encore « la librairie » : c'est la forme d'origine qu'elles
    # doivent attraper. En les déplaçant après, elles ne trouveraient plus rien.
    #
    # « de la librairie » est le cas général, et il est traité **directement**,
    # en une passe. La version naïve — « de la librairie » → « de la
    # restauration » — donnait « la direction de **le** service de
    # restauration », qu'il fallait rattraper par une seconde passe. Le script
    # fonctionnait donc seulement en étant lancé deux fois, ce qu'aucun test ne
    # vérifiait. Le cas général absorbant les trois cas particuliers, il n'y en
    # a plus besoin, et la table est idempotente.
    # Les trois phrases complètes **avant** le cas général : « le site de la
    # librairie » contient « de la librairie », et la règle générale le
    # transformerait en « le site de bord » — grammaticalement correct, mais on
    # perd le mot « service », qui est le sujet de toute l'histoire.
    ('Le premier serveur de la librairie', 'Le premier serveur de bord'),
    ('la méthode de la librairie', 'la méthode de la cabine'),
    ('le site de la librairie', 'le service de restauration'),
    ('de la librairie', 'de bord'),
    ('La librairie Verdi', 'Le service de restauration'),
    ('la librairie Verdi', 'le service de restauration'),
    ('Librairie Verdi', 'Restauration Beluga'),
    ('la librairie', 'le service de restauration'),
    ('La librairie', 'Le service de restauration'),
    ('aux libraires', 'de cabine'),
    ('libraires', 'hôtels de cabine'),
    ('commandes des libraires', 'commandes de cabine'),
    ('d\'une librairie', 'd\'un vol'),
]

# Le stock de la librairie, réécrit avec des objets de vol. Le compte est
# conservé : une mise en scène n'a pas besoin d'être numérique.
INVENTAIRE = [
    ('1284 romans, 96 Bedford, 12 Aragon',
     '1284 plateaux, 96 régime sans gluten, 12 végétarien'),
]


def transformer(texte):
    """Applique les substitutions, dans l'ordre de la table.

    Un motif de la table peut porter une troisième élément : une expression
    régulière, utilisée avec frontières de mot. C'est le cas du nom de
    conteneur `verdi`, qui est une sous-chaîne du mot français « verdict ».
    """
    for avant, apres in INVENTAIRE:
        texte = texte.replace(avant, apres)
    for regle in VESTIGES:
        avant, apres = regle[0], regle[1]
        motif = regle[2] if len(regle) > 2 else None
        texte = re.sub(motif, apres, texte) if motif else texte.replace(avant, apres)
    return texte


def compter(avant, apres):
    """Combien de lignes changent vraiment — donc combien de réécritures."""
    return sum(1 for a, b in zip(avant.split('\n'), apres.split('\n')) if a != b)


def diff_lignes(avant, apres):
    """Les (numéro, avant, après) des lignes qui changent, pour `--fiche`."""
    return [(i, a, b) for i, (a, b) in enumerate(zip(avant.split('\n'), apres.split('\n')), 1)
            if a != b]


def main():
    args = sys.argv[1:]
    verifier = '--verifier' in args
    fiche = None
    if '--fiche' in args:
        fiche = args[args.index('--fiche') + 1]

    restants = 0
    for n in range(1, 9):
        chemin = os.path.join(QUEST, f'm{n}.js')
        if not os.path.exists(chemin):
            continue
        if fiche and os.path.basename(chemin) != fiche:
            continue

        avant = io.open(chemin, encoding='utf-8').read()
        apres = transformer(avant)
        changed = compter(avant, apres)

        nom = os.path.basename(chemin)

        if fiche:
            for i, a, b in diff_lignes(avant, apres):
                print(f'  {nom}:{i}')
                print(f'    - {a.strip()}')
                print(f'    + {b.strip()}')
            return 0

        if avant == apres:
            print(f'{nom} : rien à changer')
        elif verifier:
            print(f'{nom} : {changed} ligne(s) à changer')
        else:
            io.open(chemin, 'w', encoding='utf-8').write(apres)
            print(f'{nom} : {changed} ligne(s) changées')

        # Ce qui reste, et qui doit être réécrit à la main : un nom propre que le
        # script n'a pas su transformer, ou une phrase dont le sens ne tient plus
        # une fois le nom changé.
        for i, ligne in enumerate(apres.split('\n'), 1):
            # Frontières de mot, sinon « verdict » et « library » en français
            # seraient signalés comme des restes de l'ancienne intrigue.
            if re.search(r'\bverdi\b|\blibrair\w*\b|\bkoplik\w*\b', ligne, re.I):
                print(f'    {nom}:{i} à relire : {ligne.strip()[:100]}')
                restants += 1

    if restants:
        print(f'\n{restants} ligne(s) à réécrire à la main.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
