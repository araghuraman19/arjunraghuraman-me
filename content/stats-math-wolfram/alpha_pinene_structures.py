"""ChemDraw-style (ACS Document 1996) structures for the alpha-pinene case study.

Draws alpha-pinene, dipentene, allo-ocimene and alpha-pyronene with RDKit's
ACS 1996 mode (the same bond length, line width, and double-bond spacing as
ChemDraw's "ACS Document 1996" style sheet), lays them out in one row with
labels, and writes a light and a dark PNG (site convention: <name>.png plus
<name>-dark.png).

Layouts: alpha-pinene uses hand-placed coordinates for the textbook depiction
(hexagon with the gem-dimethyl carbon at the top and the CH2 bridge drawn inside
the ring). The other three use PubChem's 2D coordinates, which are already
conventional; the SDFs are saved in pubchem_2d/ next to this script, so it
needs no network access (it falls back to RDKit's CoordGen if one is missing).

Usage: python3 alpha_pinene_structures.py [outDir] [sdfDir]
Requires rdkit and cairosvg.
"""

import io
import re
import sys
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw, ImageFont
from rdkit import Chem
from rdkit.Chem import Descriptors, rdMolDescriptors
from rdkit.Chem.Draw import rdMolDraw2D
from rdkit.Geometry import Point3D

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent

THEMES = {
    "": {"ink": "#232323", "muted": "#5c5c58"},
    "-dark": {"ink": "#ece9e3", "muted": "#9a988f"},
}

S3 = 3 ** 0.5 / 2

# alpha-pinene, SMILES atom order: 0 Me, 1 C2(=), 2 C3(=CH), 3 C4(H2), 4 C5 bridgehead,
# 5 C7(H2) bridge, 6 C1 bridgehead, 7 C6(Me2), 8 Me, 9 Me
PINENE = ("CC1=CCC2CC1C2(C)C", [
    (-2 * S3, -1.0), (-S3, -0.5), (0.0, -1.0), (S3, -0.5), (S3, 0.5),
    (0.0, 0.1), (-S3, 0.5), (0.0, 1.0), (-0.5, 1.0 + S3), (0.5, 1.0 + S3),
])


def pubchem_layout(smiles, sdf):
    """Use PubChem 2D coordinates if the SDF is at hand, else RDKit's CoordGen."""
    m = Chem.MolFromSmiles(smiles)
    if sdf and Path(sdf).exists():
        ref = Chem.RemoveHs(Chem.MolFromMolFile(str(sdf)))
        match = ref.GetSubstructMatch(m)
        conf = Chem.Conformer(m.GetNumAtoms())
        for i, j in enumerate(match):
            p = ref.GetConformer().GetAtomPosition(j)
            conf.SetAtomPosition(i, Point3D(p.x, p.y, 0))
        m.AddConformer(conf, assignId=True)
    else:
        from rdkit.Chem import rdDepictor
        rdDepictor.SetPreferCoordGen(True)
        rdDepictor.Compute2DCoords(m)
    return m


def with_coords(smiles, xy):
    m = Chem.MolFromSmiles(smiles)
    conf = Chem.Conformer(m.GetNumAtoms())
    for i, (x, y) in enumerate(xy):
        conf.SetAtomPosition(i, Point3D(x, y, 0))
    m.AddConformer(conf, assignId=True)
    return m


SDF_DIR = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(__file__).parent / "pubchem_2d"
species = [
    ("1", "α-Pinene", with_coords(*PINENE)),
    ("2", "Dipentene", pubchem_layout("C=C(C)C1CC=C(C)CC1", SDF_DIR and SDF_DIR / "limonene.sdf")),
    ("3", "Allo-ocimene", pubchem_layout("C/C=C(C)/C=C/C=C(C)C", SDF_DIR and SDF_DIR / "allo-ocimene.sdf")),
    ("4", "α-Pyronene", pubchem_layout("CC1=CC=CC(C)(C)C1C", SDF_DIR and SDF_DIR / "alpha-pyronene.sdf")),
]


def hex_to_rgb(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))


def mol_svg(m, ink):
    d = rdMolDraw2D.MolDraw2DSVG(-1, -1)
    o = d.drawOptions()
    rdMolDraw2D.SetACS1996Mode(o, rdMolDraw2D.MeanBondLength(m))
    o.setAtomPalette({-1: hex_to_rgb(ink)})
    o.clearBackground = False
    d.DrawMolecule(m)
    d.FinishDrawing()
    svg = d.GetDrawingText()
    w, h = (float(v) for v in re.search(r"width='([\d.]+)px' height='([\d.]+)px'", svg).groups())
    body = svg[svg.index(">", svg.index("<svg")) + 1: svg.rindex("</svg>")]
    body = re.sub(r"<\?xml[^>]*\?>", "", body)
    return w, h, body


SCALE = 4  # px per pt in the PNG
FONT = "/System/Library/Fonts/Helvetica.ttc"  # index 0 regular, 1 bold


def label_runs(text):
    """Split into (text, is_subscript) runs: digits right after a letter are subscripts."""
    parts = re.split(r"((?<=[A-Za-z])\d+)", text)  # odd indices are the captured subscripts
    return [(t, i % 2 == 1) for i, t in enumerate(parts) if t]


def draw_label(draw, cx, y, text, size, color, bold=False):
    """Draw centered text with subscripts (cairosvg mangles centered tspans, so PIL does labels)."""
    full = ImageFont.truetype(FONT, int(size * SCALE), index=1 if bold else 0)
    small = ImageFont.truetype(FONT, int(0.72 * size * SCALE), index=1 if bold else 0)
    runs = [(t, small if sub else full, 0.28 * size * SCALE if sub else 0) for t, sub in label_runs(text)]
    width = sum(draw.textlength(t, font=f) for t, f, _ in runs)
    x = cx - width / 2
    for t, f, dy in runs:
        draw.text((x, y + dy + (full.size - f.size) * 0.8), t, font=f, fill=color)
        x += draw.textlength(t, font=f)


def figure(theme):
    ink, muted = theme["ink"], theme["muted"]
    cells = []
    for _, _, m in species:
        w, h, body = mol_svg(m, ink)
        svg = (f"<svg xmlns='http://www.w3.org/2000/svg' width='{w}' height='{h}' "
               f"viewBox='0 0 {w} {h}'>{body}</svg>")
        cells.append(Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode(), scale=SCALE))).convert("RGBA"))
    col_w = max(max(c.width for c in cells), 118 * SCALE)
    mol_h = max(c.height for c in cells)
    gap, pad = 18 * SCALE, 8 * SCALE
    W, H = pad * 2 + col_w * 4 + gap * 3, pad * 2 + mol_h + 34 * SCALE
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for k, ((resp, name, m), cell) in enumerate(zip(species, cells)):
        x0 = pad + k * (col_w + gap)
        img.alpha_composite(cell, (x0 + (col_w - cell.width) // 2, pad + (mol_h - cell.height) // 2))
        cx = x0 + col_w / 2
        formula = rdMolDescriptors.CalcMolFormula(m)  # C10H16
        draw_label(draw, cx, pad + mol_h + 3 * SCALE, name, 11, ink, bold=True)
        draw_label(draw, cx, pad + mol_h + 18 * SCALE,
                   f"f{resp}  ·  {formula}  ·  {Descriptors.MolWt(m):.2f} g/mol", 9.5, muted)
    return img


for suffix, theme in THEMES.items():
    figure(theme).save(OUT / f"alpha_pinene_species{suffix}.png")
    print("wrote", OUT / f"alpha_pinene_species{suffix}.png")
