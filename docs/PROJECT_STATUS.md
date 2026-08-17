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

La performance est mesurée principalement par le nombre d'**années passées
sur l'archipel** au moment de l'évasion.

Le monde commence à l'Année 0.

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

## Fonctionnalités actuellement implémentées

- Service serveur de temps autoritaire avec YearsOnIsland, période Jour/Nuit et
  progression du cycle.
- Premier HUD officiel MAYDEAD affichant l'année sur l'archipel, la période
  actuelle et un indicateur visuel du cycle.
- Service serveur de survie autoritaire pour Santé, Faim, Soif, Énergie
  et apnée, avec dégâts progressifs de noyade.
- HUD de survie compact en colonne affichant Energy, Health, Hunger et
  Thirst, avec capsule Breath contextuelle sous l'eau.
- Premier système d'inventaire serveur autoritaire avec 20 slots, stacks
  et objets initiaux de test.
- Interface client d'inventaire en grille avec 8 slots d'accès
  rapide et ouverture par touche B.
- Interface responsive et conçue pour servir de base visuelle aux futurs
  écrans du jeu.

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
Jour  : 13 minutes
Nuit  : 4 minutes
Total : 17 minutes
```

Un cycle complet représente :

``` text
+1 année
```

Année de départ :

``` text
ANNÉE 0
```

**Implémentation de production : TERMINÉ — VALIDÉ STUDIO**

`TimeService` est autoritaire. Il conserve le champ persistant legacy
`Age` du schéma V1 et expose `YearsOnIsland = Age - 10`. Pour un snapshot
historique sans `CycleTimingVersion`, les secondes déjà écoulées et la phase
Jour/Nuit sont préservées lors du passage 10 + 4 vers 13 + 4 minutes.

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

**Implémentation : À TESTER**

Une récolte V1 serveur autoritaire gère les quatre modèles Test, valide
l'outil actif, la distance, le cooldown et la capacité d'inventaire, puis
attribue le loot via `InventoryService`. Tree et Stone acceptent aussi une
récolte immédiate à mains nues limitée à une ressource par nœud. Balance outil actuelle : Tree 100 PV / Wood x8 / 60 s,
Stone 100 PV / Stone x6 / 75 s, Metal 125 PV / RawMetal x4 / 120 s,
Crystal 150 PV / Crystal x3 / 180 s.

------------------------------------------------------------------------

# 13. INVENTAIRE

**Conception : validée**

``` text
Inventaire principal : 20 vrais slots
Accès rapide         : 8 vrais slots (indices logiques 21 à 28)
Total joueur         : 28 vrais slots
Touches PC           : 1 à 8
Poids                : aucun
```

Stacks prévus.

Référence initiale pour ressources ordinaires :

``` text
x50
```

**Implémentation : À TESTER**

Les 28 slots utilisent une source de vérité serveur unique. Les huit slots
rapides sont de vrais `ItemStack`, déplaçables, fusionnables et échangeables
avec les slots principaux sans duplication. La validation visuelle PC/mobile
reste à effectuer dans Roblox Studio.

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

**Implémentation : À TESTER**

Les items `StoneAxe` et `StonePickaxe` équipent respectivement les Tools
Studio existants `Axe` et `Pickaxe` lorsqu'ils sont sélectionnés depuis
les huit slots rapides. Les animations présentes sont réutilisées avec un
mouvement court de fallback.

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

**Implémentation : À TESTER**

Une première chaîne V1 est implémentée :

-   recettes partagées `Basic` et `Workbench` ;
-   interface de fabrication intégrée à l'inventaire ;
-   validation serveur et transaction atomique sur les 28 slots réels ;
-   crafts Basic `StoneAxe`, `StonePickaxe`, `CraftingTable` et
    `Campfire` avec valeurs temporaires de test validées pour cette passe ;
-   recettes Workbench de construction `Ceiling`, `Wall`, `WindowWall` et
    `DoorWall`, réservées à une Table de crafting placée et proche ;
-   placement serveur autoritaire V1 de `CraftingTable` et `Campfire`,
    avec preview des modèles officiels et clones autoritaires depuis
    `ServerStorage.AssetImports` ;
-   interaction `E` / tactile sur la Table de crafting placée.
-   inventaire runtime propre à chaque station placée : 12 slots pour la
    Table de crafting, 2 slots Fuel et 4 slots Cooking pour le Campfire ;
-   les crafts Workbench consomment exclusivement le stock de la table et
    déposent leur résultat dans l'inventaire joueur ;
-   transferts serveur joueur ↔ station, partagés entre les joueurs proches.

La validation PC, mobile et multijoueur dans Roblox Studio reste requise.

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

**Implémentation : À TESTER**

La Construction V1 utilise `Ceiling` comme pièce horizontale unique :
fondation au sol, plancher adjacent ou plancher d'étage. Les murs se
snappent sur ses quatre bords et les emplacements sont validés par le
serveur. L'ancien item Foundation est retiré du gameplay. Les previews
locales utilisent les modèles officiels normalisés depuis
`ServerStorage.AssetImports`. Le démontage et les permissions avancées
restent à développer; la persistance géométrique V2 est `À TESTER`. La validation Studio du snapping et
des pivots réels reste requise.

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

**Implémentation : À TESTER**

Implémenté :

-   état serveur autoritaire `Breath` de 100 à 0 ;
-   détection de la tête dans l'eau Terrain ;
-   récupération de l'air hors de l'eau ;
-   dégâts progressifs de noyade à zéro ;
-   capsule Breath contextuelle dans le HUD client ;
-   HUD compact disposé verticalement à gauche ;
-   interaction contextuelle PC/mobile pour boire près de l'eau Terrain ;
-   validation serveur de la distance, du cooldown et de la position hors de l'eau.

Valeurs temporaires de test :

``` text
BREATH_DURATION = 15 secondes
BREATH_RECOVERY_DURATION = 5 secondes
DROWNING_DAMAGE_PER_SECOND = 10
DRINK_COOLDOWN = 1 seconde
DRINK_INTERACTION_DISTANCE = 8 studs
```

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

**Implémentation : À TESTER**

Fondation V1 implémentée :

-   définition extensible des aliments via `Category = Food`,
    `Consumable` et `HungerRestore` ;
-   `CookedMeat` restaure 40 Hunger et accorde 45 Energy ;
-   consommation serveur autoritaire depuis le slot rapide actif ;
-   retrait d'une unité après restauration validée ;
-   interaction `F` sur PC et bouton contextuel `MANGER` sur mobile.

Prototype Campfire à tester : `RawMeat` peut être stocké dans la zone
Cooking et transformé en `CookedMeat` lorsque du Wood est disponible dans
Fuel. Valeurs temporaires de cette passe : 20 secondes de combustion par
Wood et 10 secondes de cuisson par unité. La référence finale de cuisson
du GDD reste à réconcilier après playtest.

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

**Première espèce V1 : Bison**

**Implémentation : À TESTER**

- Spawn piloté directement par Workspace.BisonSpawns (marqueurs BasePart ou Model) et template cloné depuis ServerStorage.AssetImports.Bison.
- Humanoid 100 PV ; Axe 25 dégâts ; Pickaxe 20 dégâts ; portée et cooldown validés serveur.
- Coup final : RawMeat x6, uniquement si la capacité inventaire permet de sécuriser toute la récompense.
- Verrou de mort, corps supprimé après 4 secondes et respawn après 300 secondes.
- AI conservée sans réécriture ; scripts nommés Animate désactivés sur les clones pour neutraliser les AssetIds incompatibles, à valider dans Studio.

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
XX ANNÉES
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
Nombre d'années d'évasion le plus faible
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

-   temps/années sur l'archipel ;
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

# TIME SERVICE + CYCLE JOUR/NUIT + YEARS ON ISLAND

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

## FINAL FACTORY INTERACTION HOTFIX V1

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- Cause LootCard : `_createCard` bouclait tant que plus de trois cartes existaient, mais `_removeCard` ne retirait la carte de la file qu'après son tween; les itérations suivantes ciblaient indéfiniment la même carte déjà `Removing`. Le retrait de file est désormais synchrone et l'animation reste asynchrone.
- Cause interaction : le prompt utilisait `Factory.InteractionPoint`, tandis que `StationService` validait la distance contre le pivot du grand modèle. La validation serveur utilise désormais `InteractionPoint` (`Attachment.WorldPosition` ou `BasePart.Position`) avec fallback au pivot.
- Flux officiel unique : `FinalFactoryPrompt.Triggered -> StationService:OpenStation -> StationOpened -> StationController`, qui ouvre l'inventaire joueur et les deux slots Factory.
- Des logs Studio ciblés couvrent Triggered, envoi remote, réception client et visibilité effective de l'interface.
- Les contrôleurs sont déjà démarrés sous `xpcall` indépendants; LootCard démarre après Inventory, Station et FactoryStatus et son timeout ne bloquait donc pas leur initialisation.
- Aucun changement de persistence, DataStore, recette, Boat, Naval Seaplane ou endgame.

## FINAL FACTORY INVENTORY TRANSFER V1

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- La FinalFactory réutilise `StationService` et `StationController` pour les transferts joueur/station existants : drag d'une unité, pile complète, demi-pile, clic long et gestes tactiles.
- Son inventaire partagé possède deux slots dédiés : `MetalPanelStack` puis `PlasticPanelStack`, avec une capacité de 50 unités par slot.
- Le serveur valide la structure, le type de station, la distance, le slot, l'ItemId, la quantité et la capacité avant mutation et réplication à tous les viewers.
- L'assemblage consomme exclusivement `MetalPanelStack x40` et `PlasticPanelStack x30` depuis les slots Factory et conserve les surplus.
- Les slots sont persistés dans `Factory.State.StationState`; un ancien état sans inventaire Factory démarre avec deux slots vides sans migration destructive.
- La recette, Boat, le template `ServerStorage.AssetImports.Factory.FinalFactory` et l'endgame sont inchangés.

## FINAL FACTORY STORAGE / ASSEMBLE HOTFIX V4

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- Le clic `ASSEMBLER` et son Remote étaient déjà fonctionnels ; le serveur recevait la bonne `StructureId`, mais le diagnostic observé lisait encore `Metal=0` et `Plastic=0`.
- `StationService.data.Slots`, indexé par l'instance portant la `StructureId`, est l'unique stockage serveur de la FinalFactory. Les transferts joueur ↔ Factory, le snapshot UI et `FactoryService:_startFinalBuild` utilisent ce même état autoritaire.
- Les transferts vers la Factory journalisent en Studio la requête client puis les quantités serveur avant/après mutation, et le snapshot officiel expose désormais `StructureId`, métal, plastique, état, progression et completion.
- Le rendu distingue les contrôles spécifiques FinalFactory des layouts de station ordinaires. Une interface Studio préexistante pendant un hot reload peut omettre ces contrôles sans produire l'erreur `attempt to index nil with 'Visible'`.
- La recette `MetalPanelStack x40` / `PlasticPanelStack x30`, le temps de production, les DataStores, WorldId, StructureId, Boat, Cheetah et world membership sont inchangés. Aucun reset ou migration destructive.

## FINAL FACTORY ASSEMBLE BUTTON REGRESSION FIX V5

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- Cause : le rendu V4 ne synchronisait que `TextButton.Active` avec un calcul local dépendant du snapshot, tandis que `GuiButton.Interactable` n'était pas piloté explicitement. Un rendu initial sans snapshot pouvait laisser l'état d'entrée du bouton désactivé malgré un snapshot ultérieur valide.
- L'unique `FactoryAssembleButton` est créé une fois dans `_build()` et conserve son unique connexion `Activated`, compatible souris, tactile et manette, pendant tous les renders et toutes les ouvertures.
- `canAssemble` utilise exclusivement le snapshot serveur courant : `BuildState == "Idle"`, `Completed ~= true`, `MetalPanelStack >= RequiredMetalPanelStack` et `PlasticPanelStack >= RequiredPlasticPanelStack`.
- Chaque snapshot FinalFactory reçu relance `_render()` et synchronise immédiatement `Active`, `Interactable`, `Selectable`, style et texte. Le passage 39/30 → 40/30 active donc le bouton sans fermer l'interface; le retrait inverse le désactive.
- Les logs Studio ciblés exposent l'instance réelle et les changements significatifs du calcul. Aucun polling par frame et aucun double binding ne sont ajoutés.
- Le serveur reste autoritaire. Recette, build time, DataStores, WorldId, StructureId, Naval Seaplane, Boat, Cheetah, Worlds et membership sont inchangés.

## NAVAL SEAPLANE OUTPUT ALIGNMENT FIX V5

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- `FinalFactory.ItemOutput` reste l'unique repère de sortie. L'orientation finale utilise son repère local avec un offset Y de `+90°`; aucune orientation monde n'est codée en dur.
- Le clone est d'abord placé avec son orientation finale, puis sa bounding box orientée est mesurée. Son point bas réel est aligné sur la face supérieure d'`ItemOutput` avec un epsilon vertical de `0,05` stud.
- Le centre X/Z de cette même bounding box est aligné sur le centre configuré d'`ItemOutput`; les offsets locaux X/Z restent à zéro.
- Le calcul de la face supérieure supporte la rotation de la Part en projetant ses demi-dimensions sur l'axe vertical monde. Une Factory tournée entraîne donc naturellement l'orientation et le centrage du Naval Seaplane.
- L'ancrage temporaire de 0,25 seconde, la restauration exacte des états physiques, l'idempotence du spawn et la restauration du `FinalPlanePivot` sauvegardé restent inchangés.
- Aucun modèle source, schéma de persistence, DataStore, WorldId, StructureId, recette, temps de production ou contrôle de vol n'est modifié.

## NAVAL SEAPLANE TRUE CONVEYOR GROUNDING FIX V6

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- Le yaw final remplace celui de V5 et vaut désormais `180°` dans le repère local d'`ItemOutput`; il n'est ni cumulé avec l'ancien `+90°`, ni exprimé dans le repère monde.
- La hauteur d'`ItemOutput` n'est plus traitée comme le sol. Un raycast vertical filtré exclusivement sur la FinalFactory ignore le marqueur lui-même et fournit la vraie surface du convoyeur située dessous.
- Après orientation, le minimum Y physique est calculé sur les extents orientés de toutes les `BasePart` visibles du clone. Les descendants non géométriques et les parts techniques entièrement transparentes sont exclus; les petites roues et autres pièces visibles restent incluses.
- Le placement s'effectue en deux passes : orientation/centrage X-Z, puis translation verticale `SurfaceY - LowestPhysicalY + 0,03`. Une seconde mesure journalise la différence finale attendue de `0,03` stud.
- En Studio, un contrôle différé d'une seconde compare le pivot final au pivot courant et le point bas courant afin de distinguer une erreur de placement d'un déplacement ultérieur causé par la physique du véhicule.
- Le modèle source, les états `Anchored` originaux, le pilotage, le `FinalPlanePivot` sauvegardé, le schéma de persistence, les DataStores, WorldId, StructureId, recette et temps de production restent inchangés.

## NAVAL SEAPLANE OUTPUT ALIGNMENT FIX V7

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- La rotation demandée ajoute `+90°` à l'orientation V6 de `180°` : le yaw configuré final vaut donc `270°` dans le repère local d'`ItemOutput`, sans orientation monde absolue.
- Le raycast V7 n'accepte plus n'importe quelle géométrie de la FinalFactory : il descend sous `ItemOutput`, ignore le marqueur et les obstacles intermédiaires, puis exige une `BasePart` taguée `FactoryConveyor` ou située sous une hiérarchie `Conveyor`/`Conveyer`.
- Le contact privilégie désormais le minimum Y orienté des `BasePart.CanCollide`, y compris les hitboxes transparentes. Cela évite qu'une collision technique plus basse que les meshes visibles pénètre le convoyeur au relâchement physique et fasse remonter tout le véhicule.
- En absence exceptionnelle de pièce collisionnable, le minimum visible reste un fallback diagnostiqué. Les logs indiquent le mode de contact, le nombre de colliders, les colliders non ancrés, le bas visible, le bas collisionnable et la différence avec la surface.
- Aucune propriété `CanCollide`, `Anchored`, weld, contrainte, vitesse ou script du Naval n'est remplacée. Les collisions et états d'ancrage du template sont conservés afin que la friction du convoyeur existant puisse entraîner un véhicule physique compatible.
- Le modèle source, le spawn unique, le `FinalPlanePivot`, le pilotage, la recette, le temps de production, l'inventaire Factory, les DataStores, WorldId et StructureId restent inchangés.

## BOAT WATER PLACEMENT + CHEETAH INPUT RESTORE V1

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- `Boat` déclare désormais `PlacementSurface = "Water"`. Le preview et le serveur exigent `Workspace.Terrain` avec `RaycastResult.Material == Water` au centre et aux quatre points principaux de son footprint; terre, sable, constructions et placements côtiers partiels sont refusés.
- La surface renvoyée par le raycast existant reste le plan de placement : la bounding box normalisée du Boat est posée dessus par la formule de placement existante. Rotation, scripts internes, collisions, contraintes, propulsion, steering, network ownership et persistence sont inchangés.
- En monture Cheetah sur PC, `MouseButton1` envoie désormais l'intention serveur `MountJump`. La connexion existe uniquement pendant `Mounted` et est supprimée au dismount, respawn ou unload.
- `JumpRequest` ne transforme plus le clavier/Espace en saut de monture. Il reste utilisé uniquement pour préserver les contrôles tactiles et manette existants; le saut Roblox natif peut donc de nouveau libérer le `Seat`, dont le watcher serveur exécute le démontage normal. Le binding explicite `E -> Dismount` existant reste inchangé.
- ZQSD/WASD, flèches, Shift, hauteur/cooldown/coût du saut, vitesses, UI mobile, taming, Follow/Stay, DataStores et schémas persistants sont inchangés.

## FINAL FACTORY TEMPLATE REFERENCE FIX V1

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- L'ItemId et le `StructureType` restent `Factory`; le nom affiché et l'icône sont inchangés.
- Le Folder source reste `ServerStorage.AssetImports.Factory`.
- Le modèle placeable est résolu strictement par `TemplateFolder = "Factory"` et `TemplateName = "FinalFactory"`, soit `ServerStorage.AssetImports.Factory.FinalFactory`.
- Le resolver exige un `Model` et n'utilise pas de recherche récursive de secours pour les chemins explicitement imbriqués.
- Aucun schéma, StructureId, DataStore, état Factory ou recette n'est modifié.
- `AutomaticLoader`, `Recycler`, `IndustrialPress`, Boat et Naval Seaplane sont inchangés.

## FINAL GAMEPLAY LOOP V1

Statut officiel : `VALIDÉ PAR LE GAME DIRECTOR`.

Implémenté statiquement : recettes Boat/Factory, placeables, inventaire Factory partagé, production Naval Seaplane 60 s, persistence intermédiaire, garde anti-double-build, spawn relatif à ItemOutput, état global de completion, continuation du monde, record d'évasion minimal, record de longévité maximal et grant strictement Studio.

Validation réelle obtenue : présence et comportement des assets Boat, Naval Seaplane et FinalFactory, pilotage, placement aquatique, matérialisation, scénario à deux joueurs et reload dans le périmètre du chantier final.

## MOBILE/TABLET INVENTORY + FISHING + FURNACE POLISH

Statut : `À TESTER STUDIO`

- Dans une interface joueur ↔ station ouverte, un maintien tactile de 0,5 seconde transfère la pile complète via les modes `FULL_STACK` et les remotes existants de `StationService`. Le seuil tactile de mouvement est centralisé à 14 pixels : son dépassement annule le maintien et démarre le drag, ce qui protège le scroll. Un contour cyan progressif fournit le feedback discret. Les contrôles souris PC restent sur leur chemin existant.
- L'ancien bouton tactile contextuel de pêche a été retiré au profit du toucher direct sur l'eau décrit dans `FISHING TOUCH WATER INPUT V1`.
- Le template runtime `Smelt`, résolu depuis `ServerStorage.AssetImports.Smelt`, reçoit une seule normalisation `AutoVertical` au chargement : la rotation orthogonale minimale donnant la BoundingBox la plus haute est conservée dans les métadonnées de placement. Le calcul de hauteur au sol et le yaw choisi par le joueur continuent d'utiliser la géométrie Building existante. Les nouveaux placements et leurs sauvegardes utilisent cette orientation ; aucune migration automatique risquée n'est appliquée aux anciens pivots sauvegardés.
- La destruction serveur existante de `BuildingService` accepte désormais la pioche uniquement pour `Smelt`, tout en conservant la hache pour les autres structures. Le four possède 100 points de structure : pioche 10 dégâts (environ 10 coups), hache 5,5 dégâts (environ 19 coups). Outil réellement équipé, ItemId actif, propriété, portée et cooldown restent validés côté serveur.
- La convention de sécurité station existante est conservée : un four contenant minerai, fuel ou output, ou encore actif, refuse le dernier coup avec `StationNotEmpty`. Il doit être vidé et arrêté avant restitution du placeable ; ainsi aucun contenu n'est supprimé, aucun output tardif n'est produit et aucune duplication n'est introduite. Lors d'une destruction autorisée, `UnregisterStation` coupe les Smoke/Fire/ParticleEmitter/Light/Sound et retire immédiatement le four du traitement.
- Validation Roblox Studio mobile, tablette, PC, solo, multijoueur et save/load obligatoire avant passage à `TERMINÉ`.

## FISHING TOUCH WATER INPUT V1

Statut : `À TESTER STUDIO`

- Avec `TouchEnabled` et `Fishing_Rod` équipée, un tap court directement sur l'eau construit un rayon caméra depuis la position écran touchée. Le premier impact doit être `Terrain Water`; terre, roche, bâtiment ou autre obstacle interposé annule silencieusement le lancer.
- Le tap est validé à la fin du contact avec une tolérance centralisée de 16 pixels et une durée maximale de 0,5 seconde. Un déplacement supérieur annule le lancer, ce qui laisse les drags caméra fonctionner. Une seule touche est suivie à la fois.
- Les touches marquées `gameProcessed` sont ignorées au début et à la fin : hotbar, inventaire, menus, UI Companion, joystick et contrôles Roblox ne demandent aucun cast.
- Le contrôleur réutilise exclusivement `StartCast`, `StopCast` et `FightInput`. Le tap eau ne démarre que l'état `Idle`; un tap court valide `CastMinigame`, puis un maintien tactile pilote le même `FightInput(true/false)` que le clic PC. Les instructions du minijeu s'adaptent au tactile sans modifier sa difficulté ni sa dynamique.
- La portée reste `FishingConfig.MaxCastDistance = 45`. Le serveur revalide session active, canne et visuel réellement équipés, absence de session Fishing, distance racine-cible et eau Terrain par son raycast vertical existant.
- La pêche est désactivée lorsque le Humanoid occupe `CheetahMountSeat`, côté client et serveur, afin de préserver l'action de saut montée. Déséquipement, respawn, ReturnToMenu et fin de session annulent le touch suivi sans créer de connexion supplémentaire.
- L'ancien bouton `MAYDEAD_MobileFishing` et son binding `ContextActionService` sont supprimés. Le clic souris PC, le visuel de canne, les récompenses et tous les paramètres du minijeu restent inchangés.

## HOTFIX LEGACY COOKING PERSISTENCE

Statut : `À TESTER STUDIO / PROD`

- Cause exacte : `StationService:RestorePersistentState` validait chaque item de `Campfire.CookingSlots` avec la règle de dépôt des seules entrées. Or le Campfire transforme `RawMeat` en `CookedMeat` et `Fish_Common` en `CookedFish` dans ces mêmes slots, puis les sauvegarde. Une sortie cuite légitime produisait donc `IncompatibleCooking` au restore.
- `BuildingService:RestorePersistentSnapshot` convertissait ensuite ce refus local en `InvalidStructureState`, vidait toutes les structures runtime et faisait échouer `WorldService:Load`; le monde entier devenait inaccessible alors que sa géométrie et ses inventaires étaient valides.
- Le format Campfire passe de `StateVersion = 1` à `StateVersion = 2`. Le format V2 conserve `FuelSlots`, `CookingSlots`, `IsLit`, `BurnRemaining` et `CookProgress`, mais le loader distingue désormais les entrées et sorties prouvées par `StationConfig.CAMPFIRE_RECIPES`. Les états V1 et V2 restent acceptés.
- Migration sûre : une sortie configurée présente dans un état V1 est acceptée sans déplacer ni modifier aucun item. Le prochain save normal écrit naturellement la V2. Un log `[MAYDEAD][PERSISTENCE][MIGRATION]` fournit StructureId, type et action.
- Fallback ciblé : si `CookingSlots` contient un ItemId réel et une quantité structurellement valides mais non associés aux recettes actuelles, tous les slots Cooking et Fuel sont conservés exactement. Seuls `IsLit`, `BurnRemaining` et `CookProgress` sont remis à zéro. Le même fallback s'applique à ces champs transitoires s'ils sont hors bornes. Un log `[RECOVERY]` indique StructureId, type, champs et raison.
- Les slots mal formés, ItemId inconnus, quantités invalides, versions non supportées, StructureId/pivots/types essentiels invalides et autres corruptions structurelles restent bloquants. Aucun échec n'est transformé globalement en succès silencieux.
- Un résumé non spammy journalise `StructuresLoaded`, `StructuresRecovered` et `StructuresFailed`. Aucun DataStore, clé PROD, monde, structure ou item n'est supprimé ou réécrit directement par ce hotfix.
- Fichiers du hotfix : `src/server/Services/StationService.luau`, `src/server/Services/BuildingService.luau` et `docs/PROJECT_STATUS.md`. Validation Studio des états V1/V2 et validation finale après publication sur le monde PROD concerné obligatoires.

## Chantier GardenPlot / Tomato / Chest

Statut : `À TESTER`

- GardenPlot placeable et croissance Tomato en quatre stages sur 60 secondes ajoutés côté serveur.
- Récolte atomique Tomato x3 et consommation TomatoSeed x1 ajoutées.
- Chest placeable avec stockage serveur indépendant de 30 slots ajouté.
- Transferts joueur/coffre réutilisent les règles SINGLE/FULL_STACK de StationService.
- Alignement QuarterCircleWall basé sur deux repères d’extrémités partagé client/serveur.
- Validation Roblox Studio encore obligatoire ; aucune validation visuelle déclarée.
- Hotfix nourriture `À TESTER` : Tomato et RawMeat utilisent la consommation générique serveur ; RawMeat inflige 20 dégâts, CookedMeat donne Hunger +40 / Energy +45, et la cuisson Campfire reste à 10 secondes.
- Polish stations / WildCrop `À TESTER` : inventaires station en cartes d’icônes avec drag unitaire et Shift+clic stack ; Chest runtime rendu interrogeable ; WildTomato serveur avec récompenses exclusives et respawn 480 secondes.
- Polish inventaires V2 `À TESTER` : composant de slot/grille partagé pour joueur et stations, drag global après seuil de 6 pixels (une unité), Maj+clic pile complète, feedback des cibles et validation serveur des slots explicitement visés.
- Polish inventaire V3 `À TESTER` : MainFrame station 920×560 adaptatif, 20 slots principaux + 8 vrais slots rapides, touches 1–8, déplacement/fusion/swap serveur et migration des anciennes références sans duplication.
- Équilibrage survie V1 historique, remplacé par la référence V2 documentée ci-dessous.

**MAYDEAD --- Project Status V1**

Ce document représente l'état réel connu du projet au 8 août 2026.
# FACTORY V1

Statut : `À TESTER`

- Chaîne serveur autoritaire ajoutée : déchets physiques, chargeur automatique, convoyeurs, recycleur et presse industrielle.
- `MetalWaste`, `PlasticWaste` et `WasteBag` sont non empilables ; le sac fournit une unité métal ou plastique avec une probabilité 50/50.
- Les ratios validés sont 5 déchets pour 1 bloc, puis 10 blocs pour 1 pile de panneaux, avec 15 s et 20 s de traitement respectivement.
- `AutomaticLoader`, `Recycler` et `IndustrialPress` utilisent le système de placement existant ; le chargeur réutilise l'interface station avec 30 slots filtrés.
- Le bootstrap temporaire Factory V1 fournit les trois machines, un `ConveyorStraight` et 20 `MetalWaste` à chaque joueur lorsque `FactoryConfig.ENABLE_TEST_BOOTSTRAP` vaut `true`.
- Validation Roblox Studio solo et multijoueur encore requise, notamment pour confirmer les volumes/orientations des `ItemInput`, `ItemOutput` et surfaces de convoyeur des assets Studio.
- Hotfix placement Factory : `AutomaticLoader`, `Recycler` et `IndustrialPress` utilisent une rotation libre sur 360° par pas de 10°, avec le même index validé côté serveur.
- Hotfix convoyeurs : les descendants `BasePart` des modèles `Conveyor`/`Conveyer` sont enregistrés et tagués automatiquement ; la direction est dérivée de l'axe horizontal local dominant, avec `FactoryDirectionAxis` et `FactoryDirectionSign` comme overrides facultatifs.
- Hotfix convoyeurs physiques : les surfaces ancrées reçoivent une `AssemblyLinearVelocity` locale de 6 studs/s ; la friction Roblox entraîne les objets non ancrés et les personnages en contact, puis cesse naturellement à la sortie du tapis.
- `ConveyorStraight` est déclaré constructible depuis `ServerStorage.AssetImports.Factory.ConveyorStraight`, utilise la rotation Factory de 10° et est fourni à x1 par le bootstrap temporaire.
- Le template `Recycler` utilise la normalisation complète `AutoHorizontal` avant publication de la preview et placement serveur ; l'offset sélectionné est conservé sur le pivot du modèle et combiné au yaw utilisateur.
- Le chargeur de templates recherche désormais le nom exact récursivement dans `ServerStorage.AssetImports` et audite le chemin/classe de `ConveyorStraight`. La preview est publiée uniquement lorsqu'un asset physique réel est trouvé ; aucun fallback géométrique n'est généré.
- Hotfix identification FactoryItem : chaque objet physique reçoit désormais `FactoryItem = true`, `ItemId` et le tag `FactoryItem` sur sa racine runtime. La résolution remonte tous les ancêtres et reste compatible avec l'ancien attribut `FactoryItemId`; un diagnostic unique expose la Part overlapée et la racine retenue.
- Architecture intake Factory V1 définitive : l'ancien scan spatial par machine est supprimé. Dans le Heartbeat central, `_updateConveyorSurfaces()` est immédiatement suivi de `_updateFactoryItems()`, qui compare chaque racine enregistrée aux entrées compatibles (`Recycler`/`IndustrialPress`) avec des rayons configurés de 6 studs, puis exécute une capture atomique vers la file FIFO.
- Équilibrage Factory de production restauré : ratios configurés à 5 déchets pour 1 bloc puis 10 blocs pour 1 pile de panneaux ; les timers restent 15 s et 20 s.
- Polish Factory V1 `À TESTER` : Recycler expose par `E` un panneau lecture seule (état, élément, progression serveur, temps restant, file et compteurs matière/ratio dynamique), ses rouleaux identifiés sous `Shredder` tournent uniquement pendant `Processing`, et les Lights/Particles/Beams/Trails/Sounds existants du Recycler et de la Presse suivent le même état serveur. Rafraîchissement UI : 5 Hz.
- Hotfix polish Factory `À TESTER` : les textures des surfaces `FactoryConveyor` défilent en permanence indépendamment de `Processing`; les effets de production excluent explicitement les descendants `Conveyor`/`Conveyer`. Le panneau d'état partagé accepte désormais Recycler et IndustrialPress, avec compteurs et ratio propres à chaque machine.
- Les IDs d'icônes officiels Factory sont intégrés à `ItemIconConfig` pour l'inventaire, les 8 slots rapides, les stations et le drag ghost.

## FACTORY CRAFTING + BALANCE V1

Statut : `À TESTER`

- Quatre recettes exclusivement `Workbench` sont ajoutées : `ConveyorStraight` (8 `MetalIngot`, 2 `CopperIngot`), `AutomaticLoader` (14 `MetalIngot`, 6 `CopperIngot`, 1 `GoldIngot`), `Recycler` (22 `MetalIngot`, 8 `CopperIngot`, 2 `GoldIngot`) et `IndustrialPress` (26 `MetalIngot`, 10 `CopperIngot`, 2 `GoldIngot`). Chaque craft produit exactement un objet placeable existant.
- Les recettes réutilisent les IDs d'items, icônes officielles et templates existants sous `ServerStorage.AssetImports.Factory`; aucun nouvel asset ni nouveau fallback visuel n'est introduit.
- Le recycleur consomme effectivement 5 unités de matière homogène pour produire 1 `MetalBlock` ou 1 `PlasticBlock`. `WasteBag` conserve son attribution métal/plastique aléatoire existante.
- La presse industrielle consomme effectivement 10 `MetalBlock` ou 10 `PlasticBlock` pour produire respectivement 1 `MetalPanelStack` ou 1 `PlasticPanelStack`.
- Les temps internes restent inchangés : 15 secondes par déchet au recycleur et 20 secondes par bloc à la presse. Files FIFO, sorties en attente, effets, chargeur automatique et convoyeurs restent inchangés.
- `FactoryConfig.ENABLE_TEST_BOOTSTRAP` reste désactivé (`false`). `BalanceConfig.BALANCE_DEBUG` est encore activé (`true`) et devra être traité dans un chantier séparé avant publication.
- Aucun DataStore, `SchemaVersion`, format de sauvegarde, structure persistante ou hook de persistance n'est modifié. Validation Roblox Studio solo et multijoueur obligatoire.

# CAMP + FISHING ROD V1

Statut : `À TESTER`

- `Camp` et `Fishing_Rod` sont intégrés aux définitions d'items, aux icônes officielles et au bootstrap temporaire de test (x1 chacun).
- `Fishing_Rod` utilise l'asset `ServerStorage.AssetImports.Fishing_Rod` comme Tool équipable depuis un vrai QuickSlot.
- `Camp` réutilise le placement serveur existant et devient un repos exclusif, autoritaire serveur, activé/quitté avec E.
- Le repos restaure progressivement Health et Energy en environ 30 secondes de 0 à 100, sans restaurer Hunger/Thirst ni suspendre le monde.
- `CampService` détecte un `SleepPoint`, `BedPoint` ou `RestPoint`; à défaut, il crée un repère runtime sur le Camp et journalise l'absence du repère Studio.
- Validation Roblox Studio solo et multijoueur obligatoire, notamment posture/orientation de l'asset, équipement visuel de la canne et libération du Camp après mort/déconnexion/destruction.

# CHEETAH WILDLIFE V1

Statut : `À TESTER STUDIO`

- `WildlifeService` réutilise le Remote et les validations de combat existants pour détecter `Workspace.CheetahSpawns`, choisir un spawn valide et maintenir au maximum un `Cheetah` actif depuis `ServerStorage.AssetImports.Cheetah`.
- Une IA serveur dédiée utilise les états `IDLE`, `ROAM`, `OBSERVE`, `ALERT`, `FLEE_REPOSITION`, `DEFEND`, `CHASE`, `ATTACK`, `RETURN_HOME`, `DEAD`; elle reste passive avant agression, maintient une menace simple multi-joueur, pathfind à cadence limitée, accélère progressivement et récupère vers sa dernière position terrestre seulement en secours eau.
- Valeurs de test centralisées : 1500 PV, vitesses 9/16/31/42, burst 4 s, dégâts 28–35, attaque spéciale 45, cooldown 1,15 s, mémoire 25 s, respawn 900 s et `RawMeat x20–30` calculé serveur.
- Le runtime inspecte et journalise la hiérarchie, Humanoid, Animator, animations et joints réels de l'asset Studio. Aucun AnimationId n'est inventé; la sélection/validation d'animations ou une locomotion procédurale adaptée au rig reste bloquée jusqu'à cet audit Studio.
- État runtime préparatoire uniquement : `Tamed=false`, `OwnerUserId=nil`, `Trust=0`. Aucun apprivoisement, compagnon, monture ni changement Persistence V3 n'est implémenté.

## CHEETAH LOCOMOTION V1.1

Statut : `À TESTER STUDIO`

- Le clone runtime audite son root, son `Humanoid`, son `Animator`, ses `AnimationController`, ses objets `Animation` et ses joints `Motor6D`/`Weld` avant de démarrer l'IA.
- Aucun `AnimationId` n'est inventé. En l'absence d'animation vérifiable dans le dépôt Rojo, un animateur procédural pilote uniquement `Motor6D.Transform` sur les joints identifiés par les noms réels du rig.
- Les diagonales avant-gauche/arrière-droite et avant-droite/arrière-gauche sont déphasées. Cadence et amplitude utilisent la vitesse horizontale physique réelle : respiration subtile à l'arrêt, walk modéré, trot soutenu et chase/burst dynamique.
- Les poses sont interpolées progressivement. Attack possède une frappe distincte et son impact serveur est retardé de 0,14 seconde ; Hit est une réaction courte et Death conserve la logique existante avec une pose procédurale temporaire.
- Après audit, `ChaseSpeed` reste à 31 studs/s et `BurstSpeed` à 42 : le joueur standard est à environ 16 studs/s et descend jusqu'à 72 % de sa vitesse à énergie nulle. Aucun buff de santé, dégâts, loot, aggro ou résistance n'est appliqué.
- En Studio uniquement, `InventoryService` accorde une seule fois par session exactement `RawMeat x10` après admission dans un monde, si l'inventaire accepte la quantité complète. Le reliquat DEV est retiré de l'export persistant ; aucun grant n'existe lorsque `RunService:IsStudio()` est faux.
- Apprivoisement, Trust, nourriture au sol, adoption, inventaire Cheetah et monture ne sont pas implémentés.

## CHEETAH LOCOMOTION V1.2 — RIG HOTFIX

Statut : `À TESTER STUDIO`

- Cause confirmée dans V1.1 : seuls les `Motor6D` contenant des conventions nominales supposées (`front`, `rear`, `arm`, `leg`) étaient retenus. Un rig aux noms non standards pouvait donc produire zéro articulation animée et continuer à glisser.
- Le clone runtime journalise désormais une fois la hiérarchie complète pertinente : `Humanoid`, `Animator`, `AnimationController`, `Motor6D`, `Weld`, `WeldConstraint`, `Bone`, `MeshPart`, `Part` et `UnionOperation`. Chaque joint expose `Part0`/`Part1`; les Motor6D exposent aussi `C0`, `C1` et `Transform`.
- Le mapping candidat des quatre quadrants ne dépend plus du nom : il utilise la position réelle de `Part1` dans l'espace local du root. Les références sont mises en cache et ne sont pas recherchées à chaque frame.
- En Studio avec `ANIMATION_DEBUG` et `ANIMATION_JOINT_PROBE`, chaque articulation candidate reçoit isolément une rotation de 20 degrés pendant 0,5 seconde puis retrouve exactement sa pose initiale. Les logs permettent de confirmer visuellement le vrai membre déplacé.
- `Motor6D.Transform` et, pour un `Weld` classique, `C0` sont supportés. Les `WeldConstraint` candidats sont uniquement signalés : aucune conversion destructive n'est effectuée avant confirmation visuelle du joint réel.
- La vitesse d'animation utilise le delta horizontal de position du root, filtré dans le temps, plutôt que de supposer que `AssemblyLinearVelocity` représente fidèlement `Humanoid:MoveTo()`. Walk, Trot et Chase utilisent des plages distinctes de cadence et d'amplitude.
- La locomotion reste `À TESTER STUDIO` : le mapping final et une éventuelle conversion ciblée WeldConstraint → Motor6D ne peuvent être déclarés validés sans les logs et l'observation du clone Studio réel.
- `ChaseSpeed = 31`, `BurstSpeed = 42`, combat, eau et grant DEV `RawMeat x10` restent inchangés.

## RAW MEAT WORLD DROP V1

Statut : `À TESTER STUDIO`

- L'ItemId existant `RawMeat` reste la seule source de vérité. Sur PC, `F` conserve strictement la consommation existante et le clic gauche demande désormais au serveur de déposer exactement une unité lorsque RawMeat est le QuickSlot actif.
- Le contrôleur refuse la demande si le gameplay n'est pas actif, si l'inventaire/station est ouvert, si un drag est actif, si une zone GUI interactive reçoit le pointeur, si Roblox marque l'entrée comme traitée, si un champ texte est actif ou si un Tool est équipé.
- `WorldDropService` valide à nouveau session, personnage vivant, QuickSlot serveur, possession, cooldown et surface. Le client ne transmet ni position, ni quantité, ni ItemId libre.
- Le serveur clone exclusivement `ServerStorage.AssetImports.RawMeatWorldModel`, le place à 3 studs devant le personnage après contrôle d'obstacle et raycast sol, puis refuse `Terrain Water`. Le clone stable porte `ItemId = "RawMeat"` et `WorldDrop = true` dans `Workspace.WorldDrops`.
- Un clic retire exactement une unité. Le retrait intervient après préparation du clone et la viande est restaurée si le parentage runtime échoue. Cooldown : 0,25 seconde. Durée de vie : 300 secondes.
- Les drops runtime ne sont ni ramassables ni persistants. Ils préparent seulement un futur chantier d'apprivoisement ; Cheetah, Trust et locomotion ne sont pas modifiés.
- L'asset Studio n'étant pas sérialisé par Rojo, sa classe, son pivot, ses BaseParts, dimensions et propriétés physiques sont audités une fois au démarrage. Chaque clone est normalisé `Anchored=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=true`.

## CHEETAH TAMING V1

Statut : `À TESTER STUDIO`

- `RawMeatWorldModel` est mis à l'échelle au runtime en conservant ses proportions pour obtenir un axe principal de 0,55 stud. Les dimensions originales/finales et le facteur exact sont journalisés depuis l'asset Studio, puis la hauteur au sol est recalculée après scale.
- Chaque drop `AVAILABLE` expose un `ProximityPrompt` serveur `E — RAMASSER`, portée 7 studs. Le serveur réserve atomiquement le drop, valide la capacité puis ajoute exactement `RawMeat x1` avant destruction ; un inventaire plein laisse la viande disponible.
- États atomiques : `AVAILABLE`, `RESERVED_BY_PLAYER`, `RESERVED_BY_CHEETAH`, `CONSUMED`. Joueur et guépard ne peuvent pas consommer simultanément la même unité.
- États Cheetah ajoutés : `INVESTIGATE_FOOD`, `APPROACH_FOOD`, `EAT_FOOD`. La recherche utilise le registre limité de `WorldDropService`, une fois par seconde et dans un rayon de 55 studs, jamais un scan complet de Workspace par frame.
- Approche prudente en Walk/Trot, arrêt à 2,5 studs, observation 2 secondes et consommation 2 secondes. Le combat et l'agression interrompent et libèrent proprement une réservation.
- Distances humaines selon Trust : 16 studs de 0–24, 12 de 25–49, 8 de 50–74 et 5 de 75–99. Gain serveur aléatoire de 8 à 12, cooldown de 90 secondes et pénalité de 25 si le joueur engagé attaque.
- `DroppedByUserId` lie le nourrissage à son auteur. Le premier gain fixe `TamingPlayerUserId`; ensuite, les viandes des autres joueurs peuvent être consommées mais n'accordent aucun Trust.
- À 100 : `Tamed=true`, `OwnerUserId=TamingPlayerUserId` et le propriétaire n'est plus ajouté à la menace. Follow complexe, faim, inventaire, défense et monture ne sont pas implémentés.
- `Trust`, `TamingPlayerUserId`, `Tamed` et `OwnerUserId` sont capturés dans `WorldState.CheetahTaming` par la sauvegarde monde V3 existante et restaurés au spawn. Aucun nouveau DataStore ni nouvelle sauvegarde parallèle.
- La locomotion visuelle Cheetah reportée n'est pas retravaillée dans cette passe.

## CHEETAH SYSTEM V2 COMPLETE

Statut : `À TESTER STUDIO`

- Le délai après un gain de Trust passe de 90 à 80 secondes. Durant ce délai, aucune nouvelle viande n'est ciblée ou consommée ; les drops restants restent disponibles au sol, puis la recherche reprend automatiquement.
- Trust reste serveur autoritaire : 8–12 par nourrissage, paliers 0–24/25–49/50–74/75–99/100, distances humaines 16/12/8/5 studs, ownership verrouillé au premier joueur valide et pénalité de 25 par attaque de ce joueur.
- À 100, le compagnon possède quatre slots acceptant uniquement `RawMeat`, Hunger 100, commande `Follow`, endurance 100 et Owner persistant. Une viande interne restaure 30 Hunger lorsque Hunger tombe à 60 ou moins.
- Hunger descend de 100 à 0 en 55 minutes de gameplay actif. À zéro, le compagnon ne meurt pas ; il ne régénère plus et refuse la monture sous 10. Hors combat avec Hunger > 50, régénération lente de 0,5 PV/s.
- `Follow` vise 7 studs et s'arrête vers 5 ; `Stay` conserve une zone de 10 studs. Owner absent : aucun autre joueur n'est suivi.
- L'interface propriétaire compacte expose santé, faim, endurance, quantité RawMeat, Suivre/Rester, dépôt/retrait d'une viande et Monter. Toutes les actions revalident Owner et inventaires côté serveur.
- La monture utilise un `Seat` runtime invisible soudé au root. WASD envoie une direction normalisée, Shift demande le sprint et E démonte sur le côté. Vitesses 20/30/40 ; endurance 14 secondes de sprint et 22 secondes de recharge. Sous 25 Hunger, le sprint est réduit de 25 % ; à 10 ou moins, le montage est refusé.
- La règle eau et le recovery existants restent prioritaires monté ou non. Aucun combat monté spécialisé n'est ajouté.
- La défense automatique n'attaque aucun voisin, Bison ou joueur par proximité. Le Cheetah se défend lorsqu'il reçoit lui-même une attaque ; l'interception d'une attaque Owner exige une source NPC serveur identifiable et reste à valider avec les futurs NPC hostiles.
- Mort compagnon : `Alive=false`, ownership retiré, aucun gros loot `RawMeat`; le respawn wildlife peut produire un nouveau sauvage. Limitation V2 : un seul Cheetah actif/apprivoisable par monde.
- Persistence monde existante enrichie, sans nouveau DataStore : Version, Exists, Alive, Tamed, OwnerUserId, TamingPlayerUserId, Trust, Health, Hunger, Command, quatre slots, MountStamina et Position. L'inventaire est remplacé au chargement, jamais fusionné.
- Les anciens mondes sans bloc Cheetah utilisent les valeurs par défaut. Autosave, ReturnToMenu, PlayerRemoving et BindToClose réutilisent `WorldService`.
- La locomotion visuelle des pattes reste explicitement hors scope et non finalisée.

## CHEETAH COMPANION INTERACTION HOTFIX

Statut : `À TESTER STUDIO`

- La cause du chevauchement était le `Seat` runtime placé avec un offset codé en dur `(0, 2.2, 0)`. L'unique offset est désormais centralisé à `CFrame.new(0, 3.5, 0.45)` : joueur relevé de 1,3 stud et légèrement repositionné derrière les épaules, sans ancrage ni téléportation par frame.
- Le montage conserve `Seat + WeldConstraint` sur le root. Le Prompt unique `E — INTERAGIR` est désactivé pendant la monte ; `E` devient exclusivement `DESCENDRE`, puis le Prompt est réactivé immédiatement après démontage.
- La descente utilise un offset latéral centralisé de 3 studs et un raycast sol. Une surface eau ou invalide n'est pas utilisée comme point de sortie.
- Follow utilise maintenant une hystérésis : distance désirée 6 studs, suspension d'interaction à 7 ou moins, reprise seulement à 10 ou plus. Dans la zone proche, `MoveTo` est annulé sur la position actuelle ; le Cheetah ne recule donc plus lorsque l'Owner s'approche.
- Après démontage, l'état d'interaction proche est conservé. `Follow` ou `Stay` n'est jamais remplacé par le hotfix.
- Audit collision : le lifecycle de spawn existant conserve uniquement la collision centrale `HumanoidRootPart`/`Torso`; les membres et meshes décoratifs restent `CanCollide=false`. Aucun changement de collision supplémentaire.
- Trust, RawMeat, Hunger, inventaire, vitesses, endurance, eau et persistence restent inchangés.

## CHEETAH INTERACTION E HOTFIX

Statut : `À TESTER STUDIO`

- La régression ne venait pas de Follow : le Prompt persistant était parenté au root interne du Cheetah avec `RequiresLineOfSight` laissé à `true`. Le corps/torse du rig pouvait masquer son propre Prompt malgré une distance Owner correcte.
- L'unique `CheetahCompanionPrompt` reste parenté au root stable, conserve `E — INTERAGIR` et une portée de 8 studs, mais utilise désormais `RequiresLineOfSight=false`.
- Le lifecycle `Enabled` est centralisé : actif uniquement pour un Cheetah apprivoisé à pied, désactivé au début du mount, puis réactivé immédiatement à la fin du dismount. Le Prompt n'est jamais détruit pendant le cycle.
- Le callback serveur revalide `Tamed`, `OwnerUserId` et l'absence de `MountedPlayer` avant d'ouvrir l'UI. Monté, le binding client `E` reste exclusivement réservé au démontage.
- Des diagnostics ciblés `[MAYDEAD][CHEETAH][INTERACT]` exposent Owner, joueur déclencheur, distance, Mounted, PromptEnabled et CanInteract lors d'un trigger, d'un mount et d'un dismount.
- Follow, Stay, Trust, Hunger, inventaire, monture, endurance, eau et persistence restent inchangés.

## CHEETAH INTERACTION SYSTEM REPAIR

Statut : `À TESTER STUDIO`

- Cause structurelle : le Prompt était uniquement créé pendant `_spawnAt`; les transitions Tame/Mount/Dismount supposaient ensuite qu'il existait encore. Si le Prompt était absent, mal parenté ou supprimé, l'ancien helper abandonnait sans le recréer, rendant tous les hotfixs `Enabled` inopérants.
- `WildlifeService:_ensureCheetahInteraction()` est désormais idempotent : il conserve un unique `CheetahCompanionPrompt`, supprime seulement les doublons, le crée s'il manque, le reparente systématiquement à `ai.Root`, reconnecte son trigger lors de la création et réapplique toute sa configuration.
- Configuration garantie : `E`, `INTERAGIR`, `GUÉPARD`, portée 8 studs, `HoldDuration=0`, `RequiresLineOfSight=false`. Le serveur autorise l'UI uniquement à `OwnerUserId`, avec Cheetah `Tamed`, Owner à portée et aucun `MountedPlayer`.
- Lifecycle garanti après Tame, Spawn/Restore, Mount, Dismount et respawn Owner. Un audit toutes les cinq secondes ne fait rien en état normal, mais recrée/réactive un Prompt manquant ou désactivé pour un compagnon à pied.
- Monté, le même Prompt persiste mais reste désactivé et `E` conserve exclusivement Dismount. Après descente, l'état mount est nettoyé puis le Prompt est réparé/réactivé immédiatement.
- Les logs ciblés Studio/runtime exposent raison, Tamed, OwnerUserId, FullName, parent, Enabled, touche, portée, LOS, trigger et ouverture UI sans log par frame.
- Follow, Stay, distances, taming, Trust, RawMeat, Hunger, inventaire, mount offset, stamina, eau et persistence gameplay restent inchangés.

## CHEETAH COMPANION POLISH V1.2

Statut : `À TESTER STUDIO`

- L'UI compagnon existante est restructurée en panneau premium compact : titre/statut, jauges Santé/Faim/Endurance, compteur RawMeat, états actifs Suivre/Rester, action Monter prioritaire et transferts viande. Le bouton Fermer est supprimé.
- À pied, le Prompt E existant toggle la même UI. Elle se ferme automatiquement à 14 studs, au mount, au respawn, à la sortie de session ou si le modèle devient invalide. Monté, E reste exclusivement Dismount.
- Follow ne retombe plus sur un ancien chemin vers une position Owner obsolète : destination rafraîchie toutes les 0,75 seconde, `FOLLOW_CATCHUP` au-delà de 22 studs à 31 studs/s et recalcul forcé après 2 secondes sans progression. Desired/Resume restent 6/10 studs et Stay reste inchangé.
- Le point de mount n'utilise plus l'ancien Y fixe 3,5 : il est calculé depuis le sommet de la BoundingBox runtime du Cheetah, la taille du bassin réel de l'avatar, une marge dos de 0,2 et un offset longitudinal de 0,35. Le système reste un Seat invisible soudé au root.
- Les vitesses montées passent de 20/30/40 à 26/34/40 studs/s. L'endurance et ses durées restent inchangées ; la monture est nettement plus rapide que le joueur standard d'environ 16 studs/s.
- Cause résiduelle possible du blocage après descente : Roblox peut libérer `Seat.Occupant` indépendamment du binding E. Le lifecycle observe désormais `Occupant`, sérialise Dismount avec `Dismounting`, vide `MountedPlayer`, ferme l'UI et répare immédiatement l'unique Prompt.
- Taming, Trust, RawMeat, Hunger, santé, dégâts, combat, loot, eau, inventaire logique, locomotion des pattes et persistence gameplay restent inchangés.

# PC INVENTORY TRANSFER SHORTCUTS

Statut : `À TESTER STUDIO`

- Dans les interfaces joueur ↔ station sur PC : drag réel après 6 px = une unité, Maj + clic gauche = pile complète, Maj + clic droit = `floor(Q / 2)` et clic gauche maintenu 0,45 s sans drag = pile complète. Clic simple et clic droit sans Maj restent sans transfert automatique.
- Le long press est annulé par le drag, la sortie du slot, le release, un rerender ou la fermeture. Une référence d'état consommée garantit une seule transaction par geste.
- Le client transmet uniquement `SINGLE`, `FULL_STACK` ou `HALF_STACK` via `StationRequest`; `StationService` recalcule la quantité depuis le stack serveur et applique capacité, compatibilité et restrictions existantes. QuickSlots hors station, tactile, gamepad et persistance restent inchangés.

# FISHING GAUGE DYNAMIC PASS

Statut : `À TESTER STUDIO`

- La vitesse d'interpolation purement visuelle de la jauge passe de `12` à `13.2`, soit exactement +10 %, pour rendre le poisson, la cible et la progression affichés légèrement plus réactifs sans jitter ni téléportation.
- La difficulté serveur précédemment validée à environ +15 % reste strictement inchangée. Aucune mécanique de pêche, physique, récompense ou interaction n'est modifiée.

# FISHING MINIGAME BALANCE PASS

Statut : `À TESTER STUDIO`

- Difficulté de base du combat augmentée d'environ 15 % sans nouvelle mécanique : accélérations et vitesse maximale du poisson +8 %, intervalles d'impulsion −5 % et zone de suivi −2 %.
- Le contrôle joueur, la durée, le gain/perte de progression, la morsure, les récompenses, l'équipement, le grip, le flotteur et la ligne restent inchangés.

# FISHING ROD GRIP ALIGNMENT FINAL

Statut : `À TESTER STUDIO`

- Le Handle `UnionOperation` est traité selon son axe longitudinal local X. `LineStart` détermine automatiquement si le bout de la canne se trouve vers `+X` ou `-X`; aucune orientation monde capturée dans Studio n'est utilisée.
- Une unique table `FishingConfig.FishingRodGrip` centralise la translation de paume, la rotation locale de calibration, le yaw, l'élévation de 27° et la marge depuis l'extrémité arrière. Le `C1` du Motor6D place la prise près de cette extrémité à partir de `Handle.Size.X`, plutôt qu'au pivot central.
- En Studio, un diagnostic unique à chaque création du visuel expose classe, taille, `PivotOffset`, axes du Handle, position locale de `LineStart`, direction `ROD_FORWARD_AXIS` et C0/C1 calculés. Le Motor6D reste l'unique liaison du visuel vers `RightHand`; aucun repositionnement runtime n'est effectué après son attachement.
- Tool logique, propriétés physiques validées, ligne non physique, grant Studio et boucle de pêche restent inchangés.

# FISHING ROD ORIENTATION + BITE PHYSICS HOTFIX

Statut : `À TESTER STUDIO`

- L'orientation du visuel n'utilise plus une matrice figée dépendante du pivot importé : l'axe local réel `Handle → LineStart` est aligné vers une direction avant, légèrement haute et extérieure centralisée dans `FishingConfig`; la position de prise reste également centralisée.
- La `RopeConstraint` de l'asset reste désactivée pendant le lancer, l'attente, la morsure et le combat. La ligne est rendue par un `Beam` entre les mêmes Attachments, sans liaison mécanique entre le flotteur ancré et l'assembly du Character.
- Les transitions lancer, morsure et reel journalisent ponctuellement les vélocités linéaire et angulaire du `HumanoidRootPart` pour la validation Studio. Aucun état, position ou vitesse du Character n'est modifié par le correctif.

# CRASH_AVION — FRESH CRASH STATE

Statut : `À TESTER STUDIO`

- `Workspace.Crash_Avion` reste une épave permanente. Lors de la première session d'un monde neuf, ses descendants `Fire`, `Smoke` et `ParticleEmitter` sont activés par le serveur ; les sessions suivantes les désactivent sans détruire le modèle ni ses effets.
- L'état `WorldState.CrashIntroCompleted` appartient à la sauvegarde monde existante. Il commence à `false`, passe à `true` au premier autosave ou à la première sauvegarde de fermeture réussie, et reste isolé par `WorldId`. Les mondes historiques sans champ sont considérés comme déjà introduits.
- Une future cinématique pourra utiliser ce même état d'introduction. La récolte/salvage future de certaines pièces est prévue mais n'est pas implémentée et la hiérarchie de l'épave reste intacte.

# FISHING ROD EQUIP PHYSICS HOTFIX

Statut : `À TESTER STUDIO`

- Cause racine : le clone visuel de `ServerStorage.AssetImports.Fishing_Rod` était parenté au Character avant la neutralisation de ses pièces, laissant une fenêtre où collisions, ancrage ou vitesses résiduelles de l'asset pouvaient transmettre une impulsion au personnage.
- Correction : toutes les `BasePart` du Tool logique et du clone visuel sont préparées avant parentage avec `Anchored = false`, `CanCollide/CanTouch/CanQuery = false`, `Massless = true` et vitesses d'assemblage nulles. Aucun état physique du `HumanoidRootPart` n'est modifié.
- Grant de test : Studio uniquement, exactement une `Fishing_Rod` si absente après restauration de l'inventaire. Cette unité DEV est exclue de l'export persistant et le grant reste idempotent pendant la session.
- Correctif renforcé : le Tool équipé est désormais un marqueur logique sans `Handle` ni `BasePart`; l'asset physique complet n'est plus cloné dans Backpack/Character. Le clone visuel unique est nettoyé hors Character, débarrassé de ses anciens joints/actionneurs, puis chaque pièce est soudée au Handle avant l'unique `Motor6D` vers la main. L'appel invalide à `GetConnectedParts()` est supprimé. Des diagnostics ponctuels exposent les vitesses racine aux quatre étapes d'équipement et la configuration physique de chaque pièce pour la validation Studio.

# PÊCHE V1 + CUISSON DU POISSON

Statut : `À TESTER`

- Boucle serveur autoritaire ajoutée : `Fishing_Rod` → mini-jeu de lancer → morsure → combat → `Fish_Common`.
- La canne normalise au runtime `LineStart` et `BobberPoint` autour du `RopeConstraint` existant, sans modification Studio obligatoire.
- Le serveur valide canne équipée, personnage vivant, eau Terrain, portée, session unique, combat et capacité d'inventaire avant la récompense.
- Le flotteur et la corde sont animés vers l'eau ; l'asset officiel `ServerStorage.AssetImports.Fish_Common` est utilisé pour le retour visuel vers le joueur.
- `Fish_Common` → CampFire existant → `CookedFish` réutilise les slots, le combustible et le timer de cuisson de 10 secondes existants.
- `Fish_Common` cru reprend la nutrition/pénalité de `RawMeat`; `CookedFish` reprend les valeurs de `CookedMeat`.
- Validation Roblox Studio obligatoire pour confirmer les références physiques de la canne, le rendu de la corde/flotteur, les deux mini-jeux et la cuisson.

## Hotfix commandes et crafts

Statut : `À TESTER`

- Convention PC officielle appliquée : `E` = interactions monde, `F` = boire/remplir, clic gauche = action de l'outil équipé.
- `Fishing_Rod` démarre et valide le mini-jeu de lancer au clic gauche ; le combat conserve maintien/relâchement du clic gauche.
- `Camp` est craftable à la CraftingTable avec `Wood x10 + Stone x4`.
- `Fishing_Rod` est craftable à la CraftingTable avec la recette temporaire `Wood x6 + Stone x2`, aucune ressource Fibre/Corde n'existant actuellement.
- Le bootstrap de test x1 Camp et x1 Fishing_Rod reste actif et clairement marqué dans `InventoryService`.

## Hotfix orientation canne et accessibilité du combat

Statut : `À TESTER`

- Le `Tool.Grip` de `Fishing_Rod` est normalisé depuis `FishingConfig` lors de la création runtime du Tool, sans modifier les Parts, `LineStart`, `BobberPoint` ou la corde.
- Le combat passe à 15 s, gain 22/s, perte 6/s, zone cible 30 %, accélérations réduites et vitesse verticale plafonnée.
- Les impulsions du poisson et destinations de cible sont espacées et interpolées ; le client interpole également les états serveur à chaque frame.

## Hotfix pêche V1.2

Statut : `À TESTER`

- Le Grip fixe précédent est remplacé par une calibration géométrique unique : axe local réel `Handle → LineStart` aligné sur une direction avant/légèrement haute configurée.
- Après équipement, les diagnostics runtime exposent `RightGrip`, `Rod forward dot` et les distances Handle→Head/Torso ; un dot non positif déclenche un avertissement explicite.
- Difficulté Fish_Common intermédiaire : combat 14 s, gain 19/s, perte 8/s, zone 26,4 %, accélérations/vitesse/impulsions relevées tout en conservant les interpolations.

## Liaison définitive Fishing_Rod

Statut : `À TESTER`

- `Tool.Grip` est réinitialisé et n'est plus la méthode d'orientation de la canne.
- Un `HandGripPoint` Studio existant est prioritaire ; à défaut, il est créé au runtime sur la Part poignée retenue et orienté depuis l'axe réel `Handle → LineStart`.
- Le `RightGrip` standard est remplacé uniquement pour Fishing_Rod par un `Motor6D` alignant `RightGripAttachment` et `HandGripPoint`, puis nettoyé au déséquipement.
- Les diagnostics exposent l'erreur d'alignement, le forward dot et les distances au visage/torse ; validation visuelle Studio obligatoire pour calibrer précisément la position locale de prise si l'asset ne fournit pas son Attachment.

## Recalcul Fishing_Rod HandGripPoint → LineStart

Statut : `À TESTER`

- La rotation finale est désormais calculée à l'équipement depuis l'axe physique `HandGripPoint.WorldPosition → LineStart.WorldPosition` et les vecteurs du HumanoidRootPart.
- Le Motor6D unique superpose l'origine de HandGripPoint à RightGripAttachment et aligne mathématiquement cet axe sur une direction avant, légèrement haute et extérieure.
- La validation post-Heartbeat mesure l'axe final, l'erreur d'alignement, le forward dot et la position locale de LineStart ; seuil cible forward dot ≥ 0,75.

## Calibration manuelle Fishing_Rod

Statut : `PROTOTYPE` — remplacé par la calibration du clone visuel

- Le recalcul automatique HandGripPoint/LineStart est désactivé au profit d'une source unique `FishingConfig.FishingRodGripCFrame` appliquée au C1 du Motor6D de main.
- Un mode temporaire strictement Studio permet de régler translation avec I/K, J/L, U/O et rotation avec Maj + ces touches, par pas de 0,03 stud et 1 degré.
- Chaque ajustement imprime une ligne `FishingRodGripCFrame = ...` prête à reporter dans la config ; le mode devra être désactivé après calibration visuelle finale.

## Calibration définitive Fishing_Rod

Statut : `PROTOTYPE` — remplacé par la séparation Tool logique / clone visuel

- Cette calibration du Handle natif a révélé une interférence avec le système d'équipement `Tool`/`RightGrip` et n'est plus utilisée par le système courant.
- L'attache finale utilise un unique `MAYDEADFishingRodGrip` entre `RightHand` et `Fishing_Rod.Handle`, avec la configuration en C0 et un C1 identité.
- Le mode de calibration Studio, ses raccourcis et ses diagnostics ont été supprimés ; aucun calcul fondé sur `LineStart` ou `BobberPoint` n'oriente la canne.
- Un test Studio reste requis pour valider la posture pendant les rotations, les déplacements et un cycle de pêche complet.

## Séparation Tool logique / clone visuel Fishing_Rod

Statut : `À TESTER`

- Le `Tool` `Fishing_Rod` reste l'autorité logique d'équipement mais n'utilise plus son `Handle` pour l'affichage en main ; ses pièces sont invisibles et non interactives physiquement.
- À chaque équipement, un clone `MAYDEADFishingRodVisual` issu de `ServerStorage.AssetImports.Fishing_Rod` est créé sous le Character et relié de `RightHand` à son `Handle` par l'unique moteur `MAYDEADFishingRodVisualGrip`.
- Le `RightGrip` natif de ce Tool est supprimé, et `LineStart`, `BobberPoint` ainsi que le `RopeConstraint` utilisés par la pêche proviennent désormais du clone visible.
- La calibration visuelle validée est figée sous forme de CFrame à 12 composantes dans `FishingConfig.FishingRodVisualGripCFrame` ; le mode Studio temporaire et tous ses raccourcis ont été supprimés.
- Validation Studio requise : modèle visible unique, déséquipement/rééquipement, rotations/déplacements et cycle de pêche complet.

# CRAFTING / ECONOMY BALANCE V1

Statut : `À TESTER`

- Les nouveaux joueurs commencent avec l'inventaire principal et les QuickSlots vides ; les grants temporaires `Camp` et `Fishing_Rod` ont été retirés et le bootstrap d'inventaire Factory est désactivé.
- Les 20 recettes non-Factory sont équilibrées autour des rendements actuels (`Wood x8`, `Stone x6`, `Crystal x3` par nœud détruit), avec outils et stations de survie accessibles tôt, puis stockage, pêche, camp, agriculture et construction.
- Chaque recette possède désormais un temps serveur court compris entre 0,5 et 2 secondes. Les ingrédients et la proximité de la CraftingTable restent validés au moment de la transaction.
- Les ressources de recettes V1 sont limitées aux ItemIds réellement disponibles : `Wood`, `Stone` et `Crystal`. `RawMetal` reste sans recette non-Factory ; `Copper` et `Leather` ne sont pas définis actuellement.
- `Factory Economy = NOT BALANCED / FUTURE CHANTIER` : recettes, ratios et temps Factory inchangés ; seule son attribution automatique d'objets de test est désactivée.
- Validation Studio requise depuis zéro pour confirmer l'inventaire vide, les temps courts, l'absence de blocage et le parcours outils → CraftingTable → survie → stockage → pêche/agriculture → construction.

# MENU PRINCIPAL + SESSION MULTIJOUEUR V1

Statut : `TERMINÉ` — smoke test Roblox Studio validé par le développeur

- Un menu principal responsive et sombre propose `JOUER`, trois emplacements de monde, puis la création d'une partie avec une limite stricte de 1 à 6 joueurs.
- `WorldSessionService` possède l'état autoritaire d'une unique session éphémère dans le serveur Roblox courant. Le créateur démarre la session et les autres joueurs présents peuvent la rejoindre jusqu'à la limite configurée.
- Avant admission, le personnage est immobilisé, la survie est suspendue et les principaux Remotes gameplay refusent les requêtes. Le client bloque les déplacements, contrôle la caméra de menu puis restaure caméra et contrôles au lancement.
- `WorldSessionRequest` est une RemoteFunction serveur validant action, types, slot 1–3, entier `MaxPlayers` 1–6, capacité et délai anti-spam.
- Les trois slots préparent l'interface future, mais aucune sauvegarde permanente n'est simulée. DataStore, mondes partagés, membres autorisés, session locking inter-serveurs, téléportation et serveurs réservés restent volontairement non implémentés.
- Le multijoueur V1 repose sur plusieurs joueurs rejoignant le même serveur public Roblox (notamment via rejoindre un ami), puis rejoignant la session depuis le menu. Ce flux doit être testé en Studio multi-client et dans une expérience publiée.
- Audit prépublication : la sélection visuelle 1–6 persiste après hover, une création concurrente perdante actualise la session rejoignable, le responsive suit les changements de viewport, et respawn/remplacement de caméra réappliquent l'immobilisation et la caméra de menu. L'admission ne contient aucune attente susceptible de dépasser la capacité, et les ProximityPrompts serveur sont bloqués avant admission. Le smoke test Studio a ensuite été validé par le développeur.

# MONDES PERSISTANTS MULTIJOUEUR V1

Statut : `À TESTER`

- `DataService` utilise des DataStores séparés DEV/PROD pour l'index propriétaire et les données de monde, avec retries et mutations sensibles via `UpdateAsync`.
- Chaque slot propriétaire 1–3 référence un WorldId GUID indépendant. La création réserve d'abord le slot (`Creating`), crée le monde, puis finalise l'index (`Ready`) afin d'empêcher les doubles créations et l'écrasement d'un slot.
- `SessionService` acquiert un lease de 120 secondes renouvelé toutes les 30 secondes. Le jeton de fencing réside dans la même entrée DataStore que le monde ; une sauvegarde provenant d'un serveur ayant perdu son lease est refusée atomiquement.
- `WorldService` valide le schéma V1, restaure le temps historique compatible et remplace intégralement les 28 slots d'inventaire. Autosave toutes les 120 secondes, capture avant départ joueur et sauvegarde/libération ordonnée lors du dernier départ ou de `BindToClose`.
- Données persistées : métadonnées du monde, propriétaire/slot, MaxPlayers, représentation des membres autorisés, champ legacy `Age`/progression du cycle, inventaire et QuickSlots par UserId, plus géométrie/identité/snapping des constructions via World Persistence V2 `À TESTER`.
- Données volontairement non persistées faute de format ou règle suffisamment définis : survie, états internes des stations/coffres/campfire, occupation Camp, cultures GardenPlot, ressources naturelles et état de production Factory.
- Un échec de chargement ne crée jamais de monde vide. Un échec de sauvegarde conserve l'état serveur et le lock jusqu'à une nouvelle tentative ou son expiration après crash.
- Tests DataStore Studio et publiés obligatoires : création/reconnexion, inventaire, YearsOnIsland, double serveur, lease stale, double création, autosave concurrent et échecs simulés.

# UX / INTERACTIONS / RÉCOLTE / MONDES V1.1

Statut : `À TESTER`

- Sur PC, `InventoryController` utilise désormais `E` comme fallback déterministe : tout `ProximityPrompt` visible configuré sur `E` reste prioritaire ; en l'absence d'un tel prompt, la même touche ouvre ou ferme l'inventaire personnel. Le raccourci est refusé hors session, pendant le retour menu et lorsqu'un champ texte est actif.
- Le même contrôleur fournit un bouton tactile `SAC` de 56×56 en haut à droite. Il apparaît lorsque le tactile est l'entrée préférée (ou qu'aucun clavier n'est disponible) et uniquement pendant une session. Appareils hybrides suivis via `PreferredInput`.
- Récolte mains nues rééquilibrée : Tree et Stone conservent 100 PV, mais `HandDamage = 10` (10 coups, 6,5 s théoriques au cooldown de 0,65 s) et donnent 2 unités. StoneAxe/StonePickaxe restent à 25 dégâts (4 coups, 2,6 s) et donnent respectivement Wood x8 / Stone x6. Les recettes sont inchangées.
- Les mondes possèdent maintenant un `DisplayName` persistant distinct du `WorldId`. Valeur initiale et fallback rétrocompatible : `MONDE <OwnerSlot>`, sans changement de `SchemaVersion`.
- Le propriétaire peut renommer un slot depuis une petite modale du menu. Le serveur valide type, slot, WorldId, propriété, trim, longueur Unicode 1–28 et cooldown de 2 s, puis filtre avec `TextService:FilterStringAsync(..., PublicChat)` et `GetNonChatStringForBroadcastAsync()` avant une mutation `UpdateAsync`. Un échec de filtrage ou de sauvegarde ne modifie pas le nom.
- Un contrôle `MENU` souris/tactile ouvre une confirmation. `ReturnToMenu` marque la transition, suspend les nouvelles actions via `SessionStarted = false`, capture l'inventaire, puis réutilise `WorldService:Save`.
- Si d'autres membres restent, la sauvegarde conserve le lease et seul le joueur sort de la session. Si le dernier joueur sort, la sauvegarde retire le lock avec le fencing token courant avant de fermer l'état monde. En cas d'échec, le joueur reste en jeu, `SessionStarted` est restauré et un message d'erreur permet de réessayer.
- Au retour réussi, l'inventaire et les interfaces station liées sont fermés par la source d'état commune, les QuickSlots sont masqués, les contrôles gameplay sont bloqués, le personnage est immobilisé et la caméra/menu validés sont restaurés.
- Validation Roblox Studio encore requise : priorité `E` sur chaque prompt, inventaire clavier/tactile et hybride, mesures de récolte, filtrage/persistance du nom, retour menu solo, échec de sauvegarde, respawn, puis scénarios deux joueurs avec propriétaire et dernier membre quittant.

# MENU PRINCIPAL V2 — REFONTE VISUELLE

Statut : `IMPLÉMENTÉ — À TESTER`

- Le menu principal conserve son contrôleur et tous ses flux existants, mais adopte une composition cinématique plein écran sans grand panneau prototype : titre MAYDEAD renforcé, promesse survival, accents rouge/orange et action `JOUER` primaire.
- Le background accepte désormais un asset configurable via `MainMenuVisualConfig.BACKGROUND_IMAGE_ID`, rendu avec `ScaleType.Crop`. Tant que la miniature officielle n'a pas d'asset Roblox publié, un fallback bleu nuit avec overlay, gradient et vignette légère garantit la lisibilité.
- `VOS MONDES` utilise trois cards dark-glass distinctes avec hiérarchie `MONDE`, DisplayName, année/capacité et bouton d'action. Les slots vides affichent `AUCUN MONDE` et `+ CRÉER UNE PARTIE`.
- Les interfaces de renommage et création partagent la même palette, des champs/boutons hiérarchisés, des états de focus et un compteur 0–28 pour le nom. La logique serveur, le filtrage et les appels réseau restent inchangés.
- Le bouton gameplay devient `☰ MENU`, 112×46, placé dans la safe area en haut à droite avec fond sombre semi-transparent, ombre, bordure, hover et pressed state. Il ouvre toujours la confirmation sécurisée existante.
- Le responsive utilise un `UIScale` piloté par le viewport, une grille à trois cards et `DeviceSafeInsets`. Cibles Studio à valider : 1920×1080, 1366×768, 2560×1440, 1280×800, tablette et téléphone paysage/portrait.
- Les transitions 0,14–0,22 s couvrent hover/pressed, entrée des écrans et ouverture des modales. Aucun blur animé, RenderStepped ou système UI parallèle n'a été ajouté.

# MENU PRINCIPAL V3 + DELETE WORLD

Statut : `À TESTER`

- La palette V3 remplace le rouge principal par un ambre doux et un cyan désaturé sur une base graphite translucide. Le rouge est réservé aux erreurs et aux actions de suppression irréversibles.
- Les actions importantes utilisent des `ImageLabel` alimentés par des textures Roblox centralisées dans `MainMenuVisualConfig.ICONS` : jouer, continuer, renommer, supprimer, retour, menu, confirmation et avertissement. Des fallbacks textuels non Unicode restent prévus si une texture manque.
- Les cards mondes passent à une grille responsive scrollable : trois colonnes sur PC large, deux sur tablette et une liste verticale sur téléphone. Le DisplayName reste le titre, avec slot, année/capacité et actions distinctes.
- Le bouton gameplay `MENU` devient un contrôle graphite compact 104×42 avec icône, ombre, stroke et états hover/pressed. La modal de retour utilise l'ambre, jamais le rouge.
- `DeleteWorld` ajoute une suppression propriétaire uniquement avec deux confirmations client, dont la saisie exacte de `SUPPRIMER`, plus une confirmation logique serveur, validation slot/WorldId et anti-spam.
- La suppression est refusée lorsqu'une session est active ou qu'un lease non expiré existe. Une réservation de suppression atomique dans la clé monde bloque également toute nouvelle acquisition de lock pendant l'opération.
- Stratégie DataStore récupérable : réservation avec jeton de suppression, retrait conditionnel de l'entrée `owner:<UserId>` slot → WorldId, puis remplacement définitif de `world:<WorldId>` par un tombstone minimal non chargeable. Avant le commit, tout échec tente de restaurer l'index et d'annuler la réservation ; aucun succès n'est annoncé. Le tombstone ne conserve aucun état gameplay et sert uniquement à empêcher toute résurrection/réutilisation accidentelle de l'ancien WorldId.
- Un nouveau monde créé dans le slot libéré passe toujours par `GenerateGUID(false)` et reçoit donc un nouveau WorldId.
- Tests Studio requis : textures d'icônes, responsive PC/tablette/téléphone, flux UI existants, suppression nominale, monde actif, non-propriétaire, double clic, échecs DataStore et recréation du slot.

# MENU PRINCIPAL V4 BLUE + FIX RENAMEWORLD

Statut : `À TESTER`

- L'accent principal ambre de la V3 est remplacé par un bleu premium `#4C9DFF`, avec hover `#69AFFF` et cyan secondaire `#62C4D6`. Le rouge reste exclusivement réservé aux erreurs et à DeleteWorld.
- L'accueil est plus compact et dense : promesse `SURVIE COOPÉRATIVE • MONDES PERSISTANTS`, CTA Jouer bleu plus fin, hiérarchie MAYDEAD renforcée et footer 1–6 joueurs.
- Les cards utilisent des actions principales plus courtes, des icônes centralisées pour année/joueurs/continuer et des contrôles ImageLabel pour renommer, supprimer, retour et menu. Le responsive V3 3 colonnes / 2+1 / liste verticale est conservé.
- Cause du bug RenameWorld identifiée : `snapshot.SessionLock = releaseLock and nil or current.SessionLock` ne pouvait jamais produire `nil` en Lua. Lors d'un retour menu du dernier joueur, le lease restait donc persisté malgré l'effacement de l'état local ; RenameWorld refusait ensuite l'UpdateAsync avec un lock encore valide et l'erreur était réduite à `SaveFailed`.
- `DataService:SaveWorld` utilise maintenant une branche explicite pour retirer réellement `SessionLock` lorsque `releaseLock == true`. Les vrais locks actifs continuent d'interdire le renommage.
- `DataService:RenameWorld` conserve l'ancien DisplayName tant que l'UpdateAsync n'a pas réussi et remonte désormais des erreurs distinctes : `WorldNotFound`, `NotOwner`, `WorldDeleted`, `WorldBusy` ou `SaveFailed`. L'UI distingue également `InvalidWorldName` et `FilterFailed`.
- Le filtrage reste serveur via `TextService:FilterStringAsync(..., Enum.TextFilterContext.PublicChat)` puis `GetNonChatStringForBroadcastAsync()`. Seule la valeur filtrée est transmise au DataStore.
- Tests Studio/DataStore requis : renommage `TEST`, retour/Continue, reconnexion nouveau serveur, bornes Unicode, accents/emoji, non-propriétaire, monde supprimé, lock actif, filtrage et échec UpdateAsync.

