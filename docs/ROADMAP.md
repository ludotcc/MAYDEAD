# MAYDEAD --- ROADMAP DE DÉVELOPPEMENT

**Document :** Roadmap officielle\
**Projet :** MAYDEAD\
**Plateforme :** Roblox\
**Statut :** Roadmap V1 de référence\
**Date :** 8 août 2026

------------------------------------------------------------------------

## 1. RÔLE DU DOCUMENT

Ce document définit l'ordre officiel de développement de MAYDEAD.

Il transforme le Game Design Document et l'architecture technique en une
suite de chantiers réalisables, testables et versionnables.

Objectif principal :

**obtenir le plus rapidement possible une vraie boucle jouable, puis
l'étendre progressivement jusqu'à une V1 publiable.**

La roadmap ne doit pas être interprétée comme une obligation de
développer toutes les idées imaginables avant publication.

La priorité est :

1.  fondations fiables ;
2.  boucle de survie jouable ;
3.  progression cohérente ;
4.  multijoueur robuste ;
5.  objectif final complet ;
6.  polish ;
7.  publication.

------------------------------------------------------------------------

# 2. PRINCIPE DE PRODUCTION

Chaque chantier suit autant que possible ce cycle :

``` text
CONCEPTION VALIDÉE
        ↓
IMPLÉMENTATION
        ↓
TEST SOLO
        ↓
TEST MULTIJOUEUR
        ↓
CORRECTIONS
        ↓
VALIDATION
        ↓
DOCUMENTATION
        ↓
COMMIT GIT
```

Une fonctionnalité ne doit pas être considérée terminée simplement parce
qu'elle fonctionne une fois dans Roblox Studio.

------------------------------------------------------------------------

# 3. DÉFINITION DES PRIORITÉS

## P0 --- Critique

Indispensable pour que MAYDEAD fonctionne.

## P1 --- Important

Indispensable pour une V1 publiable mais pas nécessairement pour le
premier prototype.

## P2 --- Amélioration

Apporte de la profondeur ou du polish mais peut être repoussée si
nécessaire.

------------------------------------------------------------------------

# 4. OBJECTIF INTERMÉDIAIRE PRINCIPAL

Avant de construire tout MAYDEAD, le projet doit atteindre une étape
appelée :

# FIRST PLAYABLE

Le First Playable doit permettre à un joueur de :

-   apparaître sur l'île ;
-   voir le temps évoluer ;
-   subir la météo ;
-   récolter ;
-   gérer un inventaire ;
-   fabriquer un outil ;
-   fabriquer un feu de camp ;
-   fabriquer une Table de crafting ;
-   obtenir et cuire de la nourriture ;
-   boire ;
-   perdre/récupérer de l'énergie ;
-   dormir ;
-   construire quelques éléments ;
-   sauvegarder ;
-   quitter ;
-   revenir et retrouver son monde.

À ce stade, l'hydravion n'a pas besoin d'être terminé.

Le but est de prouver que le cœur de MAYDEAD est amusant.

------------------------------------------------------------------------

# 5. GRAND CHANTIER 0 --- FONDATIONS DU PROJET

**Priorité : P0**

## Objectif

Obtenir un environnement de développement propre et reproductible.

## Tâches

-   [x] Créer le projet local.
-   [x] Installer/configurer Git.
-   [x] Créer le dépôt GitHub.
-   [x] Configurer la branche `main`.
-   [x] Configurer Rojo.
-   [x] Créer `default.project.json`.
-   [x] Créer `src/client`.
-   [x] Créer `src/server`.
-   [x] Créer `src/shared`.
-   [x] Premier commit.
-   [x] Premier push GitHub.
-   [x] Créer `GAME_DESIGN.md`.
-   [x] Créer `ARCHITECTURE.md`.
-   [x] Créer `ROADMAP.md`.
-   [x] Créer `PROJECT_STATUS.md`.
-   [x] Créer `DEVELOPMENT_RULES.md`.
-   [x] Créer `AGENTS.md`.
-   [ ] Vérifier la synchronisation Rojo complète avec Roblox Studio.
-   [ ] Introduire StyLua lorsque le workflow est prêt.
-   [ ] Introduire Selene lorsque le workflow est prêt.
-   [ ] Étudier Wally uniquement lorsqu'une dépendance réelle le
    justifie.

## Validation

Le chantier est terminé lorsque :

-   VS Code et Roblox Studio communiquent correctement ;
-   Git fonctionne ;
-   GitHub est à jour ;
-   la documentation maître existe ;
-   Codex peut comprendre le projet sans inventer son architecture.

------------------------------------------------------------------------

# 6. GRAND CHANTIER 1 --- MONDE, TEMPS ET ANNÉES SUR L'ARCHIPEL

**Priorité : P0**

## Objectif

Créer le premier système fondamental visible de MAYDEAD.

## Tâches

-   [x] Créer `TimeService`.
-   [x] Définir la configuration du cycle.
-   [x] Jour = 13 minutes.
-   [x] Nuit = 4 minutes.
-   [x] Cycle complet = 17 minutes.
-   [x] Début = Année 0.
-   [x] +1 année passée sur l'archipel à chaque cycle complet.
-   [x] Synchroniser le temps entre tous les joueurs.
-   [x] Piloter `Lighting` depuis le serveur.
-   [x] Créer transitions jour/nuit.
-   [x] Afficher l'année sur l'archipel dans l'inventaire.
-   [x] Tester le nouveau cycle et son incrément annuel.
-   [ ] Vérifier qu'un joueur rejoignant reçoit l'année correcte.

## Validation

Deux joueurs voient le même cycle et la même année sur l'archipel.

------------------------------------------------------------------------

# 7. GRAND CHANTIER 2 --- MÉTÉO V1

**Priorité : P0**

## Objectif

Intégrer immédiatement la météo dans la première boucle jouable.

## États V1

