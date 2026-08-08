# MAYDEAD --- PROJECT STATUS

**Document :** État officiel du projet\
**Projet :** MAYDEAD\
**Plateforme :** Roblox\
**Statut :** Préproduction / fondations techniques\
**Date de référence :** 8 août 2026

------------------------------------------------------------------------

## 1. RÔLE DU DOCUMENT

Ce document décrit **l'état réel de MAYDEAD à l'instant présent**.

Il ne décrit pas ce que le jeu devrait contenir à terme.

Pour cela, utiliser :

-   `GAME_DESIGN.md` pour la conception ;
-   `ARCHITECTURE.md` pour l'architecture technique ;
-   `ROADMAP.md` pour l'ordre de développement.

`PROJECT_STATUS.md` répond à une question simple :

> **Qu'est-ce qui existe réellement aujourd'hui dans MAYDEAD ?**

Ce document doit être mis à jour régulièrement au cours du
développement.

Une fonctionnalité ne doit être indiquée comme terminée que lorsqu'elle
existe réellement et a été testée.

------------------------------------------------------------------------

# 2. IDENTITÉ DU PROJET

**Nom officiel :** MAYDEAD

Le nom **MAYDEAD** est désormais définitif et figé pour l’ensemble du projet.

Il est utilisé comme :

- nom officiel du jeu ;
- nom du projet dans VS Code ;
- nom du projet Rojo ;
- nom du dépôt Git/GitHub ;
- nom de l’expérience Roblox.

L’ancien nom de travail **SurvivalIsland** est abandonné et ne doit plus être utilisé dans les nouveaux fichiers, scripts ou documents.

------------------------------------------------------------------------

# 3. CONCEPT ACTUEL

MAYDEAD est un jeu Roblox de :

-   survie ;
-   récolte ;
-   crafting ;
-   construction ;
-   exploration ;
-   production ;
-   coopération.

Le joueur survit après un crash aérien sur un archipel isolé.

L'objectif principal à long terme est de construire un nouvel hydravion
pour quitter l'archipel.

La performance est mesurée principalement par l'**Âge** du personnage au
moment de l'évasion.

Le joueur commence à l'Âge 10.

Un cycle complet jour/nuit représente une année.

Le jeu doit être jouable seul ou en coopération jusqu'à 6 joueurs.

------------------------------------------------------------------------

# 4. PHASE ACTUELLE

Le projet est actuellement en :

# PRÉPRODUCTION / FONDATIONS

La conception générale est suffisamment avancée pour commencer le
développement structuré.

Le développement complet de la boucle de gameplay n'a pas encore
commencé.

------------------------------------------------------------------------

# 5. ENVIRONNEMENT DE DÉVELOPPEMENT

## Roblox Studio

**État : opérationnel**

Une map de départ existe déjà dans Roblox Studio.

Elle comprend notamment :

-   une île principale ;
-   de l'eau autour de l'île ;
-   plusieurs zones naturelles ;
-   des ressources/assets placés pour les premiers essais ;
-   des îles/zones secondaires en cours de réflexion.

La map actuelle constitue une base de travail et n'est pas considérée
comme définitive.

------------------------------------------------------------------------

## VS Code

**État : opérationnel**

Le projet local existe actuellement dans :

``` text
D:\MAYDEAD
```

VS Code doit devenir l'environnement principal pour l'édition du code
Luau.

------------------------------------------------------------------------

## Git

**État : opérationnel**

Version constatée lors de la configuration :

``` text
git version 2.55.0.windows.1
```

Le dépôt local est initialisé.

Branche principale :

``` text
main
```

Le premier commit a été effectué.

------------------------------------------------------------------------

## GitHub

**État : opérationnel**

Le dépôt distant existe et le premier push a été réalisé avec succès.

Remote configuré :

``` text
origin
```

La branche locale `main` suit la branche distante `origin/main`.

------------------------------------------------------------------------

