# MAYDEAD --- ARCHITECTURE TECHNIQUE

**Document :** Architecture technique\
**Projet :** MAYDEAD\
**Plateforme :** Roblox\
**Langage :** Luau\
**Workflow :** VS Code + Rojo + Git/GitHub + Roblox Studio\
**Statut :** Architecture V1 de référence\
**Date :** 8 août 2026

------------------------------------------------------------------------

## 1. RÔLE DU DOCUMENT

Ce document définit l'architecture technique officielle de MAYDEAD.

Il complète `GAME_DESIGN.md`.

Le Game Design Document définit **ce que le jeu doit faire**.

Ce document définit **comment le projet doit être structuré
techniquement** pour permettre un développement :

-   propre ;
-   rapide ;
-   maintenable ;
-   sécurisé ;
-   compatible multijoueur ;
-   compatible avec les sauvegardes persistantes ;
-   adapté au travail avec Codex ;
-   adapté à Rojo et Roblox Studio.

L'architecture peut évoluer si une contrainte technique réelle l'exige,
mais toute modification importante doit être documentée.

------------------------------------------------------------------------

## 2. PRINCIPES TECHNIQUES

MAYDEAD doit respecter les principes suivants.

### 2.1 Serveur autoritaire

Le serveur décide de tout ce qui possède une importance gameplay.

Le client ne doit jamais être considéré comme une source fiable pour :

-   ajouter des ressources ;
-   retirer des ressources ;
-   infliger des dégâts ;
-   créer des objets ;
-   valider un craft ;
-   terminer une production ;
-   modifier YearsOnIsland ;
-   modifier la météo ;
-   installer une pièce d'hydravion ;
-   modifier une sauvegarde ;
-   valider un record.

Le client demande.

Le serveur vérifie.

Le serveur applique.

### 2.2 Client responsable de l'expérience utilisateur

Le client gère principalement :

-   interface ;
-   affichage ;
-   effets visuels ;
-   caméra ;
-   sons locaux ;
-   prévisualisations de construction ;
-   retours d'interaction ;
-   animations locales lorsque cela est approprié.

### 2.3 Logique partagée

Les définitions communes doivent être centralisées afin d'éviter de
dupliquer des informations entre client et serveur.

Exemples :

-   identifiants d'items ;
-   définitions d'items ;
-   recettes ;
-   constantes ;
-   types ;
-   utilitaires ;
-   configuration d'équilibrage.

### 2.4 Modularité

Éviter les scripts géants contenant plusieurs systèmes indépendants.

Chaque système important doit disposer d'un module/service clairement
identifié.

### 2.5 Pas de logique critique dans Workspace

Les modèles et objets Roblox peuvent être placés dans Workspace, mais la
logique gameplay importante ne doit pas dépendre de scripts dispersés
arbitrairement dans chaque Part.

Les interactions doivent autant que possible être pilotées par des
systèmes centralisés.

### 2.6 Configuration plutôt que duplication

Une nouvelle ressource, recette ou machine doit idéalement être ajoutée
via une définition/configuration plutôt qu'en copiant plusieurs scripts.

------------------------------------------------------------------------

## 3. OUTILS OFFICIELS

Le workflow de développement prévu utilise :

-   **Roblox Studio** --- édition de la map, modèles, tests Roblox ;
-   **VS Code** --- édition principale du code ;
-   **Rojo** --- synchronisation entre le projet local et Roblox Studio
    ;
-   **Git** --- versionnement local ;
-   **GitHub** --- dépôt distant ;
-   **Codex** --- assistance au développement ;
-   **Aftman** --- gestion d'outils du projet lorsque nécessaire.

Des outils complémentaires pourront être ajoutés :

-   Wally ;
-   StyLua ;
-   Selene.

Ils devront être introduits progressivement et documentés avant de
devenir obligatoires.

------------------------------------------------------------------------

## 4. ARBORESCENCE ROJO ACTUELLE

La configuration actuelle utilise notamment :

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

Cette séparation constitue la base officielle :

-   `src/server` = serveur ;
-   `src/client` = client ;
-   `src/shared` = code partagé.

------------------------------------------------------------------------

## 5. ARBORESCENCE CIBLE DU PROJET

L'organisation cible est :

``` text
MAYDEAD/
│
├── AGENTS.md
├── README.md
├── aftman.toml
├── default.project.json
│
├── docs/
│   ├── GAME_DESIGN.md
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   ├── PROJECT_STATUS.md
│   └── DEVELOPMENT_RULES.md
│
└── src/
    ├── client/
    │   ├── init.client.luau
    │   ├── Controllers/
    │   ├── UI/
    │   └── Effects/
    │
    ├── server/
    │   ├── init.server.luau
    │   ├── Services/
    │   └── Systems/
    │
    └── shared/
        ├── Config/
        ├── Definitions/
        ├── Types/
        ├── Util/
        └── Network/
```

Les dossiers ne doivent pas être créés inutilement avant d'être
utilisés.

L'arborescence doit grandir avec le projet.

------------------------------------------------------------------------

## 6. BOOTSTRAP SERVEUR

`src/server/init.server.luau` constitue le point d'entrée serveur.

Son rôle doit rester limité.