# MENU HUD V4 — POSITION RESPONSIVE

Statut : `À TESTER`

- Le bouton gameplay `MENU` conserve sa position supérieure droite sur PC et son comportement strictement limité à l'ouverture de la confirmation `RETOUR AU MENU`.
- Son `ScreenGui` utilise maintenant `DeviceSafeInsets`. Sur appareil tactile, le contrôleur mesure après layout les rectangles absolus de `MENU` et de `MobileInventoryButton`, puis place `MENU` sous l'inventaire avec une marge adaptée au format au lieu d'appliquer un offset universel.
- Les téléphones et les faibles hauteurs utilisent une variante compacte 92×38 ; tablette et PC conservent 104×42. L'ombre suit le même calcul.
- Le placement est recalculé lors d'un changement de viewport, d'entrée préférée, de session ou d'apparition/visibilité du bouton Inventaire. L'attribut de diagnostic `InventoryCollisionFree` sur `MAYDEADSessionControls` expose le résultat du contrôle final des rectangles.
- QuickSlots, HUD de survie et inventaire ne sont ni déplacés ni reconstruits. Tests Device Emulator requis : 1920×1080, 1280×800, tablette paysage/portrait et téléphone paysage/portrait.

# SAUT TACTILE + ALERTES PREMIUM SURVIE