## Rojo

**État : configuration de base réalisée**

Le projet possède :

``` text
default.project.json
```

Arborescence de synchronisation actuellement prévue :

``` text
ReplicatedStorage
└── Shared
    └── src/shared

ServerScriptService
└── Server
    └── src/server

StarterPlayer
└── StarterPlayerScripts
    └── Client
        └── src/client
```

Une vérification complète du workflow Rojo avec Roblox Studio reste à
effectuer avant de commencer les gros systèmes.

------------------------------------------------------------------------

## Aftman

**État : présent dans le projet**

Fichier existant :

``` text
aftman.toml
```

Son utilisation exacte sera conservée simple et documentée au fur et à
mesure.

------------------------------------------------------------------------

## Wally

**État : non intégré / non requis actuellement**

Wally ne sera introduit que lorsqu'une dépendance réelle le justifiera.

------------------------------------------------------------------------

## StyLua

**État : non intégré ou non validé dans le workflow final**

StyLua sera introduit progressivement pour le formatage automatique du
code Luau.

------------------------------------------------------------------------

## Selene

**État : non intégré ou non validé dans le workflow final**

Selene sera introduit progressivement pour l'analyse statique du code
Luau.

------------------------------------------------------------------------

# 6. STRUCTURE LOCALE ACTUELLE

Fichiers/dossiers connus :

``` text
MAYDEAD/
│
├── .gitignore
├── README.md
├── aftman.toml
├── default.project.json
│
├── docs/
│   ├── GAME_DESIGN.md
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   └── PROJECT_STATUS.md
│
└── src/
    ├── client/
    │   └── init.client.luau
    │
    ├── server/
    │   └── init.server.luau
    │
    └── shared/
        └── Hello.luau
```

Les fichiers de documentation suivants doivent encore être ajoutés :

``` text
docs/DEVELOPMENT_RULES.md
AGENTS.md
```

------------------------------------------------------------------------

# 7. FICHIERS LUAU INITIAUX

Les fichiers initiaux créés sont :

``` text
src/client/init.client.luau
src/server/init.server.luau
src/shared/Hello.luau
```

Ils correspondent actuellement au socle du projet Rojo.

Ils ne représentent pas encore l'architecture gameplay finale de
MAYDEAD.

------------------------------------------------------------------------

# 8. DOCUMENTATION CRÉÉE

## GAME_DESIGN.md

**État : créé**

Contient la conception générale validée de MAYDEAD.

Il constitue la source de vérité gameplay.

------------------------------------------------------------------------

## ARCHITECTURE.md

**État : créé**

Contient l'architecture technique cible :

-   client/serveur ;
-   services ;
-   sauvegarde ;
-   réseau ;
-   sécurité ;
-   performances ;
-   organisation du code.

------------------------------------------------------------------------

## ROADMAP.md

**État : créé**

Contient l'ordre de développement jusqu'à la V1 publiable.

Inclut notamment le jalon :

``` text
FIRST PLAYABLE
```

------------------------------------------------------------------------

## PROJECT_STATUS.md

**État : présent document**

Doit être maintenu pendant tout le développement.

------------------------------------------------------------------------

## DEVELOPMENT_RULES.md

**État : à créer**

Doit définir les règles concrètes de travail et de qualité du code.

------------------------------------------------------------------------

## AGENTS.md

**État : à créer**

Doit servir d'instructions prioritaires à Codex pour travailler
correctement sur MAYDEAD.

------------------------------------------------------------------------

# 9. GAMEPLAY ACTUELLEMENT TESTÉ

Avant la structuration définitive du projet, plusieurs essais simples
ont déjà été réalisés directement dans Roblox Studio.

Ces essais concernent notamment :

-   cycle jour/nuit ;
-   récolte ;
-   interactions simples ;
-   météo/pluie ;
-   comportement d'éléments de map.

Ces systèmes sont considérés comme :

