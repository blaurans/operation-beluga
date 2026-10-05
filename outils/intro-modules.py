#!/usr/bin/env python3
"""
Réécrit le bloc `meta` des modules de contenu.

Un seul tableau décrit l'identité des sept ateliers : slug, titre, tagline,
icône et introduction du fil rouge. Passer par un script plutôt que par sept
édits à la main, parce que la cohérence entre les ateliers est exactement ce
que l'œil ne vérifie pas — une intro qui parle encore de Verdi alors que la
précédente parle du vol Beluga ne se remarque qu'en lisant les sept bout à
bout, ce que personne ne fait.

Usage :
    python3 outils/intro-modules.py            # applique
    python3 outils/intro-modules.py --verifier # n'écrit rien, signale les trous
"""
import io
import os
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUEST = os.path.join(RACINE, 'content', 'quests')

# Mots de l'ancienne intrigue. Leur présence dans une `story` signifie que
# l'intro n'a pas été réécrite. Volontairement des mots rares et distinctifs :
# « serveur » et « migration » ne diraient rien, ils servent aussi à l'intro
# nouvelle.
ANCIEN_FIL_ROUGE = ['verdi', 'librairie', 'librairies', 'migration']

MODULES = [
    dict(
        n=1, slug='m1-evaluer-le-patient', icon='\U0001fa7a',
        title='Évaluer le patient',
        tagline="Savoir sur quoi on travaille, installer l'outillage, vérifier qu'il répond",
        story="""# Beluga est en perte de vitesse

Onze mille mètres. Le vol Beluga vient de traverser une zone de turbulence, et
le capitaine a coupé le pilote automatique. **Beluga**, le copilote, ne répond
plus : sa console affiche un *passenger service system* en défaut, sans dire
lequel.

Personne à bord ne sait diagnostiquer la machine. Vous êtes le seul ingénieur de
bord, et vous ne pouvez rien à distance : **le serveur de bord, c'est cette
machine**. Tout ce que vous ferez pendant les sept prochains ateliers, vous le
faites sur elle, dans votre terminal.

Cet atelier n'est pas une leçon, c'est une **évaluation**. Avant de toucher à
quoi que ce soit, il faut savoir sur quoi on travaille — et il faut disposer de
l'outillage qui dispense les soins. C'est la préparation à tout le reste du
vol.
""",
    ),
    dict(
        n=2, slug='m2-ramener-les-pieces', icon='\U0001f4e6',
        title='Ramener les pièces',
        tagline="Télécharger une image, la lancer, la jeter, démarrer le service de bord",
        story="""# Approvisionnement en vol

La cause du défaut est trouvée : c'est le service qui distribue les repas aux
passagers, et il est arrêté. Le diagnostic ne l'a pas remis en route, il a
montré où regarder.

Il y a une bonne nouvelle, et tous les ingénieurs la connaissent : **personne
n'écrit plus ses logiciels à partir de zéro**. On va chercher des pièces
toutes faites, les bringuer à bord, les essayer, et les jeter si elles ne
conviennent pas. C'est exactement ce que fait un registre de conteneurs, et
c'est l'outillage que vous venez d'installer.

Cet atelier, c'est le ravitaillement. Vous allez apprendre à récupérer une
pièce, à la faire tourner, et à vous en défaire. Pris séparément, ces trois
gestes ne servent à rien. C'est leur ensemble qui fait un serveur.
""",
    ),
    dict(
        n=3, slug='m3-regler-en-service', icon='\U0001f527',
        title='Régler en service',
        tagline="Ports, variables d'environnement, et un service qui s'écroule",
        story="""# Le service ne tient pas

La pièce est ramenée et elle tourne. Elle ne fait pas ce qu'on attend d'elle.

C'est le normal dans un vol, et pas le cas particulier. Une pièce qu'on lance
marche avec des réglages par défaut, et les réglages par défaut ne conviennent
jamais à l'endroit où on l'a posée. Il faut lui dire quelles sont ses conditions
de service : où elle doit écouter, ce qu'elle doit savoir, ce qu'elle a le droit
de voir.

Et quand elle s'écroule — et elle va s'écrouler, vous en verrez deux — il faut
pouvoir entrer dedans avant de décider quoi faire.

Cet atelier vous apprend à faire tourner un service en service : le régler, le
relancer, et aller le voir de l'intérieur.
""",
    ),
    dict(
        n=4, slug='m4-brancher-les-systemes', icon='\U0001f310',
        title='Brancher les systèmes',
        tagline="Réseaux privés, ports publiés, et un service qui trouve son voisin par son nom",
        story="""# Les systèmes ne se parlent pas

Le service fonctionne, mais il est seul. La seconde alarme qu'il devait
déclencher part vers un service qui n'existe pas, et le terminal qu'il doit
interroger ne lui répond pas.

Les deux tournent pourtant, sur la même machine. Ils ne se parlent simplement
pas : chacun est dans sa bulle, avec ses propres adresses, et personne ne sait
à qui parler.

C'est le problème central de tout avion, et de tout serveur. Cet atelier y
répond : on relie les systèmes, on décide qui a le droit de voir qui, et on
apprend que **trois machines qui se parlent ne s'appellent pas par leur
adresse**. Elles s'appellent par leur nom. C'est court, ça se retient, et ça ne
change jamais.
""",
    ),
    dict(
        n=5, slug='m5-certifier-les-pieces', icon='\U0001f4c4',
        title='Certifier les pièces',
        tagline="Du conteneur jetable à une image reproductible",
        story="""# La pièce non certifiée

La liaison fonctionne. Le vol pourrait continuer — et il ne peut pas.

Parce que la configuration qui marche maintenant n'existe que sur cette machine,
dans cet état, dans cette mémoire. Si le serveur de bord redémarre demain, elle
a disparu. Personne ne peut la reconstituer, et vous ne savez même pas
exactement ce que vous avez modifié. Un serveur qu'on ne peut pas reconstruire
n'est pas un serveur : c'est un accident.

Il faut donc **figer** la pièce : écrire la liste de ce qu'elle contient et de
la façon dont elle est faite, pour que la même pièce se reconstruise à
l'identique, ici ou ailleurs. Cet atelier vous apprend à écrire cette
certification, et à comprendre pourquoi elle décide de ce qui se lance au
démarrage — c'est la question qui revient à chaque incident.
""",
    ),
    dict(
        n=6, slug='m6-sauvegarder-les-donnees', icon='\U0001f4be',
        title='Sauvegarder les données',
        tagline="Faire survivre les données à la mort du conteneur",
        story="""# Tout disparaît

La certification est écrite, la pile se reconstruit à l'identique. Tout va
bien.

Et puis le service de bord plante, il est relancé, et **il ne sait plus rien**.
Trois heures de journaux de vol, parties. Le vol continue, l'avion atterrira,
mais l'enquête n'aura jamais lieu.

Parce que vous n'aviez pas encore séparé deux choses que tout le monde croit
solidaires : **le service, et ce qu'il a vécu**. Le service est jetable par
nature — on vient de le prouver, vous l'avez détruit et reconstruit dix fois.
Ce qui compte n'est pas le service.

Cet atelier porte la distinction la plus importante du jeu : ce qui doit
survivre, et ce qui peut mourir. Un serveur de bord ne survit pas à une panne
parce qu'il est solide. Il survit parce que **ce qui compte est ailleurs**.
""",
    ),
    dict(
        n=7, slug='m7-documenter-la-carte', icon='\U0001f4da',
        title='Documenter la carte',
        tagline="Toute la pile dans un fichier, puis la piloter",
        story="""# Reconstruire en quatre minutes

Il reste un problème, et il est vaste.

Vous savez faire tourner l'ensemble. Mais votre travail est devenu une
succession de gestes tapés dans un terminal, dans cet ordre, et cet ordre
n'est écrit nulle part. Le capitaine vous demande ce qui tourne — vous
répondez de mémoire. Si la machine s'éteint cette nuit, la remise en route
prend quatre heures et dépend de quelqu'un qui se souvient.

Un vol qui tient jusqu'à l'atterrissage a un dernier poste de service : **la
carte**. Tout ce qui est censé tourner, écrit en un seul endroit, de façon que
la remise en route ne dépende plus de votre mémoire.

Cet atelier écrit cette carte et vous apprend à la piloter. Il ne vous
apprendra rien de nouveau sur l'outillage ; c'est le but. Un outil qu'on ne sait
pas piloter est un outil qu'on utilise de travers.
""",
    ),
]


