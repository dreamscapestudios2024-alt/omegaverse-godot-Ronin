extends RefCounted
## All tunable numbers live here.
## Everything marked PROVISIONAL is a prototype default chosen for Stage 1,
## NOT an established Omegaverse rule. Change freely while balancing.

# --- World layout (pixels, viewport is 1152x648) ---
const TERRITORY = Rect2(24, 124, 788, 500)
const PLAYER_SPEED = 210.0
const PLAYER_RADIUS = 14.0
const INTERACT_RANGE = 52.0          # measured from the edge of the object to the player centre

# --- Resources (PROVISIONAL) ---
const RESOURCE_CHARGES = 3           # gathers before a node is depleted
# Environmental respawn: a used-up node regrows on its own after this many seconds.
# Trees and the leaves growing beside them share the same slow timer. (PROVISIONAL ~1 minute)
const RESPAWN_SECONDS = {"wood": 60.0, "grass": 60.0, "leaves": 60.0}
const INVENTORY_CAP_PER_TYPE = 20
const GATHER_OBJECTIVE_AMOUNT = 6    # "gather materials" objective: total items gathered

# --- Farming (PROVISIONAL) ---
const CROP_GROW_SECONDS = 12.0

# --- Nest (PROVISIONAL) ---
const NEST_RADIUS = 46.0
const NEST_COST = {"wood": 8, "grass": 6, "leaves": 6}   # total needed for 100%
const NEST_MILESTONE_STEP = 25       # visual upgrade every 25%

# --- Happiness / influence (PROVISIONAL stand-ins) ---
const HAPPINESS_PER_NEST_PERCENT = 0.9   # nest 100% -> 90 happiness
const HAPPINESS_CROP_BONUS = 10.0        # first harvest adds +10
const INFLUENCE_FROM_HAPPINESS = 0.8     # influence = happiness * 0.8 (stand-in only)
# Future link (NOT implemented): pack happiness needs a much higher threshold than
# individual happiness and only exists in multiplayer.
const PACK_HAPPINESS_THRESHOLD_FUTURE = 95.0

# --- Scent (PROVISIONAL) ---
const SCENT_UNLOCK_NEST_PERCENT = 50.0   # provisional unlock threshold
const SCENT_BASE_RANGE = 160.0
const SCENT_RANGE_PER_INFLUENCE = 3.0    # extra visible range per influence point
const POSTS_TO_MARK = 4

# --- Pastel palette ---
const COL_BG = Color("f7e7ed")
const COL_GRASS = Color("cfebd6")
const COL_SPECKLE = Color("b6dcc1")
const COL_BORDER = Color("a18aca")
const COL_SOIL = Color("d8b8a8")
const COL_TEXT = Color("5b4b66")
const COL_PINK = Color("f4a6c0")
const COL_LAVENDER = Color("a18aca")
const COL_MINT = Color("9fdcb5")
