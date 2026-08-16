# MAYDEAD — INPUT CONTROLS

**Document :** Source de vérité des contrôles joueur  
**Projet :** MAYDEAD  
**Plateformes :** PC, tablette et téléphone  
**Statut :** Référence officielle

------------------------------------------------------------------------

## 1. RÔLE DU DOCUMENT

`GAME_DESIGN.md` définit ce que fait le gameplay. `INPUT_CONTROLS.md`
définit comment le joueur contrôle ce gameplay selon la plateforme.

Toute nouvelle mécanique interactive doit fournir un chemin utilisateur
viable sur toutes les plateformes supportées, sauf décision de conception
explicite et documentée.

Ce document décrit le code réellement présent. Un contrôle marqué `À TESTER
EN STUDIO` existe statiquement, mais n'est pas déclaré validé sur appareil réel.

------------------------------------------------------------------------

## 2. PLATEFORMES SUPPORTÉES

- PC avec clavier et souris ;
- tablette tactile ;
- téléphone tactile.

Une mécanique interactive n'est pas considérée complète si une action
nécessaire n'a pas de chemin viable sur l'une de ces plateformes.

------------------------------------------------------------------------

## 3. PRINCIPES GÉNÉRAUX

### PC

Les bindings PC existants ne doivent pas être remplacés, modifiés ou cassés
lors de l'ajout du tactile.

### Mobile et tablette

Le tactile est une couche parallèle. Il réutilise autant que possible les
mêmes actions, contrôleurs, Remotes et validations serveur que le PC.

### Serveur autoritaire

Une interface tactile exprime une intention. Elle ne décide jamais seule du
résultat gameplay, des quantités, de l'inventaire, d'un craft, d'un placement,
d'un apprivoisement ou d'une progression persistante.

### Remotes

Ne pas créer de Remote propre au mobile si le Remote existant exprime déjà la
même intention. Une exception exige une contrainte technique démontrée.

### Multi-touch

Tout contrôle tactile doit considérer simultanément le joystick, la caméra,
un second doigt et les autres boutons contextuels.

### Boutons tactiles

Ils doivent être lisibles et suffisamment grands sur téléphone et tablette,
rester dans les safe insets et ne pas chevaucher joystick, JumpButton ou
hotbar. Les actions incompatibles partageant une zone doivent être
fonctionnellement exclusives, pas seulement séparées par leur `ZIndex`.

### `gameProcessed`

Utiliser `gameProcessed` pour protéger l'UI et les contrôles Roblox, sans
rejeter aveuglément tous les touchs. Ne pas refaire au relâchement un filtre
qui annulerait un geste valablement commencé.

### Drag, appui long et tap tactile

- drag PC inventaire et station : seuil local de 6 px dans
  `InventoryController` et `StationController` ;
- drag tactile inventaire et station :
  `InventoryConfig.MOBILE_SLOT_MOVE_TOLERANCE = 14` ;
- appui long station PC : constante locale de 0,45 s ;
- appui long station tactile :
  `InventoryConfig.MOBILE_SLOT_LONG_PRESS_TIME = 0.5` ;
- pêche tactile : `FishingConfig.TouchTapMoveTolerance = 32` et
  `FishingConfig.TouchTapMaxDuration = 0.75`.

Les valeurs centralisées doivent rester dans leurs configs. Ce document en
décrit le contrat, sans devenir une seconde configuration.

------------------------------------------------------------------------

## 4. MATRICE DES CONTRÔLES ACTUELS

