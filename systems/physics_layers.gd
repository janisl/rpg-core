class_name PhysicsLayers

const WORLD = 1
const INTERACTABLES = 2
const PLAYER = 3
const NPCS = 4
const PROJECTILES = 5
const DYNAMIC_OBJECTS = 6
const LIQUIDS = 9
const LADDERS = 10

const WORLD_MASK = 1 << (WORLD - 1)
const INTERACTABLES_MASK = 1 << (INTERACTABLES - 1)
const PLAYER_MASK = 1 << (PLAYER - 1)
const NPCS_MASK = 1 << (NPCS - 1)
const PROJECTILES_MASK = 1 << (PROJECTILES - 1)
const DYNAMIC_OBJECTS_MASK = 1 << (DYNAMIC_OBJECTS - 1)
const LIQUIDS_MASK = 1 << (LIQUIDS - 1)
const LADDERS_MASK = 1 << (LADDERS - 1)