Il doit principalement :

1.  charger les services nécessaires ;
2.  initialiser les systèmes ;
3.  démarrer les systèmes dans un ordre contrôlé ;
4.  signaler clairement les erreurs critiques.

Il ne doit pas devenir le fichier contenant toute la logique du jeu.

Exemple conceptuel :

``` text
init.server
    ↓
DataService
    ↓
WorldService
    ↓
PlayerService
    ↓
InventoryService
    ↓
SurvivalService
    ↓
CraftingService
    ↓
etc.
```

L'ordre réel sera défini au fur et à mesure du développement.

------------------------------------------------------------------------

## 7. BOOTSTRAP CLIENT

`src/client/init.client.luau` constitue le point d'entrée client.

Il initialise notamment les futurs contrôleurs responsables de :

-   HUD ;
-   interactions ;
-   inventaire ;
-   crafting ;
-   construction ;
-   caméra ;
-   notifications ;
-   effets météo ;
-   menus.

Comme le serveur, il doit rester léger.

------------------------------------------------------------------------

## 8. SERVICES SERVEUR

Les systèmes majeurs devront progressivement être organisés en services.

Architecture cible indicative :

``` text
src/server/Services/

DataService.luau
WorldService.luau
SessionService.luau
PlayerService.luau
InventoryService.luau
ItemService.luau
ResourceService.luau
SurvivalService.luau
TimeService.luau
WeatherService.luau
CraftingService.luau
BuildingService.luau
StorageService.luau
FarmingService.luau
AnimalService.luau
CombatService.luau
MachineService.luau
PowerService.luau
ExplorationService.luau
DocumentService.luau
BlueprintTableService.luau
HydroplaneService.luau
RecordService.luau
```

Cette liste représente une direction d'architecture.

Elle ne signifie pas que tous ces fichiers doivent être créés
immédiatement.

Un service doit être créé lorsqu'une fonctionnalité réelle le nécessite.

------------------------------------------------------------------------

## 9. RESPONSABILITÉS DES SERVICES

### DataService

Responsable de :

-   chargement des données persistantes ;
-   sauvegarde ;
-   migrations ;
-   validation des données ;
-   gestion des erreurs de sauvegarde.

### WorldService

Responsable de l'état général du monde :

-   identifiant du monde ;
-   propriétaire ;
-   membres ;
-   progression globale ;
-   état d'évasion.

### SessionService

Responsable de la session active :

-   verrouillage du monde ;
-   empêcher deux serveurs d'utiliser simultanément la même sauvegarde ;
-   gestion entrée/sortie des joueurs ;
-   état actif/inactif.

### PlayerService

Responsable de l'état gameplay individuel :

-   personnage ;
-   données individuelles ;
-   spawn ;
-   respawn ;
-   lit revendiqué.

### InventoryService

Responsable de :

-   slots ;
-   stacks ;
-   ajout/retrait ;
-   déplacement ;
-   validation ;
-   inventaire joueur.

### ResourceService

Responsable de :

-   arbres ;
-   rochers ;
-   minerais ;
-   récolte ;
-   respawn des ressources.

### WildlifeService

Responsable des animaux et menaces environnementales serveur. La JellyFish
placée sous `Workspace.Animals` est enregistrée sans clone ni spawn aléatoire.
`JellyfishAI` conserve son pivot initial comme position d'origine, sélectionne
le joueur aquatique valide le plus proche et pilote poursuite, leash, retour
et cooldown de dégâts depuis le `Heartbeat` central de `WildlifeService`.

La validation aquatique et les dégâts réutilisent `SurvivalService`. La
JellyFish reste exclue des définitions d'animaux chassables, porte les attributs
runtime `JellyfishHazard` et `Invulnerable`, ne produit aucun loot et n'entre
dans aucun snapshot de monde.

### SurvivalService

Responsable de :

-   vie ;
-   faim ;
-   soif ;
-   énergie ;
-   oxygène ;
-   sommeil ;
-   conséquences associées.

### TimeService

Responsable de :

-   cycle jour/nuit ;
-   temps du monde ;
-   YearsOnIsland ;
-   progression annuelle.

### WeatherService

Responsable de :

-   état météo ;
-   transitions ;
-   pluie ;
-   orage ;
-   conséquences serveur de la météo.

### CraftingService

Responsable de :

-   recettes ;
-   validation des ingrédients ;
-   craft manuel ;
-   craft des stations.

### BuildingService

Responsable de :

-   validation du placement ;
-   snapping ;
-   création serveur ;
-   démontage ;
-   permissions.

### StorageService

Responsable des inventaires persistants appartenant à :

-   coffres ;
-   stations ;
-   machines ;
-   véhicules lorsque nécessaire.

### FarmingService

Responsable de :

-   bacs ;
-   graines ;
-   eau ;
-   croissance ;
-   récoltes ;
-   engrais.

### AnimalService

Responsable de :

-   spawn ;
-   comportement ;
-   hostilité ;
-   récompenses ;
-   logique générale des animaux.

### MachineService

Responsable de :

-   production ;
-   entrées ;
-   sorties ;
-   timers ;
-   machines industrielles.

### PowerService

Responsable de :