-   [ ] Normal.
-   [ ] Pluie.
-   [ ] Orage.

## Tâches

-   [ ] Créer `WeatherService`.
-   [ ] Créer `WeatherController`.
-   [ ] Synchroniser l'état météo.
-   [ ] Créer pluie locale autour du joueur.
-   [ ] Adapter la pluie à une grande map.
-   [ ] Ajouter ambiance sonore.
-   [ ] Ajouter changements Lighting/Atmosphere.
-   [ ] Ajouter éclairs visuels.
-   [ ] Ajouter tonnerre.
-   [ ] Tester plusieurs joueurs éloignés.
-   [ ] Préparer hooks gameplay pour agriculture/récupération d'eau.

## Validation

La météo est visible, performante et cohérente sur la map entière sans
générer une quantité absurde de particules réseau.

------------------------------------------------------------------------

# 8. GRAND CHANTIER 3 --- SYSTÈME D'INTERACTION

**Priorité : P0**

## Objectif

Créer une base commune pour les futures interactions.

## Exemples

-   arbre ;
-   rocher ;
-   coffre ;
-   feu ;
-   lit ;
-   Table de crafting ;
-   Table de Plans ;
-   machines ;
-   hydravion.

## Tâches

-   [ ] Définir le système d'interaction.
-   [ ] Définir les tags `CollectionService`.
-   [ ] Gérer distance.
-   [ ] Gérer affichage de l'action.
-   [ ] Gérer touche/clavier.
-   [ ] Prévoir mobile/tablette.
-   [ ] Validation serveur.
-   [ ] Créer notifications d'erreur.

## Validation

Une interaction générique peut être réutilisée par plusieurs types
d'objets.

------------------------------------------------------------------------

# 9. GRAND CHANTIER 4 --- ITEMS ET INVENTAIRE

**Priorité : P0**

## Objectif

Créer le socle de toute l'économie matérielle.

## Règles

-   20 slots ;
-   hotbar 8 slots ;
-   pas de poids ;
-   stacks ;
-   serveur autoritaire.

## Tâches

-   [ ] Créer `ItemDefinitions`.
-   [ ] Créer les premiers IDs.
-   [ ] Créer `InventoryService`.
-   [ ] Créer inventaire serveur.
-   [ ] Ajouter stack.
-   [ ] Ajouter/supprimer item.
-   [ ] Déplacement entre slots.
-   [ ] Gestion inventaire plein.
-   [ ] Hotbar.
-   [ ] Interface inventaire V1.
-   [ ] Synchronisation client.
-   [ ] Tests anti-duplication.

## Premiers items

-   [ ] Wood.
-   [ ] Stone.
-   [ ] RawMetal.
-   [ ] WoodPlank.
-   [ ] RawMeat.
-   [ ] CookedMeat.
-   [ ] Leather.
-   [ ] premiers outils.

## Validation

Deux joueurs peuvent manipuler leurs inventaires indépendamment sans
duplication ni perte incohérente.

------------------------------------------------------------------------

# 10. GRAND CHANTIER 5 --- RÉCOLTE

**Priorité : P0**

## Objectif

Créer la première boucle active :

**voir → récolter → obtenir une ressource → attendre le respawn.**

## Ressources initiales

-   [ ] arbres ;
-   [ ] pierre ;
-   [ ] métal.

## Puis

-   [ ] cuivre ;
-   [ ] cristal.

## Tâches

-   [ ] Créer `ResourceService`.
-   [ ] Tags Harvestable.
-   [ ] Validation distance.
-   [ ] Validation outil.
-   [ ] Récompenses serveur.
-   [ ] Feedback visuel.
-   [ ] Feedback sonore.
-   [ ] Disparition/état récolté.
-   [ ] Respawn arbre \~60 s.
-   [ ] Respawn minerai \~90 s.
-   [ ] Configuration centralisée.

## Validation

Aucun joueur ne peut obtenir des ressources simplement en falsifiant une
requête client.

------------------------------------------------------------------------

# 11. GRAND CHANTIER 6 --- OUTILS

**Priorité : P0**

## Objectif

Donner une progression de récolte claire.

## Progression

-   [ ] Pierre.
-   [ ] Métal.
-   [ ] Tiers avancé ultérieur.

## Tâches

-   [ ] outil équipé ;
-   [ ] interaction récolte ;
-   [ ] vitesse/rendement ;
-   [ ] restrictions de ressources ;
-   [ ] outils permanents ;
-   [ ] aucune durabilité punitive.

## Validation

Changer de tier apporte une amélioration immédiatement perceptible.

------------------------------------------------------------------------

# 12. GRAND CHANTIER 7 --- CRAFT MANUEL

**Priorité : P0**

## Objectif

Permettre le démarrage autonome.

## Crafts indispensables

-   [ ] premiers outils ;
-   [ ] feu de camp ;
-   [ ] Table de crafting.

## Tâches

-   [ ] `RecipeDefinitions`.
-   [ ] `CraftingService`.
-   [ ] interface crafting inventaire.
-   [ ] validation ingrédients.
-   [ ] validation capacité.
-   [ ] retrait/ajout atomique.
-   [ ] messages d'erreur.

## Validation

Le joueur peut partir de ressources brutes et atteindre la Table de
crafting.

------------------------------------------------------------------------

# 13. GRAND CHANTIER 8 --- TABLE DE CRAFTING

**Priorité : P0**

## Objectif

Créer le premier niveau d'artisanat structuré.

## Premiers crafts

-   [ ] planches ;
-   [ ] coffre ;
-   [ ] bac de culture ;
-   [ ] lit ;
-   [ ] éléments de construction ;
-   [ ] radeau plus tard.

## Tâches

-   [ ] modèle interactif ;
-   [ ] inventaire station ;
-   [ ] recettes spécifiques ;
-   [ ] UI ;
-   [ ] stockage persistant futur.

## Validation

Le joueur comprend clairement la différence entre craft manuel et craft
en station.