Statut : `À TESTER`

- Le saut mobile/tablette réutilise le `JumpButton` natif du `PlayerModule` Roblox : aucun bouton, Remote, réglage de puissance ou système physique parallèle n'est ajouté. Une intégration client masque ce contrôle hors session et pendant `ReturningToMenu`, conserve son placement horizontal/safe area Roblox et ne le remonte que si son rectangle touche réellement les QuickSlots après layout.
- Le HUD survie définit désormais deux états visuels centralisés dans `SurvivalAlertConfig` : Warning à 30 ou moins, Critical à 25 ou moins. Le seuil critique 25 déjà employé par l'ancien HUD est conservé ; aucun drain, dégât ou équilibrage serveur n'est modifié.
- Warning colore progressivement le texte et le contour et affiche un indicateur secondaire. Critical ajoute un pulse lent de l'icône. Santé utilise un rouge sombre, Faim un cuivre/ambre doux, Soif un cyan froid et Énergie un bleu-violet.
- Une seule vignette de bords précréée est visible à la fois. Priorité : Santé, Soif, Faim, Énergie. La Santé critique reçoit une opacité légèrement renforcée ; aucun overlay plein écran empilé n'est créé.
- Un toast discret apparaît uniquement lors d'une aggravation d'état, pendant 1,4 s, avec fondu de 0,2 s et cooldown de 8 s par jauge. La couleur est complétée par le texte, le point d'alerte, le contour et le pulse.
- Les alertes sont pilotées par l'événement existant `SurvivalStateChanged`, sans boucle `RenderStepped` et sans nouvelle instance à chaque mise à jour. Les tweens infinis n'existent que pour les jauges actuellement critiques et sont annulés au retour à la normale, au respawn ou au menu.
- Les icônes PNG existantes Faim/Soif sont conservées. Santé et Énergie utilisent des formes UI dédiées plutôt que des caractères Unicode approximatifs ; les AssetIds restent centralisés dans `SurvivalIconConfig`.
- Tests Studio requis : seuils 100/35/29/25/15/10/1, combinaisons multi-jauges, retour normal, respawn, retour menu/Continuer et Device Emulator tablette/téléphone paysage/portrait.