-   générateurs ;
-   zones alimentées ;
-   consommation éventuelle ;
-   état électrique des machines.

### DocumentService

Responsable de :

-   Documents techniques ;
-   récupération ;
-   état analysé/non analysé ;
-   progression partagée.

### BlueprintTableService

Responsable de la Table de Plans et de l'analyse des Documents
techniques.

### HydroplaneService

Responsable de :

-   chantier ;
-   composants ;
-   installation ;
-   progression ;
-   état final ;
-   préparation de l'évasion.

### RecordService

Responsable de :

-   validation des performances ;
-   catégories Solo à 6 joueurs ;
-   enregistrement ;
-   préparation des classements.

------------------------------------------------------------------------

## 10. CONTRÔLEURS CLIENT

Les fonctionnalités purement client seront progressivement organisées en
contrôleurs.

Exemples :

``` text
src/client/Controllers/

InteractionController.luau
InventoryController.luau
CraftingController.luau
BuildingController.luau
CameraController.luau
SurvivalController.luau
WeatherController.luau
NotificationController.luau
MenuController.luau
```

Le contrôleur client ne doit pas reproduire la logique serveur.

Exemple :

`CraftingController` peut afficher qu'une recette semble disponible.

Mais seul `CraftingService` peut réellement confirmer le craft et
retirer les ressources.

------------------------------------------------------------------------

## 11. MODULES PARTAGÉS

`src/shared` contient les informations dont le client et le serveur ont
besoin.

Exemple cible :

``` text
src/shared/

Config/
    GameConfig.luau
    BalanceConfig.luau

Definitions/
    ItemDefinitions.luau
    RecipeDefinitions.luau
    ResourceDefinitions.luau
    BuildingDefinitions.luau
    MachineDefinitions.luau

Types/
    GameTypes.luau

Util/
    TableUtil.luau
    MathUtil.luau

Network/
    RemoteNames.luau
```

Le contenu réel sera créé progressivement.

------------------------------------------------------------------------

## 12. IDENTIFIANTS D'OBJETS

Les objets gameplay doivent utiliser des identifiants stables.

Exemples :

``` text
Wood
Stone
RawMetal
CopperOre
Crystal
Leather
CookedMeat
RawMeat
Campfire
CraftingTable
```

Les identifiants internes ne doivent pas dépendre du texte affiché au
joueur.

Exemple :

``` text
ID interne : RawMetal
Nom affiché FR : Métal brut
Nom affiché EN : Raw Metal
```

Cela permettra notamment une localisation future.

------------------------------------------------------------------------

## 13. DÉFINITIONS D'ITEMS

Les items doivent être pilotés par des données centralisées.

Une définition peut contenir notamment :

-   ID ;
-   catégorie ;
-   stack maximum ;
-   icône ;
-   nom affiché ;
-   description ;
-   consommable ou non ;
-   outil ou non ;
-   propriétés spécifiques.

Il faut éviter un script différent pour chaque morceau de bois ou
minerai.

------------------------------------------------------------------------

## 14. RECETTES

Les recettes doivent être centralisées.

Une recette doit pouvoir définir :

-   identifiant ;
-   station nécessaire ;
-   ingrédients ;
-   quantités ;
-   résultat ;
-   quantité produite ;
-   temps de production éventuel ;
-   conditions de déblocage.

Exemple conceptuel :

``` text
Recipe: WoodPlank
Station: CraftingTable
Input:
    Wood x5
Output:
    WoodPlank x2
```

Les valeurs exactes appartiennent au Game Design/équilibrage.

------------------------------------------------------------------------

## 15. RÉSEAU CLIENT / SERVEUR

Les communications passent par des RemoteEvents/RemoteFunctions
clairement définis.

Ils doivent être regroupés et nommés proprement.

Exemples conceptuels :

``` text
RequestCraft
RequestHarvest
RequestPlaceBuilding
RequestSleep
RequestInteract
InventoryUpdated
WeatherChanged
Notification
```

Le client ne doit jamais envoyer une commande du type :

``` text
GiveMe100Wood
```

Il envoie une intention :

``` text
RequestHarvest(resourceId)
```

Le serveur vérifie :

-   distance ;
-   ressource existante ;
-   outil ;
-   cooldown ;
-   état de la ressource ;
-   autres règles.

Puis seulement il attribue la récompense.

------------------------------------------------------------------------

## 16. VALIDATION DES REMOTES

Toute requête client ayant un effet gameplay doit être validée.

Les validations peuvent inclure :

-   type des arguments ;
-   distance ;
-   permissions ;
-   cooldown ;
-   existence de l'objet ;
-   état actuel ;
-   quantité ;
-   propriété du monde ;
-   capacité de l'inventaire.

Les RemoteEvents ne doivent jamais faire confiance au client.

------------------------------------------------------------------------

## 17. INTERACTIONS

Les interactions du monde doivent suivre une logique commune.

L'objectif est d'éviter une implémentation différente pour :

-   arbre ;
-   coffre ;
-   feu ;
-   Table de Plans ;
-   chantier ;
-   lit ;
-   machine.

Un système d'interaction central pourra gérer :

-   objet ciblé ;
-   distance ;
-   prompt ;
-   action ;
-   requête serveur.