------------------------------------------------------------------------

# 14. GRAND CHANTIER 9 --- SURVIE V1

**Priorité : P0**

## Objectif

Faire de MAYDEAD un vrai survival.

## Systèmes

-   [ ] 100 PV.
-   [ ] faim.
-   [ ] soif.
-   [ ] énergie.
-   [ ] oxygène.

## Tâches

-   [ ] `SurvivalService`.
-   [ ] HUD.
-   [ ] consommation progressive.
-   [ ] dégâts faim.
-   [ ] dégâts soif.
-   [ ] sprint/énergie.
-   [ ] nage/oxygène.
-   [ ] noyade.
-   [ ] récupération énergie par nourriture.
-   [ ] synchronisation serveur.

## Validation

Les jauges ont un impact réel sans rendre les premières minutes
pénibles.

------------------------------------------------------------------------

# 15. GRAND CHANTIER 10 --- EAU ET GOURDE

**Priorité : P0**

## Objectif

Créer la boucle de soif.

## Tâches

-   [ ] craft gourde ;
-   [ ] détecter eau ;
-   [ ] boire ;
-   [ ] remplir gourde ;
-   [ ] consommation ;
-   [ ] UI/feedback.

## Validation

Le joueur comprend sans tutoriel complexe comment obtenir de l'eau.

------------------------------------------------------------------------

# 16. GRAND CHANTIER 11 --- FEU ET NOURRITURE

**Priorité : P0**

## Objectif

Créer la première transformation alimentaire.

## Tâches

-   [ ] inventaire feu de camp ;
-   [ ] RawMeat ;
-   [ ] CookedMeat ;
-   [ ] poisson ultérieur ;
-   [ ] 25 s de cuisson par pièce ;
-   [ ] consommation cru = perte PV ;
-   [ ] consommation cuit ;
-   [ ] consommation légumes ;
-   [ ] énergie rendue.

## Validation

La viande crue, cuite et les légumes possèdent des comportements
distincts.

------------------------------------------------------------------------

# 17. GRAND CHANTIER 12 --- SOMMEIL ET LITS

**Priorité : P0**

## Objectif

Créer la récupération d'énergie et le rituel de sécurité.

## Tâches

-   [ ] construire lit ;
-   [ ] revendiquer lit ;
-   [ ] dormir ;
-   [ ] 0 → 100 énergie ≈ 3 min ;
-   [ ] dormir jour/nuit ;
-   [ ] tous les joueurs dorment → passage accéléré de nuit ;
-   [ ] réveil ;
-   [ ] point de respawn ;
-   [ ] préparer déconnexion sécurisée ;
-   [ ] risque de dormir dehors.

## Validation

Le système fonctionne correctement avec 1 à 6 joueurs.

------------------------------------------------------------------------

# 18. GRAND CHANTIER 13 --- MORT ET RESPAWN

**Priorité : P0**

## Objectif

Créer une mort punitive mais récupérable.

## Tâches

-   [ ] détecter mort ;
-   [ ] générer sac ;
-   [ ] transférer ressources ;
-   [ ] conserver outils permanents ;
-   [ ] timer sac ;
-   [ ] récupération ;
-   [ ] respawn crash ou lit ;
-   [ ] sauvegarde cohérente.

## Validation

Aucune duplication n'est possible via mort/reconnexion.

------------------------------------------------------------------------

# 19. GRAND CHANTIER 14 --- STOCKAGE

**Priorité : P0**

## Objectif

Rendre la base utile.

## Tâches

-   [ ] `StorageService`.
-   [ ] coffre.
-   [ ] slots limités.
-   [ ] transfert joueur/coffre.
-   [ ] renommage.
-   [ ] permissions.
-   [ ] sauvegarde.
-   [ ] coffre amélioré ultérieur.

## Validation

Le contenu reste correct après redémarrage du monde.

------------------------------------------------------------------------

# 20. GRAND CHANTIER 15 --- CONSTRUCTION V1

**Priorité : P0**

## Objectif

Permettre la création d'un véritable abri.

## Éléments initiaux

-   [ ] fondation ;
-   [ ] sol ;
-   [ ] mur ;
-   [ ] porte ;
-   [ ] toit ;
-   [ ] escalier si nécessaire.

## Tâches

-   [ ] ghost client ;
-   [ ] snapping ;
-   [ ] rotation ;
-   [ ] validation serveur ;
-   [ ] consommation ressources ;
-   [ ] placement ;
-   [ ] démontage ;
-   [ ] remboursement 100 % ;
-   [ ] permissions ;
-   [ ] sauvegarde.

## Validation

Le joueur peut construire, quitter, revenir et retrouver sa base.

------------------------------------------------------------------------

# 21. GRAND CHANTIER 16 --- SAUVEGARDE SOLO / MONDE

**Priorité : P0**

## Objectif

Transformer le prototype en vraie partie persistante.

## Tâches

-   [x] `DataService` — `VALIDÉ STUDIO`.
-   [x] schéma versionné — `StructuresVersion = 2`, lecture de la version précédente conservée, `VALIDÉ STUDIO`.
-   [x] WorldId — isolation monde A / monde B `VALIDÉE STUDIO`.
-   [x] données joueur — inventaire et QuickSlots `VALIDÉS STUDIO`.
-   [x] données monde — temps legacy compatible, progression, constructions et états internes `VALIDÉS STUDIO`.
-   [x] autosave — intervalle de 120 secondes `VALIDÉ STUDIO`.
-   [x] sauvegarde fermeture — `PlayerRemoving`, dernier joueur et `BindToClose` `VALIDÉS STUDIO`.
-   [x] retry contrôlé — protections DataStore et conservation du dernier snapshot réussi `VALIDÉES STUDIO`.
-   [ ] migrations.
-   [x] restauration constructions — géométrie, identifiants, rotation, relations de snapping et isolation `VALIDÉS STUDIO`.
-   [x] restauration coffres — Chest 30 slots et CraftingTable 12 slots `VALIDÉS STUDIO`.
-   [x] restauration du champ historique `Age`, conversion YearsOnIsland et progression — `VALIDÉES STUDIO`.
-   [x] restauration progression — monde et GardenPlot sans progression hors ligne `VALIDÉE STUDIO`.