| Action | PC | Tablette | Téléphone | Fichier / système | Statut |
|---|---|---|---|---|---|
| Marcher | WASD natif | Joystick natif | Joystick natif | Contrôles personnage Roblox | NATIF ROBLOX |
| Caméra | Souris | Caméra tactile | Caméra tactile | Caméra Roblox | NATIF ROBLOX |
| Saut personnage | Espace natif | JumpButton | JumpButton | `TouchJumpIntegrationController` | NATIF ROBLOX |
| Sprint général joueur | Aucun système dédié présent | Aucun | Aucun | — | NON APPLICABLE |
| Nage | Mouvement Humanoid natif | Contrôles natifs | Contrôles natifs | Roblox Humanoid | NATIF ROBLOX |
| Interaction monde | Touche du `ProximityPrompt` | Bouton de prompt | Bouton de prompt | Services d'interaction | NATIF ROBLOX |
| Récolte / attaque avec outil | `Tool.Activated`, souris | Activation outil et ciblage tactile | Idem | `HarvestController` | À TESTER EN STUDIO |
| Ouvrir l'inventaire | `E` | Bouton inventaire | Bouton inventaire | `InventoryController` | À TESTER EN STUDIO |
| Hotbar | Touches `1` à `8`, clic | Tap sur slot | Tap sur slot | `InventoryController` | À TESTER EN STUDIO |
| Sélection inventaire | Clic | Tap | Tap | `InventoryController` | À TESTER EN STUDIO |
| Drag / merge / swap | Drag souris, seuil 6 px | Drag tactile, seuil 14 px | Idem | `InventoryController`, `InventoryConfig` | À TESTER EN STUDIO |
| Main ↔ Quick | Drag | Drag tactile | Drag tactile | `InventoryController` | À TESTER EN STUDIO |
| Utiliser / consommer | `F` ou action UI | Bouton contextuel | Bouton contextuel | `InventoryController`, `DrinkController` | À TESTER EN STUDIO |
| Station : `SINGLE` | Drag vers destination | Drag tactile | Drag tactile | `StationController`, `StationRequest` | À TESTER EN STUDIO |
| Station : `FULL_STACK` | Shift + clic gauche ou clic gauche long | Appui long 0,5 s | Appui long 0,5 s | `StationController`, `InventoryConfig` | À TESTER EN STUDIO |
| Station : `HALF_STACK` | Shift + clic droit | Tap bref puis `½ PILE` | Tap bref puis `½ PILE` | `StationController`, `StationRequest` | À TESTER EN STUDIO |
| Campfire : transferts | Règles station | Règles station | Règles station | `StationController` | À TESTER EN STUDIO |
| CraftingTable : stockage | Règles station | Règles station | Règles station | `StationController` | À TESTER EN STUDIO |
| Choisir/crafter une recette | Clic UI | Bouton `Activated` | Bouton `Activated` | `CraftingController` | À TESTER EN STUDIO |
| Construction : placer | Clic gauche | `PLACER` | `PLACER` | `PlacementController` | À TESTER EN STUDIO |
| Construction : tourner | `R` | `TOURNER` | `TOURNER` | `PlacementController` | À TESTER EN STUDIO |
| Construction : annuler | Échap | `ANNULER` | `ANNULER` | `PlacementController` | À TESTER EN STUDIO |
| Pêche : lancer | Clic gauche | Tap tactile | Tap tactile | `FishingController` | VALIDÉ |
| Pêche : combat | Maintenir/relâcher clic gauche | Maintenir/relâcher le touch suivi | Idem | `FishingController` | VALIDÉ |
| Cheetah : Follow / Stay | Boutons UI | Boutons UI | Boutons UI | `CheetahCompanionController` | À TESTER EN STUDIO |
| Cheetah : Mount | Bouton UI | Bouton UI | Bouton UI | `CheetahCompanionController` | À TESTER EN STUDIO |
| Cheetah : Dismount | `E` | `DESCENDRE` | `DESCENDRE` | `CheetahCompanionController` | VALIDÉ |
| Cheetah : direction montée | WASD / flèches | Joystick (`Humanoid.MoveDirection`) | Idem | `CheetahCompanionController` | À TESTER EN STUDIO |
| Cheetah : sprint monté | Maintenir Shift gauche | Maintenir `SPRINT` | Maintenir `SPRINT` | `CheetahCompanionController`, `MountInput` | À TESTER EN STUDIO |
| Cheetah : saut monté | Clic gauche | JumpButton via `JumpRequest` | Idem | `CheetahCompanionController` | À TESTER EN STUDIO |
| Cheetah : apprivoisement | RawMeat sélectionnée puis clic gauche pour déposer | `NOURRIR` contextuel | Idem | `RawMeatDropController`, `WorldDropRequest` | VALIDÉ |
| Factory : ouvrir | Interaction monde | Prompt tactile | Prompt tactile | Factory / station | NATIF ROBLOX |
| Factory : transférer | Règles station | Règles station | Règles station | `StationController` | À TESTER EN STUDIO |
| Factory : assembler | Bouton UI | Bouton `Activated` | Bouton `Activated` | `FactoryStatusController`, `StationController` | À TESTER EN STUDIO |
| Factory : fermer | `B`, Échap ou bouton | Bouton | Bouton | `FactoryStatusController` | À TESTER EN STUDIO |
| Bateau : accélérer / tourner | Contrôles `VehicleSeat` | Contrôles de siège natifs attendus | Idem | `BoatService` | À TESTER EN STUDIO |
| Agriculture : planter / récolter | `ProximityPrompt` | Prompt tactile | Prompt tactile | `CropService` | NATIF ROBLOX |
| Menus monde | Boutons et TextBox | Boutons et clavier virtuel | Idem | `MainMenuController` | À TESTER EN STUDIO |