Roblox `ProximityPrompt` peut être utilisé lorsque pertinent.

L'utilisation exacte sera décidée système par système.

------------------------------------------------------------------------

## 18. COLLECTIONSERVICE ET TAGS

Les objets du monde peuvent utiliser `CollectionService` afin d'être
identifiés par catégorie.

Exemples de tags possibles :

``` text
Harvestable
Storage
CraftingStation
Bed
FarmPlot
Machine
HydroplanePart
Interactable
```

Cela permet aux systèmes centraux de détecter les objets sans scripts
individuels dispersés.

------------------------------------------------------------------------

## 19. ATTRIBUTES ROBLOX

Les Attributes peuvent être utilisés pour stocker des informations
simples sur les instances.

Exemples :

``` text
ResourceId = "Tree_Palm"
WorldObjectId = "..."
OwnerWorldId = "..."
BuildingId = "WoodWall"
```

Les données persistantes importantes restent gérées par les services et
la sauvegarde.

------------------------------------------------------------------------

## 20. SAUVEGARDE --- PRINCIPES

MAYDEAD nécessite une sauvegarde robuste.

Les données persistantes devront être séparées entre :

### Données joueur

Exemples :

-   paramètres ;
-   préférences ;
-   mondes possédés ;
-   références aux mondes accessibles ;
-   statistiques personnelles.

### Données monde

Exemples :

-   propriétaire ;
-   membres ;
-   YearsOnIsland ;
-   constructions ;
-   coffres ;
-   cultures ;
-   machines ;
-   progression ;
-   Documents analysés ;
-   hydravion ;
-   état d'évasion ;
-   records du monde.

------------------------------------------------------------------------

## 21. DATASTORE

Les données persistantes Roblox devront utiliser les services officiels
adaptés, notamment `DataStoreService`.

Les sauvegardes doivent être :

-   versionnées ;
-   validées ;
-   protégées contre les écritures concurrentes ;
-   récupérables autant que possible après erreur.

Il ne faut pas multiplier inutilement les écritures DataStore.

------------------------------------------------------------------------

## 22. SCHÉMA DE DONNÉES VERSIONNÉ

Chaque sauvegarde importante doit contenir une version.

Exemple :

``` text
DataVersion = 1
```

Si la structure change plus tard :

``` text
DataVersion = 2
```

une migration doit transformer les anciennes données.

Le joueur ne doit pas perdre son monde simplement parce que le code a
évolué.

------------------------------------------------------------------------

## 23. SAUVEGARDE DU MONDE

Un monde persistant devra posséder un identifiant unique.

Exemple conceptuel :

``` text
WorldId
OwnerUserId
Members
CreatedAt
Age (legacy persisted field = YearsOnIsland + 10)
WorldState
Buildings
Storages
Farms
Machines
Documents
Hydroplane
EscapeState
```

Le schéma réel sera défini avant l'implémentation du système de monde.

------------------------------------------------------------------------

## 24. VERROUILLAGE DE SESSION

Comme un membre peut jouer sans le propriétaire, une sauvegarde monde ne
peut pas simplement être attachée au joueur créateur.

Lorsqu'un serveur charge un monde :

1.  il tente d'obtenir un verrou de session ;
2.  si le monde est libre, il devient l'instance active ;
3.  si le monde est déjà actif ailleurs, le second chargement est refusé
    ou redirigé ;
4.  le verrou est libéré proprement à la fermeture.

Une protection contre les serveurs ayant crashé devra être prévue.

------------------------------------------------------------------------

## 25. AUTOSAVE

Le monde doit être sauvegardé périodiquement.

Il doit également être sauvegardé lors d'événements importants.

Exemples :

-   joueur quittant proprement ;
-   Document analysé ;
-   composant majeur d'hydravion installé ;
-   évasion réussie ;
-   fermeture serveur.

Les sauvegardes trop fréquentes doivent être évitées afin de respecter
les limites Roblox.

------------------------------------------------------------------------

## 26. DÉCONNEXION SÉCURISÉE

La mécanique du lit nécessite une distinction entre :

-   sauvegarde technique ;
-   état gameplay sécurisé.

Le serveur doit continuer à sauvegarder techniquement les données
nécessaires même si le joueur n'a pas dormi.

Le fait de ne pas dormir ne doit jamais empêcher la sauvegarde technique
et provoquer une corruption.

La règle du lit doit être appliquée au niveau gameplay.

Le comportement précis de l'inventaire lors d'une déconnexion non
sécurisée reste une décision de conception à finaliser avant
implémentation.

------------------------------------------------------------------------

## 27. CONSTRUCTIONS PERSISTANTES

Les constructions ne doivent pas être sauvegardées comme une copie brute
gigantesque du Workspace si une représentation plus compacte est
possible.

Une construction peut être représentée par :

``` text
BuildingId
Position
Rotation
OwnerUserId
State
```

Le serveur reconstruit ensuite le monde à partir de ces données.

Les informations inutiles ne doivent pas être sauvegardées.

------------------------------------------------------------------------

## 28. IDENTIFIANTS UNIQUES

Les objets persistants qui doivent être référencés individuellement
peuvent recevoir un identifiant unique.

Exemples :