# PROTOTYPES / TESTS

Ils ne doivent pas être considérés automatiquement comme des systèmes de
production.

Ils pourront être :

-   conservés ;
-   nettoyés ;
-   réécrits ;
-   remplacés.

La décision sera prise système par système.

------------------------------------------------------------------------

# 10. CYCLE JOUR / NUIT

**Conception : validée**

Référence actuelle :

``` text
Jour  : 10 minutes
Nuit  : 4 minutes
Total : 14 minutes
```

Un cycle complet représente :

``` text
+1 année
```

Âge de départ :

``` text
10 ans
```

**Implémentation de production : non commencée / à reprendre
proprement**

Des tests antérieurs de cycle jour/nuit ont été réalisés, mais le futur
système officiel doit être intégré à l'architecture MAYDEAD.

------------------------------------------------------------------------

# 11. MÉTÉO

**Conception : validée pour la première boucle**

Météos V1 prévues :

-   normal ;
-   pluie ;
-   orage.

Des tests de pluie ont déjà été réalisés sur la map.

Des ajustements ont notamment été nécessaires pour :

-   rendre la pluie plus visible ;
-   couvrir une grande map ;
-   faire suivre l'effet au joueur.

**Implémentation de production : non finalisée**

Le futur système officiel devra séparer :

-   état météo serveur ;
-   conséquences gameplay ;
-   effets visuels client.

------------------------------------------------------------------------

# 12. RÉCOLTE

**Conception : validée**

Ressources principales prévues :

-   bois ;
-   pierre ;
-   métal ;
-   cuivre ;
-   cristal.

Référence actuelle de respawn :

``` text
Arbres ordinaires : ~60 secondes
Minerais ordinaires : ~90 secondes
```

Des tests simples de récolte ont déjà été réalisés.

**Implémentation de production : non finalisée**

Le futur `ResourceService` devra être serveur autoritaire.

------------------------------------------------------------------------

# 13. INVENTAIRE

**Conception : validée**

``` text
Inventaire : 20 slots
Hotbar      : 8 slots
Poids       : aucun
```

Stacks prévus.

Référence initiale pour ressources ordinaires :

``` text
x50
```

**Implémentation : non commencée**

------------------------------------------------------------------------

# 14. OUTILS

**Conception : validée**

Progression :

``` text
Pierre
↓
Métal
↓
Tier avancé
```

Les outils doivent être permanents.

Pas de durabilité punitive.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 15. CRAFT

**Conception générale : validée**

Trois niveaux principaux sont prévus :

``` text
Inventaire joueur
↓
Table de crafting
↓
Usine / stations avancées
```

L'inventaire joueur peut notamment fabriquer :

-   premiers outils ;
-   feu de camp ;
-   Table de crafting.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 16. CONSTRUCTION

**Conception : validée**

Système prévu :

-   fondations ;
-   sols ;
-   murs ;
-   portes ;
-   toits ;
-   snapping ;
-   prévisualisation ;
-   démontage.

Les animaux ne détruisent pas les constructions.

Remboursement prévu lors du démontage volontaire :

``` text
100 %
```

**Implémentation : non commencée**

------------------------------------------------------------------------

# 17. SURVIE

**Conception : validée**

Systèmes prévus :

-   PV ;
-   faim ;
-   soif ;
-   énergie ;
-   oxygène ;
-   noyade ;
-   sommeil.

Référence :

``` text
PV maximum : 100
```

**Implémentation : non commencée**

------------------------------------------------------------------------

# 18. SOMMEIL

**Conception : validée**

Le joueur peut dormir jour ou nuit.

Référence :

``` text
0 % → 100 % énergie ≈ 3 minutes
```

En multijoueur :

-   si tous les joueurs dorment pendant la nuit, passage accéléré
    jusqu'au matin ;
-   un joueur seul ne force pas les autres à dormir.

Dormir dehors peut être dangereux.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 19. DÉCONNEXION SÉCURISÉE

