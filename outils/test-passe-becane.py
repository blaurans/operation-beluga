#!/usr/bin/env python3
"""
Le renommage lui-même, vérifié.

`passe-becane.py` a corrompu du contenu trois fois avant d'être correct, et
chaque fois le symptôme était le même : **il transformait un mot qui n'avait rien
à voir**. Un motif de substitution ne connaît pas l'intention de la personne qui
l'écrit.

    « verdict »        → « cabinect »   (le nom de conteneur avalait le mot)
    « le site de … »   → « … de le … »  (l'article ne s'accorde pas tout seul)
    `grep -i verdi`    → `grep -i cabine` (le motif a suivi le nom, pas l'intention)

Ce fichier verrouille ces trois cas. Il est volontairement minuscule : un script
de migration sans test est un script dont on ne peut pas vérifier qu'il a fini sa
tâche.

    python3 outils/test-passe-becane.py
"""
import importlib.util
import io
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('passe_becane', os.path.join(ICI, 'passe-becane.py'))
pb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pb)

# (entrée, attendu, pourquoi)
CAS = [
    # ── le conteneur et ses voisins ──
    ('docker run -d --name verdi -p 8080:80 nginx:alpine',
     'docker run -d --name cabine -p 8080:80 nginx:alpine',
     'le nom du conteneur principal'),
    ('docker network create reseau-verdi',
     'docker network create reseau-cabine',
     'le réseau garde son préfixe'),
    ('docker run -d --name verdi-db --network reseau-verdi redis:alpine',
     'docker run -d --name cabine-db --network reseau-cabine redis:alpine',
     'la base et le réseau, dans la même commande'),
    ('docker build -t verdi-site:1.0 .',
     'docker build -t service-cabine:1.0 .',
     'l\'image'),
    ('cd ~/verdi-image', 'cd ~/service-cabine', 'le répertoire de travail'),

    # ── les flags ──
    ("flag: 'FLAG{VERDI_BOOT_PERSISTED_AFTER_RESTART}'",
     "flag: 'FLAG{CABINE_UP_AFTER_DAEMON_RESTART}'",
     'le flag est renommé par son nom complet, pas par le préfixe générique'),
    ("flag: 'FLAG{PORT_9090_ENV_CONFIGURED_VERDI}'",
     "flag: 'FLAG{PORT_9090_ENV_CONFIGURED_CABINE}'",
     'un flag qui contient VERDI en fin'),

    # ── les trois pièges ──
    ('le verdict du controle de vol',
     'le verdict du controle de vol',
     '« verdict » ne doit surtout PAS devenir « cabinect »'),
    ('le site de la librairie doit tourner',
     'le service de restauration doit tourner',
     'l\'article : « de la librairie » ne devient jamais « de le service »'),
    ('Le premier serveur de la librairie',
     'Le premier serveur de bord',
     'un titre de quête, pas une phrase'),
    ('expliquer à la direction de la librairie pourquoi',
     'expliquer à la direction de bord pourquoi',
     'une phrase, pas un nom propre'),

    # ── l'inventaire ──
    ('SET stock "1284 romans, 96 Bedford, 12 Aragon"',
     'SET stock "1284 plateaux, 96 régime sans gluten, 12 végétarien"',
     'le stock est réécrit en objets de vol'),
]


def main():
    echecs = 0
    for entree, attendu, pourquoi in CAS:
        obtenu = pb.transformer(entree)
        if obtenu == attendu:
            print(f'  ok    {pourquoi}')
            continue
        echecs += 1
        print(f'  ÉCHEC {pourquoi}')
        print(f'        attendu : {attendu!r}')
        print(f'        obtenu  : {obtenu!r}')

    # Le filet de sécurité : une passe sur le contenu réel ne doit plus rien
    # changer. Si elle change quelque chose, c'est qu'une règle restante s'est
    # réveillée — et elle le ferait silencieusement au prochain atelier.
    for n in range(1, 9):
        chemin = os.path.join(pb.QUEST, f'm{n}.js')
        if not os.path.exists(chemin):
            continue
        avant = io.open(chemin, encoding='utf-8').read()
        apres = pb.transformer(avant)
        if avant != apres:
            echecs += 1
            print(f'  ÉCHEC m{n}.js : une substitution s\'applique encore sur le contenu réel')
            for i, (a, b) in enumerate(zip(avant.split('\n'), apres.split('\n')), 1):
                if a != b:
                    print(f'        {i}: - {a.strip()[:90]}')
                    print(f'        {i}: + {b.strip()[:90]}')

    if echecs:
        print(f'\n{echecs} échec(s).')
        return 1
    print(f'\n{len(CAS)} cas, et le contenu réel ne bouge plus.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