-   coffre ;
-   lit ;
-   machine ;
-   chantier ;
-   construction spéciale.

Cela permet notamment :

-   renommage ;
-   stockage ;
-   permissions ;
-   sauvegarde ;
-   mise à jour.

------------------------------------------------------------------------

## 29. RESSOURCES DU MONDE

Les arbres et minerais ordinaires respawnent.

Il n'est donc pas nécessaire de sauvegarder éternellement chaque arbre
coupé si le système peut simplement restaurer son état.

Le ResourceService doit gérer :

``` text
Disponible
↓
Récolté
↓
Cooldown
↓
Respawn
```

Les valeurs de respawn proviennent de la configuration d'équilibrage.

------------------------------------------------------------------------

## 30. TEMPS ET ANNÉES SUR L'ARCHIPEL

Le serveur est l'autorité du temps.

`TimeService` gère :

-   progression de la journée ;
-   nuit ;
-   changement de YearsOnIsland ;
-   événements de cycle.

Le client reçoit l'état nécessaire pour afficher :

-   heure visuelle ;
-   YearsOnIsland ;
-   transitions.

Le client ne calcule pas seul YearsOnIsland. `TimeService` conserve le champ
persistant historique `Age` comme source unique du schéma V1 et réplique
`YearsOnIsland = Age - 10`. `CycleProgress` reste une progression normalisée.
Un snapshot sans `CycleTimingVersion` est interprété comme le cycle historique
10 + 4 minutes puis converti une seule fois vers la version 13 + 4 en conservant
les secondes écoulées et la phase; le marqueur additif vaut ensuite `2`.

------------------------------------------------------------------------

## 31. MÉTÉO --- ARCHITECTURE

`WeatherService` choisit et maintient l'état météo officiel.

Le serveur gère les conséquences gameplay :

-   pluie sur cultures ;
-   remplissage de récupérateurs ;
-   autres effets.

Le client peut gérer les effets coûteux purement visuels :

-   particules de pluie ;
-   sons ;
-   éclairs visuels ;
-   effets écran.

Ainsi, une goutte de pluie n'a pas besoin d'être un objet réseau
physique simulé pour chaque joueur.

------------------------------------------------------------------------

## 32. INVENTAIRE --- AUTORITÉ

L'inventaire officiel existe côté serveur.

Le client possède une représentation pour l'interface.

Lorsqu'un changement est validé :

``` text
Serveur modifie inventaire
↓
Serveur envoie mise à jour
↓
Client rafraîchit UI
```

Le client ne modifie jamais directement son inventaire officiel.

------------------------------------------------------------------------

## 33. CRAFTING --- FLUX

Flux recommandé :

``` text
Joueur sélectionne recette
↓
Client RequestCraft
↓
Serveur vérifie station
↓
Serveur vérifie ingrédients
↓
Serveur vérifie espace
↓
Serveur retire ingrédients
↓
Serveur ajoute/lance résultat
↓
Client reçoit mise à jour
```

Les crafts temporisés doivent être gérés par le serveur.

------------------------------------------------------------------------

## 34. MACHINES --- TIMERS

Les machines peuvent utiliser des timestamps/états plutôt qu'une boucle
coûteuse exécutée à chaque frame.

Exemple :

``` text
ProductionStart
ProductionDuration
RecipeId
```

Le serveur détermine si la production est terminée.

L'architecture doit éviter une boucle `while true` indépendante pour
chaque machine si une approche centralisée est possible.

------------------------------------------------------------------------

## 35. AGRICULTURE --- TIMERS

Même principe pour les cultures.

Une culture peut conserver :

-   graine ;
-   stade ;
-   eau ;
-   engrais ;
-   temps de progression.

Il faut éviter des calculs coûteux à chaque frame pour chaque plante.

------------------------------------------------------------------------

## 36. ANIMAUX

Les animaux doivent être contrôlés côté serveur pour les décisions
importantes :

-   cible ;
-   attaque ;
-   dégâts ;
-   mort ;
-   loot.

Le client peut contribuer à l'affichage et aux animations lorsque cela
ne compromet pas l'autorité serveur.

Les comportements devront rester suffisamment simples pour fonctionner
avec plusieurs joueurs et plusieurs animaux.

------------------------------------------------------------------------

## 37. CONSTRUCTION --- PRÉVISUALISATION

La prévisualisation de placement peut être client-side pour offrir une
réponse immédiate.

Exemple :

``` text
Client affiche Ghost
↓
Client calcule snap visuel
↓
Joueur confirme
↓
Serveur valide position
↓
Serveur crée construction officielle
```

Le serveur doit vérifier notamment :

-   distance ;
-   collision ;
-   permissions ;
-   ressources ;
-   type de construction ;
-   position acceptable.

------------------------------------------------------------------------

## 38. HYDRAVION

Le Projet Hydravion doit être entièrement autoritaire côté serveur.

Le serveur stocke :

-   Documents analysés ;
-   composants débloqués ;
-   composants fabriqués ;
-   composants installés ;
-   progression ;
-   état final.

Le client affiche la progression et les interactions.

L'installation d'un composant ne doit jamais dépendre uniquement de la
visibilité d'un MeshPart côté client.

