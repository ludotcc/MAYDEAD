# MAYDEAD --- AGENTS.md

## 1. ROLE

This file contains mandatory instructions for any coding agent working
on MAYDEAD.

Project: - Name: MAYDEAD - Platform: Roblox - Language: Luau - Main
editor: VS Code - Roblox synchronization: Rojo - Version control: Git +
GitHub

The repository is now officially named `MAYDEAD`.

Do not rename project paths, remotes, or technical identifiers unless explicitly requested.

------------------------------------------------------------------------

## 2. READ THE PROJECT DOCUMENTATION FIRST

Before making a significant change, read the relevant project
documentation.

Primary documents:

``` text
docs/GAME_DESIGN.md
docs/ARCHITECTURE.md
docs/ROADMAP.md
docs/PROJECT_STATUS.md
docs/DEVELOPMENT_RULES.md
docs/INPUT_CONTROLS.md
```

Their responsibilities are:

-   `GAME_DESIGN.md` = gameplay source of truth.
-   `ARCHITECTURE.md` = technical architecture source of truth.
-   `ROADMAP.md` = intended development order.
-   `PROJECT_STATUS.md` = actual current implementation status.
-   `DEVELOPMENT_RULES.md` = mandatory development practices.
-   `INPUT_CONTROLS.md` = PC, tablet, and phone controls source of truth.

Do not rely only on this `AGENTS.md` when a task depends on detailed
gameplay or architecture.

------------------------------------------------------------------------

## 3. SOURCE-OF-TRUTH PRIORITY

When deciding what to implement:

### Gameplay rule

Use:

``` text
docs/GAME_DESIGN.md
```

### Technical structure

Use:

``` text
docs/ARCHITECTURE.md
```

### What already exists

Use:

``` text
docs/PROJECT_STATUS.md
```

### Development method

Use:

``` text
docs/DEVELOPMENT_RULES.md
```

### Development sequence

Use:

``` text
docs/ROADMAP.md
```

### Player controls and interactive UI

Use:

``` text
docs/INPUT_CONTROLS.md
```

Before implementing input, player interaction, or interactive UI:

-   read `INPUT_CONTROLS.md`;
-   preserve existing PC controls;
-   provide viable tablet and phone paths;
-   reuse existing Remotes when possible;
-   test PC, tablet, and phone;
-   update `INPUT_CONTROLS.md` in the same task when a control changes.

If two official documents contradict each other, do not silently choose
one.

Report the contradiction and request a decision if it materially affects
the task.

------------------------------------------------------------------------

## 4. DO NOT INVENT GAME DESIGN

Never silently invent:

-   recipes;
-   resource quantities;
-   damage values;
-   crafting times;
-   animal species;
-   progression requirements;
-   item tiers;
-   document locations;
-   hydroplane requirements;
-   monetization advantages;
-   penalties;
-   major UI flows.

First search the project documentation.

If the required decision is genuinely undefined and blocks
implementation, state exactly what decision is missing.

Do not hide an arbitrary placeholder inside production code.

------------------------------------------------------------------------

## 5. RESPECT THE CURRENT TASK

Only modify what is necessary to complete the requested task.

Do not use a small task as an excuse to:

-   refactor unrelated systems;
-   rename unrelated files;
-   reorganize the entire repository;
-   install packages;
-   change Game Design;
-   rewrite stable code;
-   redesign UI;
-   modify the Rojo tree.

Keep changes targeted.

------------------------------------------------------------------------

## 6. DO NOT OVERENGINEER

MAYDEAD should have a clean architecture, not an unnecessarily
complicated one.

Prefer:

-   simple modules;
-   clear responsibilities;
-   readable code;
-   configuration-driven systems;
-   Roblox-native solutions.

Avoid:

-   speculative frameworks;
-   excessive abstraction;
-   unnecessary dependency injection;
-   dozens of empty modules;
-   premature generic systems.

Build what the current feature actually needs.

------------------------------------------------------------------------

## 7. SERVER AUTHORITY IS MANDATORY

Gameplay-critical state must be authoritative on the server.

The client must never be trusted to decide:

-   resource rewards;
-   inventory contents;
-   crafting success;
-   building creation;
-   damage;
-   survival values;
-   YearsOnIsland;
-   blueprint progression;
-   hydroplane progression;
-   escape completion;
-   leaderboard records.

Client requests express intent.

Server code validates and applies the result.

------------------------------------------------------------------------

## 8. VALIDATE CLIENT REQUESTS

Any RemoteEvent or RemoteFunction that can affect gameplay must validate
appropriate conditions.

Depending on the action, validate:

-   argument types;
-   player state;
-   distance;
-   target existence;
-   permissions;
-   cooldown;
-   inventory contents;
-   available slots;
-   recipe validity;
-   world ownership/membership;
-   current object state.

