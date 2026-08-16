# MAYDEAD --- DEVELOPMENT RULES

**Document :** Règles officielles de développement\
**Projet :** MAYDEAD\
**Plateforme :** Roblox\
**Langage :** Luau\
**Workflow :** VS Code + Rojo + Roblox Studio + Git/GitHub + Codex\
**Statut :** V1\
**Date :** 8 août 2026

------------------------------------------------------------------------

## 1. OBJECTIF

Ce document fixe les règles de travail obligatoires pour développer
MAYDEAD de manière propre, rapide, compréhensible et maintenable.

Ces règles s'appliquent au développeur, aux modifications réalisées avec
Codex et à toute future intervention importante sur le dépôt.

------------------------------------------------------------------------

## 2. SOURCES DE VÉRITÉ

Avant toute modification importante, respecter les documents suivants :

1.  `GAME_DESIGN.md` --- règles de gameplay.
2.  `ARCHITECTURE.md` --- organisation technique.
3.  `ROADMAP.md` --- ordre de développement.
4.  `PROJECT_STATUS.md` --- état réel du projet.
5.  `DEVELOPMENT_RULES.md` --- méthode de développement.
6.  `INPUT_CONTROLS.md` --- contrôles PC, tablette et téléphone.
7.  `../AGENTS.md` --- instructions impératives destinées notamment à
    Codex.

Ne pas inventer une règle manquante pour débloquer artificiellement une
tâche.

------------------------------------------------------------------------

## 3. UNE ÉTAPE À LA FOIS

Le développement doit avancer système par système.

Éviter de demander ou de modifier simultanément plusieurs systèmes
indépendants lorsqu'ils peuvent être développés et testés séparément.

Ordre général :

``` text
Concevoir
↓
Coder
↓
Tester
↓
Corriger
↓
Valider
↓
Documenter
↓
Commit
```

------------------------------------------------------------------------

## 4. PAS DE SCOPE CREEP

Une nouvelle idée n'entre pas automatiquement dans la V1.

Avant de l'implémenter, vérifier :

-   qu'elle est validée dans le GDD ;
-   qu'elle correspond au chantier actuel ;
-   qu'elle n'introduit pas une dépendance prématurée ;
-   qu'elle ne retarde pas inutilement le First Playable.

------------------------------------------------------------------------

## 5. MODIFICATIONS CIBLÉES

Ne pas réécrire une partie stable du projet sans nécessité.

Une tâche doit modifier uniquement les fichiers réellement concernés.

Ne pas effectuer de « nettoyage global », renommage massif ou
refactorisation générale en parallèle d'une petite fonctionnalité sauf
demande explicite ou nécessité technique démontrée.

------------------------------------------------------------------------

## 6. FICHIERS COMPLETS

Lorsqu'une modification doit être appliquée manuellement par
l'utilisateur à un script, fournir de préférence **le fichier complet
prêt à remplacer**, et non quelques lignes ambiguës.

Lorsque Codex travaille directement dans le dépôt, il peut modifier les
fichiers lui-même, mais les changements doivent rester ciblés et
vérifiables.

------------------------------------------------------------------------

## 7. CODE SIMPLE AVANT CODE GÉNÉRIQUE

Préférer une solution :

-   lisible ;
-   courte ;
-   explicite ;
-   facile à déboguer ;

à une architecture abstraite complexe créée « au cas où ».

Ne pas créer de framework maison sans besoin réel.

------------------------------------------------------------------------

## 8. SERVEUR AUTORITAIRE

Toute donnée importante pour le gameplay est validée par le serveur.

Le client ne décide jamais seul :

-   des ressources obtenues ;
-   du contenu d'un inventaire ;
-   d'un craft réussi ;
-   des dégâts ;
-   de l'âge ;
-   de la progression du monde ;
-   des Documents analysés ;
-   de l'hydravion ;
-   d'un record.

------------------------------------------------------------------------

## 9. VALIDATION DES REMOTES

Toute requête réseau ayant un effet gameplay doit être validée côté
serveur.

Selon le système, vérifier notamment :

-   types des arguments ;
-   distance ;
-   permissions ;
-   cooldown ;
-   quantité ;
-   état de l'objet ;
-   recette ;
-   inventaire ;
-   capacité ;
-   existence de la cible.

Ne jamais faire confiance à une valeur fournie uniquement par le client.

------------------------------------------------------------------------

## COMPATIBILITÉ INPUT MULTIPLATEFORME

