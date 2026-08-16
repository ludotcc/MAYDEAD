# MAYDEAD --- GAME DESIGN DOCUMENT

**Document :** Game Design Document (GDD)\
**Projet :** MAYDEAD\
**Plateforme principale :** Roblox\
**Genre :** Survival / Craft / Construction / Exploration / Coopération\
**Joueurs :** 1 à 6\
**Statut :** Conception V1 validée --- document maître\
**Date :** 8 août 2026

------------------------------------------------------------------------

## 1. RÔLE DU DOCUMENT

Ce document constitue la source de vérité principale concernant la
conception de MAYDEAD.

Toute mécanique développée doit respecter ce document. Lorsqu'un point
n'est pas défini ici, il ne doit pas être inventé arbitrairement pendant
le développement : il doit être soumis à une décision de conception puis
documenté.

Les valeurs identifiées comme valeurs d'équilibrage pourront évoluer
après les playtests sans remettre en cause la conception générale.

------------------------------------------------------------------------

## 2. CONCEPT

MAYDEAD est un jeu Roblox de survie, de construction, de crafting,
d'exploration et de progression technologique jouable seul ou en
coopération jusqu'à 6 joueurs.

La partie commence après le crash d'un petit avion sur un archipel
isolé.

Les survivants doivent :

-   se nourrir ;
-   boire ;
-   dormir ;
-   récolter des ressources ;
-   fabriquer des outils ;
-   construire une base ;
-   cultiver des aliments ;
-   chasser et pêcher ;
-   explorer les autres îles ;
-   développer des moyens de production ;
-   automatiser progressivement certaines productions ;
-   retrouver des documents techniques ;
-   construire un nouvel hydravion ;
-   quitter l'archipel.

Le joueur peut poursuivre deux objectifs :

1.  **Évasion** --- quitter l'archipel après le moins d'années possible et
    battre ses records.
2.  **Survie libre** --- continuer indéfiniment à construire, produire,
    explorer et améliorer son monde sans obligation de partir.

------------------------------------------------------------------------

## 3. IDENTITÉ DE MAYDEAD

### 3.1 Nom officiel

Le nom officiel et figé du jeu est :

# MAYDEAD

Le nom est un mot inventé faisant notamment écho à l'appel aéronautique
« MAYDAY » et au mot anglais « DEAD ».

### 3.2 Ton

MAYDEAD doit combiner :

-   une vraie boucle de survie ;
-   une progression satisfaisante ;
-   une exploration présentant des dangers ;
-   une construction accessible ;
-   une industrie simple à comprendre ;
-   de la coopération ;
-   un humour ponctuel et assumé.

Le jeu ne doit pas devenir une simulation réaliste lourde.

Certaines mécaniques peuvent volontairement être amusantes ou absurdes
si elles ne détruisent pas la cohérence du gameplay.

------------------------------------------------------------------------

## 4. INTRODUCTION

Le joueur commence à la suite du crash d'un petit avion.

L'avion du crash est définitivement détruit. Il ne constitue pas le
véhicule final.

L'épave peut fournir :

-   quelques ressources ;
-   des morceaux de métal ;
-   certains composants récupérables ;
-   le premier Document technique important.

Une cinématique d'introduction est prévue.

Le joueur reprend ensuite le contrôle à proximité de la zone du crash.

------------------------------------------------------------------------

## 5. ANNÉES SUR L'ARCHIPEL

Le temps de MAYDEAD n'est pas principalement présenté en « Day 1 », «
Day 2 », etc.

Chaque monde commence à :

**ANNÉE 0**

Un cycle complet jour + nuit représente :

**1 année passée sur l'archipel.**

Le joueur passe donc progressivement à :

-   Année 1 ;
-   Année 2 ;
-   Année 3 ;
-   etc.

Le nombre d'années sur l'archipel devient le principal indicateur de
durée d'une tentative et de longévité en survie libre.

### 5.1 Record

Lors d'une évasion réussie, le score principal est le nombre d'années
nécessaires pour quitter l'archipel.

Exemple :

**ÉVASION RÉUSSIE --- 14 ANNÉES**

L'objectif compétitif consiste à réussir l'évasion après le moins
d'années possible.

Le temps réel pourra servir de critère secondaire/départage.

### 5.2 Vieillissement visuel

Le compteur ne représente pas un âge biologique. Aucun vieillissement
physique, visuel ou statistique du personnage n'en découle.

------------------------------------------------------------------------

## 6. CYCLE JOUR / NUIT

Valeur actuellement validée :

-   **Jour : 13 minutes**
-   **Nuit : 4 minutes**
-   **Cycle complet : 17 minutes**
-   **Cycle complet = +1 année**

Ces valeurs devront être évaluées pendant les playtests mais
représentent la référence actuelle.

La nuit doit modifier réellement l'ambiance du monde et favoriser
l'utilisation du sommeil et des abris.

------------------------------------------------------------------------

## 7. MÉTÉO

La météo fait partie de la première boucle jouable et n'est pas
considérée comme une fonctionnalité secondaire.

La V1 doit prévoir au minimum :

-   temps normal ;
-   pluie ;
-   orage.

La météo doit être perceptible visuellement et peut avoir des
conséquences gameplay.

Exemples validés/prévus :

-   la pluie peut arroser les cultures ;
-   la pluie peut remplir les systèmes de récupération d'eau ;
-   les orages peuvent réduire la visibilité et renforcer l'ambiance.

Les effets météorologiques doivent fonctionner correctement sur la
grande map et suivre/affecter les joueurs de manière adaptée.

------------------------------------------------------------------------

## 8. MONDES ET MULTIJOUEUR

MAYDEAD est jouable :

-   en solo ;
-   en coopération jusqu'à **6 joueurs maximum**.

Un joueur crée une **partie / monde sauvegardé**, et non simplement une
session jetable.