# ACCROCHE NARRATIVE — MENU PRINCIPAL

Statut : `À TESTER`

- L'accueil affiche désormais l'accroche officielle sur deux niveaux : `PERSONNE NE VIENDRA VOUS CHERCHER.` puis `Explorez. Construisez. Survivez. Trouvez un moyen de partir.`
- La ligne principale blanc cassé utilise une hiérarchie cinématique distincte du logo ; la seconde ligne bleu-gris reste plus légère. Le trait bleu V4 existant assure l'accent sans ajouter de panneau ni de couleur rouge/ambre.
- Les textes Home sont centralisés dans `MainMenuVisualConfig.HOME_TEXT`. Leur apparition utilise un fade et un déplacement vertical de 6 px sur 0,26 s, décalés de 0,07 s, sans bloquer le bouton `JOUER`.
- Le conteneur et les hauteurs de texte s'adaptent aux téléphones afin d'autoriser un retour à la ligne sans modifier la formulation. Tests Studio requis sur PC, tablette et téléphone paysage/portrait.

# LOGO TEXTE PREMIUM — SECOND A ROUGE SANG

Statut : `À TESTER`

- Le titre Home reste un seul élément logique RichText affichant exactement `MAYDEAD`, avec le second A uniquement en rouge sang `#991F27`. Le premier A et le D final restent blanc cassé `RGB(232, 234, 232)`.
- La police native Roblox `Oswald` remplace GothamBlack pour une silhouette plus massive et condensée. Une copie sombre du mot complet, décalée verticalement de 7 px, fournit une profondeur sobre derrière un contour contrôlé.
- Le logo suit les animations et le `UIScale` du conteneur Home sans pulse, clignotement ou animation rouge indépendante. La phrase narrative et le bouton bleu `JOUER` restent inchangés.
- `MainMenuVisualConfig` centralise le texte, les couleurs et un `LOGO_IMAGE_ID` optionnel vide. Un futur logo officiel publié pourra remplacer le rendu texte via `ScaleType.Fit` sans reconstruire l'accueil.
- Aucun faux effet d'usure composé d'éléments UI n'est ajouté : la texture abîmée précise reste une limite du rendu TextLabel natif. Validation Studio PC/tablette/téléphone requise.

# WORLD PERSISTENCE V2 — CONSTRUCTIONS + ISOLATION

Statut : `TERMINÉ` — validation Studio confirmée par le développeur

- Cause historique confirmée : les placeables existaient uniquement sous `Workspace.PlacedStructures`; aucun snapshot n'entrait dans `WorldService._world`, donc aucune construction ne pouvait survivre à un nouveau serveur.
- `WorldState.StructuresVersion = 1` et `WorldState.Structures` ajoutent un format additif sans modifier le `SchemaVersion` global, les clés DataStore ni les namespaces `DEV_V1` / `PROD_V1`.
- Chaque entrée conserve `StructureId`, `ItemId`, `StructureType`, `OwnerUserId`, le pivot sous forme de 12 nombres DataStore-safe et une liste fermée d'attributs de snapping/support. Les IDs sauvegardés sont réutilisés au restore; aucun GUID n'est régénéré.
- `BuildingService` centralise capture, validation, restauration en plusieurs passes et nettoyage runtime. Une erreur de snapshot annule entièrement `WorldService:Save` au lieu d'écrire une liste vide.
- `WorldService:Save()` capture les structures avant l'unique écriture protégée par le fencing token; autosave 120 s, ReturnToMenu, dernier joueur et BindToClose utilisent donc le même chemin.
- Le chargement restaure les structures avant le temps, les inventaires et l'admission gameplay. Un monde V1 sans `WorldState.Structures` charge normalement comme un monde sans construction persistante connue.
- Après une fermeture sauvegardée, les structures runtime sont détruites afin d'empêcher toute contamination entre deux WorldId successifs dans le même serveur.
- Géométrie, pivot, identité, liens parent/root, grille, occupations et hooks d'interaction sont restaurés pour tous les placeables connus, y compris Chest, CraftingTable, Campfire, Camp, GardenPlot, portes et machines Factory simples.
- Hors scope V2 : contenu des Chest/CraftingTable/AutomaticLoader, combustible/cuisson Campfire, culture GardenPlot, occupation Camp, état ouvert des portes et files/buffers/progression Factory. Ces états repartent de leur état runtime initial après restauration; aucune persistance complète n'est revendiquée.
- Gardes techniques configurées : 10 000 structures maximum, avertissement à 8 000, snapshot structures limité à 3 000 000 octets avec avertissement à 2 500 000. Ce sont des protections techniques, pas des limites de gameplay validées.
- Validation obligatoire exclusivement sur nouveaux mondes DEV avant toute utilisation de `PROD_V1` : legacy V1, autosave, ReturnToMenu, BindToClose, reconnexion nouveau serveur, IDs, snapping après reload, démontage, multijoueur et isolation monde A / monde B.
- Les constructions historiques perdues ne sont pas recréées. Elles ne sont récupérables que si une inspection strictement read-only révèle un ancien snapshot réellement présent dans le DataStore.
- Hotfix bootstrap `À TESTER` : `CraftingService` est désormais construit avant `WorldService`, publie `OpenWorkbench`, puis transmet explicitement ce Remote à `BuildingService:Start()`. Le constructeur de `BuildingService` ne bloque plus sur un `WaitForChild`, ce qui permet à `WorldSessionService` de publier `WorldSessionRequest`; aucun Remote supplémentaire ni délai arbitraire n'a été ajouté.

# WORLD PERSISTENCE V3 — CONTENEURS ET ÉTATS INTERNES

Statut : `TERMINÉ` — `VALIDÉ STUDIO`

Validation officielle : World Persistence V3 et la compatibilité YearsOnIsland ont été validées en Roblox Studio par le Game Director. Cette validation couvre le monde persistant, le champ legacy `Age`, la progression, la restauration après reconnexion, l'inventaire joueur et les QuickSlots sans perte.

- `WorldState.StructuresVersion` passe à 2 tout en conservant la lecture des snapshots V2/version 1. Chaque structure stateful porte désormais son `State` dans la même entrée que sa géométrie et son `StructureId`.
- `StationService` reste propriétaire des données métier et expose une capture/restauration validée. Les slots sont remplacés intégralement au chargement, jamais fusionnés, afin d'éviter les duplications.
- États persistés : inventaires Chest et CraftingTable, inventaire AutomaticLoader, Fuel/Cooking/IsLit/BurnRemaining/CookProgress du Campfire, culture et progression relative du GardenPlot.
- GardenPlot sauvegarde `GrowthElapsed` limité à la durée de croissance. Au chargement, son horloge runtime est reconstruite depuis `workspace:GetServerTimeNow()` : aucune croissance hors ligne n'est ajoutée.
- Camp reste sans état persistant : occupant, posture et repos sont transitoires. Door revient fermée. Recycler/IndustrialPress, files, buffers, matériaux, sorties et progression Factory restent hors scope.
- Le snapshot monde capture les inventaires joueurs et le temps, puis les structures avec leurs états internes, et produit une copie DataStore-safe indépendante avant `UpdateAsync`.
- Les demandes de sauvegarde sont sérialisées dans `WorldService`. Une sauvegarde finale attend un autosave en cours au lieu d'échouer avec `NoWorldOrBusy`; chaque chemin journalise sa raison (`Autosave`, `ReturnToMenu`, `PlayerRemoving`, `BindToClose`).
- Les protections existantes restent actives : retries DataStore, fencing token, lock libéré uniquement après réussite, ancien snapshot conservé en cas d'échec, autosave 120 secondes, PlayerRemoving, ReturnToMenu et BindToClose.
- Fenêtre résiduelle : une panne catastrophique avant la fin de PlayerRemoving/BindToClose peut revenir au dernier autosave réussi, soit jusqu'à environ 120 secondes de mutations. Roblox ne permet pas une garantie absolue lorsque le serveur ou DataStore devient indisponible brutalement.
- Constructions validées : `StructureId`, position, rotation, relations de snapping et isolation entre mondes sont sauvegardés puis restaurés correctement.
- Chest validé : géométrie, interaction et 30 slots `ItemId`/`Quantity` sont restaurés.
- CraftingTable validée : géométrie, interaction et 12 slots sont restaurés.
- Campfire validé : `FuelSlots`, `CookingSlots`, `IsLit`, `BurnRemaining` et `CookProgress` sont restaurés sans progression hors ligne.
- GardenPlot validé : `CropType` et `GrowthElapsed` sont restaurés sans croissance hors ligne.
- Camp validé selon son contrat : géométrie et identifiant persistent ; occupant, posture et animation restent volontairement transitoires.
- Les sauvegardes validées couvrent l'autosave toutes les 120 secondes, `ReturnToMenu`, `PlayerRemoving`, le départ du dernier joueur et `BindToClose`, avec session lock/fencing et sérialisation des sauvegardes concurrentes. `ReturnToMenu` n'est pas requis pour assurer la sauvegarde technique.
- L'autorité serveur est conservée sur l'ensemble des données persistantes.
- Compatibilité : `StructuresVersion = 2` et lecture conservée de la version précédente.
- Limites volontaires toujours non persistantes : repos temporaire du Camp, état ouvert des portes, ressources naturelles de la carte, visuels/animations transitoires, Factory complexe, Recycler/IndustrialPress, files, buffers, matériaux, sorties en attente et timers industriels.
- `Factory Economy` reste `NOT BALANCED / FUTURE CHANTIER`.
- Limite technique connue : une panne catastrophique ou une indisponibilité DataStore avant la fin de `PlayerRemoving`/`BindToClose` peut restaurer le dernier autosave réussi, soit une fenêtre maximale d'environ 120 secondes.