Toute mécanique interactive doit considérer dès sa conception :

-   PC clavier/souris ;
-   tablette tactile ;
-   téléphone tactile.

Règles obligatoires :

-   lire `INPUT_CONTROLS.md` avant de modifier un input ou une UI
    interactive ;
-   ne pas coder une action nécessaire uniquement avec `Enum.KeyCode` sans
    équivalent tactile viable ;
-   ne pas remplacer ou casser un contrôle PC pour ajouter le mobile ;
-   faire appeler au mobile la même logique gameplay, le même Remote et les
    mêmes validations serveur lorsque possible ;
-   ne jamais déplacer une validation gameplay vers le client pour faciliter
    le tactile ;
-   tester joystick, caméra et second doigt simultanément ;
-   vérifier la taille, la lisibilité, les safe insets et les chevauchements
    avec JumpButton et hotbar ;
-   gérer `gameProcessed`, drag, appui long et `InputEnded` sans annuler un
    geste valide ;
-   tester réellement PC, tablette et téléphone avant validation ;
-   mettre à jour `INPUT_CONTROLS.md` dans le même chantier que toute
    modification de contrôle, binding, geste ou UI interactive.

Une feature interactive ne doit pas être considérée terminée tant que sa
compatibilité multiplateforme n'a pas été traitée ou qu'une exception de
conception n'a pas été explicitement validée.

------------------------------------------------------------------------

## 10. CONFIGURATION CENTRALISÉE

Les valeurs d'équilibrage ne doivent pas être dispersées dans le code.

Exemples :

-   durée jour/nuit ;
-   respawn ressources ;
-   temps de cuisson ;
-   taille des stacks ;
-   consommation faim/soif ;
-   dégâts ;
-   croissance.

Utiliser des modules de configuration/définitions lorsque le système
correspondant existe.

------------------------------------------------------------------------

## 11. IDENTIFIANTS STABLES

Utiliser des IDs internes stables en anglais pour les objets et
systèmes.

Exemple :

``` text
Wood
RawMetal
CookedMeat
CraftingTable
```

Ne pas utiliser un texte d'interface localisé comme identifiant
technique.

------------------------------------------------------------------------

## 12. NOMMAGE

Conventions recommandées :

``` text
PascalCase      → modules, services, types
camelCase       → variables locales, fonctions locales
UPPER_SNAKE_CASE → constantes uniquement si réellement approprié
```

Les noms doivent décrire leur rôle.

Éviter :

``` text
thing
stuff
data2
scriptNew
testFinal2
```

------------------------------------------------------------------------

## 13. TYPES LUAU

Utiliser les types Luau lorsqu'ils améliorent réellement :

-   la compréhension ;
-   la sécurité ;
-   l'autocomplétion ;
-   la maintenance.

Ne pas rendre un petit module illisible uniquement pour typer chaque
détail.

Les structures de données importantes doivent progressivement recevoir
des types explicites.

------------------------------------------------------------------------

## 14. MODULES

Un module doit avoir une responsabilité claire.

Éviter un fichier géant contenant :

-   inventaire ;
-   météo ;
-   crafting ;
-   animaux ;
-   sauvegarde ;

dans le même script.

À l'inverse, ne pas découper une fonctionnalité triviale en dix modules
inutiles.

------------------------------------------------------------------------

## 15. SERVICES

Créer un Service uniquement lorsqu'un vrai système serveur le nécessite.

Un Service doit idéalement exposer une API claire et cacher ses détails
internes.

Exemple conceptuel :

``` text
InventoryService:AddItem(...)
InventoryService:RemoveItem(...)
InventoryService:HasItems(...)
```

------------------------------------------------------------------------

## 16. INITIALISATION

Les fichiers `init.server.luau` et `init.client.luau` doivent rester des
points d'entrée légers.

Ils ne doivent pas devenir des scripts de plusieurs milliers de lignes.

------------------------------------------------------------------------

## 17. PAS DE SCRIPTS DISPERSÉS DANS LA MAP

Éviter de placer un Script différent dans chaque arbre, roche, coffre ou
machine.

Préférer :

-   `CollectionService` ;
-   tags ;
-   Attributes ;
-   systèmes centraux.

Les exceptions doivent avoir une justification claire.

------------------------------------------------------------------------

## 18. PERFORMANCE

Éviter :