------------------------------------------------------------------------

## 39. RECORDS

Un record n'est enregistré que par le serveur.

Avant validation :

-   vérifier que l'évasion est réelle ;
-   récupérer YearsOnIsland depuis le serveur ;
-   récupérer la taille d'équipe ;
-   vérifier les règles de classement ;
-   vérifier l'intégrité de la partie.

Les classements devront être conçus de manière à limiter les exploits.

------------------------------------------------------------------------

## 40. SÉCURITÉ ANTI-EXPLOIT

MAYDEAD doit partir du principe qu'un exploiteur peut :

-   appeler des RemoteEvents ;
-   modifier son client ;
-   téléporter visuellement son personnage ;
-   falsifier son UI ;
-   envoyer des valeurs impossibles.

Les systèmes importants doivent donc effectuer leurs propres validations
serveur.

Exemples :

### Récolte

Vérifier :

-   ressource valide ;
-   distance ;
-   outil ;
-   cooldown.

### Craft

Vérifier :

-   recette valide ;
-   ingrédients ;
-   station ;
-   capacité.

### Construction

Vérifier :

-   recette ;
-   ressources ;
-   position ;
-   permissions.

### Combat

Vérifier autant que possible :

-   cadence ;
-   portée ;
-   état ;
-   cible.

------------------------------------------------------------------------

## 41. PERFORMANCE

MAYDEAD contient potentiellement :

-   grande map ;
-   végétation ;
-   ressources ;
-   animaux ;
-   constructions ;
-   machines ;
-   météo ;
-   jusqu'à 6 joueurs.

La performance doit donc être surveillée dès le début.

Principes :

-   éviter les boucles par frame inutiles ;
-   utiliser des événements lorsque possible ;
-   centraliser les mises à jour périodiques ;
-   limiter les objets physiques inutiles ;
-   désactiver/mettre en veille les systèmes éloignés si nécessaire ;
-   utiliser StreamingEnabled si les tests confirment son intérêt ;
-   profiler avant d'optimiser prématurément.

------------------------------------------------------------------------

## 42. GRANDE MAP

Les systèmes ne doivent pas supposer que la map tient dans une petite
zone.

Les effets visuels tels que la pluie doivent fonctionner autour des
joueurs plutôt que nécessiter un immense volume de particules couvrant
tout l'archipel.

Les ressources et animaux peuvent être activés selon les zones lorsque
nécessaire.

------------------------------------------------------------------------

## 43. STREAMING

Roblox `StreamingEnabled` devra être étudié pour la grande map.

Si activé, le code ne doit pas supposer que tous les objets du Workspace
existent constamment sur chaque client.

Les systèmes serveur restent la référence.

Les interactions client doivent tolérer le chargement/déchargement
d'instances.

------------------------------------------------------------------------

## 44. INTERFACE

L'interface doit être découplée de la logique gameplay.

Une UI ne doit pas directement :

-   donner un item ;
-   modifier une sauvegarde ;
-   changer la faim ;
-   terminer une production.

Elle affiche des données et envoie des intentions.

Les écrans prévus comprennent notamment :

-   menu principal ;
-   sélection/création de monde ;
-   gestion des membres ;
-   HUD ;
-   inventaire ;
-   crafting ;
-   Guide de fabrication ;
-   stockage ;
-   machines ;
-   Table de Plans ;
-   Projet Hydravion ;
-   écran d'évasion ;
-   records.

------------------------------------------------------------------------

## 45. MENU PRINCIPAL ET SERVEURS

Le joueur ne doit pas être projeté automatiquement dans une partie déjà
avancée avec des inconnus.

Le flux cible est :

``` text
Lancement MAYDEAD
↓
Menu principal
↓
Créer / Reprendre / Rejoindre un monde autorisé
↓
Chargement du monde
↓
Gameplay
```

La logique exacte de téléportation/réservation des serveurs sera conçue
lors du chantier multijoueur.

------------------------------------------------------------------------

## 46. CINÉMATIQUES

Les cinématiques peuvent être gérées principalement côté client :

-   caméra scriptée ;
-   animations ;
-   transitions ;
-   UI ;
-   son.

Le serveur doit déclencher/autoriser les événements importants.

Exemples :

-   crash initial ;
-   évasion finale.

Les cinématiques ne doivent pas être la source officielle d'un
changement de progression.

------------------------------------------------------------------------

## 47. LOCALISATION

Même si la première version peut être développée avec une langue
principale, l'architecture ne doit pas rendre impossible une
localisation future.

Les identifiants internes doivent rester indépendants du texte affiché.

Éviter :

``` text
if ItemName == "Bois" then
```

Préférer :

``` text
if ItemId == "Wood" then
```

------------------------------------------------------------------------

## 48. CONFIGURATION D'ÉQUILIBRAGE

Les valeurs susceptibles d'être ajustées doivent être regroupées.

Exemples :

-   durée jour ;
-   durée nuit ;
-   respawn arbres ;
-   respawn minerais ;
-   cuisson ;
-   consommation faim ;
-   consommation soif ;
-   énergie ;
-   dégâts ;
-   stack maximum ;
-   temps de croissance.

Elles ne doivent pas être dispersées dans des dizaines de scripts.