Prochaine étape : `VALIDATION ROBLOX PLAYER MULTIJOUEUR` — vérifier avec plusieurs clients la reconnexion, les mutations simultanées joueur↔conteneur, les sauvegardes concurrentes, le départ du dernier joueur, le verrouillage de session et l'isolation monde A/monde B.

# FEEDBACK RÉCOLTE + HUD SURVIE + LOOT CARDS + ÉNERGIE

Statut : `À TESTER`

- Le flux de récolte reste serveur autoritaire : le client exprime une intention, `ResourceService` valide cible, outil, distance, cooldown, santé et capacité d'inventaire, puis `InventoryService` attribue la récompense.
- Une récolte acceptée déclenche côté client une animation courte, un impact visuel sur la ressource, une barre représentant sa santé serveur réelle et un son discret. Aucun délai artificiel n'est ajouté aux récoltes instantanées ; les IDs d'animation et de sons optionnels sont centralisés dans `HarvestConfig`.
- Les Loot Cards utilisent le Remote existant `InventoryStateChanged` et son champ additif `GrantedItem`, émis uniquement après un ajout réel par `InventoryService:AddItem`. Elles affichent icône, DisplayName et quantité, sans rareté inventée.
- Les gains identiques sont regroupés pendant 1,25 seconde ; trois cartes au maximum restent visibles et disparaissent après deux secondes avec slide/fade/scale courts.
- Le HUD survie affiche désormais Santé, Faim, Soif et Énergie sous forme `icône + nom + barre + valeur / 100`. Les barres suivent exactement la valeur serveur avec un tween de 0,18 seconde.
- Oxygène reste contextuel : la ligne apparaît sous l'eau et disparaît une seconde après être redevenue non pertinente.
- Alertes UI de test : normal au-dessus de 35 %, faible entre 20 et 35 %, critique à 20 % ou moins, avec accent, indicateur et pulsation contrôlée sans clignotement agressif.
- Ancienne énergie : drain passif uniforme de 0,025/s, immobile ou en mouvement.
- Nouveau tuning de test centralisé dans `SurvivalConfig` : 0,005/s immobile, 0,065/s en déplacement et coût de 0,75 par impact manuel accepté. Aucun sprint n'existe actuellement, donc aucun second système de sprint n'est créé.
- Fatigue autoritaire serveur : vitesse normale à 20 % ou plus, interpolation vers 88 % à 10 %, puis vers 72 % à 0 %. La vitesse n'atteint jamais zéro et l'immobilisation temporaire du Camp reste prioritaire.
- Aucun DataStore, `SchemaVersion`, `StructuresVersion`, service de monde ou mécanisme Persistence V3 n'est modifié.
- Validation effectuée : contrôle statique ciblé et `git diff --check`. Validation Roblox Studio non effectuée.
- Tests Studio requis : récolte manuelle, spam, inventaire plein, HUD aux seuils 100/75/35/19/10/0, mesure de drain énergie, fatigue/récupération, responsive PC/tablette/téléphone, deux joueurs, sauvegarde V3 et fermeture directe.

## Refinement UI 2.0 — HUD survie et bouton MENU gameplay

Statut : `À TESTER`

- Le HUD survie conserve son architecture et ses comportements, mais descend de 24 pixels physiques à résolution standard dans sa safe area.
- Les cinq fills reçoivent des couleurs plus lisibles, un gradient vertical très léger et un highlight interne d'un pixel.
- Les fallbacks vectoriels Santé et Énergie sont modernisés ; les ImageIds et symboliques Faim, Soif et Oxygène restent inchangés.
- Le bouton MENU gameplay conserve sa position responsive et son action. Son ancien grand Frame d'ombre est remplacé par une ombre de contact fine, avec fond graphite, stroke bleu-gris et accent bleu discret.
- Aucun seuil, drain, vitesse, Remote, DataStore ou comportement Persistence V3 n'est modifié. Validation Studio PC/tablette/téléphone requise.

### UI Gameplay Assets — Final Pass 2.0

Statut : `À TESTER`

- Les assets officiels Santé `87643191382927` et Énergie `126385789259096` remplacent leurs fallbacks vectoriels via `SurvivalIconConfig`, sans recoloration ni déformation.
- Les fills utilisent un fond vide `RGB(15, 20, 28)`, des couleurs fonctionnelles plus lumineuses et un gradient horizontal discret afin de rester lisibles de nuit.
- Le bouton MENU gameplay devient un `ImageButton` transparent utilisant l'asset officiel `131150526179359`. Ancien fond, stroke, texte, icône séparée et ombre secondaire sont retirés.
- Le bouton Inventaire tactile existant devient un `ImageButton` transparent 64×64 utilisant l'asset officiel `80162683254318`; son callback, sa visibilité tactile et la priorité d'interaction `E` restent inchangés.
- Validation Studio PC, tablette et téléphone requise avant toute déclaration `VALIDÉ`.

### HUD Survival — Color Pass haute visibilité

Statut : `À TESTER`

- La palette haute visibilité officielle est intégrée aux cinq jauges avec couleurs principales et highlights explicites, sans interpolation assombrissante.
- Chaque titre reprend désormais la couleur fonctionnelle claire de sa statistique ; les valeurs restent blanc/gris très clair.
- Les fills conservent leur largeur pilotée par l'état serveur et utilisent un gradient horizontal principal→highlight sur un fond vide `RGB(14, 18, 24)`.
- Layout, responsive, assets Santé/Énergie/Faim/Soif/Oxygène, alertes et logique de survie restent inchangés. Validation Studio requise.

Correction de lisibilité prioritaire `À TESTER` : le `UIGradient` qui multipliait la couleur du fill par sa propre teinte a été retiré. Les jauges utilisent désormais une couleur pleine haute visibilité, une transparence nulle, des titres gris très clair et un rail de 9 pixels. Aucun comportement gameplay n'est modifié.

Survival HUD Premium readability pass implemented — awaiting Studio validation. Hiérarchie interne renforcée avec icônes 27 px, titres colorés 12 px, valeurs secondaires 11 px et rails 10 px ; cartes, assets, responsive et gameplay restent inchangés.

## Survival HUD 3.0 — icônes-jauges verticales

Statut : `À TESTER STUDIO`

- Les anciennes cartes, titres, rails horizontaux et valeurs `/100` sont retirés du rendu et de la construction UI.
- Chaque statistique utilise une silhouette sombre permanente et une copie lumineuse identique, clipée verticalement du bas vers le haut selon la valeur serveur normalisée de 0 à 1.
- Le niveau est tweené en 0,18 seconde uniquement lors des événements `SurvivalStateChanged`; aucun `RenderStepped` ni boucle par statistique n'est ajouté.
- Les icônes mesurent 48 px et affichent un pourcentage secondaire compact. Sous le seuil critique existant, le pulse contrôlé, les toasts et la vignette existants restent actifs.
- Oxygène conserve strictement son apparition sous l'eau et sa disparition différée. Assets, responsive, gameplay, Remotes et Persistence V3 restent inchangés.

## Relocalisation UI progression journée / années sur l'archipel

Statut : `À TESTER STUDIO`

- Le composant jour/année n'est plus un HUD permanent : il est monté dans l'inventaire personnel et suit les valeurs serveur `TimeState.YearsOnIsland` et `TimeState.CycleProgress`.
- Il est masqué avec le contenu joueur lorsque la même fenêtre affiche le craft, une CraftingTable, un Campfire, un Chest ou une autre station.
- La priorité d'interaction `E`, le bouton Inventaire tactile, le gameplay, l'autorité serveur, les Remotes et la persistance restent inchangés.

# METALLURGY V1

Statut : `À TESTER STUDIO`

- `CuivreRock`, `MetalRock_Test` et `OrRock` utilisent la récolte serveur existante avec pioche obligatoire, respectivement 150/200/300 PV et des drops CopperOre x3–5, RawMetal x2–4 et GoldOre x1–3.
- Les nouveaux items `CopperOre`, `GoldOre`, `CopperIngot`, `MetalIngot`, `GoldIngot` et le placeable `Smelt` utilisent les AssetIds officiels fournis. L'ItemId brut historique `RawMetal` reste inchangé.
- `Smelt` réutilise BuildingService et StationService : recette CraftingTable Stone x40 + Wood x15 + RawMetal x8 en 8 secondes, placement serveur, interaction et inventaire 4 Input + 4 Fuel + 4 Output.
- Fonte serveur : CopperOre x3 → CopperIngot x1 / 18 s ; RawMetal x4 → MetalIngot x1 / 24 s ; GoldOre x3 → GoldIngot x1 / 36 s. Wood est le seul fuel V1 à 45 secondes, via une configuration extensible pour un futur Petroleum non créé.
- Le fuel n'est chargé et les effets Smoke/Fire/ParticleEmitter/Light/Sound ne sont actifs que lorsqu'une recette valide peut progresser et que la sortie accepte le résultat. Une sortie pleine ou l'absence de minerai/fuel suspend la fonte sans perte.
- Smelt est stateful Persistence V3 : 12 slots, recette active, progression et combustion restante sont capturés/restaurés sans progression hors ligne. Les anciens mondes sans Smelt restent compatibles ; aucun DataStore ou schéma parallèle n'est ajouté.

## Convention officielle des minerais

Statut : `À TESTER STUDIO`

- Les noms visibles sont unifiés en `MINERAI DE MÉTAL`, `MINERAI D’OR` et `MINERAI DE CUIVRE` dans le feedback de récolte, les Loot Cards, l'inventaire, les stations et les ingrédients de recettes.
- `HarvestController` résout désormais le libellé depuis l'ItemId de drop puis `ItemDefinitions.DisplayName`, au lieu d'afficher directement le nom technique du modèle naturel.
- Les ItemIds et noms de modèles internes `RawMetal`, `GoldOre`, `CopperOre`, `MetalRock_Test`, `OrRock` et `CuivreRock` restent inchangés. Persistence V3 et Metallurgy V1 restent fonctionnellement inchangées.

## Intégration visuelle menu MAYDEAD

Statut : `À TESTER STUDIO`

- Le menu principal utilise `rbxassetid://132491826416605` comme rendu plein écran et des hitboxes transparentes proportionnelles pour `JOUER`, `CLASSEMENT` et `QUITTER`. Seul `JOUER` déclenche une logique existante ; aucune mécanique de classement ou de fermeture Roblox n'est inventée.
- `VOS MONDES` utilise `rbxassetid://130947862190730`. Les trois slots dynamiques existants restent reliés à la création, continuation, renommage, suppression, année et capacité réelles, dans les trois cadres visuels du background.
- L'unique hitbox `RETOUR` est placée en haut à droite ; aucun second bouton Retour inférieur n'est construit.
- Cette première intégration réutilisait `SoundService.Secret Transmission (C)` ; le hotfix ci-dessous la remplace par la musique officielle actuelle sans créer de Sound.
- WorldSessionService, WorldService, DataStores, limite de trois mondes et limite de six joueurs restent inchangés.

### Menu Visual Background Hotfix

Statut : `À TESTER STUDIO`

- Les deux backgrounds et leurs overlays partagent désormais un `MenuViewport` centré au ratio 16:9, dimensionné au plus grand rectangle entièrement contenu dans le viewport réel. Les écrans non 16:9 utilisent donc un letterbox sombre plutôt qu'un recadrage.
- Les ImageLabels utilisent `ScaleType.Fit` au lieu de `Crop`. Logo, boutons imprimés, titre `VOS MONDES`, bouton `RETOUR`, cartes et bas des compositions ne doivent plus être coupés.
- Les hitboxes JOUER/CLASSEMENT/QUITTER, l'unique hitbox RETOUR en haut à droite et les trois overlays monde sont enfants du même repère 16:9. Les grands fonds de cartes passent à une transparence de 0,82 afin de préserver les cadres imprimés.
- La musique de menu réutilisée devient exclusivement `SoundService.Drums Of Might` (`rbxassetid://133753360245765` configuré dans Studio), avec continuité entre les écrans menu, arrêt en gameplay et reprise au retour.
- Mécanique des mondes, Remotes, services serveur, Persistence V3 et DataStores restent inchangés.

### Menu Worlds Overlay Alignment

Statut : `À TESTER STUDIO`

- Un `FullScreenBackdrop` opaque `RGB(3, 9, 14)` couvre maintenant tout le ScreenGui derrière le `MenuViewport` 16:9, empêchant Terrain, océan ou map d'apparaître dans les bandes de letterbox.
- Les trois WorldSlots utilisent exclusivement les cadres imprimés : fond transparent, aucun Border/UIStroke externe et aucun hover de panneau. Leur conteneur commun et leurs tailles restent exprimés en Scale dans le même viewport que le background.
- Les actions `CRÉER UNE PARTIE` / `CONTINUER` sont légèrement réduites et centrées au bas de chaque slot ; Rename/Delete passent à 36 px dans le coin supérieur droit de leur propre slot.
- Backgrounds Fit, hitboxes du menu principal, ReturnHitbox, Drums Of Might et toute la mécanique monde existante sont préservés.

### Menu Visual Calibration

Statut : `À TESTER STUDIO`

- Les dimensions de référence auditées sont `1536×1024` (ratio 3:2) pour le menu principal et `1536×1152` (ratio 4:3) pour `VOS MONDES`; l'hypothèse 16:9 responsable du letterbox latéral excessif est retirée.
- Le `VisualCanvas` partagé adopte dynamiquement le ratio natif de la page active, reste centré, entièrement visible et posé devant le backdrop plein écran opaque.
- Les rectangles Play/Leaderboard/Quit/Return et les trois WorldSlots sont centralisés dans `MainMenuVisualConfig` en coordonnées normalisées.
- Le `UIGridLayout` des mondes est supprimé : chaque slot transparent occupe explicitement son cadre imprimé, tandis que ses textes et actions restent positionnés relativement à ce slot.
- Navigation, Create/Continue/Rename/Delete, données monde, Drums Of Might, services serveur, Persistence V3 et DataStores restent inchangés.

### World Select UI Premium Pass

Statut : `À TESTER STUDIO`

- Seul l'intérieur des trois WorldSlots est retravaillé ; background `VOS MONDES`, calibration globale, ReturnHitbox, menu général validé et musique restent inchangés.
- Chaque slot conserve son conteneur transparent sans cadre doublon. Label de slot, DisplayName, métadonnées, état vide et action principale utilisent désormais des positions proportionnelles au slot.
- Les boutons Créer/Continuer partagent un rendu bleu profond/cyan avec gradient discret, largeur 60 %, hauteur 9 %, position basse centrée, hover 1,015 et pressed 0,97.
- Rename/Delete sont regroupés dans un `ActionsFrame` transparent en haut à droite et restent compacts à 36 px. Les callbacks et modales existants sont réutilisés sans changement.
- Les DisplayNames longs utilisent `TextTruncate.AtEnd` sur une ligne afin de préserver la hauteur et les limites du cadre.

## CHEETAH COMPANION UI CLIENT HOTFIX

Statut : `À TESTER STUDIO`

- Les preuves Studio confirment que le `CheetahCompanionPrompt`, ses validations serveur et l'appel `CheetahCompanionRemote:FireClient` fonctionnent. L'ancien log serveur `CompanionUI opened=true` ne prouvait toutefois pas qu'une interface était devenue visible sur le client.
- La cause identifiée dans le code client était l'auto-fermeture : le serveur mesurait la distance depuis la racine locomotrice `HumanoidRootPart` / `Torso`, tandis que le client utilisait `Model:GetPivot()`. Sur cet asset, le pivot global peut être décalé de la racine et produire artificiellement une distance supérieure au seuil de 14 studs juste après l'ouverture.
- Le client résout désormais la même racine que l'IA serveur (`HumanoidRootPart`, puis `Torso`, `PrimaryPart` et enfin un BasePart de secours) avant d'appliquer l'auto-fermeture. Le `ScreenGui` est explicitement activé et les logs distinguent maintenant la demande serveur, la réception client et la visibilité réelle du Frame.
- Aucun changement n'est apporté au prompt, aux distances, au Follow, à l'IA, au taming, à la monture, à la persistance ou à l'interface visuelle. Les diagnostics d'animation et de joint sont désactivés par défaut.

## CHEETAH COMPANION POLISH V1.3

Statut : `À TESTER STUDIO`

- La nourriture du compagnon utilise désormais un mini-slot inspiré des slots d'inventaire MAYDEAD : fond sombre, coins arrondis, bordure légère, `ImageLabel` en mode `Fit` avec l'icône RawMeat officielle `rbxassetid://87706745738421`, et quantité superposée en bas à droite. À zéro, le slot et la valeur `0` restent visibles tandis que l'icône est atténuée.
- La vitesse joueur de référence reste celle configurée dans Studio, soit 30 studs/s; aucun code de déplacement joueur n'est modifié. Le guépard utilise désormais 30 studs/s en déplacement normal et Follow, puis 45 studs/s pour le catch-up à partir de 22 studs.
- Chase et Burst utilisent 45 studs/s. Les allures de monture deviennent 30/38/45 studs/s pour marche/course/sprint; le sprint maximal conserve la consommation d'endurance, la réduction liée à la faim et la régénération existantes.
- Taming, Trust, RawMeat, dépôt/retrait, interaction E, Follow/Stay hors vitesses, cycle de monture, combat hors vitesse, évitement de l'eau et persistance restent inchangés.

## CHEETAH FINAL MOUNT + LOCOMOTION PASS

Statut : `À TESTER STUDIO`

- La cause structurelle du cavalier trop haut était l'utilisation du sommet de la BoundingBox complète du guépard comme base du siège, additionnée à la demi-hauteur du Seat, une marge dépendant du torse de l'avatar et un clearance. La tête et les extrémités hautes pouvaient donc relever artificiellement le point de montage.
- Le siège est désormais placé depuis un `CheetahMountAttachment` déterministe, centré au sommet de la pièce dorsale réelle (`Body`, puis `Torso`/`UpperTorso`, avec fallback sur la racine). `Seat:Sit()` conserve l'adaptation Roblox à l'avatar; aucun offset dépendant de la taille du torse n'est ajouté manuellement et aucun offset ne s'accumule entre les montages.
- Le scale reste volontairement à `1.0` faute de justification visuelle mesurée en Studio. Le flag `CHEETAH_RIG_DEBUG`, désactivé par défaut, permet de relever le rig, les joints résolus, la vitesse réelle, la BoundingBox, le Body, l'offset de montage, le HipHeight et le scale sans spam par frame.
- La locomotion procédurale existante reste pilotée par la vitesse horizontale réelle et applique son cycle diagonal aux vrais `Motor6D`/`Weld` résolus. Les éventuels `WeldConstraint` sont journalisés comme non animables; aucune conversion automatique risquée n'est effectuée sans validation runtime du rig.
- Les vitesses officielles sont : Follow normal 30, catch-up limité à 40, Chase 40, Burst maximum 50, monture 30/40/50. L'endurance du sprint, l'interdiction de l'eau et toutes les statistiques de combat restent inchangées.

## CHEETAH MOUNT ORIENTATION HOTFIX

Statut : `À TESTER STUDIO`

- La position verticale validée du `CheetahMountAttachment` est conservée. La mauvaise orientation venait de l'héritage direct de la rotation importée de la pièce `Body`/`Torso`, qui ne garantit pas un repère Roblox vertical avec l'avant sur `-Z`.
- L'axe avant est désormais déduit géométriquement du vecteur horizontal allant de la pièce dorsale vers `Head`, sans supposer l'axe d'import de l'asset. L'orientation du siège est reconstruite avec cet avant et l'axe vertical monde, tout en conservant exactement la position calculée précédemment.
- Un unique log Studio `[MAYDEAD][CHEETAH][MOUNT_ORIENTATION]` rapporte la source de l'axe, les LookVector du Body, du mount et du rider, leurs UpVector et la rotation locale finale.
- Scale, hauteur de montage, vitesses 30/40/50, Follow, locomotion, interaction E, UI Companion, taming, combat, eau et persistance restent inchangés.

## CHEETAH LOCOMOTION FINAL PASS

Statut : `À TESTER STUDIO`

- Le cavalier reçoit un lean dynamique de 0 à 12 degrés autour de l'axe X local du repère de montage validé. La cible dépend de la vitesse horizontale réelle et est interpolée avec une réponse de 6/s; position, hauteur et orientation de base du mount restent inchangées.
- Le siège utilise désormais un `Weld` dont le `C0` de base est conservé, afin d'appliquer uniquement cette rotation visuelle relative puis de pouvoir revenir exactement à la pose validée sans cumul entre les montages.
- `CHEETAH_LOCOMOTION_DEBUG`, désactivé par défaut, journalise toutes les 1,5 secondes l'état, la vitesse et le lean. Combiné temporairement à `ANIMATION_JOINT_PROBE`, il applique le test unitaire de rotation aux quatre joints candidats en Studio.
- La capture Studio confirme que la locomotion procédurale précédente ne produit pas de mouvement visible malgré les angles calculés. Le modèle runtime n'étant pas sérialisé dans le dépôt Rojo, la nature exacte des joints et les résultats visuels des probes ne peuvent pas être établis statiquement.
- **LOCOMOTION BLOQUÉE PAR LE RIG DE L'ASSET** jusqu'à l'audit/probe Studio : les logs doivent déterminer si les membres visibles sont pilotés par les Motor6D/Weld résolus, figés par des WeldConstraint ou intégrés dans un MeshPart non riggé. Aucune conversion de joint ni fausse correction n'est appliquée sans cette preuve.
- Interaction E, mount offset, Follow, vitesses, taming, UI, combat, eau et persistance restent inchangés.