Never create a remote whose only protection is that the normal UI does
not expose it.

------------------------------------------------------------------------

## 9. CLIENT RESPONSIBILITIES

Client code should primarily handle:

-   UI;
-   camera;
-   local visual effects;
-   local audio where appropriate;
-   interaction presentation;
-   building previews;
-   notifications;
-   input.

A client may predict or preview something for responsiveness, but the
server remains authoritative.

------------------------------------------------------------------------

## 10. SHARED CODE

Use `src/shared` for definitions and logic genuinely needed by both
client and server.

Good candidates include:

-   item definitions;
-   recipe definitions;
-   types;
-   configuration;
-   remote names;
-   general utilities.

Do not put server secrets or server-only validation logic in shared
modules.

------------------------------------------------------------------------

## 11. CURRENT ROJO STRUCTURE

The established base structure is:

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

Current source entry files include:

``` text
src/client/init.client.luau
src/server/init.server.luau
src/shared/Hello.luau
```

Do not change `default.project.json` unless the task genuinely requires
a Rojo mapping change.

------------------------------------------------------------------------

## 12. KEEP ENTRY POINTS SMALL

`init.server.luau` and `init.client.luau` are bootstrap files.

Do not turn them into giant gameplay scripts.

As systems are implemented, move substantial logic into appropriately
named modules/services/controllers.

------------------------------------------------------------------------

## 13. PREFERRED SERVER STRUCTURE

When required by implemented features, server systems should
progressively live under structures such as:

``` text
src/server/Services/
```

Examples from the architecture include:

``` text
TimeService.luau
WeatherService.luau
InventoryService.luau
ResourceService.luau
CraftingService.luau
SurvivalService.luau
DataService.luau
```

Do not create every planned service in advance.

Create a service when the current feature actually needs it.

------------------------------------------------------------------------

## 14. PREFERRED CLIENT STRUCTURE

When needed, client systems may progressively use:

``` text
src/client/Controllers/
src/client/UI/
src/client/Effects/
```

Do not create empty architecture solely to match a diagram.

------------------------------------------------------------------------

## 15. AVOID SCRIPTS INSIDE EVERY WORLD OBJECT

Do not solve harvesting, storage, machines, beds, or similar systems by
copying scripts into hundreds of Parts or Models.

Prefer centralized systems using Roblox features such as:

-   `CollectionService`;
-   tags;
-   Attributes;
-   shared interaction logic.

Exceptions must have a concrete reason.

------------------------------------------------------------------------

## 16. CONFIGURATION-DRIVEN GAMEPLAY

Values likely to be balanced later should be centralized.

Examples:

-   day/night duration;
-   respawn duration;
-   cooking time;
-   stack limits;
-   hunger rates;
-   thirst rates;
-   energy rates;
-   damage;
-   growth duration.

Do not scatter the same balancing value through multiple scripts.

------------------------------------------------------------------------

## 17. INTERNAL IDS

Use stable technical identifiers independent of displayed language.

Good:

``` text
Wood
Stone
RawMetal
CopperOre
CookedMeat
CraftingTable
```

Do not use localized display strings as gameplay keys.

------------------------------------------------------------------------

## 18. LUAU STYLE

Write idiomatic, readable Luau.

General naming:

``` text
PascalCase       modules/services/types
camelCase        locals/functions
UPPER_SNAKE_CASE constants when appropriate
```

Prefer descriptive names.

Avoid vague names such as:

``` text
thing
stuff
data2
newScript
finalVersion
```

------------------------------------------------------------------------

## 19. TYPES

Use Luau typing where it meaningfully improves safety and
maintainability.

Important persistent data structures and public module APIs should
progressively receive useful types.

Do not make simple code unreadable through excessive type complexity.

------------------------------------------------------------------------

## 20. PERFORMANCE

MAYDEAD is intended to support:

-   a large map;
-   up to 6 cooperative players;
-   weather;
-   animals;
-   building;
-   farming;
-   machines;
-   persistent worlds.

Avoid obvious scaling problems.

Do not create:

-   one per-frame loop per object;
-   hundreds of independent `while true` loops;
-   unnecessary replicated particle systems;
-   repeated full Workspace scans;
-   excessive network traffic.

Prefer:

-   events;
-   centralized updates;
-   timestamps;
-   batched work;
-   local visual effects;
-   sleeping/inactive systems when useful.

Optimize based on evidence, but do not introduce obviously expensive
architecture.

------------------------------------------------------------------------

## 21. LARGE-WORLD ASSUMPTIONS

Never assume every player is close to every other player.

Visual systems such as rain should be designed to work locally around
players rather than requiring a gigantic physical effect covering the
whole archipelago.

Code should remain compatible with possible future use of
`StreamingEnabled`.

------------------------------------------------------------------------

## 22. DATASTORE SAFETY