def js_str(s):
    """Une chaîne JS sur une seule ligne.

    Les titres et les taglines contiennent des apostrophes : on les échappe,
    plutôt que d'inventer un autre style de guillemets pour deux lignes.
    """
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


def render_meta(m):
    return (
        "  meta: {\n"
        f"    slug: '{m['slug']}',\n"
        f"    module: {m['n']},\n"
        f"    title: {js_str(m['title'])},\n"
        f"    tagline: {js_str(m['tagline'])},\n"
        f"    icon: '{m['icon']}',\n"
        f"    story: `{m['story']}`,\n"
        "  },"
    )


def main():
    verifier = '--verifier' in sys.argv
    problemes = []

    for m in MODULES:
        chemin = os.path.join(QUEST, f"m{m['n']}.js")
        if not os.path.exists(chemin):
            problemes.append(f"m{m['n']}.js : fichier absent")
            continue

        texte = io.open(chemin, encoding='utf-8').read()

        if 'story:' not in texte:
            if verifier:
                print(f"m{m['n']}.js : story ABSENTE")
                problemes.append(f"m{m['n']}.js : story absente")
                continue
            debut = texte.index('  meta: {')
            fin = texte.index('  },', debut) + len('  },')
            io.open(chemin, 'w', encoding='utf-8').write(
                texte[:debut] + render_meta(m) + texte[fin:])
            print(f"m{m['n']}.js : meta réécrit")
            continue

        # Déjà en place : on ne relit pas l'intro, on vérifie qu'elle a bien
        # quitté l'ancienne intrigue. Un `story` resté sur le récit de Verdi
        # passe la validation du serveur — celle-ci ne peut pas juger le fond,
        # elle vérifie la forme.
        debut_story = texte.find('    story: `')
        fin_story = texte.find('\n`,\n  },', debut_story)
        story = texte[debut_story:fin_story] if debut_story >= 0 else ''
        restes = [mot for mot in ANCIEN_FIL_ROUGE if mot in story.lower()]
        if restes:
            problemes.append(f"m{m['n']}.js : story encore sur l'ancienne intrigue — {', '.join(restes)}")
        else:
            print(f"m{m['n']}.js : story en place, sur le bon fil rouge")

    if problemes:
        print("\nProblèmes :")
        for p in problemes:
            print(f"  - {p}")
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