-   une boucle par frame pour chaque objet ;
-   un `while true` indépendant pour des centaines d'objets ;
-   des milliers de particules réseau ;
-   des recherches globales répétées dans Workspace ;
-   des événements réseau inutiles.

Préférer :

-   événements ;
-   timers centralisés ;
-   timestamps ;
-   mise en veille ;
-   calculs uniquement lorsque nécessaires.

------------------------------------------------------------------------

## 19. GRANDE MAP

Ne jamais concevoir un système en supposant que tous les joueurs restent
proches.

Les systèmes visuels comme la pluie doivent pouvoir être locaux au
joueur.

Le code client doit tolérer le streaming d'instances si
`StreamingEnabled` est adopté.

------------------------------------------------------------------------

## 20. DATASTORE

Toute écriture DataStore doit être :

-   nécessaire ;
-   protégée ;
-   contrôlée ;
-   journalisée en cas d'erreur.

Ne pas sauvegarder à chaque petite action si ce n'est pas nécessaire.

Les données importantes doivent disposer d'un schéma versionné.

------------------------------------------------------------------------

## 21. AUCUNE PERTE SILENCIEUSE

Une erreur de sauvegarde critique ne doit pas être ignorée.

Ne jamais afficher au joueur qu'une sauvegarde est garantie si
l'opération a échoué.

------------------------------------------------------------------------

## 22. SAUVEGARDE ≠ MÉCANIQUE DU LIT

La sauvegarde technique doit protéger les données même si le joueur n'a
pas utilisé son lit.

La mécanique du lit peut modifier l'état gameplay lors d'une
déconnexion, mais elle ne doit pas être utilisée comme excuse pour ne
pas sauvegarder techniquement.

------------------------------------------------------------------------

## 23. MULTIJOUEUR DÈS LA CONCEPTION

Même lorsqu'un système est développé d'abord en solo, ne pas coder une
architecture qui suppose qu'il n'existera jamais qu'un seul joueur.

Tester les systèmes critiques en multijoueur avant validation.

------------------------------------------------------------------------

## 24. PAS DE DUPLICATION

Inventaire, stockage, mort, craft et sauvegarde doivent être testés
contre les duplications.

Les opérations sensibles doivent être atomiques autant que possible :

``` text
Vérifier
↓
Retirer
↓
Ajouter / produire
```

sans fenêtre permettant de répéter la récompense.

------------------------------------------------------------------------

## 25. TESTS MINIMUMS

Pour chaque système important, tester au minimum :

-   cas normal ;
-   inventaire plein si concerné ;
-   action trop loin ;
-   action répétée ;
-   joueur quittant ;
-   joueur mourant si pertinent ;
-   deux joueurs interagissant avec le même objet ;
-   sauvegarde/rechargement si persistant.

------------------------------------------------------------------------

## 26. PROTOTYPE ≠ PRODUCTION

Un script qui « marche » pendant un test n'est pas automatiquement
validé.

Avant de conserver un prototype :

-   vérifier son architecture ;
-   vérifier la sécurité ;
-   vérifier le multijoueur ;
-   vérifier les performances ;
-   vérifier sa compatibilité avec la documentation.

------------------------------------------------------------------------

## 27. DEBUG

Les logs temporaires sont autorisés pendant le développement.

Utiliser des préfixes utiles :

``` text
[TimeService]
[InventoryService]
[DataService]
```

Supprimer ou réduire les logs bruyants lorsque la fonctionnalité est
stabilisée.

------------------------------------------------------------------------

## 28. ERREURS

Les erreurs attendues liées aux services Roblox doivent être gérées.

Utiliser `pcall` lorsque nécessaire, notamment autour des opérations
pouvant réellement échouer.

Ne pas envelopper arbitrairement tout le code dans des `pcall` qui
masquent les bugs.

------------------------------------------------------------------------

## 29. COMMENTAIRES

Commenter :

-   les décisions non évidentes ;
-   les contraintes Roblox ;
-   les protections anti-exploit ;
-   les algorithmes particuliers.

Ne pas commenter chaque ligne évidente.

------------------------------------------------------------------------

## 30. TODO

Les TODO doivent être précis.

Bon :

``` text
-- TODO: restore stale world session locks after timeout.
```

Mauvais :

``` text
-- TODO: fix later
```

Un TODO ne remplace pas une décision de Game Design manquante.

------------------------------------------------------------------------

## 31. CODE MORT

Ne pas conserver longtemps :