Persistent data is critical.

When implementing DataStore systems:

-   use protected calls where appropriate;
-   handle failures explicitly;
-   version schemas;
-   avoid excessive writes;
-   prevent concurrent corruption;
-   log meaningful failures;
-   never silently discard important player/world data.

Do not claim a save succeeded if the operation failed.

------------------------------------------------------------------------

## 23. SHARED WORLD SAVES

MAYDEAD worlds are not ordinary single-player profile saves.

The design requires authorized members to potentially play without the
world owner.

Therefore:

-   world data must be conceptually separate from individual player
    data;
-   a world needs a stable unique ID;
-   simultaneous editing of the same world by multiple servers must be
    prevented;
-   session locking must be designed before persistent multiplayer is
    considered complete.

Do not implement shared-world persistence as a simplistic value stored
only under the owner's current session.

------------------------------------------------------------------------

## 24. BED MECHANIC VS TECHNICAL SAVE

The bed/disconnection mechanic is a gameplay rule.

Technical data safety is separate.

Never intentionally skip necessary technical saving because a player did
not sleep.

If the exact gameplay consequence of an unsafe disconnect is still
unresolved in the GDD/status documentation, do not invent it.

------------------------------------------------------------------------

## 25. INVENTORY SAFETY

Inventory changes must occur on the server.

Sensitive operations should avoid duplication windows.

Examples:

``` text
validate
↓
remove inputs
↓
produce result
↓
replicate updated state
```

Inventory, storage, death, crafting and reconnect flows require
duplication testing.

------------------------------------------------------------------------

## 26. BUILDING

The client may display a placement ghost.

The server must validate the official placement.

Validate relevant conditions such as:

-   allowed building ID;
-   resources;
-   permissions;
-   distance;
-   placement constraints;
-   current world.

Persistent buildings should use compact save data rather than blindly
serializing the whole Workspace.

------------------------------------------------------------------------

## 27. WEATHER

The server owns the official weather state and gameplay consequences.

The client should handle expensive cosmetic effects when practical.

Do not replicate every rain droplet as a networked physical object.

------------------------------------------------------------------------

## 28. TIME AND YEARS ON ISLAND

The server owns official world time and YearsOnIsland.

Current validated design reference:

``` text
Starting YearsOnIsland: 0
Day: 13 minutes
Night: 4 minutes
Full cycle: 17 minutes
Full cycle: +1 year on the island
```

Do not let clients independently determine the official YearsOnIsland.
For schema V1 compatibility, persisted `Age` remains a legacy internal field
equal to `YearsOnIsland + 10`; it must not be reset or renamed destructively.

------------------------------------------------------------------------

## 29. HYDROPLANE

The hydroplane is the central long-term objective.

It is a world progression system.

The server must own:

-   analyzed technical documents;
-   unlocked knowledge;
-   manufactured required components;
-   installed components;
-   completion state;
-   escape eligibility.

A visual MeshPart appearing on a client never constitutes authoritative
progression.

------------------------------------------------------------------------

## 30. RECORDS

Escape records are sensitive competitive data.

They must be validated by the server.

Current intended categories:

``` text
Solo
2 players
3 players
4 players
5 players
6 players
```

Primary metric:

``` text
lowest YearsOnIsland at escape
```

Do not introduce monetized gameplay advantages into official record
logic unless the Game Design is explicitly changed.

------------------------------------------------------------------------

## 31. PROTOTYPE CODE

Existing Roblox Studio experiments may include prototypes for systems
such as:

-   day/night;
-   rain;
-   harvesting;
-   interactions.

Do not assume prototype code is production-ready.

Before integrating it, check:

-   architecture;
-   server authority;
-   multiplayer behavior;
-   performance;
-   compatibility with current design.

It is acceptable to replace a prototype when a clean implementation is
safer.

------------------------------------------------------------------------

## 32. TESTING EXPECTATIONS

For important gameplay systems, consider at least:

-   normal use;
-   invalid request;
-   repeated request;
-   inventory full;
-   player too far away;
-   two players using the same object;
-   death when relevant;
-   disconnect when relevant;
-   save/reload when persistent.

Multiplayer-critical code is not considered fully validated after a
solo-only test.

------------------------------------------------------------------------

## 33. DO NOT FAKE TEST RESULTS

Never state that a feature was tested in Roblox Studio unless it was
actually tested there.

Distinguish clearly between:

``` text
static/code validation
```

and:

``` text
Roblox Studio gameplay test
```

If Studio testing must be done manually, give the user a short exact
test procedure.

------------------------------------------------------------------------

## 34. GIT SAFETY

Before risky work, inspect repository state.

Do not overwrite unrelated uncommitted user changes.

Do not use destructive Git operations unless explicitly requested and
clearly justified.

Never run commands equivalent to destructive reset/clean operations
merely to simplify your task.