## CHEETAH RIG REBUILD V1

Statut : `BLOQUÉ`

- **LOCOMOTION IMPOSSIBLE À RECONSTRUIRE DEPUIS L'ASSET ACTUELLEMENT ACCESSIBLE** : le template Cheetah utilisé dans Studio n'est pas sérialisé dans le dépôt ni dans le build Rojo disponible. `default.project.json` ne mappe que ReplicatedStorage/Shared, ServerScriptService/Server et StarterPlayerScripts/Client; aucun modèle, MeshPart, Bone ou joint du template ne peut donc être inspecté ou modifié hors Studio.
- La capture Studio confirme que les membres visibles restent figés. Les angles procéduraux précédemment journalisés ne prouvent pas que les joints candidats pilotent les pièces visibles; créer ou supprimer des Motor6D sans connaître Part0, Part1 et la pose réelle risquerait de désassembler l'asset publié.
- `CHEETAH_RIG_REBUILD_DEBUG`, désactivé par défaut, complète l'audit runtime : chaque Part/MeshPart/UnionOperation, joint, Bone, Attachment, Humanoid et contrôleur d'animation est journalisé une fois avec FullName, ClassName, Name et Parent. Avec `ANIMATION_JOINT_PROBE=true`, chaque joint FL/FR/RL/RR candidat reçoit le probe Studio indépendant existant.
- Aucun joint n'est reconstruit tant que ces résultats ne permettent pas de prouver que les quatre pattes sont des pièces séparées et d'identifier leurs liaisons réelles. Gameplay, mount, lean, vitesses, interaction E et persistance restent inchangés.

## CHEETAH BODY LOCOMOTION + MOUNT JUMP V1

Statut : `À TESTER STUDIO`

- Les membres restent non confirmés comme articulables avec l'asset Studio absent du dépôt. Le fallback recherche toutefois une liaison `Motor6D`/`Weld` réelle entre le `HumanoidRootPart` physique et `Body`/`Torso`; lorsqu'elle existe, elle anime uniquement ce corps visuel sans déplacer le root de navigation.
- Le mouvement visuel est synchronisé à la vitesse horizontale réelle : respiration Idle 0,025 stud, bob Walk/Run/Sprint 0,08/0,13/0,18 stud, pitch 3/5/8 degrés et roll plafonné à 3 degrés. Une phase d'impact asymétrique ajoute une compression contrôlée. Si aucune liaison visuelle animable n'existe, aucun mouvement du root physique n'est simulé.
- En monture, l'action contextuelle `MAYDEAD_CheetahMountJump` réserve le clic gauche PC, `ButtonA` gamepad et crée le bouton tactile `SAUT`. Elle est liée uniquement après `Mounted` et retirée immédiatement au dismount, respawn ou unload, laissant le clic RawMeat à pied inchangé.
- Le serveur réutilise `CheetahCompanionRemote` avec l'intention `MountJump` et valide Owner réellement monté, Cheetah vivant, cooldown 1 seconde, endurance minimale 8, sol à 4,5 studs et matériau non-eau. Le saut conserve l'élan horizontal, applique 45 studs/s verticalement et consomme 8 d'endurance.
- Les flags `CHEETAH_BODY_LOCOMOTION_DEBUG` et `CHEETAH_MOUNT_JUMP_DEBUG` restent désactivés par défaut. Follow/Chase/Mount 30/40/50, interaction E, mount/lean, taming, combat, eau et persistance restent inchangés.

## CHEETAH SPEED + JUMP TUNING

Statut : `À TESTER STUDIO`

- La vitesse de course montée réellement utilisée passe de 40 à 50 studs/s. La marche reste à 30 et le sprint/max reste à 50; aucune autre vitesse Follow, Catch-up, Chase ou Burst n'est modifiée.
- `MOUNT_JUMP_VELOCITY` passe de 45 à 78 studs/s. Le facteur `sqrt(3)` appliqué à la vitesse verticale vise une hauteur environ trois fois supérieure puisque, sous gravité constante, la hauteur balistique est proportionnelle au carré de la vitesse initiale.
- Avec la gravité Roblox par défaut de 196,2 studs/s² et sans autre contrainte, la hauteur théorique au-dessus du point de départ passe d'environ 5,16 à 15,50 studs, soit un facteur 3,00. Ces valeurs doivent être mesurées en Studio sur terrain réel.
- Cooldown 1 seconde, coût d'endurance 8, conservation de l'élan horizontal, validation sol/eau, inputs PC/mobile/tablette, clic RawMeat à pied, interaction E et persistance restent inchangés.

## PRE-PUBLISH CLEANUP V1

Statut : `À TESTER STUDIO / PRE-PUBLISH`

- Les appels `InventoryService:GrantStudioFishingRod(player)` et `InventoryService:GrantStudioRawMeat(player)` sont retirés de l'admission `WorldSessionService:_admit`. Aucun nouveau joueur ou nouveau monde ne reçoit désormais ces items automatiquement, y compris dans Studio.
- Les fonctions `GrantStudioFishingRod` et `GrantStudioRawMeat`, leurs constantes, tables de suivi par joueur et logs DEV sont supprimés d'`InventoryService`.
- Le filtrage spécial qui retirait la canne DEV et le reliquat RawMeat DEV de `ExportInventory` est supprimé avec les grants. L'export normal conserve désormais fidèlement toute `Fishing_Rod` et tout `RawMeat` légitimement obtenus.
- ItemDefinitions, icônes, recette et équipement Fishing_Rod, FishingService/minijeu, RawMeat gameplay, drops, pickup, Cheetah/taming et persistance normale restent inchangés. Aucun DataStore n'est purgé et aucune migration destructive n'est ajoutée.
- Reliquats prépublication hors scope relevés sans modification : `BalanceConfig.BALANCE_DEBUG=true`; bootstrap Factory toujours présent mais `ENABLE_TEST_BOOTSTRAP=false`; séparation DataStore Studio `DEV_V1` / production `PROD_V1`; flags de diagnostic Cheetah présents mais tous désactivés. Les ratios Factory de production 5/1 et 10/1 ont depuis été restaurés par `FACTORY CRAFTING + BALANCE V1`.

## RAWMEAT WORLD DROP POLISH V2

Statut : `À TESTER STUDIO`

- Chaque `RawMeatWorldDrop` continue de partir du template propre `ServerStorage.AssetImports.RawMeatWorldModel`, puis reçoit un unique scale déterministe visant désormais une longueur maximale de 1,65 stud, soit trois fois la cible runtime précédente de 0,55 stud. `Model:ScaleTo` conserve les proportions; un BasePart seul conserve la même méthode uniforme sur `Size`.
- Le placement au sol recalcule après scale le bas de la BoundingBox finale et ajoute la même marge de 0,02 stud. Le ProximityPrompt reste parenté à une BasePart elle-même mise à l'échelle et conserve sa portée serveur de 7 studs.
- Le lifetime serveur passe de 300 à 180 secondes. Chaque drop possède son propre `task.delay`; à échéance, un drop `AVAILABLE` est détruit, tandis qu'une réservation Cheetah bénéficie d'une grâce maximale de 10 secondes pour terminer sa consommation.
- Pickup joueur et consommation Cheetah passent d'abord l'état à `CONSUMED` puis détruisent l'instance; le callback d'expiration vérifie encore Parent et état, ce qui rend les courses pickup/eat/timeout sans effet secondaire. Une réservation dépassant la grâce devient `EXPIRED`, et l'IA abandonne naturellement sa cible devenue invalide.
- Lorsque plus aucun joueur n'a de session monde active, `ClearWorldDrops` détruit les drops restants côté serveur. Les drops restent temporaires, non persistants et isolés entre mondes; les grants DEV Fishing_Rod/RawMeat restent supprimés.

## BOAT PROPULSION HOTFIX V2

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- La vitesse plafonnait autour de 13 studs/s parce que le Script intégré au `VehicleSeat` imposait une force longitudinale fixe de 4 000, indépendamment de `VehicleSeat.MaxSpeed`. Ce Script est désormais désactivé au moment où chaque modèle `Boat` de `Workspace.Map` est enregistré par le contrôleur serveur central.
- La propulsion utilise la vitesse horizontale réelle de `Body.AssemblyLinearVelocity`, sa projection signée sur l'avant du siège, une vitesse cible et la formule `force = direction × AssemblyMass × accélération désirée`. La force diminue avec l'erreur de vitesse au lieu d'imposer directement une vélocité.
- Valeurs centralisées : avant 70 studs/s avec 10 studs/s², arrière 25 studs/s avec 8 studs/s², décélération 16 studs/s². Sans conducteur, la cible revient à zéro et le bateau conserve une décélération progressive.
- L'`AngularVelocity` existante est conservée. Son taux passe progressivement de 1 à basse vitesse à 0,55 à 70 studs/s afin d'élargir légèrement les virages rapides sans changer les sièges passagers.
- Le contrôleur détecte les trois modèles homonymes sans scan répété du Workspace, journalise leur `AssemblyMass` et leur NetworkOwner au démarrage, mais ne force aucun changement d'ownership.
- `Boat`, ses modèles Studio et leurs scripts intégrés n'étant pas sérialisés dans le projet Rojo, cette étape exigeait une confirmation Studio des masses et du comportement physique final. Cette confirmation est désormais couverte par la validation finale du Game Director; la capture historique disponible indiquait 96,136 pour le bateau sélectionné.
- Factory, Fishing, Cheetah, RawMeat, Building, persistance, menus, WorldSession et DataStores restent inchangés par ce hotfix.

## BOAT PROPULSION FIX V3

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- Un seul bateau subsiste et le contrôleur cible exclusivement `Workspace.Boat`; aucune boucle multi-Boat et aucune recréation des deux modèles supprimés n'est conservée.
- L'ancien `BodyForce` fixe de 4 000 atteignait environ 13 studs/s. Le V2 plafonnait ensuite vers 3 studs/s parce que sa force maximale `AssemblyMass × 10` ne valait qu'environ 961,36 pour la masse observée de 96,136, donc moins du quart de la poussée précédente déjà insuffisante contre la résistance de l'asset.
- La propulsion `BodyForce` est neutralisée et remplacée par un unique `LinearVelocity` horizontal. Sa consigne progresse à 10 studs/s² vers 70 en marche avant, à 8 studs/s² vers -25 en marche arrière et revient vers zéro à 14 studs/s², soit des cibles théoriques respectives de 7 secondes et 5 secondes.
- Le `LinearVelocity` utilise le plan horizontal monde afin de ne pas contraindre la flottaison verticale. Sa limite est recalculée à `AssemblyMass × 300`, soit environ 28 840,8 pour la masse observée, afin de disposer d'une marge contre le drag tout en conservant une force finie lors des collisions.
- L'`AngularVelocity` existante reste seule responsable de la direction, avec une interpolation de 1 à basse vitesse vers 0,55 à 70 studs/s. `VehicleSeat.MaxSpeed` peut rester configuré dans Studio mais ne pilote pas ce moteur personnalisé.
- Le NetworkOwner est seulement audité au démarrage et aux changements d'occupant; aucun `SetNetworkOwner` n'est appliqué. Des logs temporaires espacés de 0,75 seconde exposent masse, throttle, vitesse avant réelle, cible, erreur, consigne progressive et MaxForce.
- Les valeurs 68–72 studs/s, 0→70 en 5–9 secondes et 70→0 en 4–6 secondes restent obligatoirement à mesurer dans Studio; elles ne sont pas déclarées validées statiquement.

## BOAT PROPULSION FIX V4

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- Le test Studio V3 rapporte une vitesse réelle restant proche de 13 studs/s malgré une consigne configurée à 70. Les logs V3 complets n'ayant pas été fournis, la cause physique exacte (limite de force, assembly, axe ou contrainte concurrente) n'est pas encore prouvée et aucune réussite à 80 n'est déclarée.
- La cible officielle passe à 80 studs/s, la progression de consigne avant à 14 studs/s² et la décélération à 16 studs/s². La marche arrière reste limitée à 25 studs/s avec une progression de 8 studs/s².
- Pour éliminer la limite de force comme premier facteur, `LinearVelocity.MaxForce` passe de `AssemblyMass × 300` à `AssemblyMass × 1000`, soit environ 96 136 pour la masse observée de 96,136. Le `BodyForce` historique reste neutralisé et `VehicleSeat.MaxSpeed` est aligné à 80 sans devenir l'autorité moteur.
- Le mode `Plane` horizontal est provisoirement conservé afin de ne pas contraindre la vitesse verticale et la flottaison. L'audit Studio expose ses axes, son mode, sa consigne, son attachment, ses parents et les racines d'assembly de Body/VehicleSeat avant toute migration risquée vers Vector ou contrôle direct de vélocité.
- Un audit runtime Studio unique inventorie BodyForce, BodyVelocity, LinearVelocity, VectorForce, AlignPosition, AngularVelocity, toutes les contraintes et tous les Scripts du bateau. Les logs de conduite à 0,75 seconde ajoutent CommandedSpeed, ForwardSpeed, HorizontalSpeed, cible, mode, MaxForce et NetworkOwner.
- Le V4 ne sera considéré fonctionnel que lorsque `ForwardSpeed` mesuré restera entre 78 et 82 studs/s sur eau libre, avec accélération, décélération, marche arrière, direction, collisions et flottaison validées.

## CHEETAH MULTI-SPAWN V1

Statut : `À TESTER STUDIO`

- `WildlifeService` trie et utilise tous les points valides de `Workspace.CheetahSpawns`; la configuration Studio attendue contient `Cheetah_01`, `Cheetah_02`, `Cheetah_03` et `Cheetah_04`, pour un maximum d'un sauvage par point et quatre sauvages actifs.
- La cause de l'ancien Cheetah unique était double : le démarrage choisissait un seul point aléatoire et `CheetahConfig.MAX_ACTIVE` valait 1. La population est désormais initialisée une seule fois lorsqu'une session monde devient active, jamais dans le menu ni à chaque arrivée d'un joueur supplémentaire.
- Chaque sauvage conserve une association runtime bidirectionnelle avec son point et l'attribut `SpawnPointId`. L'apprivoisement libère cette association sans détruire le Cheetah devenu compagnon, puis programme un nouveau sauvage après 300 secondes. La mort sauvage utilise le même délai; la mort d'un compagnon n'entre pas dans ce lifecycle.
- L'état persistant existant est restauré sur un seul Cheetah dédié avant le remplissage des points sauvages. `OwnerUserId`, `Trust`, Health, Hunger, Command, inventaire RawMeat, MountStamina et Position V1 sont transmis sans changement; les autres sauvages restent initialisés comme sauvages.
- Le format actuel ne possède qu'un unique champ monde `CheetahTaming`. Sans changer le schéma, le service conserve donc un seul compagnon persistant par monde et refuse uniquement la finalisation d'un second apprivoisement qui ne pourrait pas être sauvegardé correctement.
- Les registres empêchent un double spawn par point et un compteur séparé exclut les compagnons du plafond sauvage. Les callbacks de respawn portent une génération de session afin de ne pas recréer d'animaux après ReturnToMenu.
- Aucun DataStore, clé `PROD_V1`, `SchemaVersion` ou format sauvegardé n'est modifié. Taming, RawMeat, statistiques, combat, monture, saut, locomotion et interface restent autrement inchangés.

## FACTORY OUTPUT PICKUP V1

Statut : `À TESTER STUDIO`

- Les sorties physiques `MetalWaste`, `PlasticWaste` et `WasteBag` du `AutomaticLoader` activent désormais le pickup Factory existant au lieu d'être créées avec `pickupEnabled=false`.
- Chaque objet conserve son tag `FactoryItem`, ses attributs `ItemId`/`FactoryItemId` et sa physique non ancrée, auxquels s'ajoutent `Quantity=1` et `Pickupable=true`. Le `ProximityPrompt` suit la racine physique, utilise `E`, affiche `RAMASSER` et résout le nom français depuis `ItemDefinitions`.
- Le serveur conserve la distance Factory existante de 10 studs, exige `SessionStarted`, relit l'ItemId sur l'instance et utilise `InventoryService:AddItem`. `FactoryClaimed` verrouille l'objet avant la transaction : un seul joueur peut réussir et un inventaire plein remet le verrou à `false` sans détruire l'objet.
- La capture machine existante reste prioritaire dès qu'elle réserve l'objet : elle positionne `FactoryProcessing`/`FactoryClaimed`, retire l'objet du registre et le détruit avant de l'ajouter à la file. Convoyeurs, chargeur, recycleur, presse, ratios 5:1/10:1 et temps de traitement restent inchangés.
- Ces objets restent exclusivement runtime et ne deviennent ni structures ni données persistantes. Aucun DataStore, `SchemaVersion`, clé `PROD_V1` ou format de sauvegarde n'est modifié.

## CHEST DUPLICATE INTERACTION HOTFIX V1

Statut : `À TESTER STUDIO`

- La duplication provenait du `ProximityPrompt` statique cloné avec le template Chest, auquel `BuildingService:_registerRuntimeStructure` ajoutait le `ChestPrompt` fonctionnel relié à `StationService:OpenStation`. Aucun autre service du dépôt ne crée une interaction Chest.
- `BuildingService` normalise désormais chaque modèle Chest lors du placement et du restore : il conserve au maximum l'unique `ChestPrompt` runtime portant l'attribut interne `MAYDEADStationInteraction`, supprime les prompts clonés ou doublons, puis crée le prompt officiel seulement s'il manque.
- L'initialisation répétée reste idempotente : le prompt officiel déjà connecté est conservé et tous les autres `ProximityPrompt` descendants sont retirés. Le résultat structurel attendu est exactement un prompt par coffre.
- Le prompt conservé garde `OUVRIR`, `COFFRE`, la touche E, la distance 10, l'absence de ligne de vue obligatoire, la validation `SessionStarted` et l'ouverture serveur du même objet Station.
- Un log Studio unique par initialisation expose StructureId, nombre avant/après, chemin du prompt fonctionnel et doublons retirés.
- Slots, contenu, capacité 30, StationId, StructureId, propriétaire, transfert multijoueur, placement et état persistant du coffre restent inchangés. Aucun DataStore, `SchemaVersion`, clé `PROD_V1` ou migration n'est modifié.

## CHEETAH SINGLE WILD SPAWN V2

Statut : `À TESTER STUDIO`

- La règle Multi-Spawn V1 « un sauvage par point » est remplacée à la source par une population monde plafonnée à un seul Cheetah sauvage. Tous les enfants valides de `Workspace.CheetahSpawns` restent intacts et servent de pool de positions.
- Le serveur choisit le point avec un `Random` dédié et exclut le dernier point utilisé lorsque plusieurs alternatives valides existent. Un point unique reste utilisable; `SpawnPointId` demeure un attribut runtime de diagnostic.
- `MAX_ACTIVE_WILD=1` est validé avant toute création. Les Cheetahs `Tamed` avec leur `OwnerUserId` ne sont pas comptés dans `_wildCheetahCount`, ce qui permet la coexistence d'un compagnon restauré et d'un sauvage.
- À la mort ou à l'apprivoisement du sauvage, son association runtime est libérée et un unique timer global programme le prochain sauvage après 180 secondes. `_cheetahRespawnScheduled` et la génération de session empêchent les doubles timers et les respawns après ReturnToMenu.
- L'ordre reste : restauration de l'état compagnon V1 par `WorldService`, activation `SessionStarted`, création du compagnon dédié, puis contrôle et création d'au plus un sauvage. L'arrivée d'un autre joueur rappelle seulement une initialisation idempotente.
- Les logs de population indiquent WildCount, CompanionCount, état du timer, raison Death/Tamed et point choisi. Aucun paramètre de taming, combat, monture, saut ou locomotion n'est modifié.
- OwnerUserId, Trust, Hunger, inventaire, Stamina, Command et Position du compagnon restent restaurés par le format existant. Aucun DataStore, `SchemaVersion`, clé `PROD_V1`, migration ou purge n'est ajouté.
## CHEETAH GLOBAL RESET MIGRATION V1 — RETIRÉE / HISTORIQUE

- Cette migration temporaire n'est plus exécutée. `CheetahResetVersion`, lorsqu'il existe déjà dans une sauvegarde, reste un champ historique sans aucun effet au chargement.
- Aucun nouveau marqueur n'est écrit; les anciennes valeurs restent simplement tolérées dans le document sauvegardé.
- Aucun `WorldState.CheetahTaming` valide n'est désormais supprimé, que `CheetahResetVersion` soit absent, égal à 1 ou supérieur.
- Les états Companion et sauvage disponibles suivent désormais directement leur restauration normale, puis SINGLE WILD SPAWN V2 initialise la population autorisée.
- Aucun DataStore n'est purgé, aucune clé n'est supprimée et aucune structure, station, Factory, bateau, progression, donnée joueur ou autre état monde n'est réinitialisé.

## CHEETAH PERSISTENCE + TAMING SESSION + NAMING V1.2

Statut : `À TESTER STUDIO / PROD VALIDATION REQUIRED`

- L'ancien reset automatique est retiré. Le champ historique `WorldState.CheetahResetVersion` est ignoré et tout Companion valide est conservé, y compris dans un ancien monde non migré.
- Le premier nourrissage donnant réellement du Trust démarre une session runtime liée à `TamingPlayerUserId`. Le HUD Trust existant reste visible pendant les déplacements et le cooldown; chaque nouveau gain anime la jauge et relance un timeout d'inactivité de 300 secondes.
- Le timeout masque le HUD et termine uniquement la session runtime. Il ne remet jamais le Trust à zéro; un futur gain reprend une nouvelle session depuis la valeur réelle. Une session partielle restaurée ne rouvre pas automatiquement le HUD.
- À Trust 100, le serveur définit `Tamed` et `OwnerUserId`, ferme la session, envoie le feedback `GUÉPARD APPRIVOISÉ`, puis propose l'interface de nommage. L'adoption est déjà valide et capturable avant toute réponse de cette interface.
- Le champ optionnel `CompanionName` est ajouté au snapshot `WorldState.CheetahTaming`. Sa valeur par défaut rétrocompatible est `Guépard`; les sauvegardes antérieures sans ce champ restent lisibles.
- Un nom comporte 2 à 16 caractères. Le serveur refuse les contrôles, normalise les espaces, applique `TextService:FilterStringAsync` en contexte `PublicChat`, puis `GetNonChatStringForBroadcastAsync`. Un échec conserve le nom courant et renvoie `NOM INVALIDE`.
- Seul `OwnerUserId` peut nommer ou renommer via l'action `SetName` du Remote Companion existant, limitée à une requête par seconde. Le crayon de la carte Companion ouvre la même interface; `PLUS TARD` conserve `Guépard`.
- Le titre de la carte et `CheetahCompanionPrompt.ObjectText` utilisent immédiatement le nom filtré. Aucun BillboardGui permanent n'est ajouté.
- Autosave, ReturnToMenu, PlayerRemoving et BindToClose réutilisent le snapshot monde normal : CompanionName, Trust, Health, Hunger, Inventory, Command, MountStamina et Position sont capturés sans nouveau DataStore ni changement de `SchemaVersion`.