-   anciens scripts inutilisés ;
-   versions `_old`;
-   fichiers `backup2`;
-   code commenté sur des centaines de lignes.

Git conserve l'historique.

Supprimer le code obsolète une fois la nouvelle version validée.

------------------------------------------------------------------------

## 32. ROBLOX STUDIO ET VS CODE

Règle générale :

### VS Code

Pour :

-   Luau ;
-   modules ;
-   services ;
-   contrôleurs ;
-   configuration ;
-   documentation.

### Roblox Studio

Pour :

-   Terrain ;
-   map ;
-   modèles ;
-   MeshParts ;
-   collisions ;
-   Attachments ;
-   animations ;
-   propriétés visuelles ;
-   tests.

Ne pas dupliquer manuellement un même script dans Studio et VS Code si
Rojo en est la source.

------------------------------------------------------------------------

## 33. ROJO

Les fichiers synchronisés par Rojo doivent être considérés comme pilotés
par le projet local.

Ne pas modifier simultanément la même source dans Studio et VS Code.

Toute modification de `default.project.json` doit être justifiée.

------------------------------------------------------------------------

## 34. GIT AVANT CHANGEMENT RISQUÉ

Avant un chantier important :

``` powershell
git status
```

Le dépôt doit idéalement être propre.

Si l'étape actuelle est stable :

``` powershell
git add .
git commit -m "message"
git push
```

Cela permet de revenir en arrière.

------------------------------------------------------------------------

## 35. COMMITS

Un commit doit correspondre à une étape cohérente.

Exemples :

``` text
feat: add world time service
feat: add player inventory
fix: prevent duplicate resource harvesting
docs: update MAYDEAD game design
```

Éviter les messages :

``` text
update
test
aaa
final
```

------------------------------------------------------------------------

## 36. NE PAS COMMITTER DE SECRETS

Interdiction de stocker dans Git :

-   mots de passe ;
-   tokens ;
-   clés API ;
-   secrets privés ;
-   informations d'authentification.

------------------------------------------------------------------------

## 37. CODEX --- LECTURE DU CONTEXTE

Avant une tâche importante, Codex doit lire les documents pertinents.

Il ne doit pas supposer qu'une mécanique absente de la documentation est
validée.

Si une décision nécessaire manque :

**STOPPER et signaler la décision à prendre.**

------------------------------------------------------------------------

## 38. CODEX --- PAS DE MODIFICATION NON DEMANDÉE

Codex ne doit pas :

-   changer le Game Design ;
-   ajouter une dépendance ;
-   renommer une architecture ;
-   modifier une autre fonctionnalité ;
-   supprimer un système stable ;

sans raison directement liée à la tâche ou instruction explicite.

------------------------------------------------------------------------

## 39. CODEX --- EXPLIQUER LES CHANGEMENTS

Après une modification, fournir un résumé court :

-   fichiers modifiés ;
-   fonctionnalité ajoutée/corrigée ;
-   tests effectués ;
-   éventuels points restant à tester dans Studio.

Éviter les rapports inutilement gigantesques pour une petite
modification.

------------------------------------------------------------------------

## 40. CODEX --- NE PAS PRÉTENDRE AVOIR TESTÉ STUDIO

Si Codex n'a pas réellement exécuté un test Roblox Studio, il ne doit
pas écrire que le comportement en jeu est validé.

Il doit distinguer :

``` text
Vérification statique
```

de :

``` text
Test réel dans Roblox Studio
```

------------------------------------------------------------------------

## 41. CODEX --- PAS DE VALEURS INVENTÉES

Si une recette, un dégât, une durée ou une quantité n'est pas définie :

-   rechercher la valeur dans la documentation ;
-   si elle n'existe pas, demander/indiquer qu'une décision est
    nécessaire.

Ne pas choisir silencieusement `10`, `25`, `100` ou toute autre valeur
arbitraire.

------------------------------------------------------------------------

## 42. CODEX --- DÉPENDANCES

Ne pas installer une librairie ou un package uniquement pour éviter
d'écrire quelques lignes simples.

Avant d'ajouter une dépendance :

-   expliquer son utilité ;
-   vérifier qu'elle est réellement nécessaire ;
-   documenter son installation.

------------------------------------------------------------------------

## 43. STYLUA

Lorsque StyLua sera activé :

-   utiliser une configuration commune au dépôt ;
-   formater le code avant validation ;
-   ne pas reformater massivement tout le projet pendant une
    modification fonctionnelle sans raison.