## Validation

Plusieurs cycles de fermeture/réouverture ne provoquent aucune perte
anormale.

World Persistence V3 : `VALIDÉ STUDIO`. Prochaine étape :
`VALIDATION ROBLOX PLAYER MULTIJOUEUR`.

------------------------------------------------------------------------

# 22. MILESTONE --- FIRST PLAYABLE

Lorsque les chantiers 0 à 16 sont validés, MAYDEAD doit être réellement
jouable.

Le joueur peut :

``` text
CRASH / SPAWN
↓
RÉCOLTER
↓
CRAFTER
↓
MANGER / BOIRE
↓
CONSTRUIRE
↓
DORMIR
↓
SURVIVRE AU TEMPS ET À LA MÉTÉO
↓
SAUVEGARDER
↓
REVENIR
```

À cette étape :

**STOP TEMPORAIRE DU DÉVELOPPEMENT DE NOUVELLES FEATURES.**

Effectuer une vraie session de jeu.

Identifier :

-   ce qui est amusant ;
-   ce qui est lent ;
-   ce qui est confus ;
-   ce qui est inutile ;
-   ce qui bug.

Corriger avant d'élargir le jeu.

------------------------------------------------------------------------

# 23. GRAND CHANTIER 17 --- AGRICULTURE

**Priorité : P1**

## Tâches

-   [ ] graines ;
-   [ ] bac ;
-   [ ] plantation ;
-   [ ] eau ;
-   [ ] croissance ;
-   [ ] pluie ;
-   [ ] récolte ;
-   [ ] légumes ;
-   [ ] sauvegarde.

------------------------------------------------------------------------

# 24. GRAND CHANTIER 18 --- COMPOST ET ENGRAIS

**Priorité : P1**

## Tâches

-   [ ] besoin naturel ;
-   [ ] action caca ;
-   [ ] interaction humoristique multijoueur ;
-   [ ] matière organique ;
-   [ ] composteur ;
-   [ ] transformation ;
-   [ ] engrais ;
-   [ ] effet agriculture.

Aucun dégât entre joueurs via cette mécanique.

------------------------------------------------------------------------

# 25. GRAND CHANTIER 19 --- ANIMAUX PASSIFS

**Priorité : P1**

## Menace aquatique JellyFish

Statut : `À TESTER`

-   [x] audit de l'asset réel exporté et réutilisation de son animation publiée ;
-   [x] IA aquatique autoritaire, cible la plus proche, leash et retour ;
-   [x] dégâts faibles avec cooldown et invulnérabilité sans loot ;
-   [ ] validation Studio solo, multijoueur, rig et animation.

## Tâches

-   [ ] architecture IA ;
-   [ ] spawn ;
-   [ ] déplacement ;
-   [ ] fuite/défense ;
-   [ ] dégâts ;
-   [ ] mort ;
-   [ ] viande ;
-   [ ] cuir.

Commencer avec une seule espèce correctement réalisée avant d'en ajouter
plusieurs.

------------------------------------------------------------------------

# 26. GRAND CHANTIER 20 --- COMBAT

**Priorité : P1**

## Tâches

-   [ ] arme primitive ;
-   [ ] portée ;
-   [ ] cadence ;
-   [ ] dégâts serveur ;
-   [ ] feedback ;
-   [ ] arme métal ;
-   [ ] équilibrage.

------------------------------------------------------------------------

# 27. GRAND CHANTIER 21 --- PÊCHE

**Priorité : P1**

## Tâches

-   [ ] système pêche ;
-   [ ] poisson cru ;
-   [ ] cuisson ;
-   [ ] consommation ;
-   [ ] équilibrage.

La pêche doit rester accessible et ne pas devenir un mini-jeu
excessivement complexe en V1.

------------------------------------------------------------------------

# 28. GRAND CHANTIER 22 --- REQUINS ET DANGER MARIN

**Priorité : P1**

## Tâches

-   [x] zones océaniques (validation Terrain Water existante) ;
-   [x] enregistrement des Shark placés dans `Workspace.Animals` ;
-   [x] détection des joueurs aquatiques ;
-   [x] poursuite ;
-   [x] attaque ;
-   [x] abandon et retour Home ;
-   [x] boucle centralisée et caches ;
-   [ ] équilibrage.

------------------------------------------------------------------------

# 29. GRAND CHANTIER 23 --- RADEAU

**Priorité : P1**

## Objectif

Débloquer la première exploration maritime.

## Tâches

-   [ ] recette ;
-   [ ] placement ;
-   [ ] pilotage ;
-   [ ] plusieurs joueurs ;
-   [ ] stockage limité ;
-   [ ] sauvegarde si nécessaire ;
-   [ ] comportement eau.

------------------------------------------------------------------------

# 30. GRAND CHANTIER 24 --- ÎLE SECONDAIRE V1

**Priorité : P1**

## Objectif

Prouver la boucle d'exploration.

## Contenu

-   [ ] nouvelle île ;
-   [ ] ressource spécifique ;
-   [ ] danger spécifique ;
-   [ ] intérêt réel de progression ;
-   [ ] élément nécessaire à la Table de Plans.

------------------------------------------------------------------------

# 31. GRAND CHANTIER 25 --- GUIDE DE FABRICATION

**Priorité : P1**

## Tâches

-   [ ] UI Guide ;
-   [ ] recherche item ;
-   [ ] source ;
-   [ ] transformations ;
-   [ ] utilisations ;
-   [ ] station nécessaire ;
-   [ ] navigation recette/composant ;
-   [ ] recettes cachées ;
-   [ ] découvertes progressives.