**Conception générale : validée**

Le lit doit avoir une importance particulière avant une déconnexion
volontaire.

Le joueur doit être encouragé à se coucher pour sécuriser son état
gameplay.

**Point encore à finaliser :**

la conséquence exacte d'une déconnexion non sécurisée en cas de :

-   Alt+F4 ;
-   crash Roblox ;
-   coupure Internet ;
-   fermeture volontaire hors lit.

Le système ne doit ni permettre d'exploit ni provoquer de pertes
injustes.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 20. NOURRITURE

**Conception : validée**

Pas de cuisine complexe.

Le joueur peut consommer :

-   légumes ;
-   poisson ;
-   viande.

Viande/poisson crus :

-   consommables ;
-   perte de PV.

Cuisson :

``` text
Feu de camp
Temps de référence : 25 secondes par pièce
```

**Implémentation : non commencée**

------------------------------------------------------------------------

# 21. EAU

**Conception : validée**

Le joueur doit pouvoir :

-   boire ;
-   fabriquer une gourde ;
-   remplir la gourde dans l'eau.

Pas de purification complexe prévue en V1.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 22. AGRICULTURE

**Conception : validée**

Boucle :

``` text
Graines
↓
Bac
↓
Plantation
↓
Eau
↓
Croissance
↓
Récolte
```

La pluie pourra contribuer à l'arrosage.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 23. COMPOST

**Conception : validée**

Mécanique volontairement humoristique.

Boucle :

``` text
Déjections / déchets organiques
↓
Composteur
↓
Compost / engrais
↓
Agriculture
```

Le joueur pourra également utiliser l'action de manière humoristique
envers un autre joueur sans effet de dégâts.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 24. ANIMAUX

**Conception générale : validée**

Île principale :

-   animaux plutôt sûrs/passifs ;
-   un animal attaqué peut devenir hostile.

Autres îles :

-   animaux plus dangereux ;
-   progression du danger selon les ressources.

Océan :

-   requins ou autres prédateurs marins.

Les animaux peuvent fournir notamment :

-   viande ;
-   cuir.

**Espèces exactes : non figées**

**Implémentation : non commencée**

------------------------------------------------------------------------

# 25. PÊCHE

**Conception : validée**

Le joueur pourra pêcher.

Le poisson suit la logique :

``` text
Poisson cru
↓
Feu de camp
↓
Poisson cuit
```

**Implémentation : non commencée**

------------------------------------------------------------------------

# 26. EXPLORATION MARITIME

**Conception : validée**

Progression prévue :

``` text
Île principale
↓
Radeau
↓
Îles secondaires
↓
Bateau avancé éventuel
```

Le radeau doit être nécessaire pour une étape importante de progression.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 27. GUIDE DE FABRICATION

**Conception : validée**

Le joueur pourra consulter les possibilités liées à une ressource ou un
objet.

Exemple :

``` text
BOIS
├── obtenu sur arbres
├── transformé en planches
└── utilisé dans plusieurs crafts
```

Les technologies spéciales restent cachées tant qu'elles ne sont pas
découvertes.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 28. DOCUMENTS TECHNIQUES

**Conception : validée**

Les Documents techniques sont des objets spéciaux de progression.

Lorsqu'un document est trouvé, le joueur doit comprendre immédiatement :

> Il doit être analysé dans une TABLE DE PLANS.

Avant analyse, il reste un objet transportable.

Après analyse, la connaissance devient une progression permanente du
monde.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 29. TABLE DE PLANS

**Conception : validée**

La Table de Plans ne doit pas être craftable dans les premières minutes.

Sa construction nécessite au moins une ressource provenant d'une autre
île.

Elle sert à analyser les Documents techniques.

Son apparence n'a pas besoin d'évoluer visuellement avec la progression.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 30. HYDRAVION

**Conception principale : validée**