### 8.1 Mondes sauvegardés

Objectif :

**3 mondes créés maximum par joueur**, sous réserve de validation
technique Roblox.

Le joueur doit pouvoir :

-   créer un monde ;
-   reprendre un monde ;
-   autoriser des joueurs ;
-   retirer des joueurs autorisés ;
-   continuer une partie sur plusieurs sessions.

### 8.2 Accès sans le créateur

Un membre autorisé doit pouvoir rejoindre/lancer le monde même si son
créateur n'est pas connecté.

Le monde appartient conceptuellement à la sauvegarde partagée.

### 8.3 Propriétaire et permissions

Le créateur reste propriétaire du monde.

Il peut :

-   gérer les membres ;
-   exclure un membre ;
-   donner des permissions avancées ;
-   désigner des administrateurs du monde.

Les systèmes anti-grief devront empêcher un membre standard de détruire
arbitrairement toute la base.

### 8.4 Monde inactif

Lorsque personne ne joue dans le monde :

**le temps du monde est arrêté.**

Les cultures, les années sur l'archipel et les autres systèmes temporels ne continuent pas
pendant plusieurs heures/jours réels d'absence.

### 8.5 Instance unique

Une même sauvegarde ne doit pas pouvoir être exécutée simultanément sur
deux serveurs différents.

Cette règle devra être garantie par l'architecture serveur.

------------------------------------------------------------------------

## 9. COOPÉRATION

MAYDEAD ne possède pas de PvP dans sa conception principale.

Les joueurs coopèrent.

Les ressources, constructions, machines, cultures et progression de
l'hydravion appartiennent au monde partagé.

Il n'existe pas de classes imposées.

Aucun joueur n'est automatiquement :

-   ingénieur ;
-   chasseur ;
-   constructeur ;
-   agriculteur.

Les rôles apparaissent naturellement selon l'organisation du groupe.

------------------------------------------------------------------------

## 10. INVENTAIRE

Le joueur possède :

-   **20 slots d'inventaire principal** ;
-   une **hotbar de 8 emplacements**.

Les ressources sont empilables.

Référence initiale pour les ressources ordinaires :

**stack x50**

Cette valeur est une valeur d'équilibrage et pourra varier selon le type
d'objet.

Les outils et équipements importants ne sont généralement pas
empilables.

Il n'existe pas de système de poids en V1.

------------------------------------------------------------------------

## 11. STOCKAGE

Les stockages fonctionnent par slots limités.

### Règle officielle de transfert joueur ↔ station

- Un clic simple ne transfère aucun objet.
- Un glisser-déposer réel transfère exactement une unité après un seuil de déplacement de 6 pixels.
- Maj + clic gauche transfère immédiatement la pile complète, dans la limite de la capacité disponible.
- Maj + clic droit transfère la moitié de la pile (`floor(Q / 2)`), sans transfert pour une pile de quantité 1.
- Un clic gauche maintenu environ 0,45 seconde sans atteindre le seuil de drag transfère la pile complète.
- Un dépôt sur un slot compatible ou sur le panneau de destination utilise le placement automatique disponible.
- Un dépôt hors interface ou sur une destination incompatible annule le transfert.
- Le serveur valide la source, la destination, la quantité, la compatibilité et la capacité avant toute mutation.

### Interaction officielle inventaire / accès rapide

- Le joueur possède 28 vrais slots : 20 principaux et 8 slots d'accès rapide.
- Les indices 21 à 28 contiennent de vrais `ItemStack`, sélectionnés avec les touches 1 à 8 sur PC.
- Main ↔ Quick et Main ↔ Main : le drag déplace le stack complet, fusionne un ItemId identique ou échange deux ItemId différents.
- Aucun raccourci virtuel ni aucune copie de stack n'est créé.
- Joueur ↔ station reste un transfert externe : drag pour une unité, Maj + clic gauche ou clic gauche long pour la pile complète, Maj + clic droit pour sa moitié.

Sont concernés notamment :

-   coffres ;
-   Table de crafting ;
-   feu de camp ;
-   four ;
-   usine ;
-   autres machines.

Les capacités exactes seront équilibrées pendant le développement.

### 11.1 Coffres

Les coffres peuvent être renommés par les joueurs disposant des
permissions nécessaires.

Exemples :

-   BOIS ;
-   MÉTAL ;
-   NOURRITURE ;
-   HYDRAVION.

Le nom du coffre est sauvegardé dans le monde et partagé entre les
joueurs.

Le nom peut être affiché lorsque le joueur est suffisamment proche.

Des coffres améliorés pourront proposer davantage de slots.

------------------------------------------------------------------------

## 12. DÉCONNEXION ET LIT

Le lit possède une importance forte.

Pour sécuriser complètement son état et conserver son inventaire de
ressources tel quel avant une déconnexion volontaire, le joueur doit
retourner dormir/se coucher dans son lit avant de quitter la partie.

Le jeu doit encourager le rituel :

**Retour à la base → rangement éventuel → lit → déconnexion sécurisée.**

Une coupure Internet, un crash Roblox ou une fermeture involontaire ne
doit cependant pas être utilisée comme moyen injuste de supprimer
arbitrairement toutes les ressources du joueur.

Le comportement précis en cas de déconnexion non sécurisée devra être
défini techniquement avant implémentation afin d'éviter les exploits et
les pertes injustes.

------------------------------------------------------------------------

## 13. SOMMEIL

Le joueur peut dormir :

-   la nuit ;
-   pendant la journée.

Le sommeil sert principalement à récupérer de l'énergie.

Référence :

**0 % → 100 % énergie = 3 minutes de sommeil.**

Le joueur se réveille lorsque son énergie est récupérée ou selon les
règles du système final.

### 13.1 Sommeil multijoueur

Si tous les joueurs actuellement connectés dorment pendant la nuit, le
monde peut avancer rapidement jusqu'au lever du jour.