------------------------------------------------------------------------

## 44. SELENE

Lorsque Selene sera activé :

-   corriger les alertes pertinentes ;
-   ne pas désactiver globalement des règles uniquement pour faire
    disparaître les warnings ;
-   documenter les exceptions justifiées.

------------------------------------------------------------------------

## 45. WALLY

Wally n'est pas obligatoire.

L'utiliser uniquement lorsqu'une dépendance externe apporte une vraie
valeur.

MAYDEAD doit éviter de dépendre inutilement d'un grand nombre de
packages.

------------------------------------------------------------------------

## 46. DOCUMENTATION APRÈS VALIDATION

Quand une décision de conception change :

1.  modifier `GAME_DESIGN.md` ;
2.  vérifier `ARCHITECTURE.md` ;
3.  vérifier `ROADMAP.md` ;
4.  mettre à jour `PROJECT_STATUS.md` ;
5.  adapter le code.

Quand seule l'implémentation avance :

mettre principalement à jour `PROJECT_STATUS.md`.

------------------------------------------------------------------------

## 47. PROJECT STATUS

Ne jamais marquer un système `TERMINÉ` s'il est seulement :

-   codé ;
-   non testé ;
-   testé uniquement en solo alors qu'il est critique en multi ;
-   connu pour avoir un bug majeur.

États officiels :

``` text
NON COMMENCÉ
EN COURS
PROTOTYPE
À TESTER
TERMINÉ
BLOQUÉ
```

------------------------------------------------------------------------

## 48. FIRST PLAYABLE PRIORITAIRE

Jusqu'au First Playable, éviter de consacrer du temps à :

-   boutique complexe ;
-   dizaines de cosmétiques ;
-   nombreuses îles ;
-   dizaines d'animaux ;
-   polish final ;
-   systèmes secondaires.

La boucle de base doit être amusante avant l'expansion.

------------------------------------------------------------------------

## 49. UX ACCESSIBLE

MAYDEAD doit rester accessible à un public Roblox.

Éviter les interfaces inutilement complexes.

Une action importante doit fournir un feedback clair :

-   succès ;
-   échec ;
-   ressource manquante ;
-   inventaire plein ;
-   action impossible.

------------------------------------------------------------------------

## 50. MOBILE

Toute interaction majeure conçue pour clavier/souris doit disposer d'un
équivalent viable sur tablette et téléphone dès sa validation.

Ne pas construire une mécanique essentielle impossible à adapter au
tactile.

------------------------------------------------------------------------

## 51. SÉCURITÉ DES RECORDS

Toute fonctionnalité pouvant améliorer l'âge d'évasion doit être
considérée comme sensible.

Les records doivent utiliser uniquement des données validées côté
serveur.

La monétisation ne doit pas permettre directement d'acheter un meilleur
record officiel.

------------------------------------------------------------------------

## 52. HYDRAVION

La progression de l'hydravion est une progression du monde.

Les Documents analysés, composants installés et état final doivent être
persistants et serveur autoritaires.

Aucune simple modification client d'un MeshPart ne doit pouvoir valider
la progression.

------------------------------------------------------------------------

## 53. DÉFINITION DE « TERMINÉ »

Une fonctionnalité est terminée lorsqu'elle :

-   respecte le GDD ;
-   respecte l'architecture ;
-   fonctionne ;
-   gère ses erreurs principales ;
-   est sécurisée côté serveur si nécessaire ;
-   fonctionne en multi si concernée ;
-   ne crée pas de bug critique connu ;
-   est documentée dans `PROJECT_STATUS.md`.

------------------------------------------------------------------------

## 54. PRIORITÉ À LA STABILITÉ

Lorsqu'un bug critique apparaît dans un système déjà utilisé par
plusieurs fonctionnalités, le corriger avant d'empiler de nouvelles
fonctionnalités dépendantes.

Particulièrement pour :

-   DataService ;
-   InventoryService ;
-   SessionService ;
-   TimeService ;
-   système réseau.

------------------------------------------------------------------------

## 55. RÈGLE FINALE

La priorité n'est pas d'écrire le plus de code possible.

La priorité est de construire :

# UN MAYDEAD JOUABLE, STABLE ET PUBLIABLE

Chaque décision technique doit servir cet objectif.

------------------------------------------------------------------------

# FIN DU DOCUMENT

**MAYDEAD --- Development Rules V1**