Le joueur ne répare pas l'avion du crash.

Il construit :

# UN NOUVEL HYDRAVION

Le nouvel appareil est construit progressivement sur un chantier/support
dédié.

Les composants apparaissent physiquement lorsqu'ils sont installés.

Référence actuelle :

environ 5 Documents techniques majeurs.

Thèmes envisagés :

-   structure ;
-   flottaison ;
-   motorisation ;
-   électricité/commandes ;
-   navigation.

**Recettes exactes : non définies**

**Implémentation : non commencée**

------------------------------------------------------------------------

# 31. ÉVASION

**Conception : validée**

Lorsque l'hydravion est terminé :

-   préparation finale ;
-   embarquement ;
-   départ ;
-   cinématique ;
-   résultat.

Affichage principal :

``` text
ÉVASION RÉUSSIE
ÂGE XX
```

Le joueur peut ensuite :

-   continuer son monde ;
-   recommencer une tentative.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 32. RECORDS

**Conception : validée**

Classements séparés :

-   Solo ;
-   Duo ;
-   Trio ;
-   4 joueurs ;
-   5 joueurs ;
-   6 joueurs.

Critère principal :

``` text
Âge d'évasion le plus faible
```

Temps réel possible comme départage secondaire.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 33. MULTIJOUEUR

**Conception : validée**

Maximum :

``` text
6 joueurs
```

Le créateur du monde choisit les joueurs autorisés.

Un joueur autorisé doit pouvoir reprendre le monde même si le
propriétaire est absent.

Le temps s'arrête lorsque personne ne joue.

Une même sauvegarde ne doit pas être active sur deux serveurs
simultanément.

Objectif :

``` text
3 mondes sauvegardés maximum par joueur
```

sous réserve de validation technique.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 34. MENU PRINCIPAL

**Conception : validée**

Le joueur ne doit pas être envoyé directement dans un serveur aléatoire
déjà avancé.

Flux prévu :

``` text
MAYDEAD
↓
MENU
↓
CRÉER / REPRENDRE / REJOINDRE
↓
MONDE
```

**Implémentation : non commencée**

------------------------------------------------------------------------

# 35. CINÉMATIQUES

**Conception : validée**

Deux cinématiques principales sont prévues :

### Introduction

Crash de l'avion et arrivée sur l'archipel.

### Fin

Décollage du nouvel hydravion et évasion.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 36. MONÉTISATION

**Direction validée**

La monétisation ne doit pas permettre d'acheter directement un meilleur
record.

Direction privilégiée :

-   cosmétiques ;
-   skins ;
-   décorations ;
-   emotes ;
-   personnalisation sans avantage compétitif.

**Implémentation : non commencée**

------------------------------------------------------------------------

# 37. FIRST PLAYABLE

**État : non atteint**

Le First Playable sera atteint lorsque les systèmes fondamentaux
suivants fonctionneront ensemble :

-   temps/âge ;
-   météo ;
-   interactions ;
-   inventaire ;
-   récolte ;
-   outils ;
-   craft ;
-   Table de crafting ;
-   survie ;
-   eau ;
-   nourriture ;
-   sommeil ;
-   mort ;
-   stockage ;
-   construction ;
-   sauvegarde.

Ce jalon est actuellement le premier grand objectif du projet.

------------------------------------------------------------------------

# 38. RISQUES TECHNIQUES IDENTIFIÉS

Les principaux points nécessitant une attention particulière sont :

### Sauvegarde de monde partagé

Plus complexe qu'une sauvegarde individuelle classique.

### Accès sans propriétaire

Le monde doit pouvoir être chargé par un membre autorisé.

### Double instance

Une même sauvegarde ne doit jamais être modifiée simultanément par deux
serveurs.

### Construction persistante

Le nombre de constructions peut devenir important.

### Grande map

Nécessite une attention aux performances et potentiellement à
`StreamingEnabled`.

### Animaux