Un seul joueur ne peut pas imposer le passage de la nuit aux autres
joueurs éveillés.

### 13.2 Sécurité

Dormir dehors doit être risqué.

Un lit placé sans protection à l'extérieur peut entraîner aléatoirement
la présence/l'attaque d'un animal au réveil.

Construire un abri améliore donc réellement la sécurité.

### 13.3 Respawn

Un lit revendiqué peut devenir le point de respawn du joueur.

Avant cela, le respawn s'effectue dans la zone de départ/crash prévue.

------------------------------------------------------------------------

## 14. VIE

Référence actuelle :

**100 PV**

Les dangers comprennent notamment :

-   faim ;
-   soif ;
-   noyade ;
-   animaux ;
-   consommation de nourriture crue ;
-   autres dangers environnementaux futurs.

Il n'est pas prévu de système RPG complexe de statistiques.

------------------------------------------------------------------------

## 15. MORT

Lorsqu'un joueur meurt :

### Conservé

-   outils permanents ;
-   équipements permanents prévus par le design.

### Perdu temporairement

Les ressources transportées quittent l'inventaire du joueur et sont
déposées dans un sac récupérable à l'endroit de la mort.

Le sac permet une expédition de récupération.

Référence initiale :

**30 minutes réelles de présence active du monde**

avant disparition éventuelle.

Le timer ne doit pas continuer inutilement lorsque le monde n'est pas
actif.

Cette durée reste une valeur d'équilibrage.

------------------------------------------------------------------------

## 16. FAIM

Le personnage possède une jauge de faim.

Elle diminue progressivement.

À zéro, le joueur commence progressivement à perdre des PV.

La nourriture permet également de récupérer une partie de l'énergie.

------------------------------------------------------------------------

## 17. SOIF

Le personnage possède une jauge de soif.

Elle diminue progressivement et peut diminuer plus rapidement que la
faim.

À zéro, le joueur commence progressivement à perdre des PV.

------------------------------------------------------------------------

## 18. EAU ET GOURDE

Le joueur doit pouvoir fabriquer une gourde.

Le fonctionnement recherché est volontairement accessible, dans l'esprit
d'ARK :

-   le joueur entre/s'approche de l'eau ;
-   il peut boire ;
-   il peut remplir sa gourde.

La V1 ne prévoit pas de système complexe de purification ou de
contamination de l'eau.

Le danger de l'eau vient principalement :

-   de la noyade ;
-   des requins ;
-   d'autres animaux marins éventuels.

------------------------------------------------------------------------

## 19. OXYGÈNE

Une jauge d'oxygène apparaît lorsque le personnage reste sous l'eau.

Lorsque l'oxygène atteint zéro :

-   le joueur perd progressivement des PV ;
-   il peut mourir noyé.

Des équipements avancés pourront ultérieurement améliorer l'autonomie
sous-marine.

------------------------------------------------------------------------

## 20. ÉNERGIE

Le personnage possède une jauge d'énergie de référence :

**100 maximum**

L'énergie est consommée notamment par :

-   sprint ;
-   nage rapide ;
-   récolte ;
-   combat ;
-   autres actions physiques selon équilibrage.

À 0 énergie :

-   le joueur ne meurt pas ;
-   il ne peut plus sprinter ;
-   certaines actions physiques peuvent être ralenties.

L'énergie peut être récupérée notamment par :

-   nourriture ;
-   sommeil.

------------------------------------------------------------------------

## 21. NOURRITURE

MAYDEAD ne possède pas de système de recettes culinaires complexes.

Le joueur mange principalement :

-   légumes récoltés ;
-   poisson ;
-   viande.

### 21.1 Viande et poisson crus

Ils peuvent être consommés crus mais provoquent une perte de PV.

### 21.2 Cuisson

La viande et le poisson doivent être placés dans l'inventaire d'un feu
de camp.

Référence :

**25 secondes de cuisson par pièce.**

Une fois cuits, ils peuvent être consommés normalement.

Il n'est pas prévu de fabriquer des plats complexes, soupes ou recettes
combinant plusieurs ingrédients.

------------------------------------------------------------------------

## 22. AGRICULTURE

Le joueur peut construire des bacs de culture.

La boucle de base est :

**Obtenir graines → construire bac → planter → arroser → attendre →
récolter.**

L'eau est nécessaire à la croissance.

Si une culture manque d'eau, la philosophie privilégiée est que sa
croissance s'arrête plutôt que de provoquer une destruction punitive
immédiate.

### 22.1 Engrais

L'engrais est facultatif.

Il améliore :

-   la vitesse de croissance ;
-   et/ou le rendement.

Les valeurs exactes seront équilibrées.

------------------------------------------------------------------------

## 23. BESOINS NATURELS ET COMPOST

MAYDEAD possède volontairement une mécanique humoristique de besoins
naturels.

Manger contribue progressivement au besoin d'aller aux toilettes.

Le joueur peut produire des déjections.

### 23.1 Utilité sérieuse

Les déjections peuvent être utilisées dans une chaîne de compost :

**Déjections + déchets organiques → Composteur → Compost / Engrais →
Agriculture**

### 23.2 Utilité humoristique

Le joueur peut également faire caca à l'extérieur et notamment sur/près
d'un autre joueur.

Cette action :

-   ne provoque aucun dégât ;
-   ne donne aucun avantage ;
-   ne provoque aucun malus gameplay majeur.

Elle existe principalement pour le fun multijoueur.

------------------------------------------------------------------------

## 24. RESSOURCES PRINCIPALES

Les ressources prévues comprennent notamment :

-   bois ;
-   pierre ;
-   métal ;
-   cuivre ;
-   cristal ;
-   nourriture ;
-   graines ;
-   cuir ;
-   autres ressources nécessaires à la progression.

### 24.1 Respawn