### Stations, Campfire et CraftingTable

Les modes réseau restent exactement `SINGLE`, `FULL_STACK` et `HALF_STACK`.
Le serveur décide de la quantité transférable et de la capacité disponible.
Le garde `if self.DragState then return end` de `StationController` protège le
drag Campfire pendant les refresh de `StationStateChanged` et doit être
préservé.

### Construction

Les boutons tactiles `PLACER`, `TOURNER` et `ANNULER` sont créés par
`ContextActionService` avec `createTouchButton = true`. Le serveur conserve la
validation du placement officiel.

### Pêche

Le tactile suit l'Input précis commencé. `gameProcessed` est vérifié au début,
mais n'est pas rejeté une seconde fois dans `_finishTouch`. Les panneaux de
pêche utilisent un `UIScale` responsive. Les contrôles PC restent séparés.

### Cheetah

`NOURRIR` et `DESCENDRE` sont mutuellement exclusifs : `NOURRIR` exige que
`CheetahCompanionController.Mounted` soit faux, tandis que `DESCENDRE` exige
qu'il soit vrai. `SPRINT` est un bouton maintenu et alimente le même booléen
`Sprint` de `MountInput` que Shift gauche. Toutes les plateformes utilisent le
même Remote et les mêmes validations serveur.

### Bateau

Le code MAYDEAD lit `VehicleSeat.ThrottleFloat` et `SteerFloat`. Aucun
contrôleur bateau mobile spécifique n'est présent. Le comportement téléphone
et tablette dépend donc des contrôles de siège Roblox et reste à tester dans
Studio sur les profils d'appareil concernés.

------------------------------------------------------------------------

## 5. STATUTS

- `VALIDÉ` : contrôle explicitement validé dans le chantier correspondant ;
- `À TESTER EN STUDIO` : chemin présent dans le code, validation réelle encore
  requise ;
- `NATIF ROBLOX` : interaction fournie principalement par Roblox ;
- `NON APPLICABLE` : mécanique ou contrôle non présent dans l'implémentation.

Une vérification statique seule ne permet jamais de promouvoir un contrôle à
`VALIDÉ`.

------------------------------------------------------------------------

## 6. CHECKLIST OBLIGATOIRE POUR TOUTE NOUVELLE MÉCANIQUE

Avant de déclarer une feature interactive terminée :

1. Quelle est l'action PC ?
2. Quelle est l'action tablette ?
3. Quelle est l'action téléphone ?
4. Les plateformes utilisent-elles le même Remote lorsque possible ?
5. Les validations gameplay restent-elles identiques et côté serveur ?
6. Le contrôle fonctionne-t-il avec joystick et second doigt ?
7. Le bouton tactile est-il suffisamment grand et lisible ?
8. L'UI évite-t-elle joystick, JumpButton, hotbar et autres actions ?
9. `gameProcessed`, drag et `InputEnded` sont-ils correctement gérés ?
10. Les tests PC, tablette et téléphone ont-ils réellement été effectués ?

La checklist doit être traitée même si l'interface initiale est développée sur
PC.

------------------------------------------------------------------------

## 7. TESTS MINIMUMS MULTIPLATEFORMES

- PC clavier/souris : chemin normal et régression des bindings existants ;
- téléphone : portrait/paysage lorsque pertinent, joystick et second doigt ;
- tablette : mêmes actions et vérification des positions UI ;
- contrôles maintenus : relâchement normal, annulation et changement d'état ;
- drag : tap, scroll, seuil, destination invalide et refresh réseau ;
- deux joueurs lorsque l'action affecte un objet ou état partagé ;
- serveur : arguments invalides, distance, permissions, cooldown et répétition.

------------------------------------------------------------------------

## 8. RÈGLE DE MISE À JOUR

Toute modification d'un contrôle, binding, geste tactile, seuil d'input ou UI
interactive doit mettre à jour `docs/INPUT_CONTROLS.md` dans le même chantier.

Une modification de ce document ne remplace pas les mises à jour nécessaires
de `GAME_DESIGN.md`, `ARCHITECTURE.md` ou `PROJECT_STATUS.md` lorsque leur
périmètre est également affecté.

