"""Shared low-poly fantasy asset framework for KnightRPG: Fractured Worlds.

One unified style: flat-shaded primitives, one shared color palette,
consistent proportions. Build space is Z-up; exported GLBs are converted
to glTF Y-up so they import correctly into Godot 4.x.
Characters are modeled facing +Y, which becomes -Z (Godot forward).
"""
import os
import numpy as np
import trimesh
from trimesh.visual import TextureVisuals
from trimesh.visual.material import PBRMaterial
from trimesh.transformations import euler_matrix

OUT_ROOT = "/sessions/stoic-sharp-hawking/mnt/3D_RGP_V2_inventaireAmeliorer/assets/model/FantasyPack"

# name: (r, g, b, metallic, roughness, emissive_strength)
PAL = {
    "steel":         (0.60, 0.64, 0.72, 0.9, 0.35, 0),
    "steel_dark":    (0.28, 0.30, 0.36, 0.9, 0.50, 0),
    "iron":          (0.35, 0.37, 0.42, 0.8, 0.60, 0),
    "gold":          (0.85, 0.65, 0.18, 1.0, 0.30, 0),
    "wood":          (0.42, 0.28, 0.16, 0.0, 0.90, 0),
    "wood_dark":     (0.26, 0.17, 0.10, 0.0, 0.90, 0),
    "wood_light":    (0.55, 0.40, 0.24, 0.0, 0.90, 0),
    "stone":         (0.52, 0.50, 0.48, 0.0, 1.00, 0),
    "stone_dark":    (0.33, 0.32, 0.34, 0.0, 1.00, 0),
    "leather":       (0.45, 0.30, 0.18, 0.0, 0.80, 0),
    "cloth_red":     (0.62, 0.14, 0.14, 0.0, 0.90, 0),
    "cloth_blue":    (0.18, 0.28, 0.55, 0.0, 0.90, 0),
    "cloth_purple":  (0.35, 0.18, 0.50, 0.0, 0.90, 0),
    "grass":         (0.30, 0.48, 0.22, 0.0, 1.00, 0),
    "leaf":          (0.22, 0.42, 0.20, 0.0, 0.95, 0),
    "leaf_dark":     (0.14, 0.30, 0.15, 0.0, 0.95, 0),
    "skin":          (0.85, 0.65, 0.50, 0.0, 0.90, 0),
    "goblin":        (0.35, 0.55, 0.25, 0.0, 0.85, 0),
    "orc":           (0.30, 0.42, 0.28, 0.0, 0.85, 0),
    "bone":          (0.88, 0.85, 0.75, 0.0, 0.80, 0),
    "slime":         (0.30, 0.70, 0.35, 0.0, 0.40, 0.15),
    "red_brute":     (0.75, 0.13, 0.10, 0.0, 0.70, 0.30),
    "void":          (0.16, 0.10, 0.24, 0.0, 0.60, 0),
    "crystal_purple":(0.55, 0.25, 0.95, 0.0, 0.20, 1.0),
    "crystal_blue":  (0.20, 0.55, 0.95, 0.0, 0.20, 1.0),
    "flame":         (1.00, 0.55, 0.15, 0.0, 0.50, 1.0),
    "glass_red":     (0.85, 0.15, 0.20, 0.0, 0.20, 0.55),
    "glass_blue":    (0.20, 0.40, 0.90, 0.0, 0.20, 0.55),
    "glass_green":   (0.20, 0.80, 0.35, 0.0, 0.20, 0.55),
    "mushroom":      (0.80, 0.30, 0.25, 0.0, 0.90, 0),
    "dark":          (0.08, 0.08, 0.10, 0.0, 0.90, 0),
    "parchment":     (0.85, 0.78, 0.60, 0.0, 0.90, 0),
}

_MATS = {}
def mat(name):
    if name not in _MATS:
        r, g, b, met, rough, em = PAL[name]
        _MATS[name] = PBRMaterial(
            name="P_" + name,
            baseColorFactor=[r, g, b, 1.0],
            metallicFactor=met,
            roughnessFactor=rough,
            emissiveFactor=[r * min(em, 1.0), g * min(em, 1.0), b * min(em, 1.0)],
        )
    return _MATS[name]