Référence actuelle :

-   arbres ordinaires : environ **60 secondes** ;
-   pierre/minerais ordinaires : environ **90 secondes**.

Les ressources rares ne doivent pas nécessairement respecter ces délais.

Elles peuvent :

-   respawn plus lentement ;
-   être réparties sur plusieurs points ;
-   nécessiter l'exploration de zones dangereuses.

Les ressources ne doivent pas devenir définitivement épuisables dans un
monde destiné à pouvoir être joué longtemps.

------------------------------------------------------------------------

## 25. CUIR

Le cuir est une ressource officielle.

Certains animaux terrestres peuvent fournir :

-   viande ;
-   cuir.

Le cuir est utilisé dans certains crafts, équipements et composants.

Les quantités dépendent de l'animal.

------------------------------------------------------------------------

## 26. OUTILS

Les outils sont permanents.

Il n'existe pas de durabilité punitive nécessitant de reconstruire
constamment la même hache.

Progression prévue :

**Pierre → Métal → tiers avancé**

Les outils améliorés peuvent :

-   récolter plus rapidement ;
-   permettre l'accès à certaines ressources ;
-   améliorer le rendement selon équilibrage.

------------------------------------------------------------------------

## 27. CRAFT MANUEL --- INVENTAIRE DU JOUEUR

L'inventaire du personnage permet uniquement de fabriquer des objets
primitifs et indispensables au démarrage.

Il doit notamment être possible d'y fabriquer :

-   premiers outils ;
-   **feu de camp** ;
-   **Table de crafting** ;
-   autres objets primitifs explicitement validés.

Un objet complexe ne doit pas pouvoir être fabriqué directement « à la
main ».

------------------------------------------------------------------------

## 28. TABLE DE CRAFTING

La Table de crafting constitue le premier vrai poste d'artisanat.

Elle possède un inventaire limité.

Elle permet notamment de fabriquer :

-   planches ;
-   cordes ;
-   coffres ;
-   bac potager ;
-   radeau ;
-   éléments de construction ;
-   composants artisanaux ;
-   autres crafts de niveau correspondant.

Exemple de philosophie :

**Bois brut → Table de crafting → Planche → Table de crafting → Radeau**

------------------------------------------------------------------------

## 29. TRANSFORMATION

Les ressources brutes peuvent nécessiter des postes spécialisés.

Exemples :

**Minerai → Four → Lingot**

**Viande crue → Feu de camp → Viande cuite**

**Déchets organiques → Composteur → Compost/Engrais**

Chaque poste possède :

-   un inventaire limité ;
-   une logique d'entrée/sortie ;
-   un temps de traitement si nécessaire.

------------------------------------------------------------------------

## 30. USINE

Les objets avancés doivent nécessiter une usine ou une machine
spécialisée.

Exemples :

-   plaques métalliques ;
-   câbles ;
-   pièces mécaniques ;
-   composants complexes ;
-   composants destinés à l'hydravion.

La philosophie centrale est :

**Récolter → Transformer → Produire → Assembler**

Le joueur ne transforme donc pas directement quelques ressources brutes
en objet technologique avancé.

------------------------------------------------------------------------

## 31. ÉLECTRICITÉ

L'électricité intervient à partir du milieu de partie.

Les systèmes primitifs n'en nécessitent pas.

Les machines industrielles avancées peuvent nécessiter une alimentation
électrique.

### 31.1 Réseau

La V1 privilégie un système accessible :

**Générateur → zone/rayon alimenté → machines fonctionnelles**

L'objectif est d'éviter une simulation de centaines de câbles difficile
à utiliser sur Roblox.

------------------------------------------------------------------------

## 32. AUTOMATISATION

MAYDEAD s'inspire partiellement de Factorio mais ne cherche pas à
reproduire sa complexité.

La première automatisation doit rester simple :

-   une machine dispose des ressources nécessaires ;
-   elle dispose éventuellement d'énergie ;
-   elle produit automatiquement ;
-   le produit arrive dans son stockage de sortie.

Des transferts automatisés entre machines/stockages pourront être
étudiés plus tard.

Une usine géante de convoyeurs n'est pas une obligation de la V1.

------------------------------------------------------------------------

## 33. CONSTRUCTION

Le joueur peut construire librement une base à partir d'éléments
modulaires.

Système validé :

**fondations / sols / murs / portes / toits / escaliers avec snapping.**

Le placement doit utiliser une prévisualisation avant validation.

Les constructions peuvent être démontées/déplacées selon les permissions
du monde.

La philosophie actuelle privilégie le remboursement de **100 % des
composants** lors d'un démontage volontaire afin de favoriser la
créativité plutôt que punir les erreurs de placement.

Les animaux ne peuvent pas détruire les constructions dans la conception
actuelle.

------------------------------------------------------------------------

## 34. GUIDE DE FABRICATION

Le joueur dispose d'un Guide de fabrication accessible depuis
l'interface.

Il fonctionne comme une encyclopédie de crafting intégrée.

Pour une ressource, il doit pouvoir afficher :

-   comment l'obtenir ;
-   comment la transformer ;
-   ce qu'elle permet de fabriquer ;
-   dans quelle station ;
-   les dépendances nécessaires.

Exemple :

**BOIS**

-   obtenu sur : arbres ;
-   transformé en : planches ;
-   utilisé pour : Table de crafting, feu de camp, etc.

### 34.1 Navigation

Le joueur peut sélectionner une recette puis sélectionner un composant
de cette recette pour remonter toute la chaîne.

Une recherche textuelle est prévue lorsque le nombre d'objets le
justifie.

### 34.2 Découverte progressive

Le Guide ne révèle pas nécessairement toutes les recettes dès le début.

La découverte d'une nouvelle matière peut révéler les crafts ordinaires
associés.

Exemple :

**premier cuivre récolté → nouvelles possibilités liées au cuivre.**