------------------------------------------------------------------------

## 35. COMMITS

Do not create a commit unless the user requested it or the current
workflow explicitly asks the agent to do so.

When a commit is requested, use a clear message such as:

``` text
feat: add world time service
fix: prevent duplicate harvest rewards
docs: update project status
```

Do not push unless requested or explicitly part of the requested
workflow.

------------------------------------------------------------------------

## 36. NEVER COMMIT SECRETS

Never add:

-   passwords;
-   API keys;
-   access tokens;
-   private credentials.

If one is discovered in tracked files, report it rather than propagating
it.

------------------------------------------------------------------------

## 37. DEPENDENCIES

Current workflow may later use:

-   Wally;
-   StyLua;
-   Selene.

Do not install or require them without a current need.

If adding a dependency:

1.  explain why;
2.  keep the dependency minimal;
3.  document required setup;
4.  avoid breaking the existing Rojo workflow.

------------------------------------------------------------------------

## 38. DOCUMENTATION UPDATES

When implementation status changes materially, update:

``` text
docs/PROJECT_STATUS.md
```

When Game Design changes, review:

``` text
docs/GAME_DESIGN.md
docs/ARCHITECTURE.md
docs/ROADMAP.md
docs/PROJECT_STATUS.md
```

Do not mark something `TERMINÉ` merely because code was written.

Official status vocabulary:

``` text
NON COMMENCÉ
EN COURS
PROTOTYPE
À TESTER
TERMINÉ
BLOQUÉ
```

------------------------------------------------------------------------

## 39. FIRST PLAYABLE IS THE CURRENT PRODUCT GOAL

Until the First Playable is reached, prioritize the core loop over
optional expansion.

Current high-level sequence begins with:

``` text
Time / YearsOnIsland
↓
Weather
↓
Interaction
↓
Items / Inventory
↓
Harvesting
↓
Tools
↓
Manual Crafting
↓
Crafting Table
↓
Survival
↓
Water / Food
↓
Sleep
↓
Death
↓
Storage
↓
Building
↓
Persistence
```

Consult `docs/ROADMAP.md` for the full order.

Do not jump to late-game systems merely because they are more
interesting to code.

------------------------------------------------------------------------

## 40. CURRENT IMMEDIATE NEXT STEP

At the time this file was created, the documentation foundation is being
finalized.

After documentation validation, the intended technical start is:

1.  verify Git status;
2.  verify Rojo synchronization;
3.  inspect existing prototype scripts;
4.  decide what prototype code should remain;
5.  implement the official `TimeService`;
6.  implement day/night;
7.  implement YearsOnIsland;
8.  test;
9.  update `PROJECT_STATUS.md`.

Do not assume this section remains current forever.

Always check `docs/PROJECT_STATUS.md` and `docs/ROADMAP.md` before
starting new work.

------------------------------------------------------------------------

## 41. RESPONSE STYLE FOR CODING WORK

When reporting completed work, be concise and concrete.

Preferred structure:

``` text
Done.

Modified:
- path/to/file
- path/to/file

Implemented:
- ...
- ...

Validation:
- ...

Studio test still required:
- ...
```

Do not produce a huge tutorial unless the user asks for one.

When manual action is required, give exact steps.

------------------------------------------------------------------------

## 42. USER-FACING MANUAL REPLACEMENTS

If the user must manually replace code outside the agent workflow,
provide the complete replacement file whenever practical.

Avoid instructions like:

> Replace lines 47--63 with this fragment

when a full ready-to-paste script is safer.

------------------------------------------------------------------------

## 43. STOP CONDITIONS

Stop and ask/report before proceeding when:

-   a required Game Design decision is missing;
-   official documents materially contradict each other;
-   a task requires destructive changes not requested;
-   a dependency would substantially alter the architecture;
-   uncommitted user work would be overwritten;
-   the requested implementation is technically unsafe without a design
    decision.

Do not create fake certainty to continue.

------------------------------------------------------------------------

## 44. FINAL PRINCIPLE

The objective is not maximum code volume.

The objective is:

# BUILD MAYDEAD CLEANLY, QUICKLY, AND SAFELY UNTIL IT IS A COMPLETE PUBLISHABLE ROBLOX GAME.

Protect:

-   the Game Design;
-   player saves;
-   multiplayer integrity;
-   performance;
-   code readability;
-   development speed.

Every technical decision should support those goals.

## 45. HISTORICAL ASSET SAFETY

A name containing `Test`, `_Test`, `Debug`, `Prototype`, `Old`, or `Temp` is
never sufficient evidence that a MAYDEAD asset is unused. Check both code
references and the Roblox Studio DataModel before deletion. Known names such
as `Tree_Test`, `Stone_Test`, `MetalRock_Test`, and `Crystal_Test` must not be
renamed or removed merely because of their names.