PARTS = []

def _finish(mesh, mname, loc, rot, scale):
    if scale is not None:
        mesh.apply_scale(scale)
    if rot != (0, 0, 0):
        mesh.apply_transform(euler_matrix(rot[0], rot[1], rot[2], "sxyz"))
    mesh.apply_translation(loc)
    mesh.unmerge_vertices()
    mesh.visual = TextureVisuals(material=mat(mname))
    PARTS.append(mesh)
    return mesh

def cube(m, size, loc, rot=(0, 0, 0)):
    return _finish(trimesh.creation.box(extents=size), m, loc, rot, None)

def cyl(m, r, d, loc, rot=(0, 0, 0), v=8):
    return _finish(trimesh.creation.cylinder(radius=r, height=d, sections=v), m, loc, rot, None)

def frustum(m, r1, r2, d, loc, rot=(0, 0, 0), v=8):
    """Truncated cone: r1 bottom, r2 top, height d, centered on origin."""
    ang = np.linspace(0, 2 * np.pi, v, endpoint=False)
    bot = np.column_stack([np.cos(ang) * r1, np.sin(ang) * r1, np.full(v, -d / 2)])
    top = np.column_stack([np.cos(ang) * r2, np.sin(ang) * r2, np.full(v, d / 2)])
    verts = np.vstack([bot, top, [[0, 0, -d / 2]], [[0, 0, d / 2]]])
    faces = []
    for i in range(v):
        j = (i + 1) % v
        faces += [[i, j, v + i], [j, v + j, v + i]]
        faces += [[2 * v, j, i], [2 * v + 1, v + i, v + j]]
    return _finish(trimesh.Trimesh(vertices=verts, faces=faces, process=False), m, loc, rot, None)

def cone(m, r, d, loc, rot=(0, 0, 0), v=8):
    c = trimesh.creation.cone(radius=r, height=d, sections=v)
    c.apply_translation([0, 0, -d / 2])
    return _finish(c, m, loc, rot, None)

def ico(m, r, loc, sub=1, scale=None, rot=(0, 0, 0)):
    return _finish(trimesh.creation.icosphere(subdivisions=sub, radius=r), m, loc, rot, scale)

def sph(m, r, loc, scale=None, rot=(0, 0, 0)):
    s = trimesh.creation.uv_sphere(radius=r, count=[8, 6])
    return _finish(s, m, loc, rot, scale)

def ring(m, r_out, r_in, d, loc, rot=(0, 0, 0), v=12):
    a = trimesh.creation.annulus(r_min=r_in, r_max=r_out, height=d, sections=v)
    return _finish(a, m, loc, rot, None)

def rock(m, r, loc, seed=0, scale=None, sub=1):
    rng = np.random.default_rng(seed)
    s = trimesh.creation.icosphere(subdivisions=sub, radius=r)
    s.vertices += rng.normal(0, r * 0.16, s.vertices.shape)
    s.vertices[:, 2] *= 0.8
    return _finish(s, m, loc, (0, 0, 0), scale)

_ZUP_TO_YUP = np.array([
    [1, 0, 0, 0],
    [0, 0, 1, 0],
    [0, -1, 0, 0],
    [0, 0, 0, 1],
], dtype=float)

MANIFEST = []

def asset(name, category):
    global PARTS
    folder = os.path.join(OUT_ROOT, category)
    os.makedirs(folder, exist_ok=True)
    scene = trimesh.Scene()
    for i, p in enumerate(PARTS):
        p.apply_transform(_ZUP_TO_YUP)
        scene.add_geometry(p, node_name=f"{name}_{i:02d}", geom_name=f"{name}_{i:02d}")
    path = os.path.join(folder, name + ".glb")
    scene.export(path)
    n_tris = sum(len(p.faces) for p in PARTS)
    MANIFEST.append((category, name, len(PARTS), n_tris))
    PARTS = []
    return path

def report():
    for cat, name, nparts, ntris in MANIFEST:
        print(f"{cat:12s} {name:28s} parts={nparts:3d} tris={ntris:5d}")
    print(f"TOTAL {len(MANIFEST)} assets")
