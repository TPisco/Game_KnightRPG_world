from lowpoly import *

# ================= PLAYER KNIGHT (faces +Y, ~1.75m tall) =================
cube("steel_dark",(0.18,0.28,0.12),(-0.12,0.04,0.06))       # foot L
cube("steel_dark",(0.18,0.28,0.12),( 0.12,0.04,0.06))       # foot R
cube("steel",(0.17,0.17,0.45),(-0.12,0,0.345))              # leg L
cube("steel",(0.17,0.17,0.45),( 0.12,0,0.345))              # leg R
cube("steel_dark",(0.42,0.28,0.14),(0,0,0.63))              # hips
cube("leather",(0.46,0.32,0.07),(0,0,0.72))                 # belt
cube("steel",(0.50,0.30,0.42),(0,0,0.97))                   # torso
cube("gold",(0.16,0.04,0.16),(0,0.16,1.02))                 # emblem
cube("steel_dark",(0.24,0.28,0.16),(-0.34,0,1.16))          # pauldron L
cube("steel_dark",(0.24,0.28,0.16),( 0.34,0,1.16))          # pauldron R
cube("steel",(0.14,0.14,0.40),(-0.34,0,0.88))               # arm L
cube("steel",(0.14,0.14,0.40),( 0.34,0,0.88))               # arm R
cube("steel_dark",(0.16,0.16,0.14),(-0.34,0,0.63))          # gauntlet L
cube("steel_dark",(0.16,0.16,0.14),( 0.34,0,0.63))          # gauntlet R
cube("steel",(0.30,0.30,0.30),(0,0,1.42))                   # helmet head
cube("dark",(0.24,0.06,0.09),(0,0.15,1.44))                 # visor slit
cube("steel_dark",(0.32,0.32,0.08),(0,0,1.56))              # helm brow
cube("cloth_red",(0.07,0.34,0.14),(0,0,1.66))               # crest
cube("cloth_red",(0.44,0.05,0.75),(0,-0.20,0.86))           # cape
asset("player_knight","characters")

# ================= MERCHANT / SHOPKEEPER (~1.55m) =================
cube("wood_dark",(0.16,0.24,0.10),(-0.11,0.03,0.05))
cube("wood_dark",(0.16,0.24,0.10),( 0.11,0.03,0.05))
cube("cloth_blue",(0.15,0.15,0.40),(-0.11,0,0.31))
cube("cloth_blue",(0.15,0.15,0.40),( 0.11,0,0.31))
frustum("leather",0.30,0.22,0.55,(0,0,0.78))                # tunic
cube("parchment",(0.28,0.05,0.40),(0,0.19,0.80))            # apron
cube("leather",(0.12,0.12,0.38),(-0.30,0,0.82))
cube("leather",(0.12,0.12,0.38),( 0.30,0,0.82))
sph("skin",0.07,(-0.30,0,0.60))
sph("skin",0.07,( 0.30,0,0.60))
cube("skin",(0.26,0.26,0.26),(0,0,1.22))                    # head
cube("skin",(0.05,0.08,0.05),(0,0.15,1.20))                 # nose
cube("stone",(0.20,0.06,0.12),(0,0.13,1.10))                # grey beard
cone("cloth_red",0.24,0.30,(0,0,1.50))                      # hat cone
cyl("cloth_red",0.28,0.03,(0,0,1.37),v=10)                  # hat brim
asset("merchant","characters")
report()