------------------------------------------------------------------------

## 49. JOURNALISATION

Les systèmes critiques doivent produire des logs utiles en
développement.

Exemples :

``` text
[DataService] World loaded: ...
[SessionService] Lock acquired: ...
[HydroplaneService] Component installed: ...
```

Éviter les `print()` permanents et inutiles en production.

Les erreurs importantes doivent être identifiables rapidement.

------------------------------------------------------------------------

## 50. GESTION DES ERREURS

Les erreurs DataStore et services Roblox doivent être anticipées.

Une sauvegarde échouée ne doit pas être silencieuse.

Les opérations critiques peuvent nécessiter :

-   `pcall` ;
-   retry raisonnable ;
-   journalisation ;
-   état de sécurité.

Le joueur ne doit jamais recevoir un faux message « sauvegardé » si la
sauvegarde a échoué.

------------------------------------------------------------------------

## 51. TESTS

Chaque grand système doit être testé dans plusieurs situations.

Minimum :

-   solo ;
-   serveur avec plusieurs joueurs ;
-   joueur rejoignant ;
-   joueur quittant ;
-   respawn ;
-   serveur fermé ;
-   mauvaise requête client ;
-   inventaire plein ;
-   interaction à distance incorrecte.

Les systèmes multijoueurs ne doivent pas être considérés terminés après
un test solo uniquement.

------------------------------------------------------------------------

## 52. GIT

Git constitue la sécurité principale du code source.

Avant une modification importante :

-   vérifier que le projet est dans un état propre ;
-   créer un commit lorsque l'étape précédente est stable.

Les commits doivent décrire clairement la modification.

Exemples :

``` text
feat: add day night cycle
feat: add resource harvesting
fix: prevent duplicate harvest rewards
docs: add MAYDEAD architecture
```

------------------------------------------------------------------------

## 53. BRANCHE PRINCIPALE

La branche principale actuelle est :

``` text
main
```

Pour le début du projet, une architecture Git complexe n'est pas
nécessaire.

Des branches dédiées pourront être utilisées plus tard pour des
chantiers risqués.

------------------------------------------------------------------------

## 54. GITHUB

GitHub sert de sauvegarde distante et d'historique.

Aucun secret ne doit être ajouté au dépôt.

Ne jamais committer :

-   token ;
-   clé API ;
-   mot de passe ;
-   secret privé.

Le `.gitignore` doit être maintenu correctement.

------------------------------------------------------------------------

## 55. ROJO

Rojo synchronise le code local avec Roblox Studio.

Le fichier :

``` text
default.project.json
```

définit la correspondance entre le projet local et le DataModel Roblox.

Toute modification de l'arborescence Rojo doit être faite avec prudence.

Ne pas modifier ce fichier uniquement pour « ranger » sans raison
technique.

------------------------------------------------------------------------

## 56. ROBLOX STUDIO

Roblox Studio reste utilisé pour :

-   map ;
-   Terrain ;
-   modèles ;
-   MeshParts ;
-   collisions ;
-   attachments ;
-   animations ;
-   tests ;
-   propriétés Roblox ;
-   éléments difficiles à gérer uniquement en texte.

Le projet ne cherche pas à supprimer Roblox Studio du workflow.

VS Code et Studio ont des rôles complémentaires.

------------------------------------------------------------------------

## 57. CODEX

Codex doit travailler à partir de la documentation officielle du projet.

Avant une modification importante, il doit tenir compte au minimum de :

-   `AGENTS.md` ;
-   `docs/GAME_DESIGN.md` ;
-   `docs/ARCHITECTURE.md` ;
-   `docs/PROJECT_STATUS.md` ;
-   `docs/DEVELOPMENT_RULES.md`.

Codex ne doit pas inventer une règle de Game Design lorsqu'elle n'est
pas définie.

------------------------------------------------------------------------

## 58. RÈGLE DES FICHIERS COMPLETS

Lorsqu'un script existant doit être remplacé manuellement, la méthode
privilégiée est de fournir le fichier complet prêt à remplacer plutôt
qu'un fragment ambigu.

Avec Codex directement dans le dépôt, il peut modifier le fichier
lui-même lorsque cela est demandé et vérifiable.

Les modifications doivent rester ciblées.

------------------------------------------------------------------------

## 59. PAS DE SUR-ARCHITECTURE

MAYDEAD doit rester simple tant que le besoin n'existe pas.

Ne pas créer :

-   100 modules vides ;
-   un framework maison complexe ;
-   des abstractions sans usage ;
-   des systèmes génériques impossibles à comprendre.

Principe :

**architecture suffisamment solide pour évoluer, mais pas plus complexe
que nécessaire.**

------------------------------------------------------------------------

## 60. ORDRE TECHNIQUE GÉNÉRAL

L'architecture recommande de construire le jeu par couches.

### Fondation

-   workflow ;
-   Rojo ;
-   Git ;
-   configuration ;
-   bootstrap.

### Monde

-   cycle ;
-   météo ;
-   interactions ;
-   ressources.

### Joueur

-   inventaire ;
-   survie ;
-   mort ;
-   sommeil.

### Production

-   crafting ;
-   stockage ;
-   construction ;
-   agriculture ;
-   transformation.