------------------------------------------------------------------------

# 32. GRAND CHANTIER 26 --- PREMIER DOCUMENT TECHNIQUE

**Priorité : P1**

## Tâches

-   [ ] modèle/document ;
-   [ ] interaction ;
-   [ ] inventaire ;
-   [ ] notification majeure ;
-   [ ] message Table de Plans ;
-   [ ] perte/récupération avant analyse ;
-   [ ] sauvegarde état.

------------------------------------------------------------------------

# 33. GRAND CHANTIER 27 --- TABLE DE PLANS

**Priorité : P1**

## Tâches

-   [ ] recette avancée ;
-   [ ] ressource île secondaire ;
-   [ ] construction ;
-   [ ] inventaire Documents ;
-   [ ] analyse ;
-   [ ] progression monde ;
-   [ ] UI ;
-   [ ] sauvegarde.

------------------------------------------------------------------------

# 34. MILESTONE --- SURVIVAL EXPLORATION BUILD

À cette étape, MAYDEAD doit proposer :

-   survie ;
-   construction ;
-   agriculture ;
-   animaux ;
-   combat ;
-   pêche ;
-   radeau ;
-   exploration ;
-   première île secondaire ;
-   premier Document ;
-   Table de Plans.

Le jeu commence alors à posséder sa véritable identité.

Effectuer un nouveau playtest complet avant l'industrie.

------------------------------------------------------------------------

# 35. GRAND CHANTIER 28 --- MÉTALLURGIE

**Priorité : P1**

## Tâches

-   [ ] four ;
-   [ ] minerai ;
-   [ ] lingots ;
-   [ ] temps de production ;
-   [ ] stockage ;
-   [ ] recettes avancées.

------------------------------------------------------------------------

# 36. GRAND CHANTIER 29 --- CUIVRE

**Priorité : P1**

## Tâches

-   [ ] ressource ;
-   [ ] récolte ;
-   [ ] transformation ;
-   [ ] composants ;
-   [ ] Guide ;
-   [ ] progression technologique.

------------------------------------------------------------------------

# 37. GRAND CHANTIER 30 --- USINE V1

**Priorité : P1**

## Tâches

-   [ ] modèle ;
-   [ ] inventaire entrée ;
-   [ ] inventaire sortie ;
-   [ ] recettes ;
-   [ ] production temporisée ;
-   [ ] sauvegarde ;
-   [ ] UI.

## Premiers produits possibles

-   [ ] plaques métalliques ;
-   [ ] câbles ;
-   [ ] pièces mécaniques.

------------------------------------------------------------------------

# 38. GRAND CHANTIER 31 --- ÉLECTRICITÉ

**Priorité : P1**

## Tâches

-   [ ] générateur ;
-   [ ] carburant/ressource énergétique à définir ;
-   [ ] rayon d'alimentation ;
-   [ ] détection machine ;
-   [ ] état alimenté ;
-   [ ] feedback visuel ;
-   [ ] sauvegarde.

------------------------------------------------------------------------

# 39. GRAND CHANTIER 32 --- AUTOMATISATION SIMPLE

**Priorité : P1**

## Tâches

-   [ ] production continue ;
-   [ ] entrée ;
-   [ ] sortie ;
-   [ ] énergie ;
-   [ ] timers centralisés ;
-   [ ] reprise après sauvegarde ;
-   [ ] performance.

Les convoyeurs complexes ne sont pas requis pour la V1.

------------------------------------------------------------------------

# 40. GRAND CHANTIER 33 --- ÎLES ET DANGERS AVANCÉS

**Priorité : P1**

## Tâches

-   [ ] nouvelles îles ;
-   [ ] ressources rares ;
-   [ ] prédateurs ;
-   [ ] ours ou équivalent ;
-   [ ] zones spécifiques ;
-   [ ] équilibrage équipement/danger.

------------------------------------------------------------------------

# 41. GRAND CHANTIER 34 --- CRISTAL

**Priorité : P1**

## Tâches

-   [ ] emplacement ;
-   [ ] récolte ;
-   [ ] danger ;
-   [ ] usages technologiques ;
-   [ ] recettes ;
-   [ ] Guide.

------------------------------------------------------------------------

# 42. GRAND CHANTIER 35 --- BATEAU

**Priorité : P2 / P1 selon playtest**

## Tâches

-   [ ] recette ;
-   [ ] construction ;
-   [ ] conduite ;
-   [ ] stockage ;
-   [ ] multijoueur ;
-   [ ] sauvegarde.

Si le radeau suffit pour une V1 amusante, le bateau peut être décalé.

------------------------------------------------------------------------

# 43. GRAND CHANTIER 36 --- DOCUMENTS TECHNIQUES COMPLETS

**Priorité : P1**

Référence actuelle : environ 5 documents majeurs.

-   [ ] Structure.
-   [ ] Flottaison.
-   [ ] Motorisation.
-   [ ] Électricité/commandes.
-   [ ] Navigation.

## Tâches

-   [ ] emplacement unique ;
-   [ ] méthode d'obtention ;
-   [ ] analyse ;
-   [ ] déblocages ;
-   [ ] progression partagée ;
-   [ ] sauvegarde.

------------------------------------------------------------------------

# 44. GRAND CHANTIER 37 --- CHANTIER AÉRONAUTIQUE

**Priorité : P1**

## Tâches

-   [ ] emplacement/support ;
-   [ ] interaction ;
-   [ ] UI progression ;
-   [ ] emplacements prédéfinis ;
-   [ ] installation de composants ;
-   [ ] MeshParts visibles progressivement ;
-   [ ] sauvegarde.

------------------------------------------------------------------------

# 45. GRAND CHANTIER 38 --- HYDRAVION

**Priorité : P1**

## Composants

La liste finale sera déterminée par le GDD détaillé des recettes.

Exemples :