Les technologies spéciales du Projet Hydravion restent cachées tant que
les Documents techniques correspondants n'ont pas été analysés.

------------------------------------------------------------------------

## 35. EXPLORATION

L'île principale est relativement sûre.

Elle permet :

-   survie initiale ;
-   construction ;
-   agriculture ;
-   ressources communes ;
-   premiers animaux ;
-   début de progression.

D'autres îles doivent pousser le joueur à quitter sa zone de confort.

Elles peuvent proposer :

-   ressources spécifiques ;
-   ressources rares ;
-   Documents techniques ;
-   animaux plus dangereux ;
-   zones particulières.

Principe :

**plus une ressource est rare/importante, plus son accès peut être
dangereux ou complexe.**

------------------------------------------------------------------------

## 36. CARTE

Le joueur ne reçoit pas nécessairement une carte complète de l'archipel
dès le début.

La carte doit pouvoir se révéler progressivement grâce à l'exploration.

L'objectif est de conserver une sensation de découverte.

------------------------------------------------------------------------

## 37. ANIMAUX

### 37.1 Île principale

Les animaux terrestres de l'île principale sont principalement
passifs/sûrs.

Un animal chassé/attaqué doit cependant pouvoir devenir hostile et se
défendre.

### 37.2 Danger

Les autres îles peuvent accueillir des animaux agressifs plus dangereux.

Exemple de philosophie :

**ressource rare → zone protégée par un animal dangereux tel qu'un
ours.**

Les espèces exactes seront définies progressivement.

Première espèce validée pour la V1 : le **Bison**. Il possède 100 PV,
subit 25 dégâts par coup de hache ou 20 par coup de pioche, et attribue
RawMeat x6 au joueur portant le coup final. Son respawn de test est de
300 secondes sur son point d'apparition d'origine.

Le **Cheetah / Guépard sauvage V1** est une rencontre rare limitée à un
individu actif. Il reste passif tant qu'il n'est pas agressé, refuse l'eau
et devient extrêmement dangereux grâce à sa mobilité lorsqu'un joueur
l'attaque. Valeurs de test : 1500 PV, attaque 28–35, attaque spéciale 45,
respawn 900 secondes et `RawMeat x20–30`. L'apprivoisement est prévu en V2,
le compagnon en V3 et la monture en V4 ; ces phases ne sont pas implémentées.

L'apprivoisement V1 du guépard utilise des unités physiques de `RawMeat`
déposées par un joueur. Le guépard sauvage attend une zone sûre, approche
prudemment puis consomme une viande. Une nourriture valide accorde 8 à 12
points de confiance au joueur qui l'a déposée, avec un délai de 90 secondes
entre deux gains. La confiance va de 0 à 100 et une attaque du joueur engagé
retire 25 points. À 100, le guépard est marqué apprivoisé par ce joueur ; les
systèmes de monture, faim, inventaire et défense du propriétaire restent futurs.

Après adoption, le compagnon possède quatre slots réservés à `RawMeat`, une
faim lente, les commandes Suivre/Rester et une endurance de monture. Il ne
nage jamais. Un compagnon mort ne fournit pas le gros loot sauvage et sa mort
est persistée ; un nouveau guépard sauvage pourra ensuite apparaître selon le
cycle wildlife normal. La V2 reste limitée à un guépard actif par monde.

### 37.3 Récompenses

Plus une créature est forte/importante, plus elle peut fournir :

-   viande ;
-   cuir ;
-   autres ressources adaptées.

Il n'est pas prévu de niveaux d'animaux façon RPG/ARK en V1.

### 37.4 Océan

L'océan doit rester dangereux.

Les requins ou autres prédateurs marins peuvent attaquer les joueurs à
proximité.

------------------------------------------------------------------------

## 38. COMBAT

Le combat reste volontairement accessible.

Progression envisagée :

-   arme primitive ;
-   arme améliorée ;
-   armes métalliques ;
-   équipement supérieur nécessaire aux zones plus dangereuses.

Exemples possibles :

-   lance ;
-   épée ;
-   arc si validé ultérieurement.

Le jeu ne doit pas devenir un RPG de combat.

Le combat sert la survie et l'exploration.

------------------------------------------------------------------------

## 39. RADEAU

Le radeau constitue une étape importante de progression.

Il doit être crafté avant certaines avancées importantes.

Caractéristiques :

-   transport maritime précoce ;
-   lent ;
-   stockage limité ;
-   permet d'atteindre d'autres îles.

Une ressource nécessaire à la Table de Plans doit notamment nécessiter
une première exploration maritime, afin que la Table de Plans ne puisse
pas être construite dans les premières minutes.

------------------------------------------------------------------------

## 40. BATEAU

Un bateau plus avancé pourra être débloqué après le radeau.

Il peut offrir :

-   meilleure vitesse ;
-   meilleur stockage ;
-   exploration plus confortable.

Le bateau ne constitue pas la méthode finale permettant de terminer le
jeu.

------------------------------------------------------------------------

## 41. DOCUMENTS TECHNIQUES

Les Documents techniques constituent une catégorie spéciale d'objets de
progression.

Ils sont :

-   rares ;
-   importants ;
-   liés au monde ;
-   liés notamment au Projet Hydravion.

Ils ne doivent jamais être présentés comme une simple ressource `+1`.

### 41.1 Découverte

Lorsqu'un joueur récupère un Document technique, une information
visuelle importante doit apparaître.

Le message doit expliquer clairement :

**Ce document doit être placé dans l'inventaire d'une TABLE DE PLANS
pour pouvoir être lu/analysé.**

Le joueur comprend donc très tôt que la Table de Plans possède une
importance majeure, même s'il ne peut pas encore la construire.

### 41.2 Transport

Avant analyse, le document est un objet transportable.

Il peut notamment être présent dans le sac récupérable après une mort.