### Exploration

-   radeau ;
-   animaux ;
-   combat ;
-   îles secondaires.

### Progression avancée

-   Table de Plans ;
-   Documents ;
-   industrie ;
-   électricité ;
-   automatisation.

### Fin

-   chantier ;
-   hydravion ;
-   évasion ;
-   records.

L'ordre détaillé appartient à `ROADMAP.md`.

------------------------------------------------------------------------

## 61. SOURCE DE VÉRITÉ

En cas de conflit :

### Conception

`docs/GAME_DESIGN.md` est prioritaire pour les règles gameplay.

### Architecture

`docs/ARCHITECTURE.md` est prioritaire pour l'organisation technique.

### État réel

`docs/PROJECT_STATUS.md` indique ce qui est réellement implémenté.

### Règles de développement

`docs/DEVELOPMENT_RULES.md` définit la manière de travailler.

### Contrôles joueur

`docs/INPUT_CONTROLS.md` est la source de vérité des chemins PC, tablette et
téléphone. Une évolution d'input ou d'UI interactive doit préserver les
validations serveur et mettre à jour cette matrice.

### Instructions Codex

`AGENTS.md` résume les instructions impératives.

Si deux documents officiels se contredisent, le conflit doit être résolu
dans la documentation avant de poursuivre une implémentation dépendante
de cette règle.

------------------------------------------------------------------------

## 62. RÈGLE DE MODIFICATION

Une modification d'architecture importante doit :

1.  répondre à un besoin réel ;
2.  être comprise avant implémentation ;
3.  éviter de casser les systèmes existants ;
4.  être documentée ;
5.  être testée ;
6.  être commitée lorsqu'elle est stable.

------------------------------------------------------------------------

## PRIVATE SHARED WORLDS + MEMBERSHIP V1

- Le record `world:<WorldId>` de `MAYDEAD_WorldData_{DEV|PROD}_V1` reste la vérité d'accès via `OwnerUserId` et `AuthorizedMembers[stringUserId] = true`.
- Le même `MAYDEAD_WorldIndex_{DEV|PROD}_V1` reçoit des records légers `member:<UserId>` contenant `PendingInvites` et `JoinedWorlds`. Cet index de navigation est réparé lazy depuis le record monde; aucun scan global ni nouveau namespace n'est introduit.
- `owner:<UserId>.Slots`, `member:<UserId>.JoinedWorlds` et `member:<UserId>.PendingInvites` restent des collections indépendantes. Les mutations emploient `UpdateAsync` en préservant le reste du record.
- `world:<WorldId>` reste la vérité d'autorisation : seul `OwnerUserId` ou une entrée dans `AuthorizedMembers` prouve l'accès. Une invitation ne modifie jamais cette liste avant son acceptation serveur.
- L'acceptation met d'abord à jour atomiquement le record monde, puis l'index membre secondaire; une divergence est réparable depuis la vérité monde. Refuser ne retire que l'invitation.
- Aucun lease/session lock n'est acquis lors de l'envoi ou de l'acceptation. L'acquisition reste réservée au vrai `Join`/`Load`.
- L'état runtime d'un serveur peut héberger un monde, mais il n'est exposé comme actif qu'aux joueurs admis dans ce monde; les autres joueurs du menu sont routés vers le monde qu'ils créent ou choisissent.
- L'acceptation réserve d'abord l'un des 3 slots rejoints avec `UpdateAsync`, ajoute ensuite le membre au record monde avec contrôle 6/6, puis finalise l'index. Une panne d'index après membership ne rollback pas le monde et reste réparable.
- `SaveWorld` conserve toujours l'`AuthorizedMembers` courant du DataStore afin qu'un snapshot mémoire actif ne puisse pas écraser une modification membership concurrente.
- `SessionService` conserve son lease 120 secondes, son renouvellement et son token de fencing. Un monde actif est rejoint via son `JobId`; un monde inactif peut être lancé par tout membre autorisé dans un serveur réservé.
- `PlayerStates` reste indexé par UserId et distinct des états uniques du monde. `WorldState.Structures`, `StructuresVersion`, `StructureId` et `OwnerUserId` historique ne sont pas transformés.

# FIN DU DOCUMENT

## FINAL GAMEPLAY LOOP V1

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

`FactoryService` étend l'industrie existante avec le type `Factory`. `StationService` reste l'unique propriétaire des transferts et de l'inventaire partagé. Le serveur revalide la distance, l'état et les ressources avant une transition atomique `Idle -> Building`. La progression sauvegarde un temps écoulé actif, sans progression hors ligne, puis passe une seule fois à `Completed`.

Le modèle final est cloné depuis `ServerStorage.AssetImports["Naval Seaplane"]`, orienté relativement à `Factory.ItemOutput` avec `PivotTo`. `WorldState.NavalSeaplaneCompleted`, `FinalPlaneSpawned` et `FinalPlanePivot` rendent le spawn idempotent et indépendant d'une éventuelle reconstruction de la Factory. Tous ces champs sont optionnels pour les anciens mondes.

**MAYDEAD --- Architecture Technique V1**

Ce document constitue la référence technique générale du projet MAYDEAD.
