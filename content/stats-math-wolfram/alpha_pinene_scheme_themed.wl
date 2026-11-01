(* Themed export of the alpha-pinene reaction scheme.
   Based on alpha-pinene-scheme.nb (that notebook is left untouched).
   Usage: wolframscript -file alpha_pinene_scheme_themed.wl light|dark [outDir]
   Writes alpha_pinene_scheme.png, with a -dark
   suffix for the dark theme (site convention for Figure light/dark pairs). *)

theme = If[Length[$ScriptCommandLine] >= 2, $ScriptCommandLine[[2]], "light"];
outDir = If[Length[$ScriptCommandLine] >= 3, $ScriptCommandLine[[3]], DirectoryName[$InputFileName]];
dark = theme === "dark";
suffix = If[dark, "-dark", ""];

ink = If[dark, RGBColor["#ece9e3"], RGBColor["#232323"]];
inkMuted = If[dark, RGBColor["#9a988f"], RGBColor["#5c5c58"]];
vertexFill = If[dark, RGBColor["#1f3a35"], RGBColor["#d7ebe6"]];  (* site teal, softened *)
vertexEdge = If[dark, RGBColor["#4f9c8c"], RGBColor["#2e7d6e"]];
font = "Helvetica";
bgC = If[dark, RGBColor["#18191b"], RGBColor["#f7f7f5"]];  (* page background, used behind edge labels *)
hy = "\:2010";  (* real hyphen; a plain "-" in a label renders as a minus sign *)
sub[x_, n_] := Subscript[x, n];

(* Reaction network: rate constants exp(theta_i) as in Bates & Watts *)
names = {"\[Alpha]-Pinene", "Dipentene", "Allo-ocimene", "Pyronene", "Dimer"};
label[n_] := Style[StringReplace[n, "-" -> hy], SingleLetterItalics -> False];
theta[i_] := Style[sub["\[Theta]", i], Background -> bgC];
scheme = Graph[
  names,
  {Labeled[DirectedEdge["\[Alpha]-Pinene", "Dipentene"], theta[1]],
   Labeled[DirectedEdge["\[Alpha]-Pinene", "Allo-ocimene"], theta[2]],
   Labeled[DirectedEdge["Allo-ocimene", "Pyronene"], theta[3]],
   Labeled[DirectedEdge["Allo-ocimene", "Dimer"], theta[4]],
   Labeled[DirectedEdge["Dimer", "Allo-ocimene"], theta[5]]},
  VertexCoordinates -> {{0, 1}, {-1.2, 0}, {1.2, 0}, {0.15, -1}, {2.25, -1}},
  VertexLabels -> (# -> Placed[label[#], Center] & /@ names),
  VertexLabelStyle -> Directive[ink, 15, FontFamily -> font],
  VertexSize -> {0.72, 0.26},
  VertexShapeFunction -> "RoundedRectangle",
  VertexStyle -> Directive[vertexFill, EdgeForm[{vertexEdge, AbsoluteThickness[1.5]}]],
  EdgeStyle -> Directive[ink, AbsoluteThickness[1.6], Arrowheads[0.035]],
  EdgeShapeFunction -> GraphElementData[{"Arrow", "ArrowSize" -> 0.035}],
  EdgeLabelStyle -> Directive[inkMuted, 16, FontFamily -> font],
  ImageSize -> 640, ImagePadding -> 20, Background -> None];

Export[FileNameJoin[{outDir, "alpha_pinene_scheme" <> suffix <> ".png"}], scheme,
  ImageResolution -> 200, Background -> None];

(* Species structures are drawn separately, in ChemDraw's ACS 1996 style, by alpha_pinene_structures.py *)

Print["Exported ", theme, " to ", outDir];