### 41.3 Analyse

Une fois placé et analysé dans la Table de Plans :

-   son contenu devient accessible ;
-   les connaissances correspondantes sont débloquées ;
-   la progression est enregistrée définitivement dans le monde ;
-   tous les membres du monde en bénéficient.

------------------------------------------------------------------------

## 42. TABLE DE PLANS

La Table de Plans n'est pas un objet de début de partie.

Sa fabrication nécessite une progression significative et au moins une
ressource obligeant le joueur à explorer une autre île.

La progression recherchée est notamment :

**Crash → survie → premier Document → progression primitive → radeau →
autre île → ressource spéciale → Table de Plans**

La Table de Plans possède son propre inventaire destiné aux Documents
techniques.

Son apparence n'a pas besoin d'évoluer visuellement à mesure que les
documents sont ajoutés.

MAYDEAD reste un jeu Roblox et la priorité est donnée à la lisibilité et
au gameplay.

------------------------------------------------------------------------

## 43. PROJET HYDRAVION

Le moyen final de quitter l'archipel est :

**un nouvel hydravion construit par les survivants.**

Il ne s'agit pas de réparer le petit avion du crash.

Le Projet Hydravion est découvert progressivement grâce aux Documents
techniques analysés dans la Table de Plans.

### 43.1 Philosophie

L'hydravion doit justifier toute la progression du jeu :

-   bois ;
-   matériaux transformés ;
-   métal ;
-   cuivre ;
-   cristal ;
-   industrie ;
-   électricité ;
-   exploration ;
-   composants mécaniques ;
-   ressources rares.

------------------------------------------------------------------------

## 44. DOCUMENTATION HYDRAVION

Référence de conception actuelle :

environ **5 Documents techniques majeurs**, à ajuster si nécessaire.

Exemple de découpage :

1.  Structure
2.  Flottaison
3.  Motorisation
4.  Électricité et commandes
5.  Navigation

Chaque document débloque une partie concrète de la progression.

Les emplacements exacts et défis associés seront conçus ultérieurement.

Les documents ne doivent pas tous être simplement placés dans des
coffres identiques.

------------------------------------------------------------------------

## 45. CHANTIER AÉRONAUTIQUE

L'hydravion est construit physiquement sur un chantier/support dédié.

Le chantier doit être placé dans une zone compatible proche de l'eau.

Le joueur ne construit pas l'avion librement comme une maison.

Les positions des composants sont prédéfinies.

Exemple :

-   châssis ;
-   aile gauche ;
-   aile droite ;
-   flotteurs ;
-   moteur ;
-   hélice ;
-   commandes ;
-   navigation.

Lorsqu'un composant est fabriqué, le joueur peut venir l'installer.

Le MeshPart/élément correspondant devient alors visible sur l'hydravion.

La progression est donc visible directement dans le monde.

------------------------------------------------------------------------

## 46. CRISTAL

Le cristal est une ressource rare.

Il ne doit pas nécessairement transformer MAYDEAD en jeu fantastique.

Il peut notamment être utilisé dans certaines technologies avancées,
composants ou systèmes liés à la navigation/électronique du Projet
Hydravion.

Son accès peut nécessiter l'exploration d'une zone dangereuse.

------------------------------------------------------------------------

## 47. ÉVASION

Lorsque l'hydravion est entièrement construit, les joueurs doivent
encore préparer le départ.

Des étapes finales peuvent inclure :

-   carburant ;
-   vérifications ;
-   embarquement.

Une interaction finale déclenche le départ.

Une cinématique montre l'hydravion quitter l'archipel.

Le jeu affiche ensuite :

**ÉVASION RÉUSSIE**

avec notamment :

-   années passées sur l'archipel ;
-   temps réel ;
-   nombre de joueurs ;
-   statistiques pertinentes ;
-   record personnel ;
-   éventuel classement.

------------------------------------------------------------------------

## 48. APRÈS L'ÉVASION

Une évasion réussie ne supprime pas la sauvegarde.

Le monde passe en état :

**ÉVASION RÉUSSIE**

Le joueur peut ensuite :

-   continuer librement ce monde ;
-   lancer une nouvelle tentative pour améliorer son record.

La survie libre reste donc possible après la fin principale.

------------------------------------------------------------------------

## 49. CLASSEMENTS

Les performances doivent être séparées selon la taille de l'équipe.

Catégories prévues :

-   Solo ;
-   Duo ;
-   Trio ;
-   4 joueurs ;
-   5 joueurs ;
-   6 joueurs.

Une performance à 6 joueurs ne doit pas être comparée directement à une
performance solo.

Le critère principal est :

**nombre d'années d'évasion le plus faible.**

------------------------------------------------------------------------

## 50. TUTORIEL

MAYDEAD ne doit pas imposer un long tutoriel textuel.

Le début utilise des objectifs contextuels simples.

Exemples :

-   récolter du bois ;
-   fabriquer un premier outil ;
-   obtenir de l'eau ;
-   obtenir de la nourriture ;
-   fabriquer un feu de camp ;
-   construire un abri.

Le jeu doit ensuite donner progressivement davantage de liberté.

Les systèmes importants doivent être expliqués au moment où ils
deviennent pertinents.

------------------------------------------------------------------------

## 51. PROGRESSION SANS XP

MAYDEAD ne possède pas de système traditionnel de niveaux/XP comme cœur
de progression.

Il ne doit pas être nécessaire d'atteindre arbitrairement :

**Niveau 15 pour construire une machine.**

La progression vient de :

**Découvrir → Récolter → Transformer → Construire → Explorer → Débloquer
→ Produire**

Les nouvelles possibilités apparaissent grâce :

-   aux ressources ;
-   aux machines ;
-   aux découvertes ;
-   aux Documents techniques ;
-   à l'exploration.

------------------------------------------------------------------------