## CHEETAH COMMANDS + FACTORY PERSISTENCE + MOUNT BUFF V1

Statut : `À TESTER STUDIO / PROD VALIDATION REQUIRED`

- `Stay` est désormais une branche terminale de locomotion compagnon : `StayPosition` est capturée à la commande, restaurée depuis la position sauvegardée et replacée sur la position du Cheetah après un dismount. Dans un rayon strict de 2 studs, l'IA annule son déplacement volontaire; hors rayon elle revient au point. Le combat serveur existant reste prioritaire, puis le Cheetah retourne à Stay.
- `Follow` reste également une branche terminale à chaque tick. La destination Owner courante est relue continuellement; au-delà des 6 studs désirés, le path/catch-up existant continue, avec détection de blocage à 2 secondes. Si l'Owner est absent, le Cheetah attend sans reprendre le roaming sauvage.
- `Command = Follow/Stay` reste dans le snapshot Companion et l'UI existante continue d'indiquer le bouton actif.
- Les allures rapides montées passent de 50 à 65 studs/s (`+30 %`); la marche reste à 30. Endurance, drain, cooldown, contrôle et inputs restent inchangés.
- `MOUNT_JUMP_VELOCITY` passe de 78 à 85,44 studs/s (`×sqrt(1,20)`). Sous gravité Roblox 196,2, la hauteur balistique théorique passe d'environ 15,50 à 18,61 studs, soit `+20 %`.
- `AutomaticLoader` conserve son état réel existant `StateVersion=1` via `StationService` : inventaire exact de 30 slots. Son délai d'éjection transitoire et les objets déjà éjectés ne sont pas persistés.
- Recycler et IndustrialPress utilisent maintenant un `FactoryState` optionnel dans le `State` de leur structure existante : `StateVersion`, `MachineType`, file FIFO, item engagé, temps restant, sorties internes en attente, sorties physiques attribuées à la machine et compteurs matière/blocs réellement utilisés.
- Recycler persiste `MetalMaterial` et `PlasticMaterial`; IndustrialPress persiste `MetalBlocksProcessed` et `PlasticBlocksProcessed`. Les ratios et temps 5/1, 10/1, 15 s et 20 s restent inchangés.
- Le restore commence par vider l'état runtime, puis remplace exactement les files et compteurs. L'item engagé reprend avec `RemainingProcessing`; aucun temps hors ligne n'est calculé et les inputs déjà consommés ne sont jamais retirés une seconde fois.
- Une sortie physique encore vivante au save est enregistrée par sa machine, nettoyée avec le runtime monde après la sauvegarde, puis remise dans `PendingOutputs` au chargement afin d'être émise exactement une fois. Les world items indépendants et sorties AutomaticLoader ne sont pas sérialisés.
- ConveyorStraight reste sans état persistant : direction et vitesse sont entièrement dérivées de sa géométrie et de ses Attributes à l'enregistrement.
- Les anciens records sans état Recycler/Press restent valides et démarrent vides. Un état incompatible conserve la structure et réinitialise seulement les champs Factory invalides avec log `[MAYDEAD][PERSISTENCE][RECOVERY]`.
- Autosave, ReturnToMenu, PlayerRemoving et BindToClose réutilisent `WorldService` et le snapshot Building avant cleanup. Aucun DataStore, clé `PROD_V1`, `SchemaVersion`, `StructuresVersion`, recette, ratio ou identité de structure n'est modifié.

## CHEETAH TAMING ROBUSTNESS + WORLD SHARED COMPANION V1

Statut : `À TESTER STUDIO / PROD VALIDATION REQUIRED`

- Le premier feed valide d'un processus vaut 60 Trust; les suivants utilisent un `Random` serveur et donnent 12 à 16 inclus. Trust est clampé à 100 et la réussite utilise `>= 100` via une finalisation autoritaire, atomique et idempotente.
- Un Cheetah ne conserve qu'un `FoodTarget` à la fois. La réservation `AVAILABLE -> RESERVED_BY_CHEETAH -> CONSUMED/AVAILABLE` est liée à l'instance Cheetah qui l'a obtenue; six RawMeat restent donc séquentiels et soumis au cooldown existant de 80 secondes.
- La session HUD démarre au premier gain réel, reste visible pendant déplacements/recherche/cooldown, puis expire après 300 secondes sans gain. Le timeout conserve Trust et libère le joueur de session; le HUD compact utilise désormais le haut-centre, `AnchorPoint (0.5, 0)` et `DeviceSafeInsets`.
- Le Companion est partagé par le monde actif : tous les joueurs admis (`SessionStarted`, hors menu/retour menu) peuvent ouvrir l'UI, nourrir, retirer, commander Follow/Stay et monter. Un seul inventaire et un seul cavalier restent autoritaires côté serveur.
- Follow possède une cible runtime unique `FollowTargetUserId`; une nouvelle commande Follow transfère explicitement la cible. Le départ de cette cible force `Stay` afin qu'aucun UserId absent ne soit suivi.
- `OwnerUserId` reste sauvegardé pour rétrocompatibilité. `OriginalTamerUserId`, avec fallback automatique vers l'ancien Owner, conserve seul les droits de nommage/renommage; nom filtré, longueur 2–16 et persistance sont inchangés.
- Le format monde reste un unique `WorldState.CheetahTaming`. Un seul Companion peut être finalisé par monde; un second sauvage reste sauvage et reçoit un feedback explicite au lieu d'être silencieusement forcé à 99. La coexistence `1 Companion + 1 Wild` reste autorisée.
- Aucun reset, purge, changement `PROD_V1`, migration destructive, duplication d'inventaire ou suppression de nom n'est ajouté.

## WORLDS UI STABILIZATION + MEMBERS PANEL POLISH V1

Statut : `À TESTER STUDIO / ROBLOX PLAYER`

- Le modal `MEMBRES DU MONDE` utilise un fond bleu-noir dédié, des lignes contrastées, des textes explicitement placés au-dessus du modal et une zone défilante avec padding et scrollbar cyan. La liste d'amis affiche un état vide explicite lorsqu'aucun ami n'est disponible.
- La cause de l'illisibilité était la combinaison de lignes entièrement transparentes et de descendants laissés au `ZIndex` par défaut sous le modal aux niveaux 40–41. Le backend existant GetMembers/ListFriends/InviteMember/RemoveMember reste inchangé.
- Les trois actions utilisent le template commun Rename/Members/Delete. Le refresh ne masque plus Rename et Delete sur le monde actif; les trois restent masquées sur les slots vides. Le recadrage `+10 px` du contenu du slot 1 est conservé.

## CHEETAH MOUNT MULTI-INPUT CONTROLS V1

Statut : `À TESTER STUDIO / ROBLOX PLAYER`

- Les contrôles montés acceptent désormais ZQSD et les flèches avec une sémantique OR par axe, sans cumul de vitesse. Sur appareil tactile, le `Humanoid.MoveDirection` analogique du joystick Roblox est transmis avec diagonales conservées.
- `JumpRequest` réutilise le saut Roblox natif pour Espace, manette et bouton tactile; l'ancien bouton tactile SAUT supplémentaire est supprimé. La connexion est créée au montage, remplacée de façon idempotente et déconnectée au démontage, respawn ou retour menu.
- Un TextBox focalisé ou le menu Roblox neutralise l'intention directionnelle. La mort du Humanoid déclenche également le nettoyage local de la monte et de sa connexion de saut.
- Vitesses, endurance, saut serveur, network ownership, Follow/Stay, taming, monde partagé, invitations et persistance ne sont pas modifiés.

## PRIVATE SHARED WORLDS + MEMBERSHIP V1

Statut : `À TESTER STUDIO / PROD VALIDATION REQUIRED`

- Les limites officielles sont 3 mondes possédés, 3 mondes rejoints et 6 membres officiels par monde propriétaire inclus. Les mondes restent privés et accessibles uniquement au propriétaire ou à `AuthorizedMembers` après invitation d'un ami.
- `world:<WorldId>.AuthorizedMembers` reste la vérité. Le DataStore Index V1 existant accueille paresseusement `member:<UserId>` avec `PendingInvites` et `JoinedWorlds`; aucun `PROD_V2`, nouveau WorldId, scan global ou migration destructive n'est ajouté.
- Acceptation : validation de l'invitation et de la limite rejointe, ajout membership par `UpdateAsync` du monde, puis ajout dans `JoinedWorlds` et retrait de `PendingInvites` par `UpdateAsync` de l'index secondaire. Aucune réservation rejointe n'existe avant l'ajout autoritaire; le record monde gagne en cas de divergence et la consultation répare l'index.

### WORLD INVITE ISOLATION + MAIN MENU ALERT V1

Statut : **À TESTER STUDIO / ROBLOX PLAYER / MULTIPLAYER**.

- Les invitations en attente sont strictement séparées des slots possédés, des mondes rejoints et de `AuthorizedMembers`.
- La création et la reprise d'un monde propriétaire restent possibles lorsqu'un autre monde est actif sur le serveur : le joueur est routé vers le monde visé sans exposer la session d'un autre joueur dans son menu.
- La première page du menu charge l'état serveur au démarrage et affiche une carte compacte Accepter/Refuser; plusieurs invitations sont indiquées par leur nombre et traitées successivement.
- Un garde de sauvegarde interdit tout autosave tant que la restauration complète du monde n'a pas réussi. Un monde neuf restauré correctement peut toujours sauvegarder zéro structure.

### FINAL FACTORY ASSEMBLY + INVENTORY INPUT FIX V2

Statut : **À TESTER STUDIO + ROBLOX PLAYER**.

- La FinalFactory réutilise exclusivement le transfert partagé de `StationController`/`StationService` dans les deux sens : drag PC/tactile pour une unité, Shift + clic gauche pour le stack complet, Shift + clic droit pour la moitié selon l'arrondi existant, et clic/appui long pour le stack complet.
- Le drag vers la Factory ne transmet plus le slot visuel survolé comme contrainte : le serveur sélectionne le slot dédié `MetalPanelStack` ou `PlasticPanelStack`, comme le faisait déjà implicitement le transfert Shift. Le seuil de déplacement existant annule l'appui long et empêche une double opération.
- Le stockage reste composé de deux slots persistants liés au `StructureId` existant : métal en slot 1, plastique en slot 2. Les autres ItemId sont refusés côté serveur sans mutation.
- `ASSEMBLER` utilise `Activated` et `FinalFactoryRequest`. Le serveur revalide membre runtime, modèle enregistré, distance, état Idle, completion mondiale et quantités 40/30 avant de verrouiller le démarrage et consommer une seule fois.
- La production reste autoritaire, dure 60 secondes actives et persiste `BuildState`, `BuildElapsed`, `PlaneSpawned` ainsi que le stockage Station V1. Une restauration Building reprend depuis l'elapsed sauvegardé sans progression hors ligne ni nouvelle consommation.
- À completion, un seul clone de `ServerStorage.AssetImports["Naval Seaplane"]` est positionné relativement au `ItemOutput`, avec orientation locale et offset calculé depuis sa bounding box. Une matérialisation échouée est retentée sans reconsommation et les gardes monde/workspace empêchent le double spawn.
- Les opérations de transfert et d'assemblage exigent maintenant une appartenance à la session runtime du monde, en plus des contrôles de proximité et des validations d'arguments existantes.
- Aucun namespace DataStore, WorldId, StructureId, ratio industriel ou recette finale n'est modifié. Les anciennes Factory sans état continuent à utiliser le fallback runtime Idle/stockage vide existant.

### FINAL FACTORY OUTPUT + UI POLISH V3

Statut : **À TESTER STUDIO + ROBLOX PLAYER**.

- `ItemOutput` est le repère unique du Naval Seaplane final. Le placement aligne la bounding box de l'avion, et non son pivot supposé, sur le centre et la face supérieure de cette Part.
- Les offsets sont centralisés dans `FactoryConfig` : position locale `(0, 0, 0)`, rotation locale `(0°, 0°, 0°)` et clearance verticale `0,15` stud. L'orientation reste relative à `ItemOutput`, y compris lorsque la FinalFactory est tournée.
- Les pièces de l'avion sont temporairement stabilisées pendant 0,25 seconde puis retrouvent exactement leur état `Anchored` d'origine; scripts et contraintes sont préservés.
- Les deux slots Factory affichent les icônes attendues même vides, sans créer de faux item : `MetalPanelStack` avec `X / 40`, puis `PlasticPanelStack` avec `X / 30`. Une quantité complète reçoit un accent discret.
- La zone droite affiche le PNG `rbxassetid://109820418000805` avec `ScaleType.Fit`, ainsi qu'une barre cyan alimentée uniquement par la progression serveur répliquée et son temps restant réel.
- Les états UI restent : `ASSEMBLER` désactivé avant 40/30, `ASSEMBLAGE EN COURS` pendant Building, puis `NAVAL SEAPLANE TERMINÉ` à 100 %.
- La recette 40/30, le temps de production, le schéma persistant, les DataStores, WorldId et StructureId sont inchangés. L'idempotence du spawn existante est conservée.
- Le save fenced fusionne l'`AuthorizedMembers` courant du record monde afin qu'une session active ne réécrase jamais une invitation acceptée ou une révocation externe.
- Un membre peut charger un monde propriétaire absent. Le routage utilise le `JobId` du lease actif ou un serveur réservé pour un monde différent; l'arrivée revalide l'autorisation avant admission.
- La page `MONDES REJOINTS` utilise `rbxassetid://121112210863801`, trois overlays transparents, invitations Accepter/Refuser, Join, liste des membres et Leave. La page propriétaire expose la gestion membres et la sélection d'amis Roblox.
- Chest, Campfire, Smelt, Factory, Door et stations étaient déjà validés par session et non par constructeur. La restriction `Structure.OwnerUserId == player.UserId` du démontage est retirée; le champ persistant et les protections anti-double-refund restent intacts.
- Famille Rico et tous les mondes V1 conservent WorldId, OwnerSlot, DisplayName, Time, PlayerStates, WorldState, StructuresVersion, structures et StructureId. Aucun reset, purge ou changement des DataStores `PROD_V1` n'est effectué.

## VOS MONDES BACKGROUND NAVIGATION POLISH V1

Statut : `À TESTER STUDIO`

- Le background `VOS MONDES` passe de `rbxassetid://130947862190730` à l'asset officiel fourni `rbxassetid://122122384221927`, réutilisé par l'unique `WorldsBackground` existant.
- L'ancien bouton Roblox visible `MONDES REJOINTS` est supprimé. Il est remplacé par un seul `TextButton` sans texte, couleur, bordure, corner ni stroke, totalement transparent et placé au-dessus du bouton déjà dessiné dans le bitmap.
- La hitbox conserve l'emprise responsive normalisée de l'ancien contrôle : position `(0.03, 0.905)`, taille `(0.20, 0.055)`, `ZIndex=20`. La navigation existante vers `JoinedWorlds` est inchangée.
- Aucun slot monde, overlay dynamique, bouton Retour, écran Mondes rejoints, service serveur, membership, DataStore ou donnée persistante n'est modifié.

## VOS MONDES CARD ACTIONS + ALIGNMENT POLISH V1

Statut : `À TESTER STUDIO`

- Le slot 1 applique désormais le même correctif horizontal `+10 px` à son petit label, son nom réel, sa ligne de métadonnées et ses icônes Année/Joueurs; leur Y et les slots 2/3 restent inchangés.

## YEARS ON ISLAND + CYCLE 17 MINUTES

Statut : `TERMINÉ — VALIDÉ STUDIO`

- Le gameplay affiche désormais `ANNÉE 0` pour un monde neuf. Un cycle complet de 17 minutes, composé de 13 minutes de jour et 4 minutes de nuit, ajoute une année passée sur l'archipel.
- La compatibilité production ne modifie ni `SchemaVersion = 1`, ni namespace, ni clé DataStore. `Time.Age`, `WorldState.EscapeAge` et `WorldState.LongevityAge` restent les champs persistants historiques et l'unique source serveur; les valeurs joueur sont dérivées avec l'offset 10.
- Un ancien monde `Age = 17` est donc présenté comme `YearsOnIsland = 7`. Un snapshot sans `CycleTimingVersion` est converti une seule fois : les secondes écoulées dans le jour ou la nuit sont conservées, puis le marqueur additif `CycleTimingVersion = 2` empêche toute reconversion ultérieure.
- `TimeState.YearsOnIsland`, les cartes de mondes, le panneau temporel de l'inventaire et le message de fin affichent la nouvelle sémantique. Les records d'évasion minimum et de longévité maximum restent stockés sans réécriture, puis sont convertis uniquement pour l'affichage.
- Validation Game Director réussie dans Roblox Studio : monde neuf, monde historique, cycle 13 + 4 minutes, incrément annuel, sauvegarde/rechargement, absence de reconversion répétée, constructions, inventaire, progression, UI, évasion et exposition des records.
- Le template commun des trois cartes utilise un conteneur d'actions élargi à 32 % avec un espacement fixe de 6 px et trois hitboxes uniformes de 38×38 px.
- L'ordre commun est imposé par `LayoutOrder` : Rename 1, Members 2, Delete 3. Rename utilise l'icône Roblox compose/crayon, Members l'icône groupe et Delete conserve la croix rouge.
- Les callbacks Rename, Members et Delete, le background, la navigation, les permissions, les mondes et toute persistence restent inchangés.

## CRAFTED BOAT RUNTIME / BUOYANCY HOTFIX V2

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- La cause runtime identifiée était le singleton de `BoatService`, limité à un modèle nommé `Workspace.Boat`. Un Boat fabriqué ou restauré sous `Workspace.PlacedStructures` conservait son assemblage physique, mais n'était jamais enregistré auprès du contrôleur central : son accélération avant/arrière n'était donc jamais mise à jour.
- `BuildingService` enregistre désormais le Boat dans son chemin de cycle de vie existant, commun à la pose et au restore, puis le désenregistre au démontage et au nettoyage du monde. Aucun second système de spawn ou scan permanent de Workspace n'est ajouté.
- `BoatService` accepte plusieurs instances de Boat, conserve la compatibilité avec l'ancien `Workspace.Boat` et pilote chacune avec les mêmes `LinearVelocity`, `AngularVelocity`, courbes d'accélération et valeurs de `BoatConfig` qu'avant.
- La préparation des véhicules continue de préserver les états `Anchored`, scripts, welds, contraintes, densités et propriétés physiques du template. Aucun nouveau modèle de flottabilité, offset vertical ou réglage de propulsion n'est introduit; la flottabilité existante du modèle/du moteur Roblox reste la référence.
- Un log `[MAYDEAD][BOAT][RUNTIME]` expose pour chaque enregistrement le chemin, `StructureId`, état enregistré, `AssemblyRootPart`, masse d'assemblage, nombre de pièces ancrées, inputs, présence des contraintes/forces, force disponible et network owner afin de valider précisément le runtime dans Studio.
- Le placement Water-only, son calcul de hauteur depuis la bounding box et la surface Terrain, les sauvegardes, `WorldId`, `StructureId`, DataStores, inventaires, contrôles et réglages de `BoatConfig` restent inchangés.

## BOAT BUOYANCY HOTFIX V3

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- La propulsion des Boats fabriqués/restaurés est réparée par V2. Le problème restant était vertical : aucun Script, `VectorForce`, `AlignPosition` ou contrôleur de flottabilité exploitable n'existe dans les sources Rojo, le `BodyForce` historique étant uniquement l'ancienne propulsion et la `LinearVelocity` validée ne contrôlant que X/Z.
- Chaque Boat enregistré reçoit donc une unique `VectorForce` verticale au centre de masse. À chaque Heartbeat centralisé, elle compense `AssemblyMass × workspace.Gravity`, puis applique une correction ressort/amortissement calculée depuis la surface Terrain Water locale et la vitesse verticale réelle.
- La masse n'est jamais mémorisée ni remplacée par une constante joueur : `AssemblyMass` est relue à chaque update, ce qui inclut conducteur et passagers soudés à l'assembly. Le changement de `VehicleSeat.Occupant` déclenche aussi un diagnostic ciblé.
- La waterline dérive de la hauteur verticale réelle de `Body` et immerge 25 % de cette coque de référence. L'initialisation place une seule fois le Boat sur cette cible locale; aucun `PivotTo` par frame, Y monde fixe, `AlignPosition` rigide ou auto-level n'est utilisé.
- Les paramètres verticaux sont centralisés dans `BoatConfig` : stiffness 35, damping 10 et plafond de force égal à trois fois le poids courant. La force est strictement verticale et ne remplace pas la propulsion horizontale.
- Les logs Studio `[MAYDEAD][BOAT][BUOYANCY]` sont limités à l'initialisation et aux changements d'occupant; ils exposent `StructureId`, masse réelle, gravité, occupant, BodyY, surface d'eau, vitesse verticale, force et système.
- Vitesses avant/arrière, accélération, décélération, direction, inputs, placement Water-only, recette, sauvegardes, DataStores, `WorldId` et `StructureId` restent inchangés.

## BOAT BUOYANCY STABILIZATION HOTFIX V4

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- Le Boat V3 ne coule plus et supporte le conducteur, mais son ressort vertical était sous-amorti : stiffness 35 contre damping 10, sans clamp explicite de la correction. Une erreur ou vitesse verticale importante pouvait donc mobiliser presque toute la réserve de force de zéro à trois fois le poids et dépasser répétitivement la waterline.
- Le contrôleur devient légèrement sur-amorti : stiffness 12 et damping 9. La correction d'accélération verticale est maintenant limitée à ±45 studs/s² avant multiplication par l'`AssemblyMass` réelle.
- Une deadband continue de 0,1 stud retire les corrections de position microscopiques autour de la waterline, tandis que l'amortissement de vitesse reste actif dans cette zone. Aucune composante de vélocité n'est écrasée et aucune limite dure de vitesse verticale n'est ajoutée.
- La compensation de gravité, la waterline géométrique, la `VectorForce` au centre de masse, le support conducteur/passagers et la boucle Heartbeat centralisée restent identiques. Les logs Studio `[MAYDEAD][BOAT][BUOYANCY_STABILITY]`, espacés par l'intervalle debug existant, exposent erreur, vitesse Y, force de base, correction, force finale et occupant.
- Propulsion avant/arrière, accélération, décélération, steering, contrôles PC/tactiles, placement Water-only, craft, modèle, persistance, DataStores, `WorldId` et `StructureId` ne sont pas modifiés.