-   [ ] structure ;
-   [ ] ailes ;
-   [ ] flotteurs ;
-   [ ] moteur ;
-   [ ] hélice ;
-   [ ] commandes ;
-   [ ] navigation ;
-   [ ] électricité.

## Validation

Chaque pièce installée est visible et sauvegardée.

------------------------------------------------------------------------

# 46. GRAND CHANTIER 39 --- FIN DE PARTIE

**Priorité : P1**

## Tâches

-   [ ] hydravion complet ;
-   [ ] carburant ;
-   [ ] préparation départ ;
-   [ ] validation équipe ;
-   [ ] embarquement ;
-   [ ] déclenchement serveur ;
-   [ ] cinématique ;
-   [ ] ÉVASION RÉUSSIE ;
-   [ ] années nécessaires à l'évasion ;
-   [ ] temps ;
-   [ ] statistiques.

------------------------------------------------------------------------

# 47. GRAND CHANTIER 40 --- CONTINUER APRÈS L'ÉVASION

**Priorité : P1**

## Tâches

-   [ ] sauvegarder EscapeState ;
-   [ ] continuer monde ;
-   [ ] afficher record ;
-   [ ] permettre nouvelle tentative ;
-   [ ] ne pas supprimer le monde.

------------------------------------------------------------------------

# 48. GRAND CHANTIER 41 --- MENU PRINCIPAL

**Priorité : P0 avant publication**

## Flux

``` text
MAYDEAD
↓
JOUER
↓
MES MONDES
↓
CRÉER / REPRENDRE
↓
MONDE
```

## Tâches

-   [ ] écran titre ;
-   [ ] nouvelle partie ;
-   [ ] mondes sauvegardés ;
-   [ ] rejoindre monde autorisé ;
-   [ ] paramètres ;
-   [ ] transitions ;
-   [ ] chargement.

------------------------------------------------------------------------

# 49. GRAND CHANTIER 42 --- MONDES MULTIJOUEURS PERSISTANTS

**Priorité : P0 avant publication**

## Objectif

Permettre jusqu'à 6 membres autorisés.

## Tâches

-   [ ] propriétaire ;
-   [ ] membres ;
-   [ ] invitations ;
-   [ ] permissions ;
-   [ ] exclusion ;
-   [ ] administrateur ;
-   [ ] accès sans propriétaire ;
-   [ ] serveur réservé/solution Roblox adaptée ;
-   [ ] verrou de session ;
-   [ ] reprise du monde ;
-   [ ] protection contre double instance ;
-   [ ] tests crash serveur.

Ce chantier devra être conçu avec attention avant implémentation.

------------------------------------------------------------------------

# 50. GRAND CHANTIER 43 --- DÉCONNEXION SÉCURISÉE

**Priorité : P1**

## Tâches

-   [ ] état « repos sécurisé » ;
-   [ ] lit ;
-   [ ] bouton quitter si nécessaire ;
-   [ ] sauvegarde technique indépendante ;
-   [ ] comportement Alt+F4 ;
-   [ ] comportement perte connexion ;
-   [ ] anti-exploit ;
-   [ ] UX claire.

La conséquence exacte d'une déconnexion non sécurisée doit être validée
avant développement final.

------------------------------------------------------------------------

# 51. GRAND CHANTIER 44 --- RECORDS

**Priorité : P1**

## Catégories

-   [ ] Solo.
-   [ ] Duo.
-   [ ] Trio.
-   [ ] 4 joueurs.
-   [ ] 5 joueurs.
-   [ ] 6 joueurs.

## Tâches

-   [ ] record personnel ;
-   [ ] YearsOnIsland ;
-   [ ] temps départage ;
-   [ ] validation serveur ;
-   [ ] classement global ;
-   [ ] protection anti-exploit ;
-   [ ] affichage.

------------------------------------------------------------------------

# 52. GRAND CHANTIER 45 --- CINÉMATIQUE D'INTRODUCTION

**Priorité : P1 avant publication**

## Tâches

-   [ ] avion ;
-   [ ] urgence ;
-   [ ] crash ;
-   [ ] transition ;
-   [ ] réveil ;
-   [ ] contrôle joueur ;
-   [ ] skip après première visualisation si pertinent.

La cinématique ne doit pas être trop longue.

------------------------------------------------------------------------

# 53. GRAND CHANTIER 46 --- CINÉMATIQUE DE FIN

**Priorité : P1 avant publication**

## Tâches

-   [ ] embarquement ;
-   [ ] démarrage ;
-   [ ] décollage hydravion ;
-   [ ] archipel ;
-   [ ] transition ;
-   [ ] écran résultat.

------------------------------------------------------------------------

# 54. GRAND CHANTIER 47 --- TUTORIEL CONTEXTUEL

**Priorité : P1**

## Tâches

-   [ ] première récolte ;
-   [ ] outil ;
-   [ ] eau ;
-   [ ] nourriture ;
-   [ ] feu ;
-   [ ] abri ;
-   [ ] sommeil ;
-   [ ] premier Document ;
-   [ ] Table de Plans.

Pas de mur de texte.

------------------------------------------------------------------------

# 55. GRAND CHANTIER 48 --- MOBILE / TABLETTE

**Priorité : P1 avant publication si plateformes ciblées**

## Tâches

-   [ ] contrôles ;
-   [ ] inventaire ;
-   [ ] interaction ;
-   [ ] construction ;
-   [ ] conduite ;
-   [ ] UI responsive ;
-   [ ] performance.

Le design PC ne doit pas être simplement réduit sur téléphone.

------------------------------------------------------------------------

# 56. GRAND CHANTIER 49 --- AUDIO

**Priorité : P1**

## Tâches

-   [ ] ambiance île ;
-   [ ] océan ;
-   [ ] pluie ;
-   [ ] orage ;
-   [ ] récolte ;
-   [ ] craft ;
-   [ ] machines ;
-   [ ] animaux ;
-   [ ] UI ;
-   [ ] musique menu ;
-   [ ] musique/ambiance cinématiques.