L'IA doit rester performante.

### Records

Ils doivent être protégés autant que possible contre les exploits.

### Déconnexion sécurisée

La mécanique du lit doit rester juste même en cas de coupure Internet.

------------------------------------------------------------------------

# 39. DÉCISIONS ENCORE OUVERTES

Les points suivants ne sont pas encore définitivement figés :

-   espèces animales exactes ;
-   légumes exacts ;
-   armes exactes ;
-   recettes numériques ;
-   ressources nécessaires à la Table de Plans ;
-   recette du radeau ;
-   détails de l'électricité ;
-   énergie/carburant des générateurs ;
-   emplacement des Documents ;
-   nombre final exact de Documents ;
-   recette complète de l'hydravion ;
-   rôle exact du cristal ;
-   conséquences précises d'une déconnexion non sécurisée ;
-   fonctionnement technique final des serveurs de monde ;
-   détails de monétisation ;
-   équilibrage final.

Codex ne doit pas choisir arbitrairement ces décisions.

------------------------------------------------------------------------

# 40. PROCHAINE ÉTAPE DOCUMENTAIRE

Documents restant à créer immédiatement :

``` text
docs/DEVELOPMENT_RULES.md
AGENTS.md
```

Après leur création, la documentation initiale MAYDEAD sera considérée
suffisamment complète pour commencer le développement structuré.

------------------------------------------------------------------------

# 41. PROCHAINE ÉTAPE TECHNIQUE

Une fois la documentation terminée :

1.  vérifier l'état Git ;
2.  vérifier Rojo ;
3.  vérifier la synchronisation avec Roblox Studio ;
4.  identifier les scripts prototypes existants ;
5.  décider lesquels conserver ou supprimer ;
6.  commencer le premier système officiel.

Premier système prévu :

# TIME SERVICE + CYCLE JOUR/NUIT + ÂGE

Puis :

# WEATHER SERVICE

------------------------------------------------------------------------

# 42. RÈGLE DE MISE À JOUR

Ce fichier doit évoluer avec le projet.

Lorsqu'un chantier est terminé :

-   passer son état à `TERMINÉ` ;
-   indiquer les fichiers principaux concernés ;
-   indiquer les tests réalisés ;
-   noter les limitations restantes.

Lorsqu'un système est seulement partiellement fonctionnel :

ne pas écrire `TERMINÉ`.

Utiliser :

``` text
NON COMMENCÉ
EN COURS
PROTOTYPE
À TESTER
TERMINÉ
BLOQUÉ
```

------------------------------------------------------------------------

# 43. ÉTAT GLOBAL AU 8 AOÛT 2026

``` text
Nom du jeu                 : MAYDEAD
Concept                     : VALIDÉ
Game Design                 : V1 DOCUMENTÉ
Architecture                : V1 DOCUMENTÉE
Roadmap                     : V1 DOCUMENTÉE
Projet VS Code              : CRÉÉ
Git                         : OPÉRATIONNEL
GitHub                      : OPÉRATIONNEL
Rojo                        : BASE CONFIGURÉE
Map Roblox                  : PROTOTYPE AVANCÉ
Gameplay de production      : NON COMMENCÉ
First Playable              : NON ATTEINT
Multijoueur persistant      : NON COMMENCÉ
Hydravion                   : CONCEPTION VALIDÉE
Publication                 : FUTURE
```

------------------------------------------------------------------------

# 44. OBJECTIF ACTUEL

L'objectif n'est pas encore de construire immédiatement toutes les
fonctionnalités de MAYDEAD.

L'objectif actuel est :

# TERMINER LES FONDATIONS DU PROJET

puis commencer une implémentation propre, système après système,
jusqu'au :

# FIRST PLAYABLE

------------------------------------------------------------------------

# FIN DU DOCUMENT

**MAYDEAD --- Project Status V1**

Ce document représente l'état réel connu du projet au 8 août 2026.