## BOAT HANDLING + BUOYANCY POLISH V5

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- Le rebond vertical résiduel est traité sans verrouiller la vélocité : stiffness 12→10, damping 9→10, correction maximale ±45→±35 studs/s² et deadband 0,10→0,15 stud. À moins de 0,35 stud de la waterline, le damping seul est multiplié par 1,5 afin d'absorber les derniers mouvements sans renforcer le ressort.
- La direction ne possédait aucun lerp ni délai logiciel : la consigne `AngularVelocity` était déjà appliquée au Heartbeat suivant. Sa lenteur provenait du couple laissé au template et du taux haute vitesse réduit à 0,55. Le taux haute vitesse passe à 0,75, le taux basse vitesse reste 1 et `MaxTorque` devient `AssemblyMass × 2 000`; la valeur template avant remplacement est journalisée au runtime.
- La décélération passive passe de 16 à 28 studs/s², soit une consigne théorique 80→0 réduite de 5 à environ 2,86 secondes. Une inversion avant/arrière utilise une décélération séparée de 40 studs/s² jusqu'au passage par zéro, puis reprend l'accélération validée dans la nouvelle direction.
- La `VectorForce` de flottabilité reste strictement verticale. Le `LinearVelocity` horizontal, le taux bas de direction, la vitesse avant 80, la vitesse arrière 25 et les accélérations avant/arrière 14/8 restent inchangés.
- Inputs PC/tactiles, mapping `VehicleSeat`, placement Water-only, craft, modèle, persistance, DataStores, `WorldId`, `StructureId`, Cheetah, Factory et Naval Seaplane ne sont pas modifiés.

## BOAT FINAL RESPONSE TUNING V6

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- Le dernier rebond vertical est ciblé par un réglage plus amorti et moins énergique : stiffness 10→9, damping 10→11, damping proche de la waterline ×1,5→×1,6, deadband 0,15→0,18 stud et correction maximale ±35→±30 studs/s². La force reste exclusivement verticale et aucune vélocité n'est écrasée.
- L'accélération avant passe de 14 à 20 studs/s² (+42,9 %), réduisant la montée théorique 0→80 de 5,71 à 4 secondes. Pour que cette consigne reste disponible avec la masse d'assembly et les passagers, la limite du `LinearVelocity` passe de `AssemblyMass × 1 000` à `AssemblyMass × 1 300`.
- La décélération au relâchement passe de 28 à 42 studs/s², soit une consigne théorique 80→0 de 2,86 à 1,90 seconde. Le freinage lors d'une inversion passe de 40 à 60 studs/s² : il rejoint toujours zéro avant d'appliquer l'accélération validée de la direction opposée.
- Vitesse avant 80, vitesse arrière 25, accélération arrière 8, TurnSpeed 1/0,75, couple de direction, `AngularVelocity`, mapping `VehicleSeat`, inputs PC/tactiles et placement Water-only restent inchangés.
- Craft, modèle, sauvegarde/restore, DataStores, `WorldId`, `StructureId`, Cheetah, Factory et Naval Seaplane ne sont pas modifiés.

## BOAT ACCELERATION + BUOYANCY FINAL TUNING V7

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- La flottabilité vise un rebond quasi imperceptible avec un ressort encore moins énergique et davantage amorti : stiffness 9→8, damping 11→14, damping proche waterline ×1,6→×1,8, deadband 0,18→0,22 stud et correction maximale ±30→±27 studs/s². La `VectorForce` reste strictement verticale, sans ancrage, `AlignPosition` ou écrasement de vélocité.
- L'accélération avant passe de 20 à 32 studs/s². La consigne théorique 0→80 passe ainsi de 4 à 2,5 secondes sans modifier la cible maximale de 80.
- La réserve du moteur horizontal passe de `AssemblyMass × 1 300` à `AssemblyMass × 1 800` afin que la nouvelle accélération reste disponible avec le drag et les passagers. La masse réelle est toujours relue sur l'assembly; aucune force monde fixe n'est introduite.
- Un diagnostic Studio `[MAYDEAD][BOAT][ACCEL]`, limité par l'intervalle debug existant, mesure vitesse avant réelle, cible 80, temps écoulé et throttle depuis un départ proche de l'arrêt jusqu'à 97,5 % de la cible.
- Décélération 42, freinage opposé 60, vitesse arrière 25, accélération arrière 8, TurnSpeed 1/0,75, couple de direction, contrôles, placement Water-only, craft, modèle, sauvegarde/restore, DataStores, `WorldId` et `StructureId` restent inchangés.

## BOAT NON-WATER SLOWDOWN V8

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- Le comportement Water V7 reste configuré explicitement à 80 studs/s, accélération 32, marche arrière 25, décélération 42 et freinage opposé 60. Aucun coefficient global ne modifie ces valeurs.
- Le détecteur Water existant est étendu à cinq raycasts sous la bounding box réelle du Boat : centre, avant, arrière, gauche et droite. Le Boat est Water à partir de 3/5 échantillons Terrain Water; le modèle et les personnages sont exclus, mais rochers, quais, fondations et autres surfaces solides restent détectables.
- Le passage Water→NonWater demande 0,2 seconde de confirmation afin d'éviter le jitter en bord de plage. Le retour NonWater→Water est immédiat dès que la majorité 3/5 est retrouvée. Chaque changement produit un unique log Studio `[MAYDEAD][BOAT][SURFACE]` avec mode et nombre d'échantillons.
- En NonWater, la cible avant est limitée à 8 studs/s, la marche arrière à 6 et les accélérations dans les deux directions à 6 studs/s². Une consigne encore supérieure est ramenée avec la décélération V7 de 42; freinage opposé 60 et steering V7 restent disponibles pour permettre au joueur de regagner l'eau.
- `SurfaceMode` est exclusivement runtime, initialisé à l'enregistrement puis recalculé à chaque update centralisé. Il n'est ajouté à aucun snapshot et ne modifie ni DataStore, `WorldId`, `StructureId`, sauvegarde/restore, placement Water-only, craft, modèle, contrôles, flottabilité, Cheetah, Factory ou Naval Seaplane.

## OWNED WORLDS DELETE UI REFRESH HOTFIX V2

Statut : `À TESTER STUDIO + ROBLOX PLAYER`

- Des mondes joueurs existent déjà en production; ce hotfix ne modifie aucun backend persistant. L'audit confirme que `DeleteOwnerWorld` valide propriétaire, slot et WorldId, réserve uniquement ce monde, retire uniquement `Slots[tostring(slot)]` par `UpdateAsync`, puis commit uniquement le record ciblé avec rollback en cas d'échec. Aucun autre slot ou monde n'est réécrit et aucun compactage n'existe.
- La disparition visuelle venait de `MainMenuController` : après un Delete réussi, il rendait directement `response.State or {}` comme snapshot complet. Si la relecture serveur post-delete échouait, cet état partiel ne contenait pas `Slots`; `_renderWorldState` interprétait alors les trois accès nil comme trois mondes absents.
- `_refreshWorlds` devient l'unique relecture Owned Worlds fiable : il exige `Ok=true`, un `State` et une table `Slots`, puis remplace atomiquement `SessionState`. Une réponse nil, invalide ou en erreur conserve le dernier snapshot valide, affiche l'erreur et ne vide plus les cartes. Un compteur de génération protège contre une réponse de refresh obsolète.
- Après confirmation serveur, le client retire optimistement uniquement le WorldId confirmé de la copie locale de son slot, conserve toutes les autres cartes, puis appelle obligatoirement `_refreshWorlds`. Si ce refresh échoue, l'état fiable `A / vide / C` reste affiché; un échec Delete ne modifie rien.
- Les logs Studio `[MAYDEAD][WORLD_UI][DELETE]` couvrent Request/Success avec WorldId, slot et compteur non sensible; `[MAYDEAD][WORLD_UI][REFRESH]` couvre Success avec les trois slots ou Failure avec préservation explicite du snapshot.
- Namespace DataStore, schéma, WorldId, OwnerSlot, AuthorizedMembers, structures, inventaires, progression, animaux, véhicules et logique Mondes rejoints restent inchangés. Aucune migration, purge, reconstruction d'index ou normalisation de données existantes n'est ajoutée.

------------------------------------------------------------------------

# CLÔTURE DU GRAND AUDIT PRODUCTION

Statut : `GRAND AUDIT PRODUCTION MAYDEAD — CLÔTURÉ`

## État validé

- Git : checkpoint complet, historique linéaire et `main` synchronisée avec `origin/main`, sans force push.
- Session/DataStore : renouvellement de lease distinguant `Confirmed`, `Uncertain`, `Lost` et `Stopped`; une indisponibilité DataStore n'est pas assimilée à une perte confirmée et les sauvegardes restent fenced.
- État monde : `GetState` protégé, requêtes simultanées contrôlées et cache serveur court invalidé lors des changements pertinents.
- Inventaire : sauvegarde finale des Tools corrigée, 20 slots principaux + 8 QuickSlots persistants, whitelist et budgets serveur sur `InventoryRequest`, avec limitation dédiée de `RequestState`.
- Stations : transferts `SINGLE`, `FULL_STACK` et `HALF_STACK`, drag/clic long Campfire corrigé, `StationRequest` validé et limité côté serveur.
- Pêche : payloads et fréquence de `FishingRequest` validés; chemin tactile et UI mobile validés.
- Cheetah : `MountInput` valide le rider et les vecteurs finis, rejette NaN/infini, limite la fréquence et évite la réplication complète par input. `NOURRIR`, `DESCENDRE` et `SPRINT` tactiles sont validés sans changer les chemins PC.
- Factory : `FinalFactoryRequest` limite ses actions, valide la machine et applique le cooldown Assemble. Une garde monde empêche également deux FinalFactory distinctes de consommer simultanément les composants du même objectif final.
- Mobile/tablette : le chantier P1/P2 couvert par `INPUT_CONTROLS.md` est validé Studio par le Game Director; les contrôles encore marqués `À TESTER` n'étaient pas inclus dans cette validation.
- Production logs : bruit diagnostic réduit, avertissements critiques conservés et `BalanceConfig.BALANCE_DEBUG = false`; aucun asset supprimé.
- Temps : YearsOnIsland, cycle 13 + 4 minutes, persistance legacy et affichages ont été validés par le Game Director.
- Multijoueur/DataStore : SessionLock, sauvegardes fenced, mondes partagés et réservation membership atomique 3/3 ont été validés par le Game Director.
- Boat / Naval Seaplane / FinalFactory : audit statique et tests réels validés par le Game Director après le correctif de concurrence `9040ede`.

## Travaux réellement ouverts

### P0

Aucun P0 connu identifié par cet audit.

### P1

Aucun P1 connu ne reste ouvert à la date de cette clôture.

### P2

- Terminer les validations visuelles encore marquées `À TESTER` dans ce document, notamment certains écrans responsive, HUD et polish d'assets.
- Réduire progressivement les diagnostics Studio restants lorsque leurs chantiers visuels seront validés.

### FUTUR

- Poursuivre les systèmes et extensions explicitement conservés dans `ROADMAP.md` : contenu, progression avancée, records globaux, localisation, monétisation non Pay-to-Win et améliorations post-publication.

## Assets historiques

Les noms `Tree_Test`, `Stone_Test`, `MetalRock_Test`, `Crystal_Test`, le fichier non suivi `MAYDEAD-cheetah-v2.rbxlx` et le dossier non suivi `assets/` sont conservés. Un nom contenant `Test`, `_Test`, `Debug`, `Prototype`, `Old` ou `Temp` n'est jamais une preuve suffisante d'inutilisation; code et DataModel Studio doivent être vérifiés avant suppression.

## P1 MULTIJOUEUR / DATASTORE — RÉSERVATION MEMBERSHIP

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- L'audit a identifié une race lors de deux acceptations simultanées vers des mondes différents : les deux records monde pouvaient autoriser le joueur avant la revérification atomique de la limite des trois mondes rejoints, puis la réparation lazy pouvait matérialiser un quatrième index.
- `AcceptWorldInvite` réserve désormais atomiquement une entrée `JoinedWorlds` en état `Accepting` avant d'ajouter le membership au monde. La limite 3/3 est donc décidée dans l'`UpdateAsync` de l'index partagé. Un échec de mutation monde rollback uniquement cette réservation; un échec de finalisation laisse une entrée découvrable et réparable.
- `GetJoinedWorlds` ne supprime pas une réservation `Accepting` récente pendant cette transaction. Une réservation abandonnée redevient nettoyable après le timeout technique existant.
- `PlayerRemoving` resynchronise également la table runtime transmise à `WorldService` après retrait du joueur, sans modifier l'ordre de capture ni le `task.defer` de l'inventaire.
- DataStores, namespaces, schéma, champs YearsOnIsland legacy, limites officielles et système de session restent inchangés.

## P1 BOAT / NAVAL SEAPLANE — AUDIT FINAL

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- Le Boat fabriqué suit le placement serveur Water-only et le snapshot générique des structures. Sa `StructureId`, son propriétaire de structure, son pivot courant et son enregistrement `BoatService` sont restaurés sans système de sauvegarde parallèle.
- Le Boat utilise le `VehicleSeat` natif et le contrôleur physique serveur central. La hiérarchie réelle de l'asset, le network ownership Roblox, les contrôles PC/tactiles et le comportement à deux joueurs ont été validés par le Game Director.
- La FinalFactory consomme côté serveur `MetalPanelStack x40` et `PlasticPanelStack x30`, persiste son stockage et sa progression, puis matérialise un unique `Naval Seaplane` et complète l'objectif monde côté serveur.
- Une race P1 entre deux FinalFactory distinctes permettait auparavant deux consommations avant la completion mondiale. `_startFinalBuild` refuse désormais tout démarrage lorsqu'une autre FinalFactory enregistrée n'est plus `Idle`; la garde est évaluée avant la consommation et sans yield.
- Le comportement réel des assets Boat, Naval Seaplane et FinalFactory, leur assemblage et leur persistance dans le périmètre du chantier ont été validés par le Game Director.
- Aucun Remote, asset, DataStore, namespace, version de schéma, inventaire, membership, SessionLock ou format monde n'est modifié.

## FACTORY DISMANTLE FULL REFUND

Statut : `IMPLÉMENTÉ — À TESTER STUDIO`

- Recycler et IndustrialPress peuvent être démontés avec leur état non vide. Le serveur capture files, input engagé, compteurs partiels, outputs en attente et outputs physiques encore attribués avant toute mutation.
- Le remboursement Recycler conserve les ItemId exacts disponibles et convertit canoniquement `MetalMaterial` en `MetalWaste` et `PlasticMaterial` en `PlasticWaste`, unité pour unité. IndustrialPress restitue ses compteurs partiels en `MetalBlock`/`PlasticBlock`, unité pour unité.
- Les 28 slots sont simulés ensemble avec fusion des stacks et limites `MaxStack`. Une capacité insuffisante refuse tout le démontage sans modifier machine, outputs ou inventaire.
- Après validation, l'inventaire simulé est appliqué une seule fois, les outputs physiques remboursés sont détruits, la machine est désenregistrée puis supprimée. Aucun yield, nouveau Remote, changement DataStore, schéma, snapshot ou migration.
- AutomaticLoader et ConveyorStraight restent sur leur comportement existant.

## CRAFTINGTABLE RECIPE CATEGORIES

Statut : `IMPLÉMENTÉ — À TESTER STUDIO`

- La liste Workbench est regroupée visuellement dans l'ordre fixe `CONSTRUCTION → FACTORY → DIVERS`. Chaque recette porte une `UiCategory` statique centralisée; l'ordre `SortOrder` historique reste inchangé dans chaque groupe.
- Les séparateurs sont non interactifs, les cartes conservent leurs dimensions et callbacks, et le `ScrollingFrame` conserve son `AutomaticCanvasSize.Y` pour PC, tablette et téléphone.
- Aucun RecipeId, ItemId, ingrédient, quantité, temps, résultat, validation serveur, Remote ou format persistant n'est modifié.

## ÉQUILIBRAGE SURVIE V2

Statut : `IMPLÉMENTÉ — À TESTER STUDIO`

- Hunger utilise désormais `100 / 1140` par seconde : une jauge pleine atteint zéro en environ 19 minutes de temps actif, soit environ 1,12 cycle annuel MAYDEAD.
- Thirst utilise désormais `100 / 900` par seconde : une jauge pleine atteint zéro en environ 15 minutes, soit environ 0,88 cycle annuel MAYDEAD.
- La régénération normale de Health passe de 1 à 0,3 PV/s et conserve les conditions autoritaires existantes `Hunger > 25` et `Thirst > 25`.
- Les dégâts existants restent inchangés : famine 0,35 PV/s (mort depuis 100 PV en environ 4 min 46 s) et déshydratation 0,5 PV/s (environ 3 min 20 s).
- L'énergie reste inchangée : 0,005/s immobile, 0,065/s en mouvement, coût de récolte manuelle 0,75 et règles de fatigue/récupération existantes.
- Aucun multiplicateur nocturne n'est ajouté. Aucun Remote, DataStore, `SchemaVersion`, format persistant, reset ou migration de jauge n'est introduit.

## JELLYFISH — MENACE AQUATIQUE V1

Statut : `À TESTER`

- L'asset réel `Workspace.Animals.JellyFish` a été audité depuis son export local : modèle mono-`MeshPart` avec `PrimaryPart`, 15 Bones, `Humanoid`, `Animator`, deux sauvegardes `KeyframeSequence` et une animation runtime publiée `rbxassetid://10509287618` déjà jouée par son Script embarqué.
- `WildlifeService` enregistre de façon idempotente toute `JellyFish` placée directement sous `Workspace.Animals`. `JellyfishAI` conserve le pivot Studio initial comme HomePosition et utilise le `Heartbeat` central existant pour le déplacement fluide du pivot, sans Pathfinding ni Remote.
- Le serveur sélectionne toutes les 0,25 seconde le joueur admis, vivant, réellement en état `Swimming` dans du `Terrain Water` et le plus proche dans un rayon de 35 studs. La poursuite reste dans un leash de 55 studs, avance à 7 studs/s puis retourne à 5 studs/s.
- À 5 studs, la menace applique 5 PV via `SurvivalService`, au maximum une fois toutes les 1,5 seconde par joueur. Terre, plage, pont et structure au-dessus de l'eau ne suffisent pas à rendre une cible valide.
- La JellyFish est explicitement exclue des animaux chassables, marquée `Invulnerable`, protégée contre la mort de son `Humanoid`, sans loot, récompense, respawn aléatoire ni persistance dynamique.
- Aucun DataStore, schéma, snapshot monde, inventaire, YearsOnIsland, SessionLock, contrôle joueur ou Remote n'est modifié. La matrice Studio solo/multijoueur, animation et rig reste à exécuter.

## FEEDBACK VISUEL DES DÉGÂTS V1

Statut : `À TESTER`

- L'unique Remote serveur `DamageFeedback` transporte seulement un type `Taken`/`Dealt`, le montant réellement appliqué et, pour `Dealt`, la cible et sa dernière position connue. Il ne reçoit aucune requête client et ne participe à aucun calcul de dégâts.
- `DamageFeedbackService` observe les pertes réelles de Health des personnages côté serveur. JellyFish, Cheetah, faim, soif, noyade et toute autre baisse serveur déclenchent ainsi la même vignette rouge légère.
- Les hits Wildlife et Resource notifient `Dealt` uniquement après validation et mutation effective de la santé. Miss, cooldown, portée invalide, inventaire bloquant et JellyFish invulnérable ne produisent aucun nombre.
- `DamageFeedbackController` affiche quatre bords rouge sombre renforcés avec un fondu de 0,32 seconde, un flash rouge translucide de 0,08 seconde et une impulsion UI de 1 à 4 pixels selon le dégât. La caméra n'est jamais modifiée. Le nombre `Dealt` rouge-orangé reste inchangé à 0,65 seconde ; les nombres simultanés sont plafonnés à 12 et toutes les instances temporaires sont détruites.
- Correction : le flash `Taken` reste strictement ponctuel. La vignette persistante distincte de `SurvivalHUDController` dépend uniquement du ratio réel `Humanoid.Health / Humanoid.MaxHealth <= 0,20`; Hunger, Thirst, Energy et Breath conservent leurs capsules/toasts sans teinte plein écran. Le passage 20% → 21% déclenche un fade out avant masquage.
- Aucun dégât, cooldown, configuration JellyFish, contrôle, inventaire, DataStore, schéma ou format persistant n'est modifié.

## SHARK — PRÉDATEUR AQUATIQUE V1

Statut : `À TESTER`

- L'asset réel exporté `Shark-audit.rbxm` a été audité : modèle rigide de 24 `MeshPart` et un `Part` Handle utilisé comme `PrimaryPart`, entièrement ancré, avec 24 `WeldConstraint`, 10 `Beam`, 8 `ParticleEmitter`, 4 `Attachment` et un `Decal`. Il ne contient ni Humanoid, Animator, AnimationController, Bone, Motor6D, Animation, KeyframeSequence ou Script.
- `WildlifeService` enregistre de façon idempotente chaque modèle nommé `Shark` placé directement sous `Workspace.Animals`. Chaque instance garde son pivot Studio comme HomePosition et reçoit une santé serveur indépendante de 500 PV.
- `SharkAI` utilise le `Heartbeat` Wildlife central et déplace l'assemblage ancré par pivot, avec orientation progressive. Il patrouille dans le Terrain Water à 7 studs/s dans un rayon de 45 studs, détecte toutes les 0,25 seconde les nageurs valides dans un rayon de 70 studs, les poursuit à 14 studs/s, puis revient à 9 studs/s dans un leash de 110 studs.
- À 7 studs, le Shark inflige 30 PV via `SurvivalService`, au maximum une fois toutes les 1,8 seconde par joueur. Le feedback `Taken` existant est ainsi conservé. Plage, pont, Boat et structures hors état aquatique valide ne déclenchent pas l'agression.
- Le Shark réutilise `WildlifeHitRequest`, la validation serveur et le feedback `Dealt`. StoneAxe inflige 25 PV, soit 20 coups théoriques; StonePickaxe inflige 20 PV, soit 25 coups théoriques.
- Sa mort est gardée par l'attribut `IsDead`, stoppe l'IA et masque l'asset. Elle ne donne aucun RawFish, RawMeat, nourriture ou autre loot. Le même modèle réapparaît après 180 secondes à sa HomePosition avec 500 PV.
- Aucun Remote, contrôle, DataStore, SchemaVersion, snapshot monde, SessionLock, YearsOnIsland, inventaire ou balance Survival n'est ajouté ou modifié. La matrice Studio patrol/terre/eau/combat/multijoueur/respawn reste à exécuter.