## 52. ABSENCE DE MONNAIE

Il n'existe pas de monnaie économique interne nécessaire à la boucle
principale.

Pas de :

-   dollars ;
-   pièces ;
-   vendeurs obligatoires ;
-   économie PNJ.

La richesse du joueur est représentée par :

-   ses ressources ;
-   sa nourriture ;
-   sa base ;
-   ses machines ;
-   ses technologies ;
-   sa progression vers l'hydravion.

------------------------------------------------------------------------

## 53. MONÉTISATION ROBLOX

MAYDEAD pourra être monétisé.

Cependant, la monétisation ne doit pas détruire la valeur des records.

Principe officiel :

**Aucun achat ne doit accélérer directement l'évasion ni améliorer
artificiellement un record officiel.**

À éviter pour les parties classées :

-   ressources x2 ;
-   production x2 ;
-   cultures accélérées ;
-   documents achetés ;
-   hydravion accéléré ;
-   invincibilité ;
-   suppression de la faim/soif ;
-   avantages permettant directement une évasion en moins d'années.

La priorité est donnée à :

-   cosmétiques ;
-   skins d'outils ;
-   apparences de coffres ;
-   décorations ;
-   emotes ;
-   vêtements ;
-   skins de véhicules sans avantage ;
-   personnalisation de base.

Si des avantages gameplay payants sont étudiés ultérieurement, ils
devront être évalués en fonction de leur impact sur l'intégrité des
classements.

------------------------------------------------------------------------

## 54. PRINCIPES DE GAME DESIGN

MAYDEAD doit respecter les principes suivants :

### Accessible

Le joueur doit comprendre rapidement les actions essentielles.

### Progressif

Les systèmes complexes apparaissent progressivement.

### Coopératif

Jouer à plusieurs doit permettre une organisation naturelle sans imposer
de classes.

### Non punitif inutilement

Les erreurs de construction, la durabilité artificielle ou les
mécaniques répétitives ne doivent pas créer de frustration sans bénéfice
gameplay.

### Exploration utile

Explorer doit permettre de trouver quelque chose qui change réellement
la progression.

### Production logique

Les objets avancés nécessitent des chaînes de transformation cohérentes.

### Objectif visible

Le Projet Hydravion donne une direction claire à la partie.

### Liberté

Le joueur peut ignorer l'évasion et continuer son monde aussi longtemps
qu'il le souhaite.

### Record équitable

Le classement doit refléter la maîtrise du jeu et non les dépenses
Robux.

### Humour

MAYDEAD peut être drôle sans devenir une parodie permanente.

------------------------------------------------------------------------

## 55. BOUCLE DE JEU PRINCIPALE

La boucle globale de MAYDEAD est :

**CRASH**

↓

**SURVIVRE**

↓

**RÉCOLTER**

↓

**CRAFTER**

↓

**CONSTRUIRE**

↓

**TRANSFORMER**

↓

**EXPLORER**

↓

**DÉCOUVRIR**

↓

**INDUSTRIALISER**

↓

**CONSTRUIRE L'HYDRAVION**

↓

**S'ÉVADER**

↓

**BATTRE SON RECORD**

ou

**CONTINUER LE MONDE LIBREMENT**

------------------------------------------------------------------------

## 56. PROGRESSION MACRO DE RÉFÉRENCE

La progression envisagée est :

### Phase 1 --- Crash et survie

-   découverte du monde ;
-   ressources primitives ;
-   eau ;
-   nourriture ;
-   outils ;
-   feu de camp ;
-   premier abri.

### Phase 2 --- Installation

-   Table de crafting ;
-   coffres ;
-   agriculture ;
-   lit ;
-   construction ;
-   premières transformations.

### Phase 3 --- Première exploration

-   radeau ;
-   autre île ;
-   nouvelles ressources ;
-   dangers ;
-   progression vers la Table de Plans.

### Phase 4 --- Projet Hydravion

-   construction de la Table de Plans ;
-   analyse des Documents ;
-   découverte du projet final.

### Phase 5 --- Industrie

-   métallurgie ;
-   cuivre ;
-   machines ;
-   électricité ;
-   usine ;
-   production avancée ;
-   automatisation simple.

### Phase 6 --- Exploration avancée

-   bateau ;
-   zones dangereuses ;
-   cristal ;
-   Documents techniques avancés ;
-   ressources rares.

### Phase 7 --- Construction aéronautique

-   chantier ;
-   structure ;
-   flotteurs ;
-   moteur ;
-   hélice ;
-   électricité ;
-   commandes ;
-   navigation.

### Phase 8 --- Départ

-   derniers composants ;
-   carburant ;
-   préparation ;
-   embarquement ;
-   décollage.

### Phase 9 --- Résultat

-   ÉVASION RÉUSSIE ;
-   années passées sur l'archipel ;
-   statistiques ;
-   record ;
-   continuation libre ou nouvelle tentative.

------------------------------------------------------------------------

## 57. INSPIRATIONS

Les inspirations principales comprennent notamment :

-   Minecraft --- récolte, construction, liberté ;
-   ARK --- survie, inventaires de stations, exploration, progression ;
-   Factorio --- transformation, production et automatisation
    simplifiée.

MAYDEAD ne doit pas copier ces jeux.

Ils servent uniquement de références pour certaines philosophies de
gameplay.

L'identité propre de MAYDEAD repose notamment sur :

-   le compteur d'années sur l'archipel ;
-   la course à l'évasion ;
-   le monde persistant coopératif ;
-   les Documents techniques ;
-   la Table de Plans ;
-   la construction progressive d'un nouvel hydravion ;
-   le mélange survival / industrie accessible / humour.

------------------------------------------------------------------------

## 58. ÉLÉMENTS NON FIGÉS

Les points suivants peuvent encore évoluer pendant la conception ou les
playtests :