------------------------------------------------------------------------

# 57. GRAND CHANTIER 50 --- POLISH VISUEL

**Priorité : P1 avant publication**

## Tâches

-   [ ] Lighting final ;
-   [ ] météo ;
-   [ ] VFX ;
-   [ ] feedback récolte ;
-   [ ] feedback dégâts ;
-   [ ] feedback craft ;
-   [ ] animations ;
-   [ ] cohérence UI ;
-   [ ] logo MAYDEAD ;
-   [ ] miniatures Roblox ;
-   [ ] icône.

------------------------------------------------------------------------

# 58. GRAND CHANTIER 51 --- PERFORMANCE

**Priorité : P0 avant publication**

## Tests

-   [ ] grande map ;
-   [ ] 6 joueurs ;
-   [ ] météo ;
-   [ ] animaux ;
-   [ ] constructions nombreuses ;
-   [ ] machines ;
-   [ ] agriculture ;
-   [ ] véhicules.

## Travail

-   [ ] MicroProfiler ;
-   [ ] mémoire ;
-   [ ] réseau ;
-   [ ] StreamingEnabled ;
-   [ ] scripts coûteux ;
-   [ ] particules ;
-   [ ] IA ;
-   [ ] sauvegardes.

------------------------------------------------------------------------

# 59. GRAND CHANTIER 52 --- SÉCURITÉ / ANTI-EXPLOIT

**Priorité : P0 avant publication**

Audit complet :

-   [ ] récolte ;
-   [ ] inventaire ;
-   [ ] craft ;
-   [ ] construction ;
-   [ ] combat ;
-   [ ] machines ;
-   [ ] Documents ;
-   [ ] hydravion ;
-   [ ] records ;
-   [ ] RemoteEvents ;
-   [ ] permissions mondes.

------------------------------------------------------------------------

# 60. GRAND CHANTIER 53 --- MONÉTISATION

**Priorité : P2 avant que la boucle principale soit validée**

La monétisation ne doit pas dicter le prototype.

## Étudier

-   [ ] cosmétiques ;
-   [ ] skins outils ;
-   [ ] décorations ;
-   [ ] vêtements ;
-   [ ] emotes ;
-   [ ] apparences véhicules ;
-   [ ] autres contenus non Pay-to-Win.

## Interdiction de principe pour records officiels

Ne pas vendre directement :

-   progression hydravion ;
-   ressources x2 ;
-   vitesse usine x2 ;
-   invincibilité ;
-   suppression faim/soif ;
-   Documents techniques ;
-   avantage direct de record.

------------------------------------------------------------------------

# 61. GRAND CHANTIER 54 --- BÊTA PRIVÉE

**Priorité : P0 avant publication publique**

## Objectif

Faire tester MAYDEAD par de vrais joueurs qui ne connaissent pas sa
conception.

## Observer

-   comprennent-ils quoi faire ?
-   trouvent-ils l'eau ?
-   comprennent-ils le craft ?
-   comprennent-ils le compteur d'années sur l'archipel ?
-   construisent-ils naturellement ?
-   comprennent-ils les Documents ?
-   trouvent-ils la Table de Plans importante ?
-   la progression est-elle trop lente ?
-   la nuit est-elle trop longue ?
-   l'inventaire 20 slots fonctionne-t-il ?
-   le jeu est-il amusant en solo ?
-   le jeu est-il amusant à plusieurs ?

Ne pas expliquer oralement toutes les mécaniques aux testeurs.

Si le développeur doit expliquer constamment le jeu, l'UX doit être
améliorée.

------------------------------------------------------------------------

## Metallurgy V1

-   [ ] Valider Studio : CopperOre, RawMetal et GoldOre avec la hiérarchie 6/8/12 coups.
-   [ ] Valider Studio : Smelt, 12 slots filtrés, Wood fuel, trois recettes de lingots et effets actifs uniquement pendant la fonte.
-   [ ] Valider Studio : sauvegarde/rechargement Persistence V3 du Smelt, sans progression hors ligne ni duplication.

# 62. GRAND CHANTIER 55 --- ÉQUILIBRAGE

**Priorité : P0 avant publication**

Ajuster notamment :

-   [ ] durée cycle ;
-   [ ] faim ;
-   [ ] soif ;
-   [ ] énergie ;
-   [ ] sommeil ;
-   [ ] ressources ;
-   [ ] stacks ;
-   [ ] recettes ;
-   [ ] cuisson ;
-   [ ] cultures ;
-   [ ] animaux ;
-   [ ] dégâts ;
-   [ ] vitesse radeau ;
-   [ ] production ;
-   [ ] industrie ;
-   [ ] hydravion ;
-   [ ] nombre moyen d'années avant l'évasion.

Les valeurs doivent être basées sur les playtests, pas uniquement sur
des suppositions.

------------------------------------------------------------------------

# 63. GRAND CHANTIER 56 --- PRÉPARATION ROBLOX

**Priorité : P0**

## Tâches

-   [ ] nom officiel MAYDEAD ;
-   [ ] description ;
-   [ ] icône ;
-   [ ] miniatures ;
-   [ ] genre ;
-   [ ] paramètres d'accès ;
-   [ ] paramètres serveurs ;
-   [ ] localisation de base ;
-   [ ] règles Roblox ;
-   [ ] contenu approprié ;
-   [ ] tests de publication ;
-   [ ] sauvegardes production ;
-   [ ] analytics adaptés ;
-   [ ] configuration monétisation validée.

------------------------------------------------------------------------

# 64. GRAND CHANTIER 57 --- RELEASE CANDIDATE

**Priorité : P0**

Une version Release Candidate doit permettre de jouer :

``` text
MENU
↓
CRÉER MONDE
↓
CRASH
↓
SURVIE
↓
CONSTRUCTION
↓
EXPLORATION
↓
INDUSTRIE
↓
DOCUMENTS
↓
HYDRAVION
↓
ÉVASION
↓
RECORD
↓
CONTINUER / RECOMMENCER
```