-   liste exacte des animaux ;
-   liste exacte des légumes ;
-   recettes numériques ;
-   quantité exacte de ressources par craft ;
-   taille des stacks selon objets ;
-   capacité exacte des coffres/machines ;
-   temps précis de croissance ;
-   consommation faim/soif/énergie ;
-   dégâts des animaux ;
-   armes exactes ;
-   emplacement des Documents ;
-   nombre final exact de Documents techniques ;
-   recettes exactes de l'hydravion ;
-   technologies industrielles détaillées ;
-   équilibrage du cristal ;
-   comportement exact des déconnexions non sécurisées ;
-   fonctionnement détaillé des classements mondiaux ;
-   détails de monétisation ;
-   valeurs de respawn des ressources rares.

Ces éléments ne doivent pas être inventés silencieusement par le code.

Ils doivent être décidés, testés puis documentés.

------------------------------------------------------------------------

## 59. RÈGLE DE MODIFICATION DU GDD

Lorsqu'une décision officielle de conception change :

1.  mettre à jour ce document ;
2.  vérifier les conséquences sur l'architecture ;
3.  mettre à jour la roadmap si nécessaire ;
4.  mettre à jour le statut du projet ;
5.  seulement ensuite adapter le code si la modification l'exige.

Le code ne doit pas devenir la seule source de vérité concernant une
mécanique.

------------------------------------------------------------------------

## ÉQUILIBRAGE V1 DE TEST — SURVIE DEPUIS ZÉRO

- Départ : inventaire vide, 20 slots principaux + 8 slots rapides réels.
- Tree : mains nues = récolte immédiate Wood x1 ; Axe 25 dégâts, Wood x8 ; respawn 60 s.
- Stone : mains nues = récolte immédiate Stone x1 ; Pickaxe 25 dégâts, Stone x6 ; respawn 75 s.
- Metal : 125 PV, Pickaxe 25, RawMetal x4, respawn 120 s.
- Crystal : 150 PV, Pickaxe 25, Crystal x3, respawn 180 s.
- Tomato : Hunger +15, Energy +10 ; RawMeat : Hunger +20, Energy +10, Health -20 ; CookedMeat : Hunger +40, Energy +45.
- Bison : 100 PV, Axe 25 / Pickaxe 20, RawMeat x6, respawn 300 s.
- Drains par seconde : Hunger 0,035 ; Thirst 0,05 ; Energy 0,025.
- Régénération : Health +1/s si Hunger > 25 et Thirst > 25.
- Dégâts : famine 0,35/s ; déshydratation 0,5/s ; noyade inchangée.

Statut : **À TESTER EN CONDITIONS RÉELLES** avant tout nouvel ajustement.

## MONDES PRIVÉS PARTAGÉS ET MEMBERSHIP V1

- Un joueur possède au maximum 3 mondes et peut rejoindre au maximum 3 autres mondes.
- Chaque monde est privé et limité à 6 membres officiels, propriétaire inclus. Il n'existe aucun navigateur public; l'accès se fait uniquement par invitation d'un ami.
- `OwnerUserId` reste permanent. Seul le propriétaire invite, retire des membres, renomme ou supprime le monde; un membre standard peut quitter volontairement le monde.
- Un membre autorisé peut lancer le monde sans le propriétaire. Une seule instance serveur peut détenir le monde à la fois.
- Structures, coffres, stations, Campfire, Smelt, Factory, cultures, ressources et Companion appartiennent au monde partagé. Tous les membres admis peuvent les utiliser et déconstruire les structures, tandis que les inventaires joueurs restent individuels.
- Le menu distingue les 3 mondes possédés des 3 « Mondes rejoints » et affiche les invitations privées, les membres et l'état de session.
- Une invitation en attente n'est jamais une adhésion. Elle ne consomme ni emplacement possédé ni emplacement rejoint, ne change pas `AuthorizedMembers` et n'empêche pas le joueur de créer ou rejoindre ses propres mondes.
- L'adhésion exige une acceptation serveur explicite. Les mondes possédés, les mondes rejoints et les invitations en attente sont trois catégories indépendantes.
- Toute invitation en attente est signalée dès la première page du menu principal, sans bloquer la navigation ni lancer automatiquement le monde après acceptation.

# FIN DU DOCUMENT

## FINAL GAMEPLAY LOOP V1

Statut : `À TESTER STUDIO / ROBLOX PLAYER`.

- Le `Boat` est fabriqué à la Table de craft avec `Wood x30`, `MetalIngot x12` et `CopperIngot x6`, puis placé comme véhicule sans altération de ses scripts, contraintes ou réglages physiques.
- Le `Boat` est exclusivement placeable sur la surface de l'eau Terrain; ses principaux points de support doivent tous rester au-dessus de l'eau.
- En monture Cheetah sur PC, le clic gauche commande le saut. `E` conserve le démontage explicite; Espace n'est pas une commande de saut du Cheetah.
- La `Factory` finale est fabriquée à la Table de craft avec `MetalPanelStack x12`, `MetalIngot x20` et `CopperIngot x10`.
- La Factory est une station partagée du monde. Son inventaire accepte uniquement `MetalPanelStack` et `PlasticPanelStack` avec les transferts officiels joueur/station.
- Le `Naval Seaplane` est produit uniquement dans la Factory avec `MetalPanelStack x40` et `PlasticPanelStack x30`, en 60 secondes de présence active du monde.
- Un seul Naval Seaplane final est validé par monde. L'objectif principal terminé ne ferme ni ne supprime le monde : survie, construction, exploration et compteur d'années continuent.
- Le record d'évasion conserve le plus faible nombre d'années sur l'archipel. Le record de longévité conserve le plus grand nombre d'années atteint et peut progresser après la fin principale.

**MAYDEAD --- Game Design Document V1**

Ce document sert de référence officielle pour la conception générale du
projet.