sans commande développeur obligatoire et sans manipulation manuelle dans
Studio.

------------------------------------------------------------------------

# 65. GRAND CHANTIER 58 --- PUBLICATION

**Priorité : P0**

Avant publication :

-   [ ] aucune erreur critique connue ;
-   [ ] sauvegarde testée ;
-   [ ] multijoueur testé ;
-   [ ] mobile ciblé testé ;
-   [ ] performances acceptables ;
-   [ ] progression complète possible ;
-   [ ] évasion possible ;
-   [ ] records fonctionnels ;
-   [ ] anti-exploit minimum ;
-   [ ] page Roblox prête ;
-   [ ] onboarding compréhensible.

Puis :

# MAYDEAD --- PUBLICATION V1

------------------------------------------------------------------------

# 66. APRÈS PUBLICATION

Ne pas lancer immédiatement dix nouveaux systèmes.

Priorité :

1.  bugs ;
2.  pertes de sauvegarde ;
3.  exploits ;
4.  problèmes de performance ;
5.  rétention/onboarding ;
6.  équilibrage ;
7.  contenu.

Les futures mises à jour peuvent ensuite ajouter :

-   nouvelles îles ;
-   nouveaux animaux ;
-   nouvelles constructions ;
-   nouvelles machines ;
-   nouvelles décorations ;
-   nouveaux événements météo ;
-   nouveaux cosmétiques ;
-   nouvelles variantes d'exploration.

Le cœur du jeu doit rester compréhensible.

------------------------------------------------------------------------

# 67. RÈGLE ANTI-SCOPE CREEP

Une nouvelle idée n'entre pas automatiquement dans la V1.

Avant de l'ajouter, demander :

1.  améliore-t-elle réellement la boucle principale ?
2.  est-elle nécessaire à la publication ?
3.  peut-elle attendre une mise à jour ?
4.  augmente-t-elle fortement la complexité technique ?
5.  risque-t-elle de retarder le First Playable ?

Si elle n'est pas nécessaire, elle peut être placée dans un backlog
futur.

------------------------------------------------------------------------

# 68. ORDRE IMMÉDIAT APRÈS DOCUMENTATION

Une fois les documents maîtres terminés, l'ordre immédiat est :

``` text
1. Vérification Rojo
2. Nettoyage du prototype/test existant
3. TimeService
4. Cycle jour/nuit
5. Compteur YearsOnIsland
6. WeatherService
7. Météo V1
8. Interaction
9. Items
10. Inventaire
11. Récolte
12. Outils
13. Craft manuel
14. Table de crafting
15. Survie
...
```

Ne pas commencer directement par l'hydravion, les records ou
l'industrie.

------------------------------------------------------------------------

# 69. OBJECTIF DE LA V1

La V1 de MAYDEAD n'a pas besoin d'être gigantesque.

Elle doit surtout être :

-   complète ;
-   stable ;
-   compréhensible ;
-   amusante ;
-   rejouable ;
-   sauvegardée ;
-   multijoueur ;
-   publiable.

Une V1 plus petite mais terminée vaut mieux qu'un immense projet
impossible à publier.

------------------------------------------------------------------------

## PRIVATE SHARED WORLDS + MEMBERSHIP V1

Statut : `VALIDÉ PAR LE GAME DIRECTOR`

- [x] Invitations, limites 3/3 et 6/6, réparation d'index et révocation validées en multijoueur.
- [x] Routage serveur propriétaire absent, join d'une instance active et fencing concurrent validés.
- [x] Page Mondes rejoints validée sur les plateformes couvertes par le chantier.
- [x] Validation Game Director obtenue sur le périmètre production prévu.

# FIN DU DOCUMENT

## FINAL GAMEPLAY LOOP V1

Statut : `VALIDÉ PAR LE GAME DIRECTOR`.

- [x] intégration code Boat et Factory aux crafts/placeables ;
- [x] production serveur autoritaire et persistence du Naval Seaplane ;
- [x] exclusion serveur des assemblages finaux concurrents entre plusieurs FinalFactory ;
- [x] continuation après objectif et records monde ;
- [x] audit des assets et pilotage dans Roblox Studio ;
- [x] tests multijoueur, reload intermédiaire et Roblox Player production.

## CLÔTURE AUDIT PRODUCTION

### TERMINÉ / VALIDÉ

- sécurisation Session/DataStore, World GetState, InventoryRequest, StationRequest, FishingRequest, MountInput et FinalFactoryRequest ;
- correctifs de persistance Tools/inventaire et transferts Campfire ;
- contrôles mobiles P1/P2 documentés comme `VALIDÉ` dans `INPUT_CONTROLS.md` ;
- réduction des logs production sans suppression d'asset ;
- YearsOnIsland et cycle 17 minutes, y compris compatibilité des sauvegardes historiques.
- mondes privés partagés, scénarios DataStore/SessionLock et réservation membership atomique 3/3 validés par le Game Director ;
- Boat, Naval Seaplane et FinalFactory validés par le Game Director après correction de la concurrence d'assemblage par `9040ede` ;
- dernier P1 connu du grand audit clôturé.

### P2 / POST-PUBLICATION OUVERT

- [ ] Boat V2 : valider en Studio/Roblox Player la restauration de la dernière position/orientation, le Cargo partagé persistant de 40 slots, la portée mobile et la perte intégrale du Cargo au démontage.
- validations visuelles et responsive encore explicitement marquées `À TESTER`.

### FUTUR

Les fonctionnalités non développées des chantiers précédents restent dans la
roadmap comme backlog futur; leur absence ne rouvre pas le grand audit de
sécurité production.

**MAYDEAD --- Roadmap V1**

Ce document définit l'ordre général de développement jusqu'à la première
version publiable.
